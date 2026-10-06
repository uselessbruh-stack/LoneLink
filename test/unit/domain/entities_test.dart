// LONE LINK — Domain Entity Tests
//
// Unit tests for core domain entities and value objects.
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lone_link/domain/entities/entities.dart';
import 'package:lone_link/domain/entities/enums.dart';

void main() {
  group('UserIdentity', () {
    test('creates with required fields', () {
      final identity = UserIdentity(
        id: 'test-id-123',
        displayName: 'Alice',
        publicKey: Uint8List(32),
        keyExchangePublicKey: Uint8List(32),
        createdAt: DateTime(2026, 1, 1),
      );

      expect(identity.id, 'test-id-123');
      expect(identity.displayName, 'Alice');
      expect(identity.publicKey.length, 32);
      expect(identity.keyExchangePublicKey.length, 32);
    });

    test('copyWith preserves unchanged fields', () {
      final identity = UserIdentity(
        id: 'id-1',
        displayName: 'Alice',
        publicKey: Uint8List(32),
        keyExchangePublicKey: Uint8List(32),
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = identity.copyWith(displayName: 'Bob');

      expect(updated.id, 'id-1'); // unchanged
      expect(updated.displayName, 'Bob'); // changed
      expect(updated.publicKey.length, 32); // unchanged
    });

    test('equality is based on id', () {
      final a = UserIdentity(
        id: 'same-id',
        displayName: 'Alice',
        publicKey: Uint8List(32),
        keyExchangePublicKey: Uint8List(32),
        createdAt: DateTime(2026, 1, 1),
      );
      final b = UserIdentity(
        id: 'same-id',
        displayName: 'Bob', // different name, same ID
        publicKey: Uint8List(32),
        keyExchangePublicKey: Uint8List(32),
        createdAt: DateTime(2026, 2, 1),
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different ids are not equal', () {
      final a = UserIdentity(
        id: 'id-1',
        displayName: 'Alice',
        publicKey: Uint8List(32),
        keyExchangePublicKey: Uint8List(32),
        createdAt: DateTime(2026, 1, 1),
      );
      final b = UserIdentity(
        id: 'id-2',
        displayName: 'Alice',
        publicKey: Uint8List(32),
        keyExchangePublicKey: Uint8List(32),
        createdAt: DateTime(2026, 1, 1),
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('Message', () {
    test('creates outgoing message', () {
      final msg = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'me',
        recipientId: 'peer-1',
        content: 'Hello!',
        status: MessageStatus.created,
        isOutgoing: true,
        createdAt: DateTime.now(),
      );

      expect(msg.id, 'msg-1');
      expect(msg.isOutgoing, true);
      expect(msg.status, MessageStatus.created);
      expect(msg.retryCount, 0);
      expect(msg.transportType, TransportType.unknown);
    });

    test('copyWith updates status correctly', () {
      final msg = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'me',
        recipientId: 'peer-1',
        content: 'Hello!',
        status: MessageStatus.created,
        isOutgoing: true,
        createdAt: DateTime.now(),
      );

      final queued = msg.copyWith(status: MessageStatus.queued);
      expect(queued.status, MessageStatus.queued);
      expect(queued.id, 'msg-1'); // unchanged
      expect(queued.content, 'Hello!'); // unchanged

      final delivered = queued.copyWith(
        status: MessageStatus.delivered,
        deliveredAt: DateTime.now(),
        transportType: TransportType.ble,
      );
      expect(delivered.status, MessageStatus.delivered);
      expect(delivered.deliveredAt, isNotNull);
      expect(delivered.transportType, TransportType.ble);
    });

    test('equality is based on id', () {
      final a = Message(
        id: 'msg-same',
        conversationId: 'conv-1',
        senderId: 'me',
        recipientId: 'peer',
        status: MessageStatus.created,
        isOutgoing: true,
        createdAt: DateTime.now(),
      );
      final b = Message(
        id: 'msg-same',
        conversationId: 'conv-1',
        senderId: 'me',
        recipientId: 'peer',
        status: MessageStatus.delivered, // different status
        isOutgoing: true,
        createdAt: DateTime.now(),
      );

      expect(a, equals(b));
    });
  });

  group('MessageEnvelope', () {
    test('creates valid envelope', () {
      final envelope = MessageEnvelope(
        protocolVersion: 1,
        messageId: 'env-1',
        conversationId: 'conv-1',
        senderId: 'sender',
        destinationId: 'dest',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        expiry: DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
        ttl: 8,
        packetType: PacketType.message,
        payload: Uint8List.fromList([1, 2, 3, 4]),
        payloadHash: Uint8List(32),
        signature: Uint8List(64),
      );

      expect(envelope.protocolVersion, 1);
      expect(envelope.ttl, 8);
      expect(envelope.isExpired, false);
      expect(envelope.isTtlExhausted, false);
    });

    test('decrementTtl reduces TTL by 1', () {
      final envelope = MessageEnvelope(
        protocolVersion: 1,
        messageId: 'env-1',
        conversationId: 'conv-1',
        senderId: 'sender',
        destinationId: 'dest',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        expiry: DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
        ttl: 5,
        packetType: PacketType.message,
        payload: Uint8List(10),
        payloadHash: Uint8List(32),
        signature: Uint8List(64),
      );

      final decremented = envelope.decrementTtl();
      expect(decremented.ttl, 4);
      expect(decremented.messageId, envelope.messageId); // preserved
    });

    test('isTtlExhausted when TTL is 0', () {
      final envelope = MessageEnvelope(
        protocolVersion: 1,
        messageId: 'env-1',
        conversationId: 'conv-1',
        senderId: 'sender',
        destinationId: 'dest',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        expiry: DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
        ttl: 0,
        packetType: PacketType.message,
        payload: Uint8List(10),
        payloadHash: Uint8List(32),
        signature: Uint8List(64),
      );

      expect(envelope.isTtlExhausted, true);
    });

    test('isExpired when expiry is in the past', () {
      final envelope = MessageEnvelope(
        protocolVersion: 1,
        messageId: 'env-1',
        conversationId: 'conv-1',
        senderId: 'sender',
        destinationId: 'dest',
        timestamp: DateTime.now().subtract(const Duration(hours: 48)).millisecondsSinceEpoch,
        expiry: DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        ttl: 8,
        packetType: PacketType.message,
        payload: Uint8List(10),
        payloadHash: Uint8List(32),
        signature: Uint8List(64),
      );

      expect(envelope.isExpired, true);
    });
  });

  group('Peer', () {
    test('isBridgeEligible requires Internet and sufficient battery', () {
      final eligiblePeer = Peer(
        id: 'peer-1',
        displayName: 'Bridge Peer',
        publicKey: Uint8List(32),
        keyExchangePublicKey: Uint8List(32),
        connectionState: PeerConnectionState.connected,
        hasInternet: true,
        batteryLevel: 80,
        firstSeen: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      expect(eligiblePeer.isBridgeEligible, true);
    });

    test('isBridgeEligible false without Internet', () {
      final peer = Peer(
        id: 'peer-2',
        displayName: 'No Internet Peer',
        publicKey: Uint8List(32),
        keyExchangePublicKey: Uint8List(32),
        connectionState: PeerConnectionState.connected,
        hasInternet: false,
        batteryLevel: 80,
        firstSeen: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      expect(peer.isBridgeEligible, false);
    });

    test('isBridgeEligible false with low battery', () {
      final peer = Peer(
        id: 'peer-3',
        displayName: 'Low Battery Peer',
        publicKey: Uint8List(32),
        keyExchangePublicKey: Uint8List(32),
        connectionState: PeerConnectionState.connected,
        hasInternet: true,
        batteryLevel: 10, // Below 20% threshold
        firstSeen: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      expect(peer.isBridgeEligible, false);
    });

    test('isBridgeEligible true when battery is null (unknown)', () {
      final peer = Peer(
        id: 'peer-4',
        displayName: 'Unknown Battery Peer',
        publicKey: Uint8List(32),
        keyExchangePublicKey: Uint8List(32),
        connectionState: PeerConnectionState.connected,
        hasInternet: true,
        batteryLevel: null, // Unknown — should still be eligible
        firstSeen: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      expect(peer.isBridgeEligible, true);
    });
  });

  group('Conversation', () {
    test('creates with required fields', () {
      final conv = Conversation(
        id: 'conv-1',
        peerId: 'peer-1',
        peerDisplayName: 'Alice',
        createdAt: DateTime.now(),
      );

      expect(conv.id, 'conv-1');
      expect(conv.unreadCount, 0);
      expect(conv.lastMessagePreview, isNull);
    });

    test('copyWith updates unread count', () {
      final conv = Conversation(
        id: 'conv-1',
        peerId: 'peer-1',
        peerDisplayName: 'Alice',
        createdAt: DateTime.now(),
      );

      final updated = conv.copyWith(unreadCount: 5);
      expect(updated.unreadCount, 5);
      expect(updated.peerId, 'peer-1');
    });
  });

  group('DiagnosticCounters', () {
    test('starts at zero', () {
      const counters = DiagnosticCounters();
      expect(counters.messagesSent, 0);
      expect(counters.messagesReceived, 0);
      expect(counters.deduplicationHits, 0);
    });

    test('increment adds correctly', () {
      const counters = DiagnosticCounters();
      final updated = counters.increment(messagesSent: 5, deduplicationHits: 2);

      expect(updated.messagesSent, 5);
      expect(updated.deduplicationHits, 2);
      expect(updated.messagesReceived, 0); // unchanged
    });

    test('multiple increments accumulate', () {
      const counters = DiagnosticCounters();
      final step1 = counters.increment(messagesSent: 3);
      final step2 = step1.increment(messagesSent: 2);

      expect(step2.messagesSent, 5);
    });
  });

  group('PacketType', () {
    test('fromCode resolves known types', () {
      expect(PacketType.fromCode(0x01), PacketType.hello);
      expect(PacketType.fromCode(0x10), PacketType.message);
      expect(PacketType.fromCode(0x11), PacketType.ack);
      expect(PacketType.fromCode(0x20), PacketType.syncRequest);
    });

    test('fromCode returns error for unknown codes', () {
      expect(PacketType.fromCode(0x99), PacketType.error);
      expect(PacketType.fromCode(0x00), PacketType.error);
    });
  });

  group('BridgeCandidate', () {
    test('creates with score', () {
      final candidate = BridgeCandidate(
        peerId: 'peer-1',
        score: 0.85,
        hasInternet: true,
        batteryLevel: 90,
        rssi: -45,
        stabilityScore: 0.9,
        currentLoad: 2,
        evaluatedAt: DateTime.now(),
      );

      expect(candidate.score, 0.85);
      expect(candidate.peerId, 'peer-1');
    });
  });
}
