  import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/api_status.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');

  // Free cloud instances sleep when idle: wake the recommendation API now so
  // it is ready by the time the user scans a QR.
  unawaited(ApiStatus.instance.check());

  runApp(const BijApp());
}
