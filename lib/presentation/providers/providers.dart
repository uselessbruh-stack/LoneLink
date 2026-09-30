/// LONE LINK — Riverpod Providers
///
/// Central provider definitions for dependency injection and state management.
/// All providers are defined here for discoverability.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lone_link/storage/database/database.dart';
import 'package:lone_link/storage/daos/daos.dart';
import 'package:lone_link/core/logging/app_logger.dart';
import 'package:lone_link/domain/entities/entities.dart';
import 'package:lone_link/domain/entities/enums.dart';

// ─────────────────────────────────────────────
// Database & DAOs
// ─────────────────────────────────────────────

/// The singleton database instance.
final databaseProvider = Provider<LoneLinkDatabase>((ref) {
  final db = LoneLinkDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final identityDaoProvider = Provider<IdentityDao>((ref) {
  return IdentityDao(ref.watch(databaseProvider));
});

final peerDaoProvider = Provider<PeerDao>((ref) {
  return PeerDao(ref.watch(databaseProvider));
});

final messageDaoProvider = Provider<MessageDao>((ref) {
  return MessageDao(ref.watch(databaseProvider));
});

final conversationDaoProvider = Provider<ConversationDao>((ref) {
  return ConversationDao(ref.watch(databaseProvider));
});

final deduplicationDaoProvider = Provider<DeduplicationDao>((ref) {
  return DeduplicationDao(ref.watch(databaseProvider));
});

final acknowledgementDaoProvider = Provider<AcknowledgementDao>((ref) {
  return AcknowledgementDao(ref.watch(databaseProvider));
});

final routeDaoProvider = Provider<RouteDao>((ref) {
  return RouteDao(ref.watch(databaseProvider));
});

final bridgeCandidateDaoProvider = Provider<BridgeCandidateDao>((ref) {
  return BridgeCandidateDao(ref.watch(databaseProvider));
});

final envelopeQueueDaoProvider = Provider<EnvelopeQueueDao>((ref) {
  return EnvelopeQueueDao(ref.watch(databaseProvider));
});

final syncStateDaoProvider = Provider<SyncStateDao>((ref) {
  return SyncStateDao(ref.watch(databaseProvider));
});

// ─────────────────────────────────────────────
// Logger
// ─────────────────────────────────────────────

final loggerProvider = Provider<AppLogger>((ref) => AppLogger());

// ─────────────────────────────────────────────
// App State
// ─────────────────────────────────────────────

/// Whether the app has completed initial setup (identity creation).
final isSetupCompleteProvider = StateProvider<bool>((ref) => false);

/// Current connectivity state.
final connectivityStateProvider = StateProvider<ConnectivityState>((ref) {
  return ConnectivityState.offline;
});

/// Diagnostic counters (in-memory, updated by services).
final diagnosticCountersProvider = StateProvider<DiagnosticCounters>((ref) {
  return const DiagnosticCounters();
});

/// Current local user identity.
final localIdentityProvider = StateProvider<UserIdentity?>((ref) => null);

// ─────────────────────────────────────────────
// Conversations & Messages (stream-based)
// ─────────────────────────────────────────────

/// Stream of all conversations (real-time from DB).
final conversationsStreamProvider = StreamProvider<List<dynamic>>((ref) {
  final dao = ref.watch(conversationDaoProvider);
  return dao.watchAllConversations();
});

/// Stream of messages for a specific conversation.
final messagesStreamProvider =
    StreamProvider.family<List<dynamic>, String>((ref, conversationId) {
  final dao = ref.watch(messageDaoProvider);
  return dao.watchMessagesForConversation(conversationId);
});

/// Stream of all peers.
final peersStreamProvider = StreamProvider<List<dynamic>>((ref) {
  final dao = ref.watch(peerDaoProvider);
  return dao.watchAllPeers();
});

/// Stream of connected peers.
final connectedPeersStreamProvider = StreamProvider<List<dynamic>>((ref) {
  final dao = ref.watch(peerDaoProvider);
  return dao.watchConnectedPeers();
});

// ─────────────────────────────────────────────
// Navigation State
// ─────────────────────────────────────────────

/// Currently selected conversation ID (for chat screen).
final selectedConversationIdProvider = StateProvider<String?>((ref) => null);

/// Currently selected tab index.
final selectedTabIndexProvider = StateProvider<int>((ref) => 0);
