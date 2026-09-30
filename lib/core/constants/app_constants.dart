/// LONE LINK — Core Constants
///
/// Application-wide constants including BLE UUIDs, protocol versions,
/// timeouts, and configuration defaults.
library;

import 'dart:typed_data';

// ─────────────────────────────────────────────
// Application
// ─────────────────────────────────────────────

const String kAppName = 'Lone Link';
const String kAppVersion = '1.0.0';
const int kProtocolVersion = 1;

// ─────────────────────────────────────────────
// BLE Service & Characteristic UUIDs
// ─────────────────────────────────────────────
// Custom UUIDs for LONE LINK BLE GATT service.
// Base UUID: 4C4F4E45-4C49-4E4B-xxxx-xxxxxxxxxxxx
// "LONELINK" in ASCII hex as base.

/// Primary LONE LINK BLE service UUID
const String kBleServiceUuid = '4c4f4e45-4c49-4e4b-0001-000000000000';

/// Characteristic for sending/receiving message packets
const String kBleMessageCharUuid = '4c4f4e45-4c49-4e4b-0002-000000000000';

/// Characteristic for peer identity exchange
const String kBleIdentityCharUuid = '4c4f4e45-4c49-4e4b-0003-000000000000';

/// Characteristic for sync operations
const String kBleSyncCharUuid = '4c4f4e45-4c49-4e4b-0004-000000000000';

/// Characteristic for ACK packets
const String kBleAckCharUuid = '4c4f4e45-4c49-4e4b-0005-000000000000';

// ─────────────────────────────────────────────
// BLE Configuration
// ─────────────────────────────────────────────

/// Maximum BLE MTU we attempt to negotiate
const int kBleMaxMtu = 512;

/// Minimum usable BLE MTU (after ATT overhead)
const int kBleMinMtu = 20;

/// Default BLE MTU if negotiation not performed
const int kBleDefaultMtu = 23;

/// ATT protocol overhead bytes
const int kBleAttOverhead = 3;

/// BLE scan duration in seconds
const int kBleScanDurationSeconds = 10;

/// BLE connection timeout in seconds
const int kBleConnectionTimeoutSeconds = 15;

/// BLE write timeout in milliseconds
const int kBleWriteTimeoutMs = 5000;

/// Maximum simultaneous BLE connections
const int kBleMaxConnections = 5;

/// BLE scan interval when in foreground (seconds)
const int kBleForegroundScanIntervalSeconds = 30;

/// BLE scan interval when in background (seconds)
const int kBleBackgroundScanIntervalSeconds = 120;

// ─────────────────────────────────────────────
// Protocol / Packet
// ─────────────────────────────────────────────

/// Magic bytes for packet framing: "LL" in ASCII
final Uint8List kPacketMagicBytes = Uint8List.fromList([0x4C, 0x4C]);

/// Maximum packet payload size in bytes
const int kMaxPacketPayloadSize = 65536;

/// Packet header size in bytes (magic + version + type + length + seqNo)
const int kPacketHeaderSize = 12;

/// Maximum fragment size (will be adjusted based on negotiated MTU)
const int kDefaultFragmentSize = 180;

// ─────────────────────────────────────────────
// Message Defaults
// ─────────────────────────────────────────────

/// Default TTL (max hops) for mesh messages
const int kDefaultMessageTtl = 8;

/// Maximum TTL allowed
const int kMaxMessageTtl = 32;

/// Message expiry duration (24 hours)
const Duration kDefaultMessageExpiry = Duration(hours: 24);

/// Maximum message text length
const int kMaxMessageTextLength = 4096;

/// Maximum number of processed message IDs to keep for deduplication
const int kMaxDeduplicationCacheSize = 10000;

/// Duration to keep processed message IDs
const Duration kDeduplicationRetentionDuration = Duration(hours: 48);

// ─────────────────────────────────────────────
// Retry & Queue
// ─────────────────────────────────────────────

/// Maximum retry attempts for message delivery
const int kMaxRetryAttempts = 10;

/// Initial retry delay
const Duration kInitialRetryDelay = Duration(seconds: 2);

/// Maximum retry delay (backoff cap)
const Duration kMaxRetryDelay = Duration(minutes: 5);

/// Retry backoff multiplier
const double kRetryBackoffMultiplier = 2.0;

/// Queue processing interval
const Duration kQueueProcessingInterval = Duration(seconds: 5);

// ─────────────────────────────────────────────
// Bridge Scoring Weights
// ─────────────────────────────────────────────

/// Weight for Internet connectivity in bridge score
const double kBridgeWeightConnectivity = 0.35;

/// Weight for battery level in bridge score
const double kBridgeWeightBattery = 0.20;

/// Weight for BLE signal strength in bridge score
const double kBridgeWeightSignal = 0.15;

/// Weight for connection stability in bridge score
const double kBridgeWeightStability = 0.20;

/// Penalty per active relay load
const double kBridgePenaltyPerLoad = 0.05;

/// Minimum battery level to be eligible as bridge (percent)
const int kBridgeMinBatteryLevel = 20;

// ─────────────────────────────────────────────
// Sync
// ─────────────────────────────────────────────

/// Maximum messages to transfer in a single sync batch
const int kSyncBatchSize = 50;

/// Sync interval in seconds
const int kSyncIntervalSeconds = 60;

// ─────────────────────────────────────────────
// Security
// ─────────────────────────────────────────────

/// Key derivation iteration count
const int kKeyDerivationIterations = 100000;

/// Nonce size in bytes for AES-GCM
const int kNonceSizeBytes = 12;

/// Auth tag size in bytes for AES-GCM
const int kAuthTagSizeBytes = 16;

/// Maximum clock skew tolerance for replay protection
const Duration kMaxClockSkew = Duration(minutes: 5);

// ─────────────────────────────────────────────
// Database
// ─────────────────────────────────────────────

/// Database file name
const String kDatabaseFileName = 'lone_link.db';

/// Current database schema version
const int kDatabaseVersion = 1;

// ─────────────────────────────────────────────
// Internet Transport
// ─────────────────────────────────────────────

/// Default WebSocket server URL (configurable)
const String kDefaultWebSocketUrl = 'ws://localhost:8080/ws';

/// WebSocket reconnect delay
const Duration kWebSocketReconnectDelay = Duration(seconds: 5);

/// WebSocket ping interval
const Duration kWebSocketPingInterval = Duration(seconds: 30);

/// HTTP request timeout
const Duration kHttpRequestTimeout = Duration(seconds: 15);
