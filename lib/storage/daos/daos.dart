/// LONE LINK — Database DAOs
///
/// Data Access Objects providing typed queries on top of the Drift database.
/// Each DAO corresponds to a repository interface in the domain layer.


import 'package:drift/drift.dart';
import 'package:lone_link/storage/database/database.dart';
import 'package:lone_link/storage/database/tables.dart';

part 'daos.g.dart';

// ─────────────────────────────────────────────
// Identity DAO
// ─────────────────────────────────────────────

@DriftAccessor(tables: [LocalIdentities])
class IdentityDao extends DatabaseAccessor<LoneLinkDatabase> with _$IdentityDaoMixin {
  IdentityDao(super.db);

  Future<LocalIdentity?> getIdentity() =>
      (select(localIdentities)..limit(1)).getSingleOrNull();

  Future<void> insertIdentity(LocalIdentitiesCompanion identity) =>
      into(localIdentities).insert(identity);

  Future<void> updateDisplayName(String id, String name) =>
      (update(localIdentities)..where((t) => t.id.equals(id)))
          .write(LocalIdentitiesCompanion(displayName: Value(name)));

  Future<bool> hasIdentity() async {
    final count = await (selectOnly(localIdentities)..addColumns([localIdentities.id.count()]))
        .map((row) => row.read(localIdentities.id.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }
}

// ─────────────────────────────────────────────
// Peer DAO
// ─────────────────────────────────────────────

@DriftAccessor(tables: [Peers])
class PeerDao extends DatabaseAccessor<LoneLinkDatabase> with _$PeerDaoMixin {
  PeerDao(super.db);

  Future<List<Peer>> getAllPeers() => select(peers).get();

  Future<Peer?> getPeerById(String peerId) =>
      (select(peers)..where((t) => t.id.equals(peerId))).getSingleOrNull();

  Future<void> upsertPeer(PeersCompanion peer) =>
      into(peers).insertOnConflictUpdate(peer);

  Future<void> updateConnectionState(String peerId, String state) =>
      (update(peers)..where((t) => t.id.equals(peerId)))
          .write(PeersCompanion(
            connectionState: Value(state),
            lastSeen: Value(DateTime.now()),
          ));

  Future<List<Peer>> getConnectedPeers() =>
      (select(peers)..where((t) => t.connectionState.equals('connected'))).get();

  Future<List<Peer>> getBridgeEligiblePeers() =>
      (select(peers)
            ..where((t) =>
                t.hasInternet.equals(true) &
                (t.batteryLevel.isNull() | t.batteryLevel.isBiggerThanValue(20))))
          .get();

  Future<void> deletePeer(String peerId) =>
      (delete(peers)..where((t) => t.id.equals(peerId))).go();

  Stream<List<Peer>> watchAllPeers() => select(peers).watch();

  Stream<List<Peer>> watchConnectedPeers() =>
      (select(peers)..where((t) => t.connectionState.equals('connected'))).watch();
}

// ─────────────────────────────────────────────
// Message DAO
// ─────────────────────────────────────────────

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<LoneLinkDatabase> with _$MessageDaoMixin {
  MessageDao(super.db);

  Future<void> insertMessage(MessagesCompanion message) =>
      into(messages).insert(message);

  Future<Message?> getMessageById(String messageId) =>
      (select(messages)..where((t) => t.id.equals(messageId))).getSingleOrNull();

  Future<List<Message>> getMessagesForConversation(
      String conversationId, {int limit = 50, int offset = 0}) =>
      (select(messages)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<void> updateStatus(String messageId, String status) =>
      (update(messages)..where((t) => t.id.equals(messageId)))
          .write(MessagesCompanion(status: Value(status)));

  Future<void> updateDeliveryInfo(
    String messageId, {
    String? status,
    String? transportType,
    DateTime? deliveredAt,
    DateTime? acknowledgedAt,
    int? retryCount,
    String? transportPath,
  }) {
    final companion = MessagesCompanion(
      status: status != null ? Value(status) : const Value.absent(),
      transportType: transportType != null ? Value(transportType) : const Value.absent(),
      deliveredAt: deliveredAt != null ? Value(deliveredAt) : const Value.absent(),
      acknowledgedAt: acknowledgedAt != null ? Value(acknowledgedAt) : const Value.absent(),
      retryCount: retryCount != null ? Value(retryCount) : const Value.absent(),
      transportPath: transportPath != null ? Value(transportPath) : const Value.absent(),
    );
    return (update(messages)..where((t) => t.id.equals(messageId))).write(companion);
  }

  Future<List<Message>> getMessagesByStatus(String status) =>
      (select(messages)..where((t) => t.status.equals(status))).get();

  Future<List<Message>> getPendingOutgoing() =>
      (select(messages)
            ..where((t) =>
                t.isOutgoing.equals(true) &
                (t.status.equals('queued') |
                    t.status.equals('sending') |
                    t.status.equals('failed'))))
          .get();

  Stream<List<Message>> watchMessagesForConversation(String conversationId) =>
      (select(messages)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<List<String>> getAllMessageIds() async {
    final rows = await (selectOnly(messages)..addColumns([messages.id])).get();
    return rows.map((row) => row.read(messages.id)!).toList();
  }

  Future<List<String>> getMessageIdsForConversation(String conversationId) async {
    final rows = await (selectOnly(messages)
          ..addColumns([messages.id])
          ..where(messages.conversationId.equals(conversationId)))
        .get();
    return rows.map((row) => row.read(messages.id)!).toList();
  }
}

// ─────────────────────────────────────────────
// Conversation DAO
// ─────────────────────────────────────────────

@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<LoneLinkDatabase> with _$ConversationDaoMixin {
  ConversationDao(super.db);

  Future<List<Conversation>> getAllConversations() =>
      (select(conversations)..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)])).get();

  Future<Conversation?> getConversationById(String conversationId) =>
      (select(conversations)..where((t) => t.id.equals(conversationId))).getSingleOrNull();

  Future<Conversation?> getConversationByPeerId(String peerId) =>
      (select(conversations)..where((t) => t.peerId.equals(peerId))).getSingleOrNull();

  Future<void> upsertConversation(ConversationsCompanion conversation) =>
      into(conversations).insertOnConflictUpdate(conversation);

  Future<void> updateConversation(ConversationsCompanion conversation) =>
      (update(conversations)..where((t) => t.id.equals(conversation.id.value)))
          .write(conversation);

  Future<void> markAsRead(String conversationId) =>
      (update(conversations)..where((t) => t.id.equals(conversationId)))
          .write(const ConversationsCompanion(unreadCount: Value(0)));

  Future<void> deleteConversation(String conversationId) =>
      (delete(conversations)..where((t) => t.id.equals(conversationId))).go();

  Stream<List<Conversation>> watchAllConversations() =>
      (select(conversations)..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)])).watch();
}

