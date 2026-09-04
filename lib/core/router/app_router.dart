import 'package:flutter/material.dart';

import '../../screens/login/login_screen.dart';
import '../../screens/payment_recommendation/payment_recommendation_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/qr_scanner/qr_scanner_screen.dart';

/// Canonical route names used across the app.
class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String qrScanner = '/qr-scanner';
  static const String paymentRecommendation = '/payment-recommendation';
  static const String profile = '/profile';
}

/// Named-route resolver. Screens that require typed args (confirmation)
/// are pushed directly via [MaterialPageRoute] from the previous screen.
class AppRouter {
  const AppRouter._();

  static const String initialRoute = AppRoutes.login;

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _page(settings, const LoginScreen());
      case AppRoutes.qrScanner:
        return _page(settings, const QrScannerScreen());
      case AppRoutes.paymentRecommendation:
        final payload = settings.arguments as String? ?? '';
        return _page(
          settings,
          PaymentRecommendationScreen(qrPayload: payload),
        );
      case AppRoutes.profile:
        return _page(settings, const ProfileScreen());
      default:
        // ConfirmationScreen requires typed args; it's pushed directly with
        // MaterialPageRoute from PaymentRecommendationScreen.
        return null;
    }
  }

  static MaterialPageRoute<dynamic> _page(RouteSettings s, Widget child) {
    return MaterialPageRoute(settings: s, builder: (_) => child);
  }
}
