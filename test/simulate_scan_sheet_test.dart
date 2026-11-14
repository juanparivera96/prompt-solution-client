import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agent_payment_ai_recomendation/screens/qr_scanner/widgets/simulate_scan_sheet.dart';
import 'package:agent_payment_ai_recomendation/services/api_status.dart';

http.Response _awake() => http.Response.bytes(
      utf8.encode(jsonEncode({'modelo_version': 'xgb-v10-test'})),
      200,
    );

ApiStatus _status(MockClientHandler handler) =>
    ApiStatus(client: MockClient(handler), baseUrl: 'http://api.test');

Future<void> _pumpSheet(WidgetTester tester, ApiStatus status) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SimulateScanSheet(status: status)),
  ));
}

void main() {
  testWidgets('wakes the AI up when it opens and confirms when it is ready',
      (tester) async {
    final answer = Completer<http.Response>();
    var requests = 0;
    await _pumpSheet(
      tester,
      _status((_) {
        requests++;
        return answer.future;
      }),
    );

    expect(requests, 1);
    expect(find.text('Conectando con la IA…'), findsOneWidget);
    expect(find.text('IA lista'), findsNothing);

    answer.complete(_awake());
    await tester.pumpAndSettle();

    expect(find.text('IA lista'), findsOneWidget);
    expect(find.text('Restaurante El Portal'), findsOneWidget);
  });

  testWidgets('says the AI does not answer and lets the user retry',
      (tester) async {
    var requests = 0;
    await _pumpSheet(
      tester,
      _status((_) async {
        requests++;
        if (requests == 1) throw http.ClientException('sin conexión');
        return _awake();
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('La IA no responde'), findsOneWidget);
    expect(
      find.text('La recomendación saldrá por reglas de beneficios.'),
      findsOneWidget,
    );

    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();

    expect(find.text('IA lista'), findsOneWidget);
    expect(requests, 2);
  });

  testWidgets('does not ask again when the AI answered a moment ago',
      (tester) async {
    var requests = 0;
    final status = _status((_) async {
      requests++;
      return _awake();
    });
    await tester.runAsync(status.check);

    await _pumpSheet(tester, status);
    await tester.pumpAndSettle();

    expect(find.text('IA lista'), findsOneWidget);
    expect(requests, 1);
  });
}
