/// LONE LINK — Shared Widgets
///
/// Reusable UI components used across multiple screens.
library;

import 'package:flutter/material.dart';
import 'package:lone_link/domain/entities/enums.dart';
import 'package:lone_link/presentation/theme/app_theme.dart';

// ─────────────────────────────────────────────
// Transport Badge
// ─────────────────────────────────────────────

/// Displays the transport type as a colored badge.
class TransportBadge extends StatelessWidget {
  final TransportType transport;
  final String? customLabel;
  final double fontSize;

  const TransportBadge({
    super.key,
    required this.transport,
    this.customLabel,
    this.fontSize = 10,
  });

  Color get _color => switch (transport) {
        TransportType.ble => LoneLinkColors.bleColor,
        TransportType.internet => LoneLinkColors.internetColor,
        TransportType.bleBridge => LoneLinkColors.bridgeColor,
        TransportType.unknown => LoneLinkColors.offlineColor,
      };

  IconData get _icon => switch (transport) {
        TransportType.ble => Icons.bluetooth,
        TransportType.internet => Icons.cloud_outlined,
        TransportType.bleBridge => Icons.swap_horiz,
        TransportType.unknown => Icons.help_outline,
      };

  String get _label =>
      customLabel ??
      switch (transport) {
        TransportType.ble => 'BLE Mesh',
        TransportType.internet => 'Internet',
        TransportType.bleBridge => 'BLE → Bridge',
        TransportType.unknown => 'Pending',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: fontSize + 2, color: _color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Message Status Indicator
// ─────────────────────────────────────────────

/// Shows the delivery status of a message with appropriate icon.
class MessageStatusIndicator extends StatelessWidget {
  final MessageStatus status;
  final double size;

  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, semanticLabel) = switch (status) {
      MessageStatus.created => (Icons.schedule, LoneLinkColors.darkTextTertiary, 'Creating'),
      MessageStatus.queued => (Icons.schedule, LoneLinkColors.darkTextTertiary, 'Queued'),
      MessageStatus.encrypted => (Icons.lock_outline, LoneLinkColors.darkTextTertiary, 'Encrypted'),
      MessageStatus.sending => (Icons.arrow_upward, LoneLinkColors.warning, 'Sending'),
      MessageStatus.relaying => (Icons.swap_horiz, LoneLinkColors.info, 'Relaying'),
      MessageStatus.delivered => (Icons.done, LoneLinkColors.success, 'Delivered'),
      MessageStatus.acknowledged => (Icons.done_all, LoneLinkColors.primary, 'Acknowledged'),
      MessageStatus.failed => (Icons.error_outline, LoneLinkColors.error, 'Failed'),
      MessageStatus.expired => (Icons.timer_off, LoneLinkColors.darkTextTertiary, 'Expired'),
    };

    return Tooltip(
      message: semanticLabel,
      child: Icon(
        icon,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Connection Status Dot
// ─────────────────────────────────────────────

/// A small colored dot indicating connection state.
class ConnectionDot extends StatelessWidget {
  final PeerConnectionState state;
  final double size;

  const ConnectionDot({
    super.key,
    required this.state,
    this.size = 10,
  });

  Color get _color => switch (state) {
        PeerConnectionState.connected => LoneLinkColors.success,
        PeerConnectionState.connecting => LoneLinkColors.warning,
        PeerConnectionState.reconnecting => LoneLinkColors.warning,
        PeerConnectionState.discovered => LoneLinkColors.info,
        PeerConnectionState.disconnected => LoneLinkColors.offlineColor,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.4),
            blurRadius: size * 0.6,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Connectivity Banner
// ─────────────────────────────────────────────

/// Shows current connectivity state as a subtle banner.
class ConnectivityBanner extends StatelessWidget {
  final ConnectivityState state;

  const ConnectivityBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state == ConnectivityState.full) return const SizedBox.shrink();

    final (icon, label, color) = switch (state) {
      ConnectivityState.offline => (Icons.cloud_off, 'Offline', LoneLinkColors.error),
      ConnectivityState.bleOnly => (Icons.bluetooth, 'BLE Only', LoneLinkColors.bleColor),
      ConnectivityState.internetOnly => (Icons.wifi, 'Internet Only', LoneLinkColors.internetColor),
      ConnectivityState.full => (Icons.check_circle, 'Connected', LoneLinkColors.success),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty State Widget
// ─────────────────────────────────────────────

/// Placeholder for empty lists with icon and message.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Signal Strength Indicator
// ─────────────────────────────────────────────

/// Displays BLE signal strength as bars.
class SignalStrengthIndicator extends StatelessWidget {
  final int? rssi;
  final double size;

  const SignalStrengthIndicator({super.key, this.rssi, this.size = 20});

  int get _bars {
    if (rssi == null) return 0;
    if (rssi! >= -50) return 4;
    if (rssi! >= -65) return 3;
    if (rssi! >= -80) return 2;
    if (rssi! >= -95) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Signal strength: $_bars of 4 bars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          final isActive = index < _bars;
          final height = size * (0.35 + (index * 0.2));
          return Padding(
            padding: const EdgeInsets.only(right: 1.5),
            child: Container(
              width: size * 0.15,
              height: height,
              decoration: BoxDecoration(
                color: isActive ? LoneLinkColors.primary : LoneLinkColors.darkTextTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────

/// A styled section header for lists.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}
