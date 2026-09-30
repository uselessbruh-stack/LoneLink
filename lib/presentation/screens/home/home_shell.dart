/// LONE LINK — Home Shell
///
/// Main navigation shell with bottom navigation bar.
/// Contains the four primary tabs: Chats, Nearby, Network, Settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lone_link/presentation/router.dart';
import 'package:lone_link/presentation/theme/app_theme.dart';
import 'package:lone_link/presentation/providers/providers.dart';
import 'package:lone_link/presentation/widgets/shared_widgets.dart';
import 'package:lone_link/domain/entities/enums.dart';

class HomeShell extends ConsumerWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home/nearby')) return 1;
    if (location.startsWith('/home/network')) return 2;
    if (location.startsWith('/home/settings')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.conversations);
      case 1:
        context.go(AppRoutes.nearby);
      case 2:
        context.go(AppRoutes.network);
      case 3:
        context.go(AppRoutes.settings);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final connectivity = ref.watch(connectivityStateProvider);

    return Scaffold(
      body: Column(
        children: [
          // Connectivity banner
          ConnectivityBanner(state: connectivity),
          // Main content
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        height: 68,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: LoneLinkColors.primary),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: const Icon(Icons.radar_outlined),
            selectedIcon: Icon(Icons.radar, color: LoneLinkColors.primary),
            label: 'Nearby',
          ),
          NavigationDestination(
            icon: const Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub, color: LoneLinkColors.primary),
            label: 'Network',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: LoneLinkColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
