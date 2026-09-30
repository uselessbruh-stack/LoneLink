# LONE LINK — Implementation Plan

**Version:** 1.0
**Date:** 2026-09-30
**Status:** Phase 0 Complete

---

## 1. Project Analysis

### 1.1 Current State
- **Repository:** Empty — no existing code, dependencies, or configuration
- **Platform Decision:** Flutter/Dart, targeting Android first
- **Database:** Drift (type-safe SQLite with migrations)
- **Cloud Transport:** Custom WebSocket server
- **BLE Library:** flutter_blue_plus

### 1.2 Technology Stack

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Framework | Flutter 3.x / Dart 3.x | Cross-platform, strong BLE plugin ecosystem |
| BLE | flutter_blue_plus | Most actively maintained Flutter BLE library |
| Database | Drift (moor successor) | Type-safe SQL, compile-time checked queries, migrations |
| State Management | Riverpod | Testable, compile-safe, no context dependency |
| DI | Riverpod providers | Native to state management, no extra framework |
| Crypto | pointycastle + flutter_secure_storage | Established Dart crypto + platform keystore |
| Serialization | freezed + json_serializable | Immutable models, union types, JSON codec |
| Routing (UI) | go_router | Declarative, type-safe navigation |
| Logging | logger | Structured logging with levels |
| Testing | flutter_test + mockito + integration_test | Standard Flutter testing stack |
| Cloud Backend | Dart shelf + web_socket_channel | Lightweight, same-language server |

### 1.3 Platform Limitations (Android BLE)

| Limitation | Impact | Mitigation |
|-----------|--------|------------|
| Background BLE scanning restricted (Android 8+) | Cannot continuously scan in background | Use foreground service with notification; scan in bursts |
| BLE connection limit (~7 simultaneous) | Limits mesh size per node | Connection pooling, priority-based connect/disconnect |
| MTU negotiation required | Default 23 bytes usable is too small | Negotiate MTU up to 512; implement fragmentation |
| Location permission required for BLE scanning | UX friction | Clear permission rationale UI |
| Doze mode kills background tasks | Messages delayed in deep sleep | Use WorkManager for periodic wake; foreground service for active mesh |
| BLE advertising payload limited (31 bytes) | Cannot advertise full identity | Advertise service UUID only; exchange identity post-connect |

### 1.4 Security Concerns

