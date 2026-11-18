import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../core/config/api_config.dart';

/// Phones and desktop: a connection that doesn't open in
/// [ApiConfig.connectTimeout] fails instead of hanging for minutes.
http.Client createHttpClient() =>
    IOClient(HttpClient()..connectionTimeout = ApiConfig.connectTimeout);
