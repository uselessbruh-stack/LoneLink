/// LONE LINK — Domain Enums
///
/// All enumerations used across the domain layer.
library;

/// The current delivery status of a message.
/// Implements the message lifecycle state machine.
///
/// State transitions:
/// ```
/// CREATED → QUEUED → ENCRYPTED → SENDING → DELIVERED → ACKNOWLEDGED
///                                    ↓
///                                  FAILED → QUEUED (retry)
///                                    ↓
///                                  EXPIRED
/// ```
enum MessageStatus {
  /// Message created locally, not yet queued.
  created,

  /// Queued for delivery, waiting for transport.
  queued,

  /// Payload has been encrypted for the destination.
  encrypted,

  /// Actively being sent through a transport.
  sending,

  /// Relay node has accepted the message for forwarding.
  relaying,

  /// Message confirmed received at destination.
  delivered,

  /// Destination has acknowledged reading/receipt.
  acknowledged,

  /// Delivery failed after retries.
  failed,

  /// Message TTL or timestamp expiry reached.
  expired,
}

/// Transport type used for message delivery.
enum TransportType {
  /// Bluetooth Low Energy direct connection.
  ble,

  /// Internet / WebSocket connection.
  internet,

  /// BLE to Internet bridge (hybrid path).
  bleBridge,

  /// Unknown or not yet determined.
  unknown,
}

/// Type of a protocol packet.
enum PacketType {
  /// Initial handshake packet.
  hello(0x01),

  /// Capability exchange.
  capabilities(0x02),

  /// Identity/key exchange.
  identity(0x03),

  /// Chat message.
  message(0x10),

  /// Acknowledgement.
  ack(0x11),

  /// Relay request.
  relay(0x12),

  /// Synchronization request.
  syncRequest(0x20),

  /// Synchronization response.
  syncResponse(0x21),

  /// Synchronization data chunk.
  syncChunk(0x22),

  /// Keep-alive ping.
  ping(0x30),

  /// Keep-alive pong.
  pong(0x31),

  /// Graceful disconnect.
  goodbye(0x40),

  /// Error notification.
  error(0xFF);

  final int code;
  const PacketType(this.code);

  static PacketType fromCode(int code) {
    return PacketType.values.firstWhere(
      (t) => t.code == code,
      orElse: () => PacketType.error,
    );
  }
}

/// Acknowledgement type.
enum AckType {
  /// Transport-level acknowledgement (packet received by next hop).
  received,

  /// Application-level delivery confirmation (reached destination).
  delivered,

  /// User-level read receipt.
  read,

  /// Delivery failed.
  failed,
}

/// Peer connection state.
enum PeerConnectionState {
  /// Discovered but not connected.
  discovered,

  /// Connection in progress.
  connecting,

  /// Connected and ready.
  connected,

  /// Was connected, currently reconnecting.
  reconnecting,

  /// Disconnected.
  disconnected,
}

/// Node role in the mesh network.
enum NodeRole {
  /// Normal messaging client.
  client,

  /// Acting as a relay for other peers.
  relay,

  /// Acting as a BLE-to-Internet bridge.
  bridge,

  /// Both relay and bridge.
  relayBridge,
}

/// Connectivity state of the device.
enum ConnectivityState {
  /// No connectivity.
  offline,

  /// BLE only.
  bleOnly,

  /// Internet only.
  internetOnly,

  /// Both BLE and Internet available.
  full,
}

/// Synchronization state between two peers.
enum SyncState {
  /// Not syncing.
  idle,

  /// Comparing inventories.
  comparing,

  /// Transferring missing messages.
  transferring,

  /// Sync complete.
  complete,

  /// Sync failed.
  failed,
}
