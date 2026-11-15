import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agent_payment_ai_recomendation/models/ai_recommendation.dart';
import 'package:agent_payment_ai_recomendation/models/merchant.dart';
import 'package:agent_payment_ai_recomendation/screens/explanation/recommendation_explanation_screen.dart';
import 'package:agent_payment_ai_recomendation/services/api_status.dart';

const _elPortal = Merchant(
  id: 'TXN-99284-B',
  name: 'Restaurante El Portal',
  location: 'Bogotá, COL',
  category: MerchantCategory.restaurant,
  amount: 145200,
);

const _modaAndina = Merchant(
  id: 'TXN-64092-R',
  name: 'Moda Andina',
  location: 'Cali, COL',
  category: MerchantCategory.clothing,
  amount: 215000,
);

// Real answers of the API for profile USR-1483 (Saturday 14-Nov-2026, 3 p.m.).

/// El Portal: credit is the habit, but the incentive makes transfer win.
const _incentiveWins = {
  'disponible': true,
  'recomendacion': 'DIRECT_ACCOUNT_TRANSFER',
  'habito': 'CREDIT_CARD_BANK',
  'sugerencia_activa': true,
  'propensiones': {
    'CREDIT_CARD_BANK': 0.6584,
    'DEBIT_CARD': 0.1548,
    'DIRECT_ACCOUNT_TRANSFER': 0.1869,
  },
  'utilidades': {
    'CREDIT_CARD_BANK': 0.3292,
    'DEBIT_CARD': 0.0774,
    'DIRECT_ACCOUNT_TRANSFER': 0.5768,
  },
  'factibles': ['CREDIT_CARD_BANK', 'DEBIT_CARD', 'DIRECT_ACCOUNT_TRANSFER'],
  'excluidos': <String, String>{},
  'beneficio_cop': 14500.0,
  'motivo': 'Lo más probable es que pagues con crédito (66 %), pero con '
      'transferencia ahorras \$14.500 por el incentivo del comercio.',
  'perfil': 'USR-1483',
  'contexto': {
    'monto': 145200.0,
    'incentivo_cop': 14500.0,
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
  'latencia_ms': 28.69,
};

/// Moda Andina: the balance doesn't cover the purchase, so transfer is
/// discarded although its utility is the highest.
const _balanceTooLow = {
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
  'beneficio_cop': 0.0,
  'motivo': 'Tu saldo no cubre esta compra con débito ni transferencia, '
      'por eso te sugerimos crédito.',
  'perfil': 'USR-1483',
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

/// Supermercado Central for the customer without a credit card (USR-1167,
/// Saturday 14-Nov-2026, 8 p.m.): the model sees credit as the most probable
/// method, but the customer doesn't own one.
const _noCreditCard = {
  'disponible': true,
  'recomendacion': 'DIRECT_ACCOUNT_TRANSFER',
  'habito': 'DIRECT_ACCOUNT_TRANSFER',
  'sugerencia_activa': false,
  'propensiones': {
    'CREDIT_CARD_BANK': 0.5107,
    'DEBIT_CARD': 0.0976,
    'DIRECT_ACCOUNT_TRANSFER': 0.3917,
  },
  'utilidades': {
    'CREDIT_CARD_BANK': 0.2554,
    'DEBIT_CARD': 0.0488,
    'DIRECT_ACCOUNT_TRANSFER': 0.7292,
  },
  'factibles': ['DEBIT_CARD', 'DIRECT_ACCOUNT_TRANSFER'],
  'excluidos': {'CREDIT_CARD_BANK': 'sin_producto'},
  'beneficio_cop': 16000.0,
  'motivo': 'Te sugerimos transferencia: es tu medio más probable (39 %) y '
      'además ahorras \$16.000 por el incentivo del comercio.',
  'perfil': 'USR-1167',
  'contexto': {
    'monto': 320000.0,
    'incentivo_cop': 16000.0,
    'incentivo_aplica_a': 'DIRECT_ACCOUNT_TRANSFER',
    'saldo_cop': 600000.0,
    'uso_cupo': 1.0,
    'medios': ['DEBIT_CARD', 'DIRECT_ACCOUNT_TRANSFER'],
    'fuente_perfil': 'peticion',
    'hora': 20,
    'dia_semana': 5,
    'dia_quincena': true,
  },
  'modelo_version': 'xgb-v10-b2afda2f',
  'latencia_ms': 6.54,
};

const _supermercado = Merchant(
  id: 'TXN-55110-A',
  name: 'Supermercado Central',
  location: 'Medellín, COL',
  category: MerchantCategory.grocery,
  amount: 320000,
);

const _meta = {
  'modelo_version': 'xgb-v10-b2afda2f',
  'capa2': {
    'w_propension': 0.5,
    'w_beneficio': 0.5,
    'ref_incentivo_cop': 15000.0,
    'incentivo_aplica_a': 'DIRECT_ACCOUNT_TRANSFER',
    'tope_incentivo_cop': 25000,
    'uso_cupo_max': 0.9,
  },
};

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Merchant merchant,
  required Map<String, dynamic> answer,
  bool apiPublishesWeights = true,
}) async {
  // Tall surface so the whole breakdown is laid out.
  tester.view.physicalSize = const Size(1080, 4800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final status = ApiStatus(
    client: MockClient(
      (_) async => apiPublishesWeights
          ? http.Response.bytes(utf8.encode(jsonEncode(_meta)), 200)
          : http.Response('', 503),
    ),
    baseUrl: 'http://api.test',
  );
  await tester.pumpWidget(MaterialApp(
    home: RecommendationExplanationScreen(
      merchant: merchant,
      ai: AiRecommendation.fromJson(answer),
      status: status,
    ),
  ));
  await tester.pumpAndSettle();
}

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  testWidgets('breaks the recommendation down into both layers',
      (tester) async {
    await _pumpScreen(tester, merchant: _elPortal, answer: _incentiveWins);

    // The API's own sentence, and the same decision in numbers.
    expect(find.textContaining('Lo más probable es que pagues'), findsOneWidget);
    expect(
      find.text(
        'Transferencia: probabilidad 19 % + incentivo \$14.500 '
        '→ utilidad 0,58, frente a 0,33 de crédito.',
      ),
      findsOneWidget,
    );

    // Methods ordered by utility, with their role in the decision.
    expect(_top(tester, 'Transferencia'), lessThan(_top(tester, 'Crédito')));
    expect(_top(tester, 'Crédito'), lessThan(_top(tester, 'Débito')));
    expect(find.text('SUGERIDO'), findsOneWidget);
    expect(find.text('MÁS PROBABLE'), findsOneWidget);
    expect(find.text('DESCARTADO'), findsNothing);
    expect(find.text('66 %'), findsOneWidget);
    expect(find.text('0,58'), findsOneWidget);

    // The sum behind each utility, with the weights the API publishes.
    expect(
      find.text('utilidad = 0,5 × probabilidad + 0,5 × (incentivo ÷ \$15.000)'),
      findsOneWidget,
    );
    expect(find.text('0,5 × 0,187 + 0,5 × 0,967 = 0,577'), findsOneWidget);
    expect(find.text('0,5 × 0,658 + 0,5 × 0 = 0,329'), findsOneWidget);
    expect(find.text('0,5 × 0,155 + 0,5 × 0 = 0,077'), findsOneWidget);
    expect(find.textContaining('el cupo usado llega al 90 %'), findsOneWidget);

    // What the API decided with.
    expect(find.text('\$145.200'), findsOneWidget);
    expect(find.text('\$150.000'), findsOneWidget);
    expect(find.text('\$14.500 por transferencia'), findsOneWidget);
    // The customer data the API decided with, and where it came from.
    expect(find.text('crédito, débito y transferencia'), findsOneWidget);
    expect(find.text('Enviados por la app'), findsOneWidget);
    expect(find.text('sábado, 15 h · quincena'), findsOneWidget);
    expect(find.text('xgb-v10-b2afda2f'), findsOneWidget);
    expect(find.text('29 ms'), findsOneWidget);
  });

  testWidgets('says when a method was discarded despite the best utility',
      (tester) async {
    await _pumpScreen(tester, merchant: _modaAndina, answer: _balanceTooLow);

    expect(
      find.text('Crédito: probabilidad 52 % → utilidad 0,26.'),
      findsOneWidget,
    );
    // Methods the user can pay with come first.
    expect(_top(tester, 'Crédito'), lessThan(_top(tester, 'Transferencia')));
    expect(find.text('DESCARTADO'), findsNWidgets(2));
    expect(
      find.text(
        'Saldo insuficiente para esta compra. Tenía la mayor utilidad, '
        'pero no puedes pagar con este medio.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Saldo insuficiente para esta compra. No entra en la comparación.',
      ),
      findsOneWidget,
    );
    expect(find.text('0,5 × 0,454 + 0,5 × 1,667 = 1,060'), findsOneWidget);
  });

  testWidgets('without the weights it shows only what the API returned',
      (tester) async {
    await _pumpScreen(
      tester,
      merchant: _elPortal,
      answer: _incentiveWins,
      apiPublishesWeights: false,
    );

    expect(find.textContaining('→ utilidad 0,58'), findsOneWidget);
    expect(find.text('0,33'), findsOneWidget);
    expect(find.textContaining('×'), findsNothing);
    expect(
      find.textContaining('La utilidad combina la probabilidad con el incentivo'),
      findsOneWidget,
    );
  });

  testWidgets('explains a method the customer does not own', (tester) async {
    await _pumpScreen(tester, merchant: _supermercado, answer: _noCreditCard);

    expect(
      find.text(
        'Transferencia: probabilidad 39 % + incentivo \$16.000 '
        '→ utilidad 0,73, frente a 0,05 de débito.',
      ),
      findsOneWidget,
    );
    // Credit is the model's most probable method, but it isn't offered.
    expect(find.text('51 %'), findsOneWidget);
    expect(find.text('DESCARTADO'), findsOneWidget);
    expect(
      find.text('No tienes este medio de pago. No entra en la comparación.'),
      findsOneWidget,
    );
    // "Most probable" is said of a method the customer owns.
    expect(_top(tester, 'MÁS PROBABLE'), lessThan(_top(tester, 'Débito')));

    expect(find.text('\$600.000'), findsOneWidget);
    expect(find.text('Sin tarjeta de crédito'), findsOneWidget);
    expect(find.text('débito y transferencia'), findsOneWidget);
    expect(find.text('Enviados por la app'), findsOneWidget);
  });

  testWidgets('says when the customer data came from the API catalog',
      (tester) async {
    final answer = {
      ..._incentiveWins,
      'contexto': {
        ...(_incentiveWins['contexto']! as Map<String, Object>),
        'fuente_perfil': 'catalogo',
      },
    };
    await _pumpScreen(tester, merchant: _elPortal, answer: answer);

    expect(find.text('Catálogo de la API'), findsOneWidget);
    expect(find.text('Enviados por la app'), findsNothing);
  });

  testWidgets('an older API that reports no customer data shows none',
      (tester) async {
    final answer = {
      ..._incentiveWins,
      'contexto': {'incentivo_cop': 14500.0, 'saldo_cop': 150000},
    };
    await _pumpScreen(tester, merchant: _elPortal, answer: answer);

    expect(find.text('\$150.000'), findsOneWidget);
    expect(find.text('MEDIOS DEL CLIENTE'), findsNothing);
    expect(find.text('DATOS DEL CLIENTE'), findsNothing);
    expect(find.text('CUPO DE CRÉDITO USADO'), findsNothing);
  });

  test('no suggestion, no headline', () {
    final ai = AiRecommendation.fromJson({
      ..._balanceTooLow,
      'recomendacion': null,
      'excluidos': {
        'CREDIT_CARD_BANK': 'cupo_agotado',
        'DEBIT_CARD': 'saldo_insuficiente',
        'DIRECT_ACCOUNT_TRANSFER': 'saldo_insuficiente',
      },
    });

    expect(explanationHeadline(ai), isNull);
    expect(ai.runnerUp, isNull);
  });
}
