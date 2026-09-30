/// LONE LINK — Error Types
///
/// Typed failure hierarchy for clean error handling throughout the app.
/// Uses sealed classes for exhaustive pattern matching.
library;

/// Base failure type for all LONE LINK errors.
sealed class LoneLinkFailure {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const LoneLinkFailure({
    required this.message,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' (cause: $cause)' : ''}';
}

// ─────────────────────────────────────────────
// BLE Failures
// ─────────────────────────────────────────────

class BleUnavailableFailure extends LoneLinkFailure {
  const BleUnavailableFailure({super.message = 'Bluetooth is not available on this device'});
}

class BleDisabledFailure extends LoneLinkFailure {
  const BleDisabledFailure({super.message = 'Bluetooth is turned off'});
}

class BlePermissionDeniedFailure extends LoneLinkFailure {
  const BlePermissionDeniedFailure({super.message = 'Bluetooth permissions were denied'});
}

class BleConnectionFailure extends LoneLinkFailure {
  const BleConnectionFailure({required super.message, super.cause, super.stackTrace});
}

class BleDiscoveryFailure extends LoneLinkFailure {
  const BleDiscoveryFailure({required super.message, super.cause, super.stackTrace});
}

class BleWriteFailure extends LoneLinkFailure {
  const BleWriteFailure({required super.message, super.cause, super.stackTrace});
}

class BleTimeoutFailure extends LoneLinkFailure {
  const BleTimeoutFailure({super.message = 'BLE operation timed out'});
}

// ─────────────────────────────────────────────
// Network / Internet Failures
// ─────────────────────────────────────────────

class InternetUnavailableFailure extends LoneLinkFailure {
  const InternetUnavailableFailure({super.message = 'No Internet connection'});
}

class ServerUnavailableFailure extends LoneLinkFailure {
  const ServerUnavailableFailure({required super.message, super.cause, super.stackTrace});
}

class WebSocketFailure extends LoneLinkFailure {
  const WebSocketFailure({required super.message, super.cause, super.stackTrace});
}

class ConnectionTimeoutFailure extends LoneLinkFailure {
  const ConnectionTimeoutFailure({super.message = 'Connection timed out'});
}

// ─────────────────────────────────────────────
// Protocol Failures
// ─────────────────────────────────────────────

class InvalidPacketFailure extends LoneLinkFailure {
  const InvalidPacketFailure({required super.message, super.cause});
}

class PacketTooLargeFailure extends LoneLinkFailure {
  const PacketTooLargeFailure({required super.message});
}

class UnsupportedProtocolVersionFailure extends LoneLinkFailure {
  final int receivedVersion;
  const UnsupportedProtocolVersionFailure({required this.receivedVersion})
      : super(message: 'Unsupported protocol version: $receivedVersion');
}

class CorruptedPacketFailure extends LoneLinkFailure {
  const CorruptedPacketFailure({required super.message, super.cause});
}

// ─────────────────────────────────────────────
// Message Failures
// ─────────────────────────────────────────────

class MessageExpiredFailure extends LoneLinkFailure {
  final String messageId;
  const MessageExpiredFailure({required this.messageId})
      : super(message: 'Message $messageId has expired');
}

class DuplicateMessageFailure extends LoneLinkFailure {
  final String messageId;
  const DuplicateMessageFailure({required this.messageId})
      : super(message: 'Duplicate message: $messageId');
}

class TtlExhaustedFailure extends LoneLinkFailure {
  final String messageId;
  const TtlExhaustedFailure({required this.messageId})
      : super(message: 'TTL exhausted for message: $messageId');
}

class MessageTooLargeFailure extends LoneLinkFailure {
  const MessageTooLargeFailure({required super.message});
}

class DeliveryFailure extends LoneLinkFailure {
  const DeliveryFailure({required super.message, super.cause, super.stackTrace});
}

// ─────────────────────────────────────────────
// Security Failures
// ─────────────────────────────────────────────

class EncryptionFailure extends LoneLinkFailure {
  const EncryptionFailure({required super.message, super.cause, super.stackTrace});
}

class DecryptionFailure extends LoneLinkFailure {
  const DecryptionFailure({required super.message, super.cause, super.stackTrace});
}

class SignatureVerificationFailure extends LoneLinkFailure {
  const SignatureVerificationFailure({super.message = 'Signature verification failed'});
}

class ReplayAttackDetectedFailure extends LoneLinkFailure {
  final String messageId;
  const ReplayAttackDetectedFailure({required this.messageId})
      : super(message: 'Replay attack detected for message: $messageId');
}

class KeyExchangeFailure extends LoneLinkFailure {
  const KeyExchangeFailure({required super.message, super.cause, super.stackTrace});
}

class KeyNotFoundFailure extends LoneLinkFailure {
  final String peerId;
  const KeyNotFoundFailure({required this.peerId})
      : super(message: 'No public key found for peer: $peerId');
}

class SecureStorageFailure extends LoneLinkFailure {
  const SecureStorageFailure({required super.message, super.cause, super.stackTrace});
}

// ─────────────────────────────────────────────
// Storage Failures
// ─────────────────────────────────────────────

class DatabaseFailure extends LoneLinkFailure {
  const DatabaseFailure({required super.message, super.cause, super.stackTrace});
}

class MigrationFailure extends LoneLinkFailure {
  const MigrationFailure({required super.message, super.cause, super.stackTrace});
}

// ─────────────────────────────────────────────
// Routing Failures
// ─────────────────────────────────────────────

class NoRouteAvailableFailure extends LoneLinkFailure {
  final String destinationId;
  const NoRouteAvailableFailure({required this.destinationId})
      : super(message: 'No route available to: $destinationId');
}

class RoutingLoopDetectedFailure extends LoneLinkFailure {
  final String messageId;
  const RoutingLoopDetectedFailure({required this.messageId})
      : super(message: 'Routing loop detected for message: $messageId');
}

// ─────────────────────────────────────────────
// Sync Failures
// ─────────────────────────────────────────────

class SyncFailure extends LoneLinkFailure {
  const SyncFailure({required super.message, super.cause, super.stackTrace});
}

class MerkleVerificationFailure extends LoneLinkFailure {
  const MerkleVerificationFailure({required super.message});
}
