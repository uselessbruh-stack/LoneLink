/// LONE LINK — Drift Database Tables
///
/// Defines all database tables for local persistence.
/// Uses Drift (type-safe SQLite) for compile-time checked queries.
library;

import 'package:drift/drift.dart';

// ─────────────────────────────────────────────
// Identity Table
// ─────────────────────────────────────────────

/// Stores the local device identity.
/// There should be exactly one row in this table.
class LocalIdentities extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().withLength(min: 1, max: 100)();
  BlobColumn get publicKey => blob()();
  BlobColumn get keyExchangePublicKey => blob()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────
// Peers Table
// ─────────────────────────────────────────────

/// Stores discovered and known peers.
class Peers extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().withLength(min: 1, max: 100)();
  BlobColumn get publicKey => blob()();
  BlobColumn get keyExchangePublicKey => blob()();
  TextColumn get connectionState => text().withDefault(const Constant('disconnected'))();
  IntColumn get rssi => integer().nullable()();
  TextColumn get bleDeviceId => text().nullable()();
  BoolColumn get hasInternet => boolean().withDefault(const Constant(false))();
  IntColumn get batteryLevel => integer().nullable()();
  TextColumn get role => text().withDefault(const Constant('client'))();
  DateTimeColumn get firstSeen => dateTime()();
  DateTimeColumn get lastSeen => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────
// Conversations Table
// ─────────────────────────────────────────────

/// Stores conversation metadata.
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get peerId => text().references(Peers, #id)();
  TextColumn get peerDisplayName => text()();
  TextColumn get lastMessagePreview => text().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────
// Messages Table
// ─────────────────────────────────────────────

/// Stores chat messages.
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text().references(Conversations, #id)();
  TextColumn get senderId => text()();
  TextColumn get recipientId => text()();
  TextColumn get content => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('created'))();
  TextColumn get transportType => text().withDefault(const Constant('unknown'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  DateTimeColumn get acknowledgedAt => dateTime().nullable()();
  BoolColumn get isOutgoing => boolean()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get transportPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────
// Message Envelopes Table (pending queue)
// ─────────────────────────────────────────────

/// Stores serialized message envelopes in the pending delivery queue.
class MessageEnvelopes extends Table {
  TextColumn get messageId => text()();
  TextColumn get conversationId => text()();
  TextColumn get senderId => text()();
  TextColumn get destinationId => text()();
  IntColumn get protocolVersion => integer()();
  IntColumn get timestamp => integer()();
  IntColumn get expiry => integer()();
  IntColumn get ttl => integer()();
  TextColumn get packetType => text()();
  BlobColumn get payload => blob()();
  BlobColumn get payloadHash => blob()();
  BlobColumn get signature => blob()();
  BlobColumn get encryptionMetadataJson => blob().nullable()();
  BlobColumn get routeMetadataJson => blob().nullable()();
  TextColumn get queueStatus => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get enqueuedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {messageId};
}

// ─────────────────────────────────────────────
// Processed Message IDs (Deduplication)
// ─────────────────────────────────────────────

/// Tracks message IDs that have been processed for deduplication.
class ProcessedMessageIds extends Table {
  TextColumn get messageId => text()();
  DateTimeColumn get processedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {messageId};
}

// ─────────────────────────────────────────────
// Acknowledgements Table
// ─────────────────────────────────────────────

/// Stores received acknowledgements.
class Acknowledgements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text()();
  TextColumn get fromPeerId => text()();
  TextColumn get type => text()();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get transport => text().withDefault(const Constant('unknown'))();
}

// ─────────────────────────────────────────────
// Routes Table
// ─────────────────────────────────────────────

/// Stores routing information for reaching destinations.
class Routes extends Table {
  TextColumn get destinationId => text()();
  TextColumn get nextHopPeerId => text()();
  TextColumn get transport => text()();
  IntColumn get hopCount => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {destinationId};
}

// ─────────────────────────────────────────────
// Bridge Candidates Table
// ─────────────────────────────────────────────

/// Stores bridge candidate evaluations.
class BridgeCandidates extends Table {
  TextColumn get peerId => text()();
  RealColumn get score => real()();
  BoolColumn get hasInternet => boolean()();
  IntColumn get batteryLevel => integer().nullable()();
  IntColumn get rssi => integer().nullable()();
  RealColumn get stabilityScore => real().withDefault(const Constant(0.0))();
  IntColumn get currentLoad => integer().withDefault(const Constant(0))();
  DateTimeColumn get evaluatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {peerId};
}

// ─────────────────────────────────────────────
// Sync State Table
// ─────────────────────────────────────────────

/// Stores synchronization state with each peer.
class SyncStates extends Table {
  TextColumn get peerId => text()();
  TextColumn get lastSyncState => text().withDefault(const Constant('idle'))();
  TextColumn get lastLocalMerkleRoot => text().nullable()();
  TextColumn get lastRemoteMerkleRoot => text().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  IntColumn get messagesTransferred => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {peerId};
}
