/// LONE LINK — BLE Providers
///
/// Riverpod providers for the BLE transport layer.
/// Manages the BLE transport lifecycle and exposes
/// scan state and discovered peers as reactive streams.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lone_link/networking/transport/ble_transport.dart';
import 'package:lone_link/networking/transport/transport.dart';
import 'package:lone_link/presentation/providers/providers.dart';
import 'package:lone_link/domain/entities/entities.dart';
import 'package:lone_link/domain/entities/enums.dart';
import 'package:lone_link/core/logging/app_logger.dart';

// ─────────────────────────────────────────────
// BLE Transport Provider
// ─────────────────────────────────────────────

/// Singleton BLE transport instance.
final bleTransportProvider = Provider<BleTransport>((ref) {
  final identity = ref.watch(localIdentityProvider);
  final transport = BleTransport(
    localIdentityId: identity?.id ?? 'uninitialized',
    localDisplayName: identity?.displayName ?? 'Unknown',
  );

  ref.onDispose(() => transport.dispose());
  return transport;
});

// ─────────────────────────────────────────────
// BLE Status Provider
// ─────────────────────────────────────────────

/// Reactive BLE transport status.
final bleStatusProvider = StreamProvider<TransportStatus>((ref) {
  final transport = ref.watch(bleTransportProvider);
  return transport.events
      .whereType<TransportStatusChangedEvent>()
      .map((e) => e.status);
});

// ─────────────────────────────────────────────
// BLE Scan State
// ─────────────────────────────────────────────

/// Whether BLE is currently scanning.
final bleScanningProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────────
// Discovered Peers (from BLE scan)
// ─────────────────────────────────────────────

/// In-memory list of discovered peers from current/recent BLE scans.
/// This is separate from the database peers — these are "live" scan results.
final discoveredPeersProvider =
    StateNotifierProvider<DiscoveredPeersNotifier, List<DiscoveredPeer>>((ref) {
  final transport = ref.watch(bleTransportProvider);
  return DiscoveredPeersNotifier(transport);
});

/// A discovered peer with live BLE scan metadata.
class DiscoveredPeer {
  final String id;
  final String displayName;
  final int rssi;
  final PeerConnectionState connectionState;
  final DateTime lastSeen;
  final String deviceId;

  const DiscoveredPeer({
    required this.id,
    required this.displayName,
    required this.rssi,
    required this.connectionState,
    required this.lastSeen,
    required this.deviceId,
  });

  DiscoveredPeer copyWith({
    int? rssi,
    PeerConnectionState? connectionState,
    DateTime? lastSeen,
  }) {
    return DiscoveredPeer(
      id: id,
      displayName: displayName,
      rssi: rssi ?? this.rssi,
      connectionState: connectionState ?? this.connectionState,
      lastSeen: lastSeen ?? this.lastSeen,
      deviceId: deviceId,
    );
  }
}

/// Manages the list of BLE-discovered peers.
class DiscoveredPeersNotifier extends StateNotifier<List<DiscoveredPeer>> {
  DiscoveredPeersNotifier(this._transport) : super([]) {
    _subscription = _transport.events.listen(_handleEvent);
  }

  final BleTransport _transport;
  StreamSubscription<TransportEvent>? _subscription;

  void _handleEvent(TransportEvent event) {
    if (event is PeerDiscoveredEvent) {
      final peer = event.peer;
      final existing = state.indexWhere((p) => p.id == peer.id);

      final discovered = DiscoveredPeer(
        id: peer.id,
        displayName: peer.displayName,
        rssi: peer.rssi ?? -100,
        connectionState: PeerConnectionState.discovered,
        lastSeen: DateTime.now(),
        deviceId: peer.id,
      );

      if (existing >= 0) {
        // Update existing peer (e.g., RSSI changed)
        final updated = List<DiscoveredPeer>.from(state);
        updated[existing] = discovered;
        state = updated;
      } else {
        state = [...state, discovered];
      }
    } else if (event is PeerConnectionChangedEvent) {
      final idx = state.indexWhere((p) => p.id == event.peerId);
      if (idx >= 0) {
        final updated = List<DiscoveredPeer>.from(state);
        updated[idx] = updated[idx].copyWith(connectionState: event.state);
        state = updated;
      }
    }
  }

  /// Clear all discovered peers (e.g., before new scan).
  void clear() {
    state = [];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// BLE Actions (scan, connect, etc.)
// ─────────────────────────────────────────────

/// Controller for BLE scan actions.
class BleController {
  final BleTransport transport;
  final StateController<bool> scanningState;
  final DiscoveredPeersNotifier peersNotifier;

  BleController({
    required this.transport,
    required this.scanningState,
    required this.peersNotifier,
  });

  /// Initialize BLE and start a scan.
  Future<void> initializeAndScan() async {
    // Initialize if needed
    if (transport.status == TransportStatus.uninitialized) {
      final initResult = await transport.initialize();
      if (initResult.isFailure) {
        log.error(LogCategory.ble, 'BLE init failed',
            initResult.failureOrNull?.message ?? 'Unknown error');
        return;
      }
    }

    // Wait for BLE to be ready
    if (transport.status == TransportStatus.unavailable) {
      log.warning(LogCategory.ble, 'BLE unavailable', 'Bluetooth may be off');
      return;
    }

    // Clear previous results and start scan
    peersNotifier.clear();
    scanningState.state = true;

    // Try broad scan (no service filter) first — more compatible
    final result = await transport.startBroadDiscovery();
    if (result.isFailure) {
      log.error(LogCategory.ble, 'Scan failed',
          result.failureOrNull?.message ?? 'Unknown');
      scanningState.state = false;
      return;
    }

    // Auto-stop scanning state when scan completes
    transport.events
        .whereType<TransportStatusChangedEvent>()
        .firstWhere((e) =>
            e.status == TransportStatus.ready ||
            e.status == TransportStatus.connected)
        .then((_) {
      scanningState.state = false;
    }).catchError((_) {
      scanningState.state = false;
    });
  }

  /// Connect to a discovered peer.
  Future<void> connectToPeer(String peerId) async {
    final result = await transport.connectToPeer(peerId);
    if (result.isFailure) {
      log.error(LogCategory.ble, 'Connect failed',
          result.failureOrNull?.message ?? 'Unknown');
    }
  }
}

/// Provider for the BLE controller.
final bleControllerProvider = Provider<BleController>((ref) {
  return BleController(
    transport: ref.watch(bleTransportProvider),
    scanningState: ref.watch(bleScanningProvider.notifier),
    peersNotifier: ref.watch(discoveredPeersProvider.notifier),
  );
});
