import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../data/mock_repository.dart';
import '../models/demo_profile.dart';
import 'session_manager.dart';

/// The simulated login, shared by the login screen and the sheet shown
/// after scanning a QR: the username and password fields, the error, and
/// the two ways in (password and biometrics).
class LoginController extends ChangeNotifier {
  LoginController({MockRepository repository = const MockRepository()})
      : _repo = repository;

  final MockRepository _repo;
  final username = TextEditingController();
  final password = TextEditingController();

  /// Why the last attempt failed. Null when there is nothing to say.
  String? get error => _error;
  String? _error;

  /// Fills the form with a demo customer's credentials.
  void fill(DemoProfile profile) {
    username.text = profile.username;
    password.text = profile.password;
    _setError(null);
  }

  /// Logs in with the typed credentials. Returns the customer, or null
  /// (and sets [error]) when they don't match.
  DemoProfile? loginWithPassword() {
    if (username.text.trim().isEmpty || password.text.isEmpty) {
      _setError('Ingresa tu usuario y tu contraseña.');
      return null;
    }
    final profile = _repo.authenticate(username.text, password.text);
    if (profile == null) {
      _setError('Usuario o contraseña incorrectos.');
      return null;
    }
    return _start(profile);
  }

  /// Signs in again the last customer who logged in during this app run.
  /// Returns null (and sets [error]) when nobody has yet.
  DemoProfile? loginWithBiometrics() {
    final profile = SessionManager.instance.rememberedProfile;
    if (profile == null) {
      _setError(
        'Inicia sesión una vez con usuario y contraseña para activar la '
        'biometría.',
      );
      return null;
    }
    return _start(profile);
  }

  /// Clears the error once the user starts typing again.
  void edited() => _setError(null);

  DemoProfile _start(DemoProfile profile) {
    SessionManager.instance.login(profile);
    _setError(null);
    return profile;
  }

  void _setError(String? error) {
    if (_error == error) return;
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }
}

/// Shows the error of a [LoginController] under the form, or nothing.
class LoginError extends StatelessWidget {
  final LoginController controller;

  const LoginError({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final error = controller.error;
        if (error == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: AppColors.lightError,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  error,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
