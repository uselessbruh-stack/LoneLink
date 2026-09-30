# LONE LINK — Architecture Overview

## System Architecture

```mermaid
graph TB
    subgraph Presentation["Presentation Layer"]
        UI[Flutter UI]
        Providers[Riverpod Providers]
    end

    subgraph Services["Service Layer"]
        MsgSvc[Message Service]
        PeerSvc[Peer Service]
        BridgeSvc[Bridge Service]
        SyncSvc[Sync Service]
        ConnSvc[Connectivity Service]
    end

    subgraph Domain["Domain Layer"]
        Entities[Entities]
        RepoInterfaces[Repository Interfaces]
    end

    subgraph Networking["Networking Layer"]
        Transport[Transport Interface]
        BLE[BLE Transport]
        Internet[Internet Transport]
        Routing[Routing Engine]
        Discovery[Peer Discovery]
        Packets[Packet Protocol]
    end

    subgraph Security["Security Layer"]
        Identity[Identity Manager]
        Encryption[E2E Encryption]
        KeyMgmt[Key Management]
        Replay[Replay Protection]
    end

    subgraph Storage["Storage Layer"]
        DB[(Drift SQLite)]
        SecureStore[(Secure Storage)]
        DAOs[Data Access Objects]
    end

    subgraph Sync["Synchronization"]
        Merkle[Merkle Tree]
        Reconciliation[Reconciliation]
        Queue[Message Queue]
    end

    UI --> Providers
    Providers --> Services
    Services --> Domain
    Services --> Networking
    Services --> Security
    Services --> Storage
    Services --> Sync

    Transport --> BLE
    Transport --> Internet

    MsgSvc --> Transport
    MsgSvc --> Routing
    MsgSvc --> Encryption
    MsgSvc --> Queue

    PeerSvc --> Discovery
    PeerSvc --> BLE

    BridgeSvc --> Routing
    BridgeSvc --> ConnSvc

    SyncSvc --> Merkle
    SyncSvc --> Reconciliation

    DAOs --> DB
    Identity --> SecureStore
    KeyMgmt --> SecureStore
```

## Communication Paths

```mermaid
flowchart LR
    A["📱 Phone A"]
    B["📱 Phone B"]
    C["📱 Phone C"]
    Cloud["☁️ Cloud Server"]

    A <-->|BLE| B
    B <-->|BLE| C
    B <-->|Internet| Cloud
    C <-->|Internet| Cloud

    style A fill:#00BFA6,color:#000
    style B fill:#448AFF,color:#fff
    style C fill:#FF9800,color:#000
    style Cloud fill:#66BB6A,color:#000
```

### Path Types

| Path | Example | Description |
|------|---------|-------------|
| Direct BLE | A ↔ B | Two nearby phones communicate directly |
| Multi-hop BLE | A → B → C | Message relayed through intermediate node |
| Internet | A → Cloud → C | Both phones have Internet |
| Bridge | A → BLE → B → Internet → Cloud → C | B bridges BLE to Internet |
| Store-and-forward | A → Queue → ... → C | C offline, message queued |

## Layer Responsibilities

### Presentation
- Flutter widgets and screens
- Riverpod state management
- Navigation (go_router)
- No business logic

### Services
- Orchestrate domain operations
- Coordinate between networking and storage
- Manage message lifecycle
- Bridge selection logic

### Domain
- Pure business entities
- Repository interfaces (contracts)
- No framework dependencies
- Immutable data models

### Networking
- Transport abstraction (BLE / Internet interchangeable)
- BLE GATT server and client
- Packet framing and fragmentation
- Routing engine
- Peer discovery

### Security
- Cryptographic identity (Ed25519 + X25519)
- End-to-end encryption (AES-256-GCM)
- Message signatures
- Replay protection
- Secure key storage

### Storage
- Drift SQLite database
- 10 normalized tables
- Real-time streams
- Schema migrations
- Offline-first persistence

### Synchronization
- Merkle-tree message inventory
- Missing message detection
- Incremental transfer
- Deduplication during sync

## Implementation Status

| Component | Status |
|-----------|--------|
| Project architecture | ✅ IMPLEMENTED |
| Domain entities | ✅ IMPLEMENTED |
| Database schema | ✅ IMPLEMENTED |
| Repository interfaces | ✅ IMPLEMENTED |
| Transport interface | ✅ IMPLEMENTED |
| Theme system | ✅ IMPLEMENTED |
| Navigation | ✅ IMPLEMENTED |
| UI shell (all screens) | ✅ IMPLEMENTED |
| Unit tests (entities, Result) | ✅ IMPLEMENTED |
| BLE transport | ⬜ DESIGNED (Phase 2) |
| Direct BLE messaging | ⬜ DESIGNED (Phase 2) |
| Message queue | ⬜ DESIGNED (Phase 3) |
| Multi-hop routing | ⬜ DESIGNED (Phase 4) |
| Internet transport | ⬜ DESIGNED (Phase 5) |
| Bridge selection | ⬜ DESIGNED (Phase 6) |
| Merkle sync | ⬜ DESIGNED (Phase 7) |
| Encryption | ⬜ DESIGNED (Phase 8) |
