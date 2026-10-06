/// LONE LINK — BLE Transport Implementation
///
/// Real BLE scanning, advertising, connection, and data transfer
/// using flutter_blue_plus. This is the core of Phase 2.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:lone_link/core/constants/app_constants.dart';
import 'package:lone_link/core/logging/app_logger.dart';
import 'package:lone_link/core/result/result.dart';
import 'package:lone_link/domain/entities/entities.dart';
import 'package:lone_link/domain/entities/enums.dart';
import 'package:lone_link/networking/transport/transport.dart';

/// Real BLE transport using flutter_blue_plus.
///
/// Responsibilities:
/// - BLE scanning (discover LONE LINK peers)
/// - BLE advertising (make this device visible)
/// - GATT connection management
/// - Data transfer via characteristics
class BleTransport implements Transport {
  BleTransport({
    required this.localIdentityId,
    required this.localDisplayName,
  });

  final String localIdentityId;
  final String localDisplayName;

  // ── State ──
  TransportStatus _status = TransportStatus.uninitialized;
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, String> _deviceIdToPeerId = {};
  final Map<String, String> _peerIdToDeviceId = {};
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  Timer? _scanTimer;
  bool _isScanning = false;

  // ── Event stream ──
  final _eventController = StreamController<TransportEvent>.broadcast();

  @override
  TransportType get type => TransportType.ble;

  @override
  TransportStatus get status => _status;

  @override
  Stream<TransportEvent> get events => _eventController.stream;

  // ── Initialize ──

