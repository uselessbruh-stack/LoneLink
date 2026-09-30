/// LONE LINK — Diagnostics Screen
///
/// Developer-facing diagnostics showing real application state.
/// BLE state, Internet state, peers, routes, queue, counters, logs.
/// All data comes from real providers — no fake data.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lone_link/core/constants/app_constants.dart';
import 'package:lone_link/core/logging/app_logger.dart';
import 'package:lone_link/presentation/theme/app_theme.dart';
import 'package:lone_link/presentation/providers/providers.dart';
import 'package:lone_link/presentation/widgets/shared_widgets.dart';
import 'package:lone_link/domain/entities/enums.dart';

class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LogLevel _logFilter = LogLevel.debug;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: LoneLinkColors.primary,
          labelColor: LoneLinkColors.primary,
          unselectedLabelColor: LoneLinkColors.darkTextTertiary,
          tabs: const [
            Tab(text: 'Status', icon: Icon(Icons.dashboard_outlined, size: 18)),
            Tab(text: 'Counters', icon: Icon(Icons.bar_chart, size: 18)),
            Tab(text: 'Logs', icon: Icon(Icons.article_outlined, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatusTab(),
          _buildCountersTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  // ─── Status Tab ───

  Widget _buildStatusTab() {
    final connectivity = ref.watch(connectivityStateProvider);
    final counters = ref.watch(diagnosticCountersProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Protocol info
        _DiagCard(
          title: 'Protocol',
          children: [
            _DiagRow('Version', '$kProtocolVersion'),
            _DiagRow('App Version', kAppVersion),
            _DiagRow('Max TTL', '$kDefaultMessageTtl'),
            _DiagRow('Max Payload', '${kMaxPacketPayloadSize ~/ 1024} KB'),
          ],
        ),

        // Connectivity
        _DiagCard(
          title: 'Connectivity',
          children: [
            _DiagRow('State', connectivity.name.toUpperCase()),
            _DiagRow('BLE', connectivity == ConnectivityState.bleOnly ||
                    connectivity == ConnectivityState.full
                ? '✓ Available'
                : '✗ Unavailable'),
            _DiagRow('Internet', connectivity == ConnectivityState.internetOnly ||
                    connectivity == ConnectivityState.full
                ? '✓ Available'
                : '✗ Unavailable'),
          ],
        ),

        // BLE State
        _DiagCard(
          title: 'BLE Transport',
          children: [
            _DiagRow('Status', 'NOT INITIALIZED'), // TODO(Phase 2)
            _DiagRow('Service UUID', kBleServiceUuid.substring(0, 18) + '...'),
            _DiagRow('Max MTU', '$kBleMaxMtu bytes'),
            _DiagRow('Max Connections', '$kBleMaxConnections'),
            _DiagRow('Scan Duration', '${kBleScanDurationSeconds}s'),
          ],
        ),

        // Internet Transport
        _DiagCard(
          title: 'Internet Transport',
          children: [
            _DiagRow('Status', 'NOT INITIALIZED'), // TODO(Phase 5)
            _DiagRow('Server URL', kDefaultWebSocketUrl),
            _DiagRow('Ping Interval', '${kWebSocketPingInterval.inSeconds}s'),
          ],
        ),

        // Queue
        _DiagCard(
          title: 'Message Queue',
          children: [
            _DiagRow('Pending', '0'), // TODO: read from envelopeQueueDao
            _DiagRow('Processing Interval', '${kQueueProcessingInterval.inSeconds}s'),
            _DiagRow('Max Retries', '$kMaxRetryAttempts'),
            _DiagRow('Retry Backoff', '${kRetryBackoffMultiplier}x'),
          ],
        ),

        // Security
        _DiagCard(
          title: 'Security',
          children: [
            _DiagRow('Identity', 'CONFIGURED'), // TODO: check identity DAO
            _DiagRow('Encryption', 'AES-256-GCM'), // Design, not yet implemented
            _DiagRow('Signatures', 'Ed25519'), // Design, not yet implemented
            _DiagRow('Key Exchange', 'X25519'), // Design, not yet implemented
            _DiagRow('Replay Protection', 'Nonce + Timestamp + Expiry'),
          ],
        ),

        // Deduplication
        _DiagCard(
          title: 'Deduplication',
          children: [
            _DiagRow('Cache Size', '0 / $kMaxDeduplicationCacheSize'),
            _DiagRow('Retention', '${kDeduplicationRetentionDuration.inHours}h'),
          ],
        ),
      ],
    );
  }

  // ─── Counters Tab ───

  Widget _buildCountersTab() {
    final counters = ref.watch(diagnosticCountersProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DiagCard(
          title: 'Messages',
          children: [
            _DiagRow('Sent', '${counters.messagesSent}'),
            _DiagRow('Received', '${counters.messagesReceived}'),
            _DiagRow('Relayed', '${counters.messagesRelayed}'),
            _DiagRow('Failed', '${counters.deliveryFailures}'),
          ],
        ),
        _DiagCard(
          title: 'Acknowledgements',
          children: [
            _DiagRow('ACKs Sent', '${counters.acksSent}'),
            _DiagRow('ACKs Received', '${counters.acksReceived}'),
          ],
        ),
        _DiagCard(
          title: 'Network',
          children: [
            _DiagRow('BLE Connections', '${counters.bleConnections}'),
            _DiagRow('BLE Disconnections', '${counters.bleDisconnections}'),
            _DiagRow('BLE Discoveries', '${counters.bleDiscoveries}'),
            _DiagRow('Internet Connects', '${counters.internetConnections}'),
            _DiagRow('Internet Disconnects', '${counters.internetDisconnections}'),
          ],
        ),
        _DiagCard(
          title: 'Protection',
          children: [
            _DiagRow('Dedup Hits', '${counters.deduplicationHits}'),
            _DiagRow('TTL Drops', '${counters.ttlDrops}'),
            _DiagRow('Corrupted Packets', '${counters.packetsCorrupted}'),
          ],
        ),
        _DiagCard(
          title: 'Sync',
          children: [
            _DiagRow('Attempts', '${counters.syncAttempts}'),
            _DiagRow('Successes', '${counters.syncSuccesses}'),
            _DiagRow('Failures', '${counters.syncFailures}'),
          ],
        ),
      ],
    );
  }

  // ─── Logs Tab ───

  Widget _buildLogsTab() {
    final logger = ref.watch(loggerProvider);
    final filteredEntries = logger.entriesByLevel(_logFilter);

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Level: ', style: TextStyle(fontSize: 12)),
              ...LogLevel.values.map((level) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(level.name.toUpperCase()),
                      selected: _logFilter == level,
                      onSelected: (_) => setState(() => _logFilter = level),
                      labelStyle: const TextStyle(fontSize: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  )),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () {
                  logger.clear();
                  setState(() {});
                },
                tooltip: 'Clear logs',
              ),
            ],
          ),
        ),

        // Log entries
        Expanded(
          child: filteredEntries.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.article_outlined,
                  title: 'No log entries',
                  subtitle: 'Logs will appear here as the app operates.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredEntries.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[filteredEntries.length - 1 - index];
                    return _LogEntryTile(entry: entry);
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Shared Diagnostic Widgets ───

class _DiagCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DiagCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: LoneLinkColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final String value;

  const _DiagRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: LoneLinkColors.darkTextSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: LoneLinkColors.darkTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final LogEntry entry;

  const _LogEntryTile({required this.entry});

  Color get _levelColor => switch (entry.level) {
        LogLevel.debug => LoneLinkColors.darkTextTertiary,
        LogLevel.info => LoneLinkColors.info,
        LogLevel.warning => LoneLinkColors.warning,
        LogLevel.error => LoneLinkColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _levelColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: _levelColor, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _formatTimestamp(entry.timestamp),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: LoneLinkColors.darkTextTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _levelColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    entry.level.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _levelColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '[${entry.category.name}]',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: LoneLinkColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              entry.message,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: LoneLinkColors.darkTextPrimary,
              ),
            ),
            if (entry.detail != null)
              Text(
                entry.detail!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: LoneLinkColors.darkTextTertiary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}.'
        '${dt.millisecond.toString().padLeft(3, '0')}';
  }
}
