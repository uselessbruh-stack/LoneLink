/// LONE LINK — Nearby Peers Screen
///
/// Shows discovered BLE peers with signal strength, connection state,
/// battery level, and bridge eligibility.
/// The scan button triggers real BLE discovery (Phase 2).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lone_link/presentation/theme/app_theme.dart';
import 'package:lone_link/presentation/providers/providers.dart';
import 'package:lone_link/presentation/widgets/shared_widgets.dart';
import 'package:lone_link/domain/entities/enums.dart';

class NearbyPeersScreen extends ConsumerStatefulWidget {
  const NearbyPeersScreen({super.key});

  @override
  ConsumerState<NearbyPeersScreen> createState() => _NearbyPeersScreenState();
}

class _NearbyPeersScreenState extends ConsumerState<NearbyPeersScreen> {
  bool _isScanning = false;

  Future<void> _startScan() async {
    // TODO(Phase 2): Connect to BLE transport's startDiscovery()
    // This will:
    // 1. Check BLE permissions (permission_handler)
    // 2. Check if BLE is enabled
    // 3. Start flutter_blue_plus scan
    // 4. Filter for LONE LINK service UUID
    // 5. Emit PeerDiscoveredEvent for each found device
    // 6. Auto-stop after kBleScanDurationSeconds
    //
    // For Phase 1, we show the scan animation and empty state.

    setState(() => _isScanning = true);

    // Simulate scan duration
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final peersAsync = ref.watch(peersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Peers'),
        actions: [
          if (_isScanning)
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
          // Scan button area
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: _ScanButton(
                isScanning: _isScanning,
                onPressed: _isScanning ? null : _startScan,
              ),
            ),
          ),

          const SectionHeader(title: 'Discovered Peers'),

          // Peer list
          Expanded(
            child: peersAsync.when(
              data: (peers) {
                if (peers.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.radar,
                    title: _isScanning ? 'Scanning...' : 'No peers found',
                    subtitle: _isScanning
                        ? 'Looking for nearby LONE LINK devices'
                        : 'Tap "Scan for Peers" to discover nearby devices.\n'
                            'Make sure Bluetooth is enabled on both devices.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: peers.length,
                  itemBuilder: (context, index) {
                    final peer = peers[index];
                    return _PeerTile(peer: peer);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
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
  final dynamic peer;

  const _PeerTile({required this.peer});

  @override
  Widget build(BuildContext context) {
    final String name = peer.displayName ?? 'Unknown Device';
    final String stateStr = peer.connectionState ?? 'disconnected';
    final int? rssi = peer.rssi;
    final int? battery = peer.batteryLevel;
    final bool hasInternet = peer.hasInternet ?? false;
    final String roleStr = peer.role ?? 'client';

    final connectionState = PeerConnectionState.values.firstWhere(
      (s) => s.name == stateStr,
      orElse: () => PeerConnectionState.disconnected,
    );

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            _buildAvatar(name),
            Positioned(
              bottom: 0,
              right: 0,
              child: ConnectionDot(state: connectionState, size: 12),
            ),
          ],
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                // Signal strength
                if (rssi != null) ...[
                  SignalStrengthIndicator(rssi: rssi, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${rssi}dBm',
                    style: TextStyle(
                      fontSize: 11,
                      color: LoneLinkColors.darkTextTertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Battery
                if (battery != null) ...[
                  Icon(
                    battery > 60
                        ? Icons.battery_full
                        : battery > 20
                            ? Icons.battery_3_bar
                            : Icons.battery_1_bar,
                    size: 14,
                    color: battery > 20 ? LoneLinkColors.success : LoneLinkColors.error,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$battery%',
                    style: TextStyle(
                      fontSize: 11,
                      color: LoneLinkColors.darkTextTertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Bridge eligibility
                if (hasInternet)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: LoneLinkColors.bridgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, size: 10, color: LoneLinkColors.bridgeColor),
                        const SizedBox(width: 3),
                        Text(
                          'Bridge',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: LoneLinkColors.bridgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: connectionState == PeerConnectionState.connected
            ? TextButton(
                onPressed: () {
                  // TODO(Phase 2): Start conversation with this peer
                },
                child: const Text('Chat'),
              )
            : OutlinedButton(
                onPressed: () {
                  // TODO(Phase 2): Connect to this peer via BLE
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: LoneLinkColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Connect'),
              ),
      ),
    );
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