| Concern | Approach |
|---------|----------|
| Key storage | Android Keystore via flutter_secure_storage — keys never in plaintext DB |
| Encryption | X25519 key exchange + AES-256-GCM for messages |
| Signatures | Ed25519 for message authentication |
| Replay protection | Unique message ID + timestamp + expiry + nonce |
| Relay privacy | Relay nodes see envelope metadata but NOT plaintext payload |
| Identity | Cryptographic identity (Ed25519 public key hash), display name separate |

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                 PRESENTATION                     │
│  Screens · Widgets · Controllers · State         │
├─────────────────────────────────────────────────┤
│                   SERVICES                       │
│  MessageService · PeerService · BridgeService    │
│  SyncService · ConnectivityService               │
├─────────────────────────────────────────────────┤
│                    DOMAIN                        │
│  Entities · Value Objects · Repository Interfaces │
├──────────┬──────────┬──────────┬────────────────┤
│ NETWORK  │ STORAGE  │ SECURITY │ SYNC           │
│ BLE      │ Drift DB │ Keys     │ Merkle Tree    │
│ Internet │ Repos    │ Encrypt  │ Reconciliation │
│ Routing  │ Migrate  │ Sign     │ Queues         │
│ Discovery│          │ Verify   │                │
└──────────┴──────────┴──────────┴────────────────┘
```

### 2.1 Directory Structure

```
lib/
├── core/
│   ├── constants/          # App-wide constants, UUIDs, config
│   ├── errors/             # Failure types, error handling
│   ├── logging/            # Structured logger wrapper
│   ├── result/             # Result<T> type for error handling
│   └── utils/              # Shared utilities
│
├── domain/
│   ├── entities/           # Core business objects
│   ├── value_objects/       # Typed wrappers (MessageId, PeerId, etc.)
│   ├── repositories/       # Abstract repository interfaces
│   └── services/           # Domain service interfaces
│
├── data/
│   ├── models/             # DB models, DTOs
│   ├── repositories/       # Repository implementations
│   └── datasources/        # Local (Drift) and remote data sources
│
├── networking/
│   ├── transport/          # Transport interface + registry
│   ├── ble/                # BLE transport implementation
│   │   ├── scanner.dart
│   │   ├── advertiser.dart
│   │   ├── connection.dart
│   │   ├── gatt_server.dart
│   │   ├── gatt_client.dart
│   │   ├── framing.dart    # Packet fragmentation/reassembly
│   │   └── ble_transport.dart
│   ├── internet/           # WebSocket transport implementation
│   ├── packets/            # Packet types, serialization, protocol
│   ├── routing/            # Route computation, TTL, loop prevention
│   ├── discovery/          # Peer discovery abstraction
│   └── acknowledgements/   # ACK tracking, delivery confirmation
│
├── security/
│   ├── identity/           # Device identity generation/management
│   ├── keys/               # Key generation, storage, exchange
│   ├── encryption/         # E2E encryption (X25519 + AES-GCM)
│   ├── signatures/         # Ed25519 message signing
│   └── replay_protection/  # Nonce tracking, expiry enforcement
│
├── storage/
│   ├── database/           # Drift database definition, tables
│   ├── daos/               # Data access objects
│   └── migrations/         # Schema migration strategies
│
├── synchronization/
│   ├── merkle/             # Merkle tree implementation
│   ├── reconciliation/     # Diff + transfer logic
│   └── queues/             # Pending message queue management
│
├── services/
│   ├── message_service.dart
│   ├── peer_service.dart
│   ├── bridge_service.dart
│   ├── sync_service.dart
│   └── connectivity_service.dart
│
├── presentation/
│   ├── app.dart
│   ├── router.dart
│   ├── theme/
│   ├── screens/
│   │   ├── splash/
│   │   ├── identity_setup/
│   │   ├── home/
│   │   ├── conversations/
│   │   ├── chat/
│   │   ├── nearby_peers/
│   │   ├── network_topology/
│   │   ├── diagnostics/
│   │   ├── settings/
│   │   └── about/
│   ├── widgets/
│   └── providers/          # Riverpod providers
│
└── main.dart

test/
├── unit/
│   ├── domain/
│   ├── networking/
│   ├── security/
│   ├── storage/
│   └── synchronization/
├── integration/
└── device/

