/// LONE LINK — Domain Entities
///
/// Core domain objects. These are plain Dart classes with no framework
/// dependencies. They represent the business concepts of the application.
///
/// Using plain classes (not freezed) to avoid code-generation dependency
/// for core domain objects. Immutability enforced by convention with final fields.
library;

import 'dart:typed_data';
import 'package:lone_link/domain/entities/enums.dart';

// ─────────────────────────────────────────────
// User Identity
// ─────────────────────────────────────────────

/// Represents this device's identity in the LONE LINK network.
/// The cryptographic identity (public key) is separate from the display name.
class UserIdentity {
  /// Unique device identity ID (derived from public key hash).
  final String id;

  /// Human-readable display name (user-chosen, not cryptographic).
  final String displayName;

  /// Ed25519 public key bytes.
  final Uint8List publicKey;

  /// X25519 public key bytes (for key exchange).
  final Uint8List keyExchangePublicKey;

  /// When this identity was created.
  final DateTime createdAt;

  const UserIdentity({
    required this.id,
    required this.displayName,
    required this.publicKey,
    required this.keyExchangePublicKey,
    required this.createdAt,
  });

  UserIdentity copyWith({
    String? displayName,
  }) {
    return UserIdentity(
      id: id,
      displayName: displayName ?? this.displayName,
      publicKey: publicKey,
      keyExchangePublicKey: keyExchangePublicKey,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserIdentity && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserIdentity($id, $displayName)';
}

// ─────────────────────────────────────────────
// Peer
// ─────────────────────────────────────────────

/// Represents a discovered or known peer in the network.
class Peer {
  /// Peer's identity ID.
  final String id;

  /// Peer's display name.
  final String displayName;

  /// Peer's Ed25519 public key bytes.
  final Uint8List publicKey;

  /// Peer's X25519 public key bytes.
  final Uint8List keyExchangePublicKey;

  /// Current connection state.
  final PeerConnectionState connectionState;

  /// BLE RSSI signal strength (null if not available / not BLE).
  final int? rssi;

  /// BLE device address (for reconnection).
  final String? bleDeviceId;

  /// Whether this peer has Internet connectivity (for bridge candidacy).
  final bool hasInternet;

  /// Battery level percentage (if shared by peer).
  final int? batteryLevel;

  /// Current role in the network.
  final NodeRole role;

  /// When this peer was first discovered.
  final DateTime firstSeen;

  /// When this peer was last seen.
  final DateTime lastSeen;

  const Peer({
    required this.id,
    required this.displayName,
    required this.publicKey,
    required this.keyExchangePublicKey,
    required this.connectionState,
    this.rssi,
    this.bleDeviceId,
    this.hasInternet = false,
    this.batteryLevel,
    this.role = NodeRole.client,
    required this.firstSeen,
    required this.lastSeen,
  });

  Peer copyWith({
    String? displayName,
    Uint8List? publicKey,
    Uint8List? keyExchangePublicKey,
    PeerConnectionState? connectionState,
    int? rssi,
    String? bleDeviceId,
    bool? hasInternet,
    int? batteryLevel,
    NodeRole? role,
    DateTime? lastSeen,
  }) {
    return Peer(
      id: id,
      displayName: displayName ?? this.displayName,
      publicKey: publicKey ?? this.publicKey,
      keyExchangePublicKey: keyExchangePublicKey ?? this.keyExchangePublicKey,
      connectionState: connectionState ?? this.connectionState,
      rssi: rssi ?? this.rssi,
      bleDeviceId: bleDeviceId ?? this.bleDeviceId,
      hasInternet: hasInternet ?? this.hasInternet,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      role: role ?? this.role,
      firstSeen: firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  /// Whether this peer can serve as a bridge.
  bool get isBridgeEligible => hasInternet && (batteryLevel == null || batteryLevel! > 20);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Peer && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Peer($id, $displayName, $connectionState)';
}

// ─────────────────────────────────────────────
// Conversation
// ─────────────────────────────────────────────

/// Represents a 1:1 conversation between this device and a peer.
class Conversation {
  /// Unique conversation ID.
  final String id;

  /// The remote peer's ID.
  final String peerId;

  /// The remote peer's display name (denormalized for list display).
  final String peerDisplayName;

  /// Last message text preview.
  final String? lastMessagePreview;

  /// Timestamp of the last message.
  final DateTime? lastMessageAt;

  /// Number of unread messages.
  final int unreadCount;

  /// When this conversation was created.
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.peerId,
    required this.peerDisplayName,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
  });

  Conversation copyWith({
    String? peerDisplayName,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return Conversation(
      id: id,
      peerId: peerId,
      peerDisplayName: peerDisplayName ?? this.peerDisplayName,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Conversation && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────
// Message
// ─────────────────────────────────────────────

/// A chat message within a conversation.
class Message {
  /// Globally unique message ID (cryptographically secure).
  final String id;

  /// Conversation this message belongs to.
  final String conversationId;

  /// Sender's identity ID.
  final String senderId;

  /// Recipient's identity ID.
  final String recipientId;

  /// Plaintext content (null if not decrypted yet or if this node is a relay).
  final String? content;

  /// Current delivery status.
  final MessageStatus status;

  /// Transport used for delivery (or attempted delivery).
  final TransportType transportType;

  /// When the message was created.
  final DateTime createdAt;

  /// When the message was delivered (null if not yet).
  final DateTime? deliveredAt;

  /// When the message was acknowledged (null if not yet).
  final DateTime? acknowledgedAt;

  /// Whether this message was sent by the local user.
  final bool isOutgoing;

  /// Number of retry attempts made.
  final int retryCount;

  /// Relay path description (e.g., "BLE → Bridge → Internet").
  final String? transportPath;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    this.content,
    required this.status,
    this.transportType = TransportType.unknown,
    required this.createdAt,
    this.deliveredAt,
    this.acknowledgedAt,
    required this.isOutgoing,
    this.retryCount = 0,
    this.transportPath,
  });

  Message copyWith({
    String? content,
    MessageStatus? status,
    TransportType? transportType,
    DateTime? deliveredAt,
    DateTime? acknowledgedAt,
    int? retryCount,
    String? transportPath,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      recipientId: recipientId,
      content: content ?? this.content,
      status: status ?? this.status,
      transportType: transportType ?? this.transportType,
      createdAt: createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      isOutgoing: isOutgoing,
      retryCount: retryCount ?? this.retryCount,
      transportPath: transportPath ?? this.transportPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Message && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Message($id, $status, ${isOutgoing ? "out" : "in"})';
}

// ─────────────────────────────────────────────
// Message Envelope (wire format entity)
// ─────────────────────────────────────────────

/// The complete wire-format envelope for a message being transported.
/// This is what travels over BLE / Internet, not the [Message] entity.
class MessageEnvelope {
  /// Protocol version.
  final int protocolVersion;

  /// Globally unique message ID.
  final String messageId;

  /// Conversation ID.
  final String conversationId;

  /// Sender's identity ID.
  final String senderId;

  /// Destination identity ID.
  final String destinationId;

  /// Creation timestamp (UTC epoch milliseconds).
  final int timestamp;

  /// Expiry timestamp (UTC epoch milliseconds).
  final int expiry;

  /// Time-to-live (hop count remaining).
  final int ttl;

  /// Packet type.
  final PacketType packetType;

  /// Encrypted payload bytes.
  final Uint8List payload;

  /// SHA-256 hash of the plaintext payload (for integrity).
  final Uint8List payloadHash;

  /// Ed25519 signature of the envelope.
  final Uint8List signature;

  /// Encryption metadata (nonce, algorithm ID, etc.).
  final EncryptionMetadata? encryptionMetadata;

  /// Route metadata (visible to relay nodes).
  final RouteMetadata? routeMetadata;

  const MessageEnvelope({
    required this.protocolVersion,
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.destinationId,
    required this.timestamp,
    required this.expiry,
    required this.ttl,
    required this.packetType,
    required this.payload,
    required this.payloadHash,
    required this.signature,
    this.encryptionMetadata,
    this.routeMetadata,
  });

  /// Creates a copy with decremented TTL (for relay).
  MessageEnvelope decrementTtl() {
    return MessageEnvelope(
      protocolVersion: protocolVersion,
      messageId: messageId,
      conversationId: conversationId,
      senderId: senderId,
      destinationId: destinationId,
      timestamp: timestamp,
      expiry: expiry,
      ttl: ttl - 1,
      packetType: packetType,
      payload: payload,
      payloadHash: payloadHash,
      signature: signature,
      encryptionMetadata: encryptionMetadata,
      routeMetadata: routeMetadata,
    );
  }

  /// Whether this envelope has expired.
  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiry;

  /// Whether TTL has been exhausted.
  bool get isTtlExhausted => ttl <= 0;

  @override
  String toString() => 'MessageEnvelope($messageId, ttl=$ttl, type=$packetType)';
}

// ─────────────────────────────────────────────
// Encryption Metadata
// ─────────────────────────────────────────────

/// Metadata needed to decrypt the payload. Attached to the envelope
/// but does NOT contain the key itself.
class EncryptionMetadata {
  /// Encryption algorithm identifier (e.g., "AES-256-GCM").
  final String algorithm;

  /// Nonce / IV used for encryption.
  final Uint8List nonce;

  /// Ephemeral public key (for X25519 key exchange per message).
  final Uint8List? ephemeralPublicKey;

  /// Key derivation info if applicable.
  final String? keyDerivationInfo;

  const EncryptionMetadata({
    required this.algorithm,
    required this.nonce,
    this.ephemeralPublicKey,
    this.keyDerivationInfo,
  });
}

// ─────────────────────────────────────────────
// Route Metadata
// ─────────────────────────────────────────────

/// Metadata about the route a message has taken.
/// Visible to relay nodes for routing decisions.
/// Minimizes information to prevent metadata leakage.
class RouteMetadata {
  /// ID of the last relay node (for ACK routing).
  final String? lastRelayId;

  /// Transport type of the last hop.
  final TransportType lastTransport;

  /// Number of hops already taken (original TTL - current TTL).
  final int hopCount;

  const RouteMetadata({
    this.lastRelayId,
    this.lastTransport = TransportType.unknown,
    this.hopCount = 0,
  });

  RouteMetadata copyWith({
    String? lastRelayId,
    TransportType? lastTransport,
    int? hopCount,
  }) {
    return RouteMetadata(
      lastRelayId: lastRelayId ?? this.lastRelayId,
      lastTransport: lastTransport ?? this.lastTransport,
      hopCount: hopCount ?? this.hopCount,
    );
  }
}

// ─────────────────────────────────────────────
// Acknowledgement
// ─────────────────────────────────────────────

/// An acknowledgement record for a message.
class Acknowledgement {
  /// The message ID being acknowledged.
  final String messageId;

  /// Who sent this ACK.
  final String fromPeerId;

  /// ACK type.
  final AckType type;

  /// When the ACK was received.
  final DateTime receivedAt;

  /// Transport used for the ACK.
  final TransportType transport;

  const Acknowledgement({
    required this.messageId,
    required this.fromPeerId,
    required this.type,
    required this.receivedAt,
    this.transport = TransportType.unknown,
  });
}

// ─────────────────────────────────────────────
// Network Node (for visualization)
// ─────────────────────────────────────────────

/// Represents a node in the network topology visualization.
class NetworkNode {
  /// Node identity ID.
  final String id;

  /// Display label.
  final String label;

  /// Node role.
  final NodeRole role;

  /// Whether this is the local device.
  final bool isLocal;

  /// Connection state.
  final PeerConnectionState state;

  /// Connected peer IDs (edges).
  final List<String> connectedPeerIds;

  const NetworkNode({
    required this.id,
    required this.label,
    required this.role,
    this.isLocal = false,
    required this.state,
    this.connectedPeerIds = const [],
  });
}

// ─────────────────────────────────────────────
// Bridge Candidate
// ─────────────────────────────────────────────

/// A peer evaluated for bridge (BLE-to-Internet) candidacy.
class BridgeCandidate {
  /// Peer ID.
  final String peerId;

  /// Computed bridge score (0.0 to 1.0).
  final double score;

  /// Internet available.
  final bool hasInternet;

  /// Battery level.
  final int? batteryLevel;

  /// BLE signal strength.
  final int? rssi;

  /// Connection stability score (0.0 to 1.0).
  final double stabilityScore;

  /// Current relay load (number of messages being relayed).
  final int currentLoad;

  /// When this candidacy was last evaluated.
  final DateTime evaluatedAt;

  const BridgeCandidate({
    required this.peerId,
    required this.score,
    required this.hasInternet,
    this.batteryLevel,
    this.rssi,
    this.stabilityScore = 0.0,
    this.currentLoad = 0,
    required this.evaluatedAt,
  });

  @override
  String toString() => 'BridgeCandidate($peerId, score=$score)';
}

// ─────────────────────────────────────────────
// Diagnostics
// ─────────────────────────────────────────────

/// Diagnostic counters for the application.
class DiagnosticCounters {
  final int messagesSent;
  final int messagesReceived;
  final int messagesRelayed;
  final int acksReceived;
  final int acksSent;
  final int deliveryFailures;
  final int deduplicationHits;
  final int ttlDrops;
  final int packetsCorrupted;
  final int bleConnections;
  final int bleDisconnections;
  final int bleDiscoveries;
  final int internetConnections;
  final int internetDisconnections;
  final int syncAttempts;
  final int syncSuccesses;
  final int syncFailures;

  const DiagnosticCounters({
    this.messagesSent = 0,
    this.messagesReceived = 0,
    this.messagesRelayed = 0,
    this.acksReceived = 0,
    this.acksSent = 0,
    this.deliveryFailures = 0,
    this.deduplicationHits = 0,
    this.ttlDrops = 0,
    this.packetsCorrupted = 0,
    this.bleConnections = 0,
    this.bleDisconnections = 0,
    this.bleDiscoveries = 0,
    this.internetConnections = 0,
    this.internetDisconnections = 0,
    this.syncAttempts = 0,
    this.syncSuccesses = 0,
    this.syncFailures = 0,
  });

  DiagnosticCounters increment({
    int messagesSent = 0,
    int messagesReceived = 0,
    int messagesRelayed = 0,
    int acksReceived = 0,
    int acksSent = 0,
    int deliveryFailures = 0,
    int deduplicationHits = 0,
    int ttlDrops = 0,
    int packetsCorrupted = 0,
    int bleConnections = 0,
    int bleDisconnections = 0,
    int bleDiscoveries = 0,
    int internetConnections = 0,
    int internetDisconnections = 0,
    int syncAttempts = 0,
    int syncSuccesses = 0,
    int syncFailures = 0,
  }) {
    return DiagnosticCounters(
      messagesSent: this.messagesSent + messagesSent,
      messagesReceived: this.messagesReceived + messagesReceived,
      messagesRelayed: this.messagesRelayed + messagesRelayed,
      acksReceived: this.acksReceived + acksReceived,
      acksSent: this.acksSent + acksSent,
      deliveryFailures: this.deliveryFailures + deliveryFailures,
      deduplicationHits: this.deduplicationHits + deduplicationHits,
      ttlDrops: this.ttlDrops + ttlDrops,
      packetsCorrupted: this.packetsCorrupted + packetsCorrupted,
      bleConnections: this.bleConnections + bleConnections,
      bleDisconnections: this.bleDisconnections + bleDisconnections,
      bleDiscoveries: this.bleDiscoveries + bleDiscoveries,
      internetConnections: this.internetConnections + internetConnections,
      internetDisconnections: this.internetDisconnections + internetDisconnections,
      syncAttempts: this.syncAttempts + syncAttempts,
      syncSuccesses: this.syncSuccesses + syncSuccesses,
      syncFailures: this.syncFailures + syncFailures,
    );
  }
}
