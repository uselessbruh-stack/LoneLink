/// LONE LINK — Network Topology Screen
///
/// Visualizes the mesh network topology showing nodes and connections.
/// Uses a custom painter for the graph (no fake data).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import 'package:lone_link/presentation/theme/app_theme.dart';
import 'package:lone_link/presentation/providers/providers.dart';
import 'package:lone_link/presentation/widgets/shared_widgets.dart';
import 'package:lone_link/domain/entities/enums.dart';

class NetworkTopologyScreen extends ConsumerWidget {
  const NetworkTopologyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peersAsync = ref.watch(connectedPeersStreamProvider);
    final connectivity = ref.watch(connectivityStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh topology',
            onPressed: () {
              // TODO(Phase 4): Trigger topology refresh
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend
          _buildLegend(),

          // Network graph
          Expanded(
            child: peersAsync.when(
              data: (peers) {
                if (peers.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.hub_outlined,
                    title: 'No network topology',
                    subtitle: 'Connect to peers to see the mesh network.\n'
                        'Your device will appear as the central node.',
                  );
                }

                return _NetworkGraphView(
                  peers: peers,
                  connectivity: connectivity,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),

          // Stats bar
          _buildStatsBar(ref),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: LoneLinkColors.primary, label: 'You'),
          const SizedBox(width: 16),
          _LegendItem(color: LoneLinkColors.bleColor, label: 'BLE'),
          const SizedBox(width: 16),
          _LegendItem(color: LoneLinkColors.internetColor, label: 'Internet'),
          const SizedBox(width: 16),
          _LegendItem(color: LoneLinkColors.bridgeColor, label: 'Bridge'),
        ],
      ),
    );
  }

  Widget _buildStatsBar(WidgetRef ref) {
    final counters = ref.watch(diagnosticCountersProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LoneLinkColors.darkSurface,
        border: Border(
          top: BorderSide(color: LoneLinkColors.darkDivider, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Peers',
            value: '0', // TODO: from real data
            icon: Icons.people_outline,
          ),
          _StatItem(
            label: 'Routes',
            value: '0', // TODO: from route DAO
            icon: Icons.alt_route,
          ),
          _StatItem(
            label: 'Relayed',
            value: '${counters.messagesRelayed}',
            icon: Icons.swap_horiz,
          ),
          _StatItem(
            label: 'Bridges',
            value: '0', // TODO: from bridge candidate DAO
            icon: Icons.cloud_outlined,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: LoneLinkColors.darkTextTertiary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: LoneLinkColors.primary,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// Interactive network graph visualization.
/// Renders real peer data as nodes with connections.
class _NetworkGraphView extends StatelessWidget {
  final List<dynamic> peers;
  final ConnectivityState connectivity;

  const _NetworkGraphView({
    required this.peers,
    required this.connectivity,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _NetworkGraphPainter(
            peers: peers,
            connectivity: connectivity,
          ),
        );
      },
    );
  }
}

/// Custom painter for the network graph.
/// Places nodes in a radial layout around the local device.
class _NetworkGraphPainter extends CustomPainter {
  final List<dynamic> peers;
  final ConnectivityState connectivity;

  _NetworkGraphPainter({
    required this.peers,
    required this.connectivity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.32;

    // Draw connection lines from center to each peer
    final linePaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Calculate positions for peer nodes
    final peerPositions = <Offset>[];
    for (var i = 0; i < peers.length; i++) {
      final angle = (2 * math.pi * i / peers.length) - (math.pi / 2);
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      peerPositions.add(pos);

      // Draw edge
      linePaint.color = LoneLinkColors.bleColor.withValues(alpha: 0.4);
      canvas.drawLine(center, pos, linePaint);

      // Draw peer node
      _drawNode(canvas, pos, peers[i].displayName ?? '?', LoneLinkColors.bleColor, 18);
    }

    // Draw cloud node if Internet is available
    if (connectivity == ConnectivityState.internetOnly ||
        connectivity == ConnectivityState.full) {
      final cloudPos = Offset(center.dx, center.dy - radius - 50);
      linePaint.color = LoneLinkColors.internetColor.withValues(alpha: 0.4);
      linePaint.strokeWidth = 1.0;
      // Dashed effect approximation
      canvas.drawLine(center, cloudPos, linePaint);
      _drawNode(canvas, cloudPos, 'Cloud', LoneLinkColors.internetColor, 16);
    }

    // Draw local node (center, larger)
    _drawNode(canvas, center, 'YOU', LoneLinkColors.primary, 24);
  }

  void _drawNode(Canvas canvas, Offset position, String label, Color color, double radius) {
    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(position, radius + 6, glowPaint);

    // Node circle
    final nodePaint = Paint()..color = color.withValues(alpha: 0.2);
    canvas.drawCircle(position, radius, nodePaint);

    // Border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(position, radius, borderPaint);

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label.length > 6 ? '${label.substring(0, 5)}…' : label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy + radius + 6,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _NetworkGraphPainter oldDelegate) {
    return oldDelegate.peers.length != peers.length ||
        oldDelegate.connectivity != connectivity;
  }
}
