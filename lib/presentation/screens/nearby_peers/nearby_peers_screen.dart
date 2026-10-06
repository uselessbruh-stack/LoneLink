/// LONE LINK — Nearby Peers Screen
///
/// Shows discovered BLE peers with signal strength, connection state,
/// battery level, and bridge eligibility.
/// Uses real BLE scanning via flutter_blue_plus.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lone_link/presentation/theme/app_theme.dart';
import 'package:lone_link/presentation/widgets/shared_widgets.dart';
import 'package:lone_link/domain/entities/enums.dart';
import 'package:lone_link/networking/transport/ble_provider.dart';
import 'package:lone_link/networking/transport/transport.dart';

class NearbyPeersScreen extends ConsumerStatefulWidget {
  const NearbyPeersScreen({super.key});

  @override
  ConsumerState<NearbyPeersScreen> createState() => _NearbyPeersScreenState();
}

class _NearbyPeersScreenState extends ConsumerState<NearbyPeersScreen> {
  String? _statusMessage;

  Future<void> _startScan() async {
    final controller = ref.read(bleControllerProvider);

    setState(() => _statusMessage = null);

    // Listen for status changes to show feedback
    final transport = ref.read(bleTransportProvider);

    if (transport.status == TransportStatus.unavailable) {
      setState(() => _statusMessage = 'Bluetooth is turned off. Please enable Bluetooth.');
      return;
    }

    await controller.initializeAndScan();
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(bleScanningProvider);
    final discoveredPeers = ref.watch(discoveredPeersProvider);
    final bleStatus = ref.watch(bleStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Peers'),
        actions: [
          if (isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(LoneLinkColors.primary),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BLE Status banner
          bleStatus.when(
            data: (status) {
              if (status == TransportStatus.unavailable) {
                return _StatusBanner(
                  message: 'Bluetooth is off',
                  icon: Icons.bluetooth_disabled,
                  color: LoneLinkColors.error,
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Status message (permission errors, etc.)
          if (_statusMessage != null)
            _StatusBanner(
              message: _statusMessage!,
              icon: Icons.warning_amber_rounded,
              color: LoneLinkColors.warning,
            ),

          // Scan button area
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: _ScanButton(
                isScanning: isScanning,
                onPressed: isScanning ? null : _startScan,
              ),
            ),
          ),

          // Scan results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SectionHeader(title: 'Discovered Peers'),
                const Spacer(),
                if (discoveredPeers.isNotEmpty)
                  Text(
                    '${discoveredPeers.length} found',
                    style: TextStyle(
                      fontSize: 12,
                      color: LoneLinkColors.darkTextTertiary,
                    ),
                  ),
              ],
            ),
          ),

          // Peer list
          Expanded(
            child: discoveredPeers.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.radar,
                    title: isScanning ? 'Scanning...' : 'No peers found',
                    subtitle: isScanning
                        ? 'Looking for nearby LONE LINK devices'
                        : 'Tap "Scan for Peers" to discover nearby devices.\n'
                            'Make sure Bluetooth is enabled on both devices\n'
                            'and both are running LONE LINK.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: discoveredPeers.length,
                    itemBuilder: (context, index) {
                      final peer = discoveredPeers[index];
                      return _PeerTile(
                        peer: peer,
                        onConnect: () {
                          final controller = ref.read(bleControllerProvider);
                          controller.connectToPeer(peer.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _StatusBanner({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final bool isScanning;
  final VoidCallback? onPressed;

  const _ScanButton({required this.isScanning, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isScanning
              ? [LoneLinkColors.primaryDark, LoneLinkColors.primary]
              : [LoneLinkColors.darkSurfaceElevated, LoneLinkColors.darkSurfaceHighest],
        ),
        border: Border.all(
          color: isScanning
              ? LoneLinkColors.primary.withValues(alpha: 0.3)
              : LoneLinkColors.darkDivider,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                  color: isScanning ? Colors.white : LoneLinkColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  isScanning ? 'Scanning for Peers...' : 'Scan for Peers',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isScanning ? Colors.white : LoneLinkColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeerTile extends StatelessWidget {
  final DiscoveredPeer peer;
  final VoidCallback onConnect;

  const _PeerTile({required this.peer, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            _buildAvatar(peer.displayName),
            Positioned(
              bottom: 0,
              right: 0,
              child: ConnectionDot(state: peer.connectionState, size: 12),
            ),
          ],
        ),
        title: Text(
          peer.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                SignalStrengthIndicator(rssi: peer.rssi, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${peer.rssi} dBm',
                  style: TextStyle(
                    fontSize: 11,
                    color: LoneLinkColors.darkTextTertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _stateColor(peer.connectionState).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    peer.connectionState.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _stateColor(peer.connectionState),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: peer.connectionState == PeerConnectionState.connected
            ? TextButton(
                onPressed: () {
                  // TODO(Phase 3): Navigate to chat with this peer
                },
                child: const Text('Chat'),
              )
            : OutlinedButton(
                onPressed: peer.connectionState == PeerConnectionState.connecting
                    ? null
                    : onConnect,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: LoneLinkColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  peer.connectionState == PeerConnectionState.connecting
                      ? 'Connecting...'
                      : 'Connect',
                ),
              ),
      ),
    );
  }

  Color _stateColor(PeerConnectionState state) {
    switch (state) {
      case PeerConnectionState.connected:
        return LoneLinkColors.success;
      case PeerConnectionState.connecting:
        return LoneLinkColors.warning;
      case PeerConnectionState.discovered:
        return LoneLinkColors.primary;
      case PeerConnectionState.disconnected:
      case PeerConnectionState.failed:
        return LoneLinkColors.darkTextTertiary;
    }
  }

  Widget _buildAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hue = (name.hashCode % 360).abs().toDouble();
    final color = HSLColor.fromAHSL(1.0, hue, 0.5, 0.35).toColor();

    return CircleAvatar(
      radius: 22,
      backgroundColor: color,
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
