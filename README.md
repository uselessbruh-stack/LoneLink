# LONE LINK

A hybrid decentralized messaging application using BLE mesh networking and Internet transport.

![Platform](https://img.shields.io/badge/platform-Android-green)
![Framework](https://img.shields.io/badge/framework-Flutter-blue)
![Protocol](https://img.shields.io/badge/protocol-v1-orange)
![License](https://img.shields.io/badge/license-Academic-lightgrey)

## Overview

Lone Link enables smartphone-to-smartphone communication through:

- **Direct BLE messaging** — Two nearby phones communicate without Internet
- **Multi-hop BLE mesh** — Messages relay through intermediate phones
- **Internet transport** — WebSocket-based cloud relay
- **Automatic bridging** — Internet-connected phones bridge BLE and cloud
- **Store-and-forward** — Messages queue when recipients are offline
- **End-to-end encryption** — Relay nodes cannot read message content

```
Phone A ←→ BLE ←→ Phone B ←→ BLE ←→ Phone C
                       ↕
                   Internet
                       ↕
                    Cloud ←→ Phone D
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│               PRESENTATION (Flutter)             │
├─────────────────────────────────────────────────┤
│                   SERVICES                       │
│  Message · Peer · Bridge · Sync · Connectivity   │
├─────────────────────────────────────────────────┤
│               DOMAIN (Entities)                  │
├──────────┬──────────┬──────────┬────────────────┤
│ NETWORK  │ STORAGE  │ SECURITY │ SYNC           │
│ BLE      │ Drift DB │ E2E      │ Merkle Tree    │
│ Internet │ DAOs     │ Keys     │ Reconciliation │
│ Routing  │          │ Replay   │                │
└──────────┴──────────┴──────────┴────────────────┘
```

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.2.0
- Android SDK with API 23+ (Android 6.0+)
- An Android device with BLE support (for device testing)

### Setup

```bash
# 1. Clone the repository
git clone <repo-url>
cd LoneLink

# 2. Install dependencies
flutter pub get

# 3. Generate code (Drift database, etc.)
dart run build_runner build --delete-conflicting-outputs

# 4. Copy environment config
cp .env.example .env

# 5. Run the app
flutter run
```

### Running Tests

```bash
# Unit tests
flutter test

# Specific test file
flutter test test/unit/domain/entities_test.dart

# With coverage
flutter test --coverage
```

## Project Structure

```
lib/
├── core/              # Constants, errors, logging, Result type
├── domain/            # Entities, enums, repository interfaces
├── data/              # Repository implementations
├── networking/        # Transport interface, BLE, Internet, routing
├── security/          # Identity, encryption, signatures, replay
├── storage/           # Drift database, DAOs, migrations
├── synchronization/   # Merkle tree, reconciliation, queues
├── services/          # Business logic orchestration
├── presentation/      # Screens, widgets, providers, theme
└── main.dart

test/
├── unit/              # Unit tests
├── integration/       # Integration tests
└── device/            # Real-device tests

docs/
├── architecture/      # System design, diagrams, state machine
├── protocol/          # Packet format, BLE GATT, routing
├── security/          # Threat model, cryptography, privacy
├── testing/           # Test plan, device test matrix
└── development/       # Setup, implementation plan
```

## Key Technologies

| Component | Technology |
|-----------|-----------|
| Framework | Flutter / Dart |
| BLE | flutter_blue_plus |
| Database | Drift (SQLite) |
| State | Riverpod |
| Crypto | pointycastle + Android Keystore |
| Navigation | go_router |

## Protocol

- **Encryption:** AES-256-GCM with X25519 ECDH key exchange
- **Signatures:** Ed25519
- **Message IDs:** UUIDv4 (cryptographically secure)
- **TTL:** Default 8 hops, configurable
- **Deduplication:** Persistent message ID cache
- **Sync:** Merkle-tree based inventory comparison

## Development Phases

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Repository analysis & planning | ✅ Complete |
| 1 | Foundation (architecture, DB, UI shell) | ✅ Complete |
| 2 | Direct BLE messaging | 🔲 Next |
| 3 | Offline messaging & persistence | 🔲 Planned |
| 4 | Multi-hop mesh routing | 🔲 Planned |
| 5 | Internet transport | 🔲 Planned |
| 6 | Bridge selection | 🔲 Planned |
| 7 | Synchronization | 🔲 Planned |
| 8 | Security (E2E encryption) | 🔲 Planned |
| 9 | UI polish & diagnostics | 🔲 Planned |
| 10 | Testing & documentation | 🔲 Planned |

## Academic Context

This application was developed as a capstone project demonstrating:

- **WHY BLE mesh**: Enables communication without Internet infrastructure
- **WHY store-and-forward**: Handles intermittent connectivity
- **WHY deduplication**: Prevents duplicate delivery in mesh networks
- **WHY TTL**: Prevents infinite routing loops
- **WHY ACKs**: Provides delivery confirmation across hops
- **WHY bridge selection**: Optimizes hybrid BLE/Internet routing
- **WHY Merkle sync**: Efficient reconciliation after disconnection
- **WHY E2E encryption**: Relay nodes should not read message content
- **WHY metadata minimization**: Protects user privacy in mesh

## Documentation

- [Architecture Overview](docs/architecture/overview.md)
- [Message State Machine](docs/architecture/state-machine.md)
- [Implementation Plan](docs/development/implementation-plan.md)

## License

Academic capstone project. See LICENSE file for details.