// ─────────────────────────────────────────────
// Deduplication DAO
// ─────────────────────────────────────────────

@DriftAccessor(tables: [ProcessedMessageIds])
class DeduplicationDao extends DatabaseAccessor<LoneLinkDatabase>
    with _$DeduplicationDaoMixin {
  DeduplicationDao(super.db);

  Future<bool> isProcessed(String messageId) async {
    final row = await (select(processedMessageIds)
          ..where((t) => t.messageId.equals(messageId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> markProcessed(String messageId) =>
      into(processedMessageIds).insert(
        ProcessedMessageIdsCompanion.insert(
          messageId: messageId,
          processedAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  Future<int> pruneOldEntries(DateTime before) async {
    return (delete(processedMessageIds)
          ..where((t) => t.processedAt.isSmallerThanValue(before)))
        .go();
  }

  Future<int> getCount() async {
    final countExpr = processedMessageIds.messageId.count();
    final result = await (selectOnly(processedMessageIds)..addColumns([countExpr]))
        .map((row) => row.read(countExpr))
        .getSingle();
    return result ?? 0;
  }
}

// ─────────────────────────────────────────────
// Acknowledgement DAO
// ─────────────────────────────────────────────

@DriftAccessor(tables: [Acknowledgements])
class AcknowledgementDao extends DatabaseAccessor<LoneLinkDatabase>
    with _$AcknowledgementDaoMixin {
  AcknowledgementDao(super.db);

  Future<void> insertAck(AcknowledgementsCompanion ack) =>
      into(acknowledgements).insert(ack);

  Future<List<Acknowledgement>> getAcksForMessage(String messageId) =>
      (select(acknowledgements)..where((t) => t.messageId.equals(messageId))).get();

  Future<bool> isAcknowledged(String messageId) async {
    final row = await (select(acknowledgements)
          ..where((t) =>
              t.messageId.equals(messageId) &
              (t.type.equals('delivered') | t.type.equals('read'))))
        .getSingleOrNull();
    return row != null;
  }
}

// ─────────────────────────────────────────────
// Route DAO
// ─────────────────────────────────────────────

@DriftAccessor(tables: [Routes])
class RouteDao extends DatabaseAccessor<LoneLinkDatabase> with _$RouteDaoMixin {
  RouteDao(super.db);

  Future<void> upsertRoute(RoutesCompanion route) =>
      into(routes).insertOnConflictUpdate(route);

  Future<Route?> getBestRoute(String destinationId) =>
      (select(routes)
            ..where((t) => t.destinationId.equals(destinationId))
            ..orderBy([(t) => OrderingTerm.asc(t.hopCount)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<Route>> getAllRoutes() => select(routes).get();

  Future<void> removeRoutesVia(String peerId) =>
      (delete(routes)..where((t) => t.nextHopPeerId.equals(peerId))).go();

  Future<void> clearAll() => delete(routes).go();
}

// ─────────────────────────────────────────────
// Bridge Candidate DAO
// ─────────────────────────────────────────────

@DriftAccessor(tables: [BridgeCandidates])
class BridgeCandidateDao extends DatabaseAccessor<LoneLinkDatabase>
    with _$BridgeCandidateDaoMixin {
  BridgeCandidateDao(super.db);

  Future<void> upsertCandidate(BridgeCandidatesCompanion candidate) =>
      into(bridgeCandidates).insertOnConflictUpdate(candidate);

  Future<BridgeCandidate?> getBestCandidate() =>
      (select(bridgeCandidates)
            ..orderBy([(t) => OrderingTerm.desc(t.score)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<BridgeCandidate>> getAllCandidates() =>
      (select(bridgeCandidates)..orderBy([(t) => OrderingTerm.desc(t.score)])).get();

  Future<void> removeCandidate(String peerId) =>
      (delete(bridgeCandidates)..where((t) => t.peerId.equals(peerId))).go();
}

// ─────────────────────────────────────────────
// Envelope Queue DAO
// ─────────────────────────────────────────────

@DriftAccessor(tables: [MessageEnvelopes])
class EnvelopeQueueDao extends DatabaseAccessor<LoneLinkDatabase>
    with _$EnvelopeQueueDaoMixin {
  EnvelopeQueueDao(super.db);

  Future<void> insertEnvelope(MessageEnvelopesCompanion envelope) =>
      into(messageEnvelopes).insert(envelope);

  Future<MessageEnvelope?> getNextPending() =>
      (select(messageEnvelopes)
            ..where((t) => t.queueStatus.equals('pending'))
            ..orderBy([(t) => OrderingTerm.asc(t.enqueuedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<MessageEnvelope>> getAllPending() =>
      (select(messageEnvelopes)
            ..where((t) =>
                t.queueStatus.equals('pending') | t.queueStatus.equals('in_flight'))
            ..orderBy([(t) => OrderingTerm.asc(t.enqueuedAt)]))
          .get();

  Future<void> markInFlight(String messageId) =>
      (update(messageEnvelopes)..where((t) => t.messageId.equals(messageId)))
          .write(const MessageEnvelopesCompanion(queueStatus: Value('in_flight')));

  Future<void> requeueFailed(String messageId, int retryCount) =>
      (update(messageEnvelopes)..where((t) => t.messageId.equals(messageId)))
          .write(MessageEnvelopesCompanion(
            queueStatus: const Value('pending'),
            retryCount: Value(retryCount),
          ));

  Future<void> removeEnvelope(String messageId) =>
      (delete(messageEnvelopes)..where((t) => t.messageId.equals(messageId))).go();

  Future<int> removeExpired() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (delete(messageEnvelopes)
          ..where((t) => t.expiry.isSmallerThanValue(now)))
        .go();
  }

  Future<int> getPendingCount() async {
    final countExpr = messageEnvelopes.messageId.count();
    final result = await (selectOnly(messageEnvelopes)
          ..addColumns([countExpr])
          ..where(messageEnvelopes.queueStatus.equals('pending')))
        .map((row) => row.read(countExpr))
        .getSingle();
    return result ?? 0;
  }
}

// ─────────────────────────────────────────────
// Sync State DAO
// ─────────────────────────────────────────────

@DriftAccessor(tables: [SyncStates])
class SyncStateDao extends DatabaseAccessor<LoneLinkDatabase> with _$SyncStateDaoMixin {
  SyncStateDao(super.db);

  Future<SyncState?> getSyncState(String peerId) =>
      (select(syncStates)..where((t) => t.peerId.equals(peerId))).getSingleOrNull();

  Future<void> upsertSyncState(SyncStatesCompanion state) =>
      into(syncStates).insertOnConflictUpdate(state);

  Future<List<SyncState>> getAllSyncStates() => select(syncStates).get();
}