  @override
  Future<Result<void>> initialize() async {
    try {
      _setStatus(TransportStatus.initializing);

      // 1. Check BLE support
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        _setStatus(TransportStatus.unavailable, 'BLE not supported on this device');
        return const Result.failure(
          BleUnavailableFailure(message: 'BLE is not supported on this device'),
        );
      }

      // 2. Request permissions
      final permResult = await _requestPermissions();
      if (permResult.isFailure) {
        _setStatus(TransportStatus.unavailable, 'Permissions denied');
        return permResult;
      }

      // 3. Monitor adapter state
      _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
        if (state == BluetoothAdapterState.on) {
          if (_status == TransportStatus.unavailable) {
            _setStatus(TransportStatus.ready);
          }
        } else {
          _setStatus(TransportStatus.unavailable, 'Bluetooth is turned off');
        }
      });

      // 4. Check if BLE is currently on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _setStatus(TransportStatus.unavailable, 'Bluetooth is turned off');
        // Don't return failure — user might turn it on later.
        // The adapter state listener will update the status.
        return const Result.success(null);
      }

      _setStatus(TransportStatus.ready);
      log.info(LogCategory.ble, 'BLE Transport initialized', 'Ready for scanning');
      return const Result.success(null);
    } catch (e, st) {
      _setStatus(TransportStatus.error, e.toString());
      return Result.failure(
        BleConnectionFailure(message: 'BLE init failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  // ── Discovery (Scanning) ──

  @override
  Future<Result<void>> startDiscovery() async {
    if (_status != TransportStatus.ready &&
        _status != TransportStatus.connected) {
      return Result.failure(
        BleUnavailableFailure(message: 'BLE not ready. Status: $_status'),
      );
    }

    if (_isScanning) {
      return const Result.success(null); // Already scanning
    }

    try {
      _isScanning = true;
      _setStatus(TransportStatus.scanning);

      log.info(LogCategory.ble, 'Starting BLE scan',
          'Duration: ${kBleScanDurationSeconds}s, Service: $kBleServiceUuid');

      // Start scanning with service filter
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: kBleScanDurationSeconds),
        withServices: [Guid(kBleServiceUuid)],
        androidUsesFineLocation: false,
      );

      // Listen for scan results
      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (final result in results) {
            _handleScanResult(result);
          }
        },
        onError: (e) {
          log.error(LogCategory.ble, 'Scan error', e.toString());
          _eventController.add(TransportErrorEvent('Scan error', e));
        },
      );

      // Auto-stop after timeout
      _scanTimer?.cancel();
      _scanTimer = Timer(Duration(seconds: kBleScanDurationSeconds), () {
        stopDiscovery();
      });

      return const Result.success(null);
    } catch (e, st) {
      _isScanning = false;
      _setStatus(TransportStatus.ready);
      return Result.failure(
        BleConnectionFailure(message: 'Scan failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  /// Also scan WITHOUT service filter to find devices that are
  /// advertising with LONE LINK in their local name.
  /// This is a fallback for devices where GATT service advertisement
  /// isn't supported.
  Future<Result<void>> startBroadDiscovery() async {
    if (_status != TransportStatus.ready &&
        _status != TransportStatus.connected) {
      return Result.failure(
        BleUnavailableFailure(message: 'BLE not ready. Status: $_status'),
      );
    }

    if (_isScanning) {
      return const Result.success(null);
    }

    try {
      _isScanning = true;
      _setStatus(TransportStatus.scanning);

      log.info(LogCategory.ble, 'Starting broad BLE scan',
          'Duration: ${kBleScanDurationSeconds}s, No service filter');

      // Scan for ALL BLE devices, filter by name containing "LoneLink"
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: kBleScanDurationSeconds),
        androidUsesFineLocation: false,
      );

      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (final result in results) {
            // Accept if device has LONE LINK service UUID or name prefix
            final hasService = result.advertisementData.serviceUuids
                .any((uuid) => uuid.toString().toLowerCase() == kBleServiceUuid);
            final hasName = result.advertisementData.advName
                .startsWith('LL:');

            if (hasService || hasName) {
              _handleScanResult(result);
            }
          }
        },
        onError: (e) {
          log.error(LogCategory.ble, 'Broad scan error', e.toString());
        },
      );

      _scanTimer?.cancel();
      _scanTimer = Timer(Duration(seconds: kBleScanDurationSeconds), () {
        stopDiscovery();
      });

      return const Result.success(null);
    } catch (e, st) {
      _isScanning = false;
      _setStatus(TransportStatus.ready);
      return Result.failure(
        BleConnectionFailure(message: 'Broad scan failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<void>> stopDiscovery() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _scanSubscription = null;
      _scanTimer?.cancel();
      _scanTimer = null;
      _isScanning = false;

      if (_connectedDevices.isNotEmpty) {
        _setStatus(TransportStatus.connected);
      } else {
        _setStatus(TransportStatus.ready);
      }

      log.info(LogCategory.ble, 'BLE scan stopped', '');
      return const Result.success(null);
    } catch (e, st) {
      _isScanning = false;
      return Result.failure(
        BleConnectionFailure(message: 'Stop scan failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  // ── Connection ──

  @override
  Future<Result<void>> connectToPeer(String peerId) async {
    final deviceId = _peerIdToDeviceId[peerId];
    if (deviceId == null) {
      return Result.failure(
        BleConnectionFailure(message: 'Unknown peer: $peerId'),
      );
    }

    final device = BluetoothDevice.fromId(deviceId);

    try {
      log.info(LogCategory.ble, 'Connecting to peer', 'peerId=$peerId deviceId=$deviceId');

      await device.connect(
        timeout: const Duration(seconds: kBleConnectionTimeoutSeconds),
        autoConnect: false,
      );

      // Request higher MTU
      await device.requestMtu(kBleMaxMtu);

      // Discover services
      final services = await device.discoverServices();
      final loneLinkService = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == kBleServiceUuid,
        orElse: () => throw Exception('LONE LINK service not found'),
      );

      // Subscribe to message characteristic for incoming data
      final messageChar = loneLinkService.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == kBleMessageCharUuid,
        orElse: () => throw Exception('Message characteristic not found'),
      );
      await messageChar.setNotifyValue(true);
      messageChar.onValueReceived.listen((data) {
        _handleIncomingData(peerId, Uint8List.fromList(data));
      });

      _connectedDevices[peerId] = device;
      _setStatus(TransportStatus.connected);

      _eventController.add(PeerConnectionChangedEvent(
        peerId,
        PeerConnectionState.connected,
      ));

      // Monitor disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection(peerId);
        }
      });

      log.info(LogCategory.ble, 'Connected to peer', peerId);
      return const Result.success(null);
    } catch (e, st) {
      _eventController.add(PeerConnectionChangedEvent(
        peerId,
        PeerConnectionState.failed,
      ));
      return Result.failure(
        BleConnectionFailure(message: 'Connect failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<void>> disconnectFromPeer(String peerId) async {
    final device = _connectedDevices.remove(peerId);
    if (device == null) {
      return const Result.success(null);
    }

    try {
      await device.disconnect();
      _handleDisconnection(peerId);
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(
        BleConnectionFailure(message: 'Disconnect failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  // ── Send Data ──

  @override
  Future<Result<void>> sendEnvelope(String peerId, MessageEnvelope envelope) async {
    final device = _connectedDevices[peerId];
    if (device == null) {
      return Result.failure(
        BleConnectionFailure(message: 'Not connected to peer: $peerId'),
      );
    }

    try {
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == kBleServiceUuid,
      );
      final char = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == kBleMessageCharUuid,
      );

      // Serialize the envelope as JSON bytes
      final jsonStr = jsonEncode({
        'type': 'envelope',
        'messageId': envelope.messageId,
        'conversationId': envelope.conversationId,
        'senderId': envelope.senderId,
        'destinationId': envelope.destinationId,
        'timestamp': envelope.timestamp,
        'expiry': envelope.expiry,
        'ttl': envelope.ttl,
        'packetType': envelope.packetType.code,
        'payload': base64Encode(envelope.payload),
        'payloadHash': base64Encode(envelope.payloadHash),
        'signature': base64Encode(envelope.signature),
      });

      final data = utf8.encode(jsonStr);

      // Fragment if needed (BLE MTU is limited)
      final mtu = await device.requestMtu(kBleMaxMtu);
      final chunkSize = mtu - kBleAttOverhead;

      for (var i = 0; i < data.length; i += chunkSize) {
        final end = (i + chunkSize > data.length) ? data.length : i + chunkSize;
        final chunk = data.sublist(i, end);
        await char.write(chunk, withoutResponse: false);
      }

      log.info(LogCategory.ble, 'Sent envelope', 'msgId=${envelope.messageId} to=$peerId');
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(
        BleConnectionFailure(message: 'Send failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<void>> sendAck(String peerId, Acknowledgement ack) async {
    final device = _connectedDevices[peerId];
    if (device == null) {
      return Result.failure(
        BleConnectionFailure(message: 'Not connected to peer: $peerId'),
      );
    }

    try {
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == kBleServiceUuid,
      );
      final char = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == kBleAckCharUuid,
      );

      final jsonStr = jsonEncode({
        'type': 'ack',
        'messageId': ack.messageId,
        'fromPeerId': ack.fromPeerId,
        'status': ack.status.name,
        'timestamp': ack.timestamp.millisecondsSinceEpoch,
      });

      await char.write(utf8.encode(jsonStr), withoutResponse: false);
      log.info(LogCategory.ble, 'Sent ACK', 'msgId=${ack.messageId}');
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(
        BleConnectionFailure(message: 'ACK send failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  @override
  List<String> getConnectedPeerIds() => _connectedDevices.keys.toList();

  @override
  Future<Result<bool>> isPeerReachable(String peerId) async {
    return Result.success(_connectedDevices.containsKey(peerId));
  }

  // ── Dispose ──

  @override
  Future<void> dispose() async {
    _setStatus(TransportStatus.disposing);

    _scanTimer?.cancel();
    await _scanSubscription?.cancel();
    await _adapterSubscription?.cancel();

    // Disconnect all
    for (final device in _connectedDevices.values) {
      try {
        await device.disconnect();
      } catch (_) {}
    }
    _connectedDevices.clear();
    _deviceIdToPeerId.clear();
    _peerIdToDeviceId.clear();

    await _eventController.close();
  }

  // ── Private Helpers ──

  Future<Result<void>> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    final denied = statuses.entries
        .where((e) => !e.value.isGranted)
        .map((e) => e.key.toString())
        .toList();

    if (denied.isNotEmpty) {
      return Result.failure(
        BleUnavailableFailure(
          message: 'BLE permissions denied: ${denied.join(", ")}',
        ),
      );
    }
    return const Result.success(null);
  }

  void _handleScanResult(ScanResult result) {
    final device = result.device;
    final advData = result.advertisementData;

    // Extract peer identity from advertisement data
    // Convention: advName = "LL:<peerId_short>:<displayName>"
    String peerId;
    String displayName;

    if (advData.advName.startsWith('LL:')) {
      final parts = advData.advName.split(':');
      peerId = parts.length > 1 ? parts[1] : device.remoteId.str;
      displayName = parts.length > 2 ? parts.sublist(2).join(':') : 'Unknown';
    } else {
      // Fallback: use device remoteId as peer identifier
      peerId = device.remoteId.str;
      displayName = advData.advName.isNotEmpty
          ? advData.advName
          : 'Device ${device.remoteId.str.substring(0, 8)}';
    }

    // Map device <-> peer
    _deviceIdToPeerId[device.remoteId.str] = peerId;
    _peerIdToDeviceId[peerId] = device.remoteId.str;

    // Create Peer domain entity
    final peer = Peer(
      id: peerId,
      displayName: displayName,
      publicKey: Uint8List(0), // Will be exchanged during handshake
      keyExchangePublicKey: Uint8List(0),
      connectionState: PeerConnectionState.discovered,
      rssi: result.rssi,
      hasInternet: false,
      firstSeen: DateTime.now(),
      lastSeen: DateTime.now(),
    );

    _eventController.add(PeerDiscoveredEvent(peer));

    log.info(LogCategory.ble, 'Peer discovered',
        'name=$displayName rssi=${result.rssi} id=$peerId');
  }

  void _handleDisconnection(String peerId) {
    _connectedDevices.remove(peerId);

    _eventController.add(PeerConnectionChangedEvent(
      peerId,
      PeerConnectionState.disconnected,
    ));

    if (_connectedDevices.isEmpty && !_isScanning) {
      _setStatus(TransportStatus.ready);
    }

    log.info(LogCategory.ble, 'Peer disconnected', peerId);
  }

  void _handleIncomingData(String peerId, Uint8List data) {
    try {
      final jsonStr = utf8.decode(data);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (json['type'] == 'ack') {
        final ack = Acknowledgement(
          messageId: json['messageId'] as String,
          fromPeerId: json['fromPeerId'] as String,
          status: AckStatus.values.firstWhere(
            (s) => s.name == json['status'],
            orElse: () => AckStatus.received,
          ),
          timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        );
        _eventController.add(AckReceivedEvent(ack));
      } else {
        final envelope = MessageEnvelope(
          protocolVersion: kProtocolVersion,
          messageId: json['messageId'] as String,
          conversationId: json['conversationId'] as String,
          senderId: json['senderId'] as String,
          destinationId: json['destinationId'] as String,
          timestamp: json['timestamp'] as int,
          expiry: json['expiry'] as int,
          ttl: json['ttl'] as int,
          packetType: PacketType.fromCode(json['packetType'] as int),
          payload: base64Decode(json['payload'] as String),
          payloadHash: base64Decode(json['payloadHash'] as String),
          signature: base64Decode(json['signature'] as String),
        );
        _eventController.add(EnvelopeReceivedEvent(envelope, TransportType.ble));
      }
    } catch (e) {
      log.error(LogCategory.ble, 'Failed to parse incoming data', e.toString());
    }
  }

  void _setStatus(TransportStatus newStatus, [String? reason]) {
    _status = newStatus;
    _eventController.add(TransportStatusChangedEvent(newStatus, reason));
  }
}
