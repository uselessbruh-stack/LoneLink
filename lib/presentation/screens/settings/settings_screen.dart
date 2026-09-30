/// LONE LINK — Settings Screen
///
/// Application settings including identity, theme, transport config,
/// and links to diagnostics/about.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lone_link/core/constants/app_constants.dart';
import 'package:lone_link/presentation/router.dart';
import 'package:lone_link/presentation/theme/app_theme.dart';
import 'package:lone_link/presentation/providers/providers.dart';
import 'package:lone_link/presentation/widgets/shared_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Identity section
          const SectionHeader(title: 'Identity'),
          _buildIdentityCard(context, ref),

          // Transport section
          const SectionHeader(title: 'Transport'),
          _SettingsTile(
            icon: Icons.bluetooth,
            iconColor: LoneLinkColors.bleColor,
            title: 'BLE Settings',
            subtitle: 'Scan interval, connections, MTU',
            onTap: () {
              // TODO: BLE settings screen
            },
          ),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            iconColor: LoneLinkColors.internetColor,
            title: 'Internet Transport',
            subtitle: kDefaultWebSocketUrl,
            onTap: () {
              // TODO: Internet settings screen
            },
          ),
          _SettingsTile(
            icon: Icons.swap_horiz,
            iconColor: LoneLinkColors.bridgeColor,
            title: 'Bridge Settings',
            subtitle: 'Bridge candidacy, scoring weights',
            onTap: () {
              // TODO: Bridge settings screen
            },
          ),

          // Messages section
          const SectionHeader(title: 'Messages'),
          _SettingsTile(
            icon: Icons.timer_outlined,
            title: 'Message TTL',
            subtitle: 'Default: $kDefaultMessageTtl hops',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.schedule,
            title: 'Message Expiry',
            subtitle: 'Default: ${kDefaultMessageExpiry.inHours} hours',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.replay,
            title: 'Retry Settings',
            subtitle: 'Max attempts: $kMaxRetryAttempts',
            onTap: () {},
          ),

          // Security section
          const SectionHeader(title: 'Security'),
          _SettingsTile(
            icon: Icons.enhanced_encryption,
            title: 'Encryption',
            subtitle: 'AES-256-GCM, X25519 key exchange',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.key,
            title: 'Key Management',
            subtitle: 'View public key, export identity',
            onTap: () {},
          ),

          // Developer section
          const SectionHeader(title: 'Developer'),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            iconColor: LoneLinkColors.warning,
            title: 'Diagnostics',
            subtitle: 'Logs, counters, network state',
            onTap: () => context.push(AppRoutes.diagnostics),
          ),

          // About section
          const SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About Lone Link',
            subtitle: 'Version $kAppVersion • Protocol v$kProtocolVersion',
            onTap: () => context.push(AppRoutes.about),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<dynamic>(
          future: ref.read(identityDaoProvider).getIdentity(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final identity = snapshot.data;
            if (identity == null) {
              return const Text('No identity configured');
            }

            final String name = identity.displayName as String? ?? 'Unknown';
            final String idStr = identity.id as String? ?? '';

            return Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: LoneLinkColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: LoneLinkColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        idStr.length >= 8 ? 'ID: ${idStr.substring(0, 8)}...' : 'ID: $idStr',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: LoneLinkColors.darkTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {
                    // TODO: Edit display name dialog
                  },
                  tooltip: 'Edit name',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? LoneLinkColors.darkTextSecondary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor ?? LoneLinkColors.darkTextSecondary),
      ),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
