import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agent_payment_ai_recomendation/core/router/app_router.dart';
import 'package:agent_payment_ai_recomendation/data/mock_repository.dart';
import 'package:agent_payment_ai_recomendation/screens/qr_scanner/widgets/scan_verification_sheet.dart';
import 'package:agent_payment_ai_recomendation/services/session_manager.dart';

const _repo = MockRepository();

/// The app from the login screen, with a tall surface so every field and
/// product is laid out.
Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  addTearDown(SessionManager.instance.reset);

  await tester.pumpWidget(const MaterialApp(
    initialRoute: AppRouter.initialRoute,
    onGenerateRoute: AppRouter.onGenerateRoute,
  ));
}

Future<void> _type(WidgetTester tester, String user, String password) async {
  await tester.enterText(find.widgetWithText(TextField, 'Usuario'), user);
  await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), password);
}

Future<void> _tapLogin(WidgetTester tester) async {
  await tester.tap(find.text('INICIAR SESIÓN'));
  await tester.pumpAndSettle();
}

void main() {
  group('demo customers', () {
    test('each one has a unique username and the demo password', () {
      final profiles = _repo.demoProfiles();
      expect(
        profiles.map((p) => p.username),
        ['holgado', 'ajustado', 'cashback', 'sincredito'],
      );
      expect(profiles.every((p) => p.password == 'demo2026'), isTrue);
    });

    test('the username ignores case and spaces; the password does not', () {
      expect(_repo.authenticate('  Ajustado ', 'demo2026')?.id, 'USR-1483');
      expect(_repo.authenticate('ajustado', 'DEMO2026'), isNull);
      expect(_repo.authenticate('nadie', 'demo2026'), isNull);
    });
  });

  testWidgets('wrong credentials do not log in', (tester) async {
    await _pumpApp(tester);

    await _tapLogin(tester);
    expect(find.text('Ingresa tu usuario y tu contraseña.'), findsOneWidget);

    await _type(tester, 'ajustado', 'otra');
    await _tapLogin(tester);
    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
    expect(SessionManager.instance.isLoggedIn, isFalse);

    // Typing again clears the error.
    await tester.enterText(
        find.widgetWithText(TextField, 'Contraseña'), 'demo');
    await tester.pump();
    expect(find.text('Usuario o contraseña incorrectos.'), findsNothing);
  });

  testWidgets('logging in loads the customer and their own products',
      (tester) async {
    await _pumpApp(tester);

    await _type(tester, 'ajustado', 'demo2026');
    await _tapLogin(tester);

    expect(SessionManager.instance.profile?.id, 'USR-1483');
    expect(find.text('MI PERFIL'), findsOneWidget);
    expect(find.text('Saldo ajustado'), findsOneWidget);
    expect(find.text('Usuario: ajustado'), findsOneWidget);
    expect(find.text('\$150.000'), findsOneWidget);
    expect(find.text('15 %'), findsOneWidget);
    expect(find.text('TUS PRODUCTOS (4)'), findsOneWidget);
    expect(find.text('Visa Infinite'), findsOneWidget);
    expect(find.text('Cupo disponible: \$6.800.000'), findsOneWidget);
    expect(find.text('Saldo disponible: \$150.000'), findsNWidgets(2));
  });

  testWidgets('the demo users list fills the form', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('USUARIOS DE DEMOSTRACIÓN'));
    await tester.pumpAndSettle();
    expect(find.text('Usuario: holgado · Contraseña: demo2026'), findsOneWidget);

    await tester.tap(find.text('Sin tarjeta de crédito'));
    await tester.pumpAndSettle();
    await _tapLogin(tester);

    // This customer has no credit card: the profile shows only debit and
    // the account.
    expect(SessionManager.instance.profile?.id, 'USR-1167');
    expect(find.text('TUS PRODUCTOS (2)'), findsOneWidget);
    expect(find.text('No tiene'), findsOneWidget);
    expect(find.text('Visa Infinite'), findsNothing);
    expect(find.text('Mastercard Black'), findsNothing);
    expect(find.text('Saldo disponible: \$600.000'), findsNWidgets(2));
  });

  testWidgets('logging out goes back to the login', (tester) async {
    await _pumpApp(tester);
    await _type(tester, 'holgado', 'demo2026');
    await _tapLogin(tester);

    await tester.ensureVisible(find.text('CERRAR SESIÓN'));
    await tester.tap(find.text('CERRAR SESIÓN'));
    await tester.pumpAndSettle();

    expect(SessionManager.instance.isLoggedIn, isFalse);
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });

  testWidgets('biometrics sign in the last customer again', (tester) async {
    await _pumpApp(tester);

    // Nobody has logged in yet: nothing to remember.
    await tester.tap(find.text('Usar Biometría'));
    await tester.pumpAndSettle();
    expect(find.textContaining('para activar la biometría'), findsOneWidget);

    await _type(tester, 'cashback', 'demo2026');
    await _tapLogin(tester);
    await tester.ensureVisible(find.text('CERRAR SESIÓN'));
    await tester.tap(find.text('CERRAR SESIÓN'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usar Biometría'));
    await tester.pumpAndSettle();
    expect(SessionManager.instance.profile?.id, 'USR-1372');
    expect(find.text('Busca cashback'), findsOneWidget);
  });

  testWidgets('the sheet after a QR scan logs in with the same credentials',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(SessionManager.instance.reset);

    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const ScanVerificationSheet(),
          ),
          child: const Text('escanear'),
        ),
      ),
    ));
    await tester.tap(find.text('escanear'));
    await tester.pumpAndSettle();

    await _type(tester, 'sincredito', 'mala');
    await tester.tap(find.text('INGRESAR'));
    await tester.pumpAndSettle();
    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
    expect(result, isNull);

    await _type(tester, 'sincredito', 'demo2026');
    await tester.tap(find.text('INGRESAR'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(SessionManager.instance.profile?.id, 'USR-1167');
  });
}
