/// LONE LINK — App Widget
///
/// Root MaterialApp with theme and router configuration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lone_link/presentation/theme/app_theme.dart';
import 'package:lone_link/presentation/router.dart';

class LoneLinkApp extends ConsumerWidget {
  const LoneLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Lone Link',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: LoneLinkTheme.lightTheme,
      darkTheme: LoneLinkTheme.darkTheme,
      themeMode: ThemeMode.dark, // Dark-first

      // Router
      routerConfig: appRouter,
    );
  }
}
