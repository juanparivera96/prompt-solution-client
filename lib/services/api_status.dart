import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/capa2_params.dart';

enum ApiState {
  /// Not checked yet.
  unknown,

  /// A check is waiting for the API's answer.
  checking,
  ready,
  unreachable,
}

/// Knows whether the recommendation API is awake.
///
/// Free cloud instances sleep when idle and take tens of seconds to answer
/// the first request. The app checks ahead of time (at launch and when the
/// QR simulator opens) and shows the state, so a sleeping API is never
/// silently replaced by the rule-based recommendation.
class ApiStatus extends ChangeNotifier {
  ApiStatus({
    http.Client? client,
    String? baseUrl,
    this.wakeTimeout = ApiConfig.wakeTimeout,
    DateTime Function()? clock,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _now = clock ?? DateTime.now;

  /// The one the app shares.
  static final ApiStatus instance = ApiStatus();

  /// A check that has waited this long means the API is waking up.
  static const Duration slowAfter = Duration(seconds: 3);

  /// The free plan puts the API to sleep after 15 minutes without requests,
  /// so an older "ready" is checked again.
  static const Duration freshFor = Duration(minutes: 10);

  final http.Client _client;
  final String _baseUrl;
  final Duration wakeTimeout;
  final DateTime Function() _now;

  ApiState _state = ApiState.unknown;
  DateTime? _checkingSince;
  DateTime? _readyAt;
  Capa2Params? _params;
  Future<bool>? _inFlight;

  ApiState get state => _state;

  /// When the check in progress started. Null unless [state] is checking.
  DateTime? get checkingSince =>
      _state == ApiState.checking ? _checkingSince : null;

  /// How the API computes the utility. Null until a check succeeds.
  Capa2Params? get params => _params;

  /// True when a check has waited long enough to tell the API is asleep.
  bool get isWaking {
    final since = checkingSince;
    return since != null && _now().difference(since) >= slowAfter;
  }

  /// True when the API answered recently enough to trust it is still awake.
  bool get isFresh {
    final readyAt = _readyAt;
    return _state == ApiState.ready &&
        readyAt != null &&
        _now().difference(readyAt) < freshFor;
  }

  /// Asks the API whether it is up, waiting up to [wakeTimeout] for a
  /// sleeping one. Calls made while a check is in progress join it.
  /// Never throws.
  Future<bool> check() =>
      _inFlight ??= _check().whenComplete(() => _inFlight = null);

  /// The API just answered a request: no need to check it.
  void markReady() {
    _readyAt = _now();
    _set(ApiState.ready);
  }

  Future<bool> _check() async {
    _checkingSince = _now();
    _set(ApiState.checking);
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/v1/meta'))
          .timeout(wakeTimeout);
      if (response.statusCode != 200) {
        throw http.ClientException('HTTP ${response.statusCode}');
      }
      final meta = jsonDecode(utf8.decode(response.bodyBytes));
      // A proxy in front of a waking instance may answer with a placeholder
      // page: only the API's own JSON counts as awake.
      if (meta is! Map<String, dynamic> || meta['modelo_version'] is! String) {
        throw const FormatException('Not the recommendation API');
      }
      _params = Capa2Params.fromMeta(meta);
      markReady();
      return true;
    } catch (_) {
      _set(ApiState.unreachable);
      return false;
    }
  }

  void _set(ApiState state) {
    _state = state;
    notifyListeners();
  }
}
