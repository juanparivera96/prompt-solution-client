import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agent_payment_ai_recomendation/data/mock_repository.dart';
import 'package:agent_payment_ai_recomendation/screens/payment_recommendation/payment_recommendation_screen.dart';
import 'package:agent_payment_ai_recomendation/services/api_recommendation_service.dart';
import 'package:agent_payment_ai_recomendation/services/session_manager.dart';

const _clothingQr = 'TXN-64092-R|Moda Andina|Cali, COL|clothing|215000';

/// What the API answers for that purchase with profile USR-1483: the balance
/// doesn't cover it, so only credit is feasible.
const _insufficientBalance = {
  'disponible': true,
  'recomendacion': 'CREDIT_CARD_BANK',
  'habito': 'CREDIT_CARD_BANK',
  'sugerencia_activa': false,
  'propensiones': {
    'CREDIT_CARD_BANK': 0.5243,
    'DEBIT_CARD': 0.0216,
    'DIRECT_ACCOUNT_TRANSFER': 0.4541,
  },
  'utilidades': {
    'CREDIT_CARD_BANK': 0.2622,
    'DEBIT_CARD': 0.0108,
    'DIRECT_ACCOUNT_TRANSFER': 1.0604,
  },
  'factibles': ['CREDIT_CARD_BANK'],
  'excluidos': {
    'DEBIT_CARD': 'saldo_insuficiente',
    'DIRECT_ACCOUNT_TRANSFER': 'saldo_insuficiente',
  },
  'beneficio_cop': 0,
  'motivo': 'Tu saldo no cubre esta compra con débito ni transferencia, '
      'por eso te sugerimos crédito.',
  'contexto': {
    'monto': 215000.0,
    'incentivo_cop': 25000.0,
    'incentivo_aplica_a': 'DIRECT_ACCOUNT_TRANSFER',
    'saldo_cop': 150000,
    'uso_cupo': 0.15,
    'medios': ['CREDIT_CARD_BANK', 'DEBIT_CARD', 'DIRECT_ACCOUNT_TRANSFER'],
    'fuente_perfil': 'peticion',
    'hora': 15,
    'dia_semana': 5,
    'dia_quincena': true,
  },
  'modelo_version': 'xgb-v10-b2afda2f',
  'latencia_ms': 8.21,
};

/// What `GET /v1/meta` answers: the app's "are you awake?" question.
const _meta = {
  'modelo_version': 'xgb-v10-b2afda2f',
  'capa2': {
    'w_propension': 0.5,
    'w_beneficio': 0.5,
    'ref_incentivo_cop': 15000.0,
    'uso_cupo_max': 0.9,
  },
};

http.Response _json(Object body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), 200);

Future<http.Response> _noAnswer() =>
    Future.error(http.ClientException('sin respuesta'));

Future<void> _pumpScreen(WidgetTester tester, MockClientHandler handler) async {
  // Tall surface so the whole product list is laid out.
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  // Logged in as the "Saldo ajustado" customer.
  SessionManager.instance.login(const MockRepository().profileById('USR-1483'));
  addTearDown(SessionManager.instance.reset);

  await tester.pumpWidget(MaterialApp(
    home: PaymentRecommendationScreen(
      qrPayload: _clothingQr,
      service: ApiRecommendationService(
        client: MockClient(handler),
        baseUrl: 'http://api.test',
      ),
    ),
  ));
}

/// An API that is asleep: the first recommendation request gets no answer,
/// and the "are you awake?" check stays pending until [wakeUp] is called.
class _SleepingApi {
  final _awake = Completer<http.Response>();
  int requests = 0;

  Future<http.Response> handle(http.Request request) {
    if (request.url.path == '/v1/meta') return _awake.future;
    requests++;
    return requests == 1
        ? _noAnswer()
        : Future.value(_json(_insufficientBalance));
  }

  void wakeUp() => _awake.complete(_json(_meta));
}

bool _canConfirm(WidgetTester tester) =>
    tester
        .widget<FilledButton>(
          find.widgetWithText(FilledButton, 'CONFIRMAR PAGO'),
        )
        .onPressed !=
    null;

