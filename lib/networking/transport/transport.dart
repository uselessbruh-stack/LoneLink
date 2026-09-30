/// LONE LINK — Transport Interface
///
/// Defines the common transport abstraction that both BLE and Internet
/// transports must implement. This ensures message logic is decoupled
/// from the physical transport mechanism.
///
/// Future transports (Wi-Fi Direct, NFC, LoRa, etc.) can be added
/// by implementing this interface without modifying message logic.
library;

import 'dart:async';
import 'package:lone_link/core/result/result.dart';
import 'package:lone_link/domain/entities/entities.dart';
import 'package:lone_link/domain/entities/enums.dart';

/// The status of a transport layer.
enum TransportStatus {
  /// Not initialized.
  uninitialized,

  /// Initializing (requesting permissions, setting up).
  initializing,

  /// Ready to send/receive.
  ready,

  /// Actively scanning/listening for peers.
  scanning,

  /// Connected to one or more peers.
  connected,

  /// Temporarily unavailable (permissions denied, hardware off).
  unavailable,

  /// Fatal error, cannot recover without re-initialization.
  error,

  /// Shutting down.
  disposing,
}

/// Event emitted by a transport when something happens.
sealed class TransportEvent {
  const TransportEvent();
}

/// A new peer was discovered.
class PeerDiscoveredEvent extends TransportEvent {
  final Peer peer;
  const PeerDiscoveredEvent(this.peer);
}

/// A peer connection state changed.
class PeerConnectionChangedEvent extends TransportEvent {
  final String peerId;
  final PeerConnectionState state;
  const PeerConnectionChangedEvent(this.peerId, this.state);
}

/// A message envelope was received.
class EnvelopeReceivedEvent extends TransportEvent {
  final MessageEnvelope envelope;
  final TransportType transport;
  const EnvelopeReceivedEvent(this.envelope, this.transport);
}

/// An ACK was received.
class AckReceivedEvent extends TransportEvent {
  final Acknowledgement ack;
  const AckReceivedEvent(this.ack);
}

/// Transport status changed.
class TransportStatusChangedEvent extends TransportEvent {
  final TransportStatus status;
  final String? reason;
  const TransportStatusChangedEvent(this.status, [this.reason]);
}

/// An error occurred in the transport.
class TransportErrorEvent extends TransportEvent {
  final String message;
  final Object? error;
  const TransportErrorEvent(this.message, [this.error]);
}

/// Abstract transport interface.
///
/// Both [BleTransport] and [InternetTransport] implement this.
/// The message service uses transports interchangeably through this interface.
abstract class Transport {
  /// The type of this transport.
  TransportType get type;

  /// Current status of this transport.
  TransportStatus get status;

  /// Stream of transport events.
  Stream<TransportEvent> get events;

  /// Initialize the transport (request permissions, set up hardware).
  Future<Result<void>> initialize();

  /// Start discovering peers.
  Future<Result<void>> startDiscovery();

  /// Stop discovering peers.
  Future<Result<void>> stopDiscovery();

  /// Connect to a specific peer.
  Future<Result<void>> connectToPeer(String peerId);

  /// Disconnect from a specific peer.
  Future<Result<void>> disconnectFromPeer(String peerId);

  /// Send a message envelope to a peer.
  Future<Result<void>> sendEnvelope(String peerId, MessageEnvelope envelope);

  /// Send an ACK to a peer.
  Future<Result<void>> sendAck(String peerId, Acknowledgement ack);

  /// Get the list of currently connected peer IDs.
  List<String> getConnectedPeerIds();

  /// Check if a specific peer is reachable through this transport.
  Future<Result<bool>> isPeerReachable(String peerId);

  /// Dispose of the transport and release resources.
  Future<void> dispose();
}

/// Registry that manages multiple transports and routes messages
/// through the best available transport.
abstract class TransportRegistry {
  /// Register a transport.
  void registerTransport(Transport transport);

  /// Unregister a transport.
  void unregisterTransport(TransportType type);

  /// Get a specific transport by type.
  Transport? getTransport(TransportType type);

  /// Get all registered transports.
  List<Transport> getAllTransports();

  /// Get transports that are currently ready.
  List<Transport> getReadyTransports();

  /// Find the best transport to reach a peer.
  Future<Transport?> findBestTransportForPeer(String peerId);

  /// Merged event stream from all transports.
  Stream<TransportEvent> get allEvents;

  /// Dispose all transports.
  Future<void> disposeAll();
}
