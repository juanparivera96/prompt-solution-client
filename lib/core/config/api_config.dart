import 'package:flutter/foundation.dart';

/// Where the recommendation API lives.
///
/// Override at build time, e.g. for the cloud deployment or a physical phone:
///   flutter run --dart-define=API_BASE_URL=https://my-api.onrender.com
class ApiConfig {
  const ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // The Android emulator reaches the host machine through 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// How long the first attempt waits. An awake API answers in well under a
  /// second, so no answer by then means it is asleep or unreachable.
  static const Duration timeout = Duration(seconds: 4);

  /// How long the app waits for a sleeping API to wake up. Free cloud
  /// instances take tens of seconds (41 s measured on Render).
  static const Duration wakeTimeout = Duration(seconds: 90);

  /// Deadline of the second (and last) attempt, made once the API is awake.
  static const Duration retryTimeout = Duration(seconds: 15);
}