void main() {
  testWidgets('shows the AI recommendation and blocks unaffordable products',
      (tester) async {
    await _pumpScreen(tester, (_) async => _json(_insufficientBalance));

    // First frame: still waiting for the API.
    expect(find.text('Consultando el modelo de IA…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('RECOMENDADO POR IA'), findsOneWidget);
    expect(find.text('SALDO AJUSTADO'), findsOneWidget);
    expect(find.textContaining('Tu saldo no cubre esta compra'), findsOneWidget);
    expect(find.text('MEJOR OPCIÓN'), findsOneWidget);
    // Layer-1 propensity, in the customer's terms.
    expect(
      find.text('Históricamente usas crédito en el 52 % de compras como esta'),
      findsNWidgets(2),
    );
    expect(find.textContaining('Probabilidad de pagar'), findsNothing);
    expect(find.text('Saldo insuficiente para esta compra'), findsNWidgets(2));
    // Each product shows the money the customer can pay with: the balance
    // the app sent to the API explains why debit and transfer are blocked.
    expect(find.text('Saldo disponible: \$150.000'), findsNWidgets(2));
    expect(find.text('Cupo disponible: \$6.800.000'), findsOneWidget);
    expect(find.text('Cupo disponible: \$3.400.000'), findsOneWidget);
    expect(find.textContaining('Despertando la IA'), findsNothing);
    expect(find.text('REINTENTAR CON IA'), findsNothing);
    expect(_canConfirm(tester), isTrue);
  });

  testWidgets('falls back to the rules when the API is down', (tester) async {
    await _pumpScreen(tester, (_) => _noAnswer());
    await tester.pumpAndSettle();

    expect(find.text('RECOMENDACIÓN POR REGLAS'), findsOneWidget);
    expect(find.textContaining('No hubo respuesta del modelo de IA'), findsOneWidget);
    expect(find.text('REINTENTAR CON IA'), findsOneWidget);
    expect(find.text('MEJOR OPCIÓN'), findsOneWidget);
    expect(find.textContaining('Históricamente usas'), findsNothing);
    expect(find.text('¿POR QUÉ ESTA SUGERENCIA?'), findsNothing);
  });

  testWidgets('says the AI is waking up, then shows its recommendation',
      (tester) async {
    final api = _SleepingApi();
    await _pumpScreen(tester, api.handle);
    await tester.pump(const Duration(milliseconds: 100));

    // No silent switch to the rules while the API wakes up.
    expect(find.textContaining('Despertando la IA…'), findsOneWidget);
    expect(find.text('NO ESPERAR: USAR REGLAS'), findsOneWidget);
    expect(find.text('Servidor: api.test'), findsOneWidget);
    expect(find.text('RECOMENDACIÓN POR REGLAS'), findsNothing);
    expect(_canConfirm(tester), isFalse);

    api.wakeUp();
    await tester.pumpAndSettle();

    expect(find.text('RECOMENDADO POR IA'), findsOneWidget);
    expect(find.textContaining('Despertando la IA'), findsNothing);
    expect(api.requests, 2);
    expect(_canConfirm(tester), isTrue);
  });

  testWidgets('the user can pay with the rules instead of waiting',
      (tester) async {
    final api = _SleepingApi();
    await _pumpScreen(tester, api.handle);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('NO ESPERAR: USAR REGLAS'));
    await tester.pump();

    expect(find.text('RECOMENDACIÓN POR REGLAS'), findsOneWidget);
    expect(find.textContaining('No esperaste a que la IA despertara'), findsOneWidget);
    expect(_canConfirm(tester), isTrue);

    // The answer that arrives later doesn't replace what the user chose.
    api.wakeUp();
    await tester.pumpAndSettle();
    expect(find.text('RECOMENDACIÓN POR REGLAS'), findsOneWidget);

    // Asking again, now that the API is awake, brings the AI recommendation.
    await tester.tap(find.text('REINTENTAR CON IA'));
    await tester.pumpAndSettle();
    expect(find.text('RECOMENDADO POR IA'), findsOneWidget);
    expect(find.text('REINTENTAR CON IA'), findsNothing);
  });

  testWidgets('opens the explanation of an AI recommendation', (tester) async {
    await _pumpScreen(
      tester,
      (request) async => request.url.path == '/v1/meta'
          ? _json(_meta)
          : _json(_insufficientBalance),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('¿POR QUÉ ESTA SUGERENCIA?'));
    await tester.pumpAndSettle();

    expect(find.text('¿Por qué esta sugerencia?'), findsOneWidget);
    expect(
      find.text('Crédito: probabilidad 52 % → utilidad 0,26.'),
      findsOneWidget,
    );
    expect(find.text('DESCARTADO'), findsNWidgets(2));
    expect(find.text('Enviados por la app'), findsOneWidget);

    await tester.ensureVisible(find.text('VOLVER AL PAGO'));
    await tester.tap(find.text('VOLVER AL PAGO'));
    await tester.pumpAndSettle();
    expect(find.text('CONFIRMAR PAGO'), findsOneWidget);
  });
}