docs/
├── architecture/
├── protocol/
├── security/
├── testing/
└── development/
```

---

## 3. Implementation Phases

### PHASE 1 — Foundation (Current Target)
**Goal:** Buildable project with core architecture, models, database, DI, navigation, basic UI shell.

Tasks:
1. Create Flutter project
2. Add all dependencies to pubspec.yaml
3. Create core/ module (constants, errors, logging, result type)
4. Create domain/ entities (UserIdentity, Peer, Message, Conversation, MessageEnvelope, etc.)
5. Create value objects (MessageId, PeerId, ConversationId, etc.)
6. Create Drift database with all tables
7. Create repository interfaces
8. Set up Riverpod providers
9. Set up go_router navigation
10. Create UI shell (all screens as placeholders with real navigation)
11. Create theme system (dark/light mode)
12. Write unit tests for entities, value objects, serialization
13. Build and verify no analyzer errors

**Definition of Done:**
- `flutter analyze` passes with no errors
- `flutter test` passes
- App launches on Android with navigation between all screens
- Database creates and migrates correctly
- All domain entities serialize/deserialize correctly

### PHASE 2 — Direct BLE
**Goal:** Two phones discover each other and exchange messages over BLE.

Tasks:
1. Implement Transport interface
2. Implement BLE permissions handling
3. Implement BLE scanner (discover peers)
4. Implement BLE advertiser (be discoverable)
5. Define GATT service and characteristics (custom UUIDs)
6. Implement GATT server (receive connections)
7. Implement GATT client (initiate connections)
8. Implement packet framing (fragmentation + reassembly over BLE)
9. Define packet types (HELLO, MESSAGE, ACK, etc.)
10. Implement packet serialization (binary, compact)
11. Implement direct message send/receive
12. Implement ACK for direct messages
13. Update UI: nearby peers screen, chat screen with real BLE data
14. Write unit tests for framing, packet serialization
15. Device test: two phones, direct BLE chat

**Definition of Done:**
- Phone A discovers Phone B
- Phone A sends "Hello" to Phone B over BLE
- Phone B receives the message and sends ACK
- Phone A shows "Delivered"
- Works on real Android devices

### PHASE 3 — Offline Messaging & Persistence
**Goal:** Messages survive app restart, queue when peer unavailable, retry on reconnect.

Tasks:
1. Implement message state machine (CREATED → QUEUED → SENDING → DELIVERED → ACK)
2. Implement persistent message queue
3. Implement retry scheduling with exponential backoff
4. Implement message expiration (TTL-based)
5. Implement deduplication (processed message ID cache + DB)
6. Handle app lifecycle (background/foreground)
7. Handle BLE disconnect gracefully
8. Write unit tests for state machine, queue, dedup, retry
9. Integration test: send while offline, deliver when reconnected

**Definition of Done:**
- Send message while peer offline → message queued
- Peer comes back → message delivered automatically
- App restart → pending messages still in queue
- Duplicate message received → only one copy stored
- Expired message → dropped, marked expired

### PHASE 4 — Multi-Hop Mesh
**Goal:** A→B→C message relay over BLE mesh.

Tasks:
1. Implement routing engine (direct, relay, unavailable)
2. Implement TTL decrement + enforcement
3. Implement relay logic (receive, check dedup, forward)
4. Implement loop prevention (message ID + TTL)
5. Implement route tracking (which peer to forward to)
6. Implement relay ACK propagation (C→B→A)
7. Update peer discovery to share routing table
8. Write unit tests for routing, TTL, relay
9. Device test: three phones, A→B→C

**Definition of Done:**
- A sends message to C; B relays it
- B does not create a duplicate message
- TTL decrements at each hop
- ACK propagates back: C→B→A
- TTL=0 → message dropped

### PHASE 5 — Internet Transport
**Goal:** Messages can be sent via WebSocket to a cloud relay server.

Tasks:
1. Create WebSocket server (Dart shelf)
2. Implement InternetTransport (WebSocket client)
3. Implement cloud message relay (upload, download, ACK)
4. Implement authentication token for server
5. Implement message retrieval (poll or push)
6. Write integration tests with local server
7. Update UI: transport indicator (BLE vs Internet)

**Definition of Done:**
- Phone A sends message via Internet to Phone C
- Cloud server relays correctly
- ACK flows back
- Transport badge shows "Internet"

### PHASE 6 — Bridge Selection
**Goal:** Automatic BLE→Internet bridge when a mesh peer has Internet.

Tasks:
1. Implement connectivity monitoring (BLE + Internet state)
2. Implement bridge candidate detection
3. Implement bridge scoring algorithm
4. Implement hybrid routing (BLE→Bridge→Internet→Cloud→Destination)
5. Implement seamless transport switching (BLE fails → try Internet)
6. Implement deduplication across transports
7. Write unit tests for bridge scoring
8. Device test: A(no internet)→BLE→B(internet)→Cloud→C

**Definition of Done:**
- B automatically selected as bridge based on score
- A's message reaches C via B's Internet
- Transport badge shows "BLE → Bridge → Internet"
- If B loses Internet, bridge re-ranked

### PHASE 7 — Synchronization
**Goal:** Peers sync missing messages efficiently when reconnecting.

Tasks:
1. Implement message inventory (local set of message IDs per conversation)
2. Implement sync request/response protocol
3. Implement Merkle tree for message inventory
4. Implement tree comparison (root → subtree → leaf diff)
5. Implement incremental sync (transfer only missing)
6. Implement sync over BLE and Internet
7. Write unit tests for Merkle tree, sync protocol
8. Integration test: two peers, disconnect, add messages, reconnect, sync

**Definition of Done:**
- Two peers reconnect after being offline
- Only missing messages transferred
- Merkle tree correctly identifies differences
- No full database transfer

### PHASE 8 — Security
**Goal:** End-to-end encryption, signatures, replay protection.

Tasks:
1. Implement identity generation (Ed25519 keypair)
2. Implement secure key storage (Android Keystore / flutter_secure_storage)
3. Implement key exchange (X25519 ECDH)
4. Implement message encryption (AES-256-GCM)
5. Implement message signing (Ed25519)
6. Implement signature verification
7. Implement replay protection (nonce + timestamp + expiry)
8. Implement encrypted envelope (relay nodes can't read payload)
9. Write unit tests for all crypto operations
10. Write security documentation + threat model

**Definition of Done:**
- Messages encrypted end-to-end
- Relay nodes cannot read plaintext
- Replayed messages rejected
- Tampered messages rejected
- Private keys never in plaintext DB

### PHASE 9 — Polish
**Goal:** Production-quality UI, network visualization, diagnostics.

Tasks:
1. Refine all screens with premium design
2. Implement network topology graph visualization
3. Implement diagnostics screen (counters, logs, queue, routes)
4. Implement dark/light theme with smooth transitions
5. Implement accessibility (semantic labels, touch targets)
6. Implement proper error states and recovery flows
7. Performance profiling and optimization

### PHASE 10 — Testing & Documentation
**Goal:** Complete test suite, documentation, academic writeup support.

Tasks:
1. Complete unit test coverage (>80% for core modules)
2. Integration tests for all subsystems
3. Device test matrix (all 10 scenarios from spec)
4. Performance benchmarks (discovery time, latency, battery)
5. Complete all /docs/ documentation
6. Generate architecture diagrams
7. Security audit of crypto implementation

---

## 4. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| BLE background restrictions break mesh | High | High | Foreground service; document limitations; graceful degradation |
| BLE connection limit hit with 4+ peers | Medium | Medium | Connection pooling; priority queue for connections |
| MTU negotiation fails on some devices | Medium | Medium | Fallback to minimum MTU; robust fragmentation |
| WebSocket server hosting for demo | Low | Medium | Run server locally or on free tier; document setup |
| Crypto performance on low-end devices | Low | Low | Use efficient curves (Curve25519); lazy key derivation |

---

## 5. Assumptions

1. **ASSUMPTION:** BLE Classic is NOT used — only BLE (Bluetooth Low Energy) 4.2+
2. **ASSUMPTION:** Maximum mesh size for demo is ~5-10 nodes (BLE connection limit)
3. **ASSUMPTION:** The WebSocket server runs on the same LAN or a cloud VM for demo
4. **ASSUMPTION:** No SMS/cellular fallback transport (could be added later)
5. **ASSUMPTION:** Single device per identity (no multi-device sync in v1)
6. **ASSUMPTION:** Android 6.0+ (API 23+) minimum for BLE + permissions
7. **ASSUMPTION:** No group chat in v1 — only 1:1 conversations

---

## 6. Phase 1 Detailed Task Breakdown

### Task 1.1: Create Flutter Project
```
flutter create --org com.lonelink --project-name lone_link --platforms android .
```

### Task 1.2: Dependencies (pubspec.yaml)
- flutter_blue_plus (BLE)
- drift + sqlite3_flutter_libs (database)
- flutter_riverpod (state management)
- go_router (navigation)
- freezed + json_serializable (models)
- pointycastle (crypto)
- flutter_secure_storage (key storage)
- uuid (message IDs)
- logger (logging)
- connectivity_plus (network monitoring)
- battery_plus (battery level for bridge scoring)
- permission_handler (runtime permissions)
- equatable (value equality)
- build_runner + freezed_annotation + json_annotation (codegen)
- drift_dev (codegen)
- mockito + build_runner (testing)

### Task 1.3-1.13: See Phase 1 tasks above

**Estimated effort:** Phase 1 alone involves ~40 files across core, domain, data, and presentation layers.

---

*This document will be updated after each phase completion.*
