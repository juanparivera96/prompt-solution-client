import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agent_payment_ai_recomendation/screens/login/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders brand and QR shortcut', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('Banco Inteligente Javeriana'), findsOneWidget);
    expect(find.text('Pagar con QR'), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });
}
