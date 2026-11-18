/// Where the recommendation API lives.
///
/// By default, the API deployed on Render, so any build works on any device
/// (emulator, physical phone, web, desktop) without extra flags. To use the
/// API running on this computer instead, pass its address at build time:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000     (Android emulator)
///   flutter run --dart-define=API_BASE_URL=http://localhost:8000    (web, desktop)
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000 (phone on the same Wi-Fi)
class ApiConfig {
  const ApiConfig._();

  /// The API deployed on Render (free plan).
  static const String cloudUrl =
      'https://prompt-solution-client-api.onrender.com';

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _override.isNotEmpty ? _override : cloudUrl;

  /// How long the first attempt waits. An awake API answers in well under a
  /// second, so no answer by then means it is asleep or unreachable.
  static const Duration timeout = Duration(seconds: 4);

  /// How long the app waits for a sleeping API to wake up. Free cloud
  /// instances take tens of seconds (41 s measured on Render).
  static const Duration wakeTimeout = Duration(seconds: 90);

  /// Deadline of the second (and last) attempt, made once the API is awake.
  static const Duration retryTimeout = Duration(seconds: 15);

  /// How long opening a connection may take. A sleeping Render instance
  /// accepts the connection right away and only delays the answer, so a
  /// connection that doesn't open means the address is wrong or the network
  /// is down: there is nothing to wait for.
  static const Duration connectTimeout = Duration(seconds: 10);
}

/// "prompt-solution-client-api.onrender.com", or "10.0.2.2:8000" when the
/// port is explicit. Shown on screen so a wrong address is easy to spot.
String serverName(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  if (uri == null || uri.host.isEmpty) return baseUrl;
  return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
}
