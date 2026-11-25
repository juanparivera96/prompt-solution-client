import 'package:flutter/foundation.dart';

import '../models/demo_profile.dart';

/// In-memory session state for the prototype.
///
/// The login is simulated: the demo customers and their passwords live in
/// `MockRepository`. Whoever logs in is the customer the app works for:
/// their products, balance and credit feed the recommendation.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  DemoProfile? _profile;
  DemoProfile? _remembered;

  bool get isLoggedIn => _profile != null;

  /// The customer logged in. Null when nobody is.
  DemoProfile? get profile => _profile;

  /// The last customer who logged in during this app run: biometrics sign
  /// them in again. Null until someone logs in with username and password.
  DemoProfile? get rememberedProfile => _remembered;

  void login(DemoProfile profile) {
    _profile = profile;
    _remembered = profile;
  }

  void logout() => _profile = null;

  /// Forgets everything, including the remembered customer.
  @visibleForTesting
  void reset() {
    _profile = null;
    _remembered = null;
  }
}
