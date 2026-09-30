/// LONE LINK — Repository Interfaces
///
/// Abstract repository contracts for the domain layer.
/// Implementations live in data/repositories/.
library;

import 'package:lone_link/core/result/result.dart';
import 'package:lone_link/domain/entities/entities.dart';
import 'package:lone_link/domain/entities/enums.dart';

// ─────────────────────────────────────────────
// Identity Repository
// ─────────────────────────────────────────────

/// Manages the local device identity.
abstract class IdentityRepository {
  /// Gets the current device identity, or null if not yet created.
  Future<Result<UserIdentity?>> getLocalIdentity();

  /// Creates and persists a new device identity.
  Future<Result<UserIdentity>> createIdentity(String displayName);

  /// Updates the display name.
  Future<Result<UserIdentity>> updateDisplayName(String newName);

  /// Checks if an identity has been set up.
  Future<Result<bool>> hasIdentity();
}

// ─────────────────────────────────────────────
// Peer Repository
// ─────────────────────────────────────────────

/// Manages known and discovered peers.
abstract class PeerRepository {
  /// Gets all known peers.
  Future<Result<List<Peer>>> getAllPeers();

  /// Gets a specific peer by ID.
  Future<Result<Peer?>> getPeerById(String peerId);

  /// Saves or updates a peer.
  Future<Result<void>> savePeer(Peer peer);

  /// Updates a peer's connection state.
  Future<Result<void>> updatePeerConnectionState(
      String peerId, PeerConnectionState state);

  /// Gets peers currently connected via BLE.
  Future<Result<List<Peer>>> getConnectedPeers();

  /// Gets peers eligible for bridge role.
  Future<Result<List<Peer>>> getBridgeEligiblePeers();

  /// Removes a peer.
  Future<Result<void>> removePeer(String peerId);

  /// Watch peers for real-time updates.
  Stream<List<Peer>> watchPeers();

  /// Watch connected peers.
  Stream<List<Peer>> watchConnectedPeers();
}

// ─────────────────────────────────────────────
// Message Repository
// ─────────────────────────────────────────────

/// Manages message persistence and queries.
abstract class MessageRepository {
  /// Saves a new message.
  Future<Result<void>> saveMessage(Message message);

  /// Gets a message by ID.
  Future<Result<Message?>> getMessageById(String messageId);

  /// Gets all messages for a conversation, ordered by timestamp.
  Future<Result<List<Message>>> getMessagesForConversation(
      String conversationId, {int limit = 50, int offset = 0});

  /// Updates message status.
  Future<Result<void>> updateMessageStatus(String messageId, MessageStatus status);

  /// Updates message delivery info.
  Future<Result<void>> updateMessageDelivery(
      String messageId, {
      MessageStatus? status,
      TransportType? transportType,
      DateTime? deliveredAt,
      DateTime? acknowledgedAt,
      int? retryCount,
      String? transportPath,
      });

  /// Gets all messages with a given status.
  Future<Result<List<Message>>> getMessagesByStatus(MessageStatus status);

  /// Gets pending outgoing messages (queued, sending, failed).
  Future<Result<List<Message>>> getPendingOutgoingMessages();

  /// Watch messages for a conversation (real-time).
  Stream<List<Message>> watchMessagesForConversation(String conversationId);

  /// Gets all message IDs for sync inventory.
  Future<Result<List<String>>> getAllMessageIds();

  /// Gets message IDs for a specific conversation.
  Future<Result<List<String>>> getMessageIdsForConversation(String conversationId);
}

// ─────────────────────────────────────────────
// Conversation Repository
// ─────────────────────────────────────────────

/// Manages conversation persistence.
abstract class ConversationRepository {
  /// Gets all conversations, ordered by last message time.
  Future<Result<List<Conversation>>> getAllConversations();

  /// Gets a conversation by ID.
  Future<Result<Conversation?>> getConversationById(String conversationId);

  /// Gets or creates a conversation with a peer.
  Future<Result<Conversation>> getOrCreateConversation(String peerId, String peerDisplayName);

  /// Updates conversation metadata (last message, unread count).
  Future<Result<void>> updateConversation(Conversation conversation);

