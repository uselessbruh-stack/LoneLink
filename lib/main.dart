/// LONE LINK — Main Entry Point
///
/// Initializes Flutter bindings and launches the app with Riverpod.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lone_link/core/logging/app_logger.dart';
import 'package:lone_link/presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121820),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  log.info(LogCategory.lifecycle, 'LONE LINK starting', 'App initialized');

  runApp(
    const ProviderScope(
      child: LoneLinkApp(),
    ),
  );
}
