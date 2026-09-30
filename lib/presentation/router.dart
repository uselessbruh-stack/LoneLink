/// LONE LINK — App Router
///
/// Declarative routing using go_router.
/// All routes are defined here for discoverability.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lone_link/presentation/screens/splash/splash_screen.dart';
import 'package:lone_link/presentation/screens/identity_setup/identity_setup_screen.dart';
import 'package:lone_link/presentation/screens/home/home_shell.dart';
import 'package:lone_link/presentation/screens/conversations/conversations_screen.dart';
import 'package:lone_link/presentation/screens/nearby_peers/nearby_peers_screen.dart';
import 'package:lone_link/presentation/screens/network_topology/network_topology_screen.dart';
import 'package:lone_link/presentation/screens/settings/settings_screen.dart';
import 'package:lone_link/presentation/screens/chat/chat_screen.dart';
import 'package:lone_link/presentation/screens/diagnostics/diagnostics_screen.dart';
import 'package:lone_link/presentation/screens/about/about_screen.dart';

// Route paths
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String identitySetup = '/setup';
  static const String home = '/home';
  static const String conversations = '/home/conversations';
  static const String nearby = '/home/nearby';
  static const String network = '/home/network';
  static const String settings = '/home/settings';
  static const String chat = '/chat/:conversationId';
  static const String diagnostics = '/diagnostics';
  static const String about = '/about';

  static String chatPath(String conversationId) => '/chat/$conversationId';
}

// Navigation keys for nested navigation
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// The application router.
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    // Splash / initialization
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),

    // Identity setup
    GoRoute(
      path: AppRoutes.identitySetup,
      builder: (context, state) => const IdentitySetupScreen(),
    ),

    // Main app shell with bottom navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.conversations,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ConversationsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.nearby,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NearbyPeersScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.network,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NetworkTopologyScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),

    // Chat (full-screen, outside shell)
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) {
        final conversationId = state.pathParameters['conversationId']!;
        return ChatScreen(conversationId: conversationId);
      },
    ),

    // Diagnostics (full-screen)
    GoRoute(
      path: AppRoutes.diagnostics,
      builder: (context, state) => const DiagnosticsScreen(),
    ),

    // About
    GoRoute(
      path: AppRoutes.about,
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);