  /// Marks all messages in a conversation as read.
  Future<Result<void>> markConversationAsRead(String conversationId);

  /// Deletes a conversation and its messages.
  Future<Result<void>> deleteConversation(String conversationId);

  /// Watch all conversations (real-time).
  Stream<List<Conversation>> watchConversations();
}

// ─────────────────────────────────────────────
// Pending Queue Repository
// ─────────────────────────────────────────────

/// Manages the persistent outgoing message queue.
abstract class PendingQueueRepository {
  /// Enqueues a message envelope for delivery.
  Future<Result<void>> enqueue(MessageEnvelope envelope);

  /// Dequeues the next envelope ready for delivery.
  Future<Result<MessageEnvelope?>> dequeueNext();

  /// Gets all pending envelopes.
  Future<Result<List<MessageEnvelope>>> getAllPending();

  /// Marks an envelope as in-flight.
  Future<Result<void>> markInFlight(String messageId);

  /// Returns an in-flight envelope to the queue (delivery failed).
  Future<Result<void>> requeueFailed(String messageId, {int? retryCount});

  /// Removes a successfully delivered envelope.
  Future<Result<void>> removeDelivered(String messageId);

  /// Removes expired envelopes.
  Future<Result<int>> removeExpired();

  /// Gets the count of pending messages.
  Future<Result<int>> getPendingCount();
}

// ─────────────────────────────────────────────
// Deduplication Repository
// ─────────────────────────────────────────────

/// Manages processed message IDs for deduplication.
abstract class DeduplicationRepository {
  /// Checks if a message ID has been processed.
  Future<Result<bool>> isProcessed(String messageId);

  /// Marks a message ID as processed.
  Future<Result<void>> markProcessed(String messageId);

  /// Removes old entries beyond the retention period.
  Future<Result<int>> pruneOldEntries(Duration retention);

  /// Gets the count of tracked message IDs.
  Future<Result<int>> getCount();
}

// ─────────────────────────────────────────────
// Acknowledgement Repository
// ─────────────────────────────────────────────

/// Manages acknowledgement records.
abstract class AcknowledgementRepository {
  /// Saves an acknowledgement.
  Future<Result<void>> saveAck(Acknowledgement ack);

  /// Gets acknowledgements for a message.
  Future<Result<List<Acknowledgement>>> getAcksForMessage(String messageId);

  /// Gets pending ACKs to send.
  Future<Result<List<Acknowledgement>>> getPendingAcks();

  /// Checks if a message has been acknowledged.
  Future<Result<bool>> isAcknowledged(String messageId);
}

// ─────────────────────────────────────────────
// Route Repository
// ─────────────────────────────────────────────

/// Manages routing information.
abstract class RouteRepository {
  /// Saves/updates a route to a destination.
  Future<Result<void>> saveRoute(String destinationId, String nextHopPeerId,
      TransportType transport, int hopCount);

  /// Gets the best route to a destination.
  Future<Result<({String nextHopPeerId, TransportType transport, int hopCount})?>>
      getBestRoute(String destinationId);

  /// Gets all known routes.
  Future<Result<List<({String destinationId, String nextHopPeerId, TransportType transport, int hopCount})>>>
      getAllRoutes();

  /// Removes routes through a disconnected peer.
  Future<Result<void>> removeRoutesVia(String peerId);

  /// Clears all routes.
  Future<Result<void>> clearAllRoutes();
}

// ─────────────────────────────────────────────
// Bridge Candidate Repository
// ─────────────────────────────────────────────

/// Manages bridge candidate evaluations.
abstract class BridgeCandidateRepository {
  /// Saves/updates a bridge candidate evaluation.
  Future<Result<void>> saveBridgeCandidate(BridgeCandidate candidate);

  /// Gets the best bridge candidate.
  Future<Result<BridgeCandidate?>> getBestBridgeCandidate();

  /// Gets all bridge candidates sorted by score.
  Future<Result<List<BridgeCandidate>>> getAllBridgeCandidates();

  /// Removes a bridge candidate.
  Future<Result<void>> removeBridgeCandidate(String peerId);
}
