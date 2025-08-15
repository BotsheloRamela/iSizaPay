import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class PeerDevice {
  final String id;
  final String name;
  final bool isConnected;
  final DateTime discoveredAt;

  PeerDevice({
    required this.id,
    required this.name,
    this.isConnected = false,
    required this.discoveredAt,
  });

  PeerDevice copyWith({
    String? id,
    String? name,
    bool? isConnected,
    DateTime? discoveredAt,
  }) {
    return PeerDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      isConnected: isConnected ?? this.isConnected,
      discoveredAt: discoveredAt ?? this.discoveredAt,
    );
  }
}

enum P2PConnectionStatus {
  disconnected,
  discovering,
  advertising,
  connecting,
  connected,
  error,
}

class P2PService extends ChangeNotifier {
  static const String _serviceId = 'com.example.isiza_pay.p2p';
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  final Map<String, PeerDevice> _discoveredDevices = {};
  final Map<String, PeerDevice> _connectedDevices = {};
  P2PConnectionStatus _status = P2PConnectionStatus.disconnected;
  String? _currentDeviceId;
  String? _errorMessage;
  
  // Message handler callback
  Function(String endpointId, Map<String, dynamic> message)? onMessageReceived;

  Map<String, PeerDevice> get discoveredDevices => Map.unmodifiable(_discoveredDevices);
  Map<String, PeerDevice> get connectedDevices => Map.unmodifiable(_connectedDevices);
  P2PConnectionStatus get status => _status;
  String? get currentDeviceId => _currentDeviceId;
  String? get errorMessage => _errorMessage;

  void _updateStatus(P2PConnectionStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _updateStatus(P2PConnectionStatus.error);
  }

  Future<bool> _checkAndRequestPermissions() async {
    // First check if permissions are already granted
    final permissions = <Permission>[
      Permission.location,
      Permission.locationWhenInUse,
    ];

    // Check Bluetooth permissions
    final bluetoothScanStatus = await Permission.bluetoothScan.status;
    if (bluetoothScanStatus.isGranted) {
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ]);
    } else {
      // For older Android versions
      permissions.add(Permission.bluetooth);
    }

    // Check WiFi permissions
    final nearbyWifiStatus = await Permission.nearbyWifiDevices.status;
    if (nearbyWifiStatus.isGranted) {
      permissions.add(Permission.nearbyWifiDevices);
    }

    // Check if all permissions are already granted
    bool allGranted = true;
    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        allGranted = false;
        break;
      }
    }

    // If all permissions are granted, return early
    if (allGranted) {
      return true;
    }

    // Request only the permissions that are not granted
    final Map<Permission, PermissionStatus> statuses = {};
    final List<String> deniedPermissions = [];

    for (final permission in permissions) {
      final currentStatus = await permission.status;
      if (!currentStatus.isGranted) {
        final status = await permission.request();
        statuses[permission] = status;
        
        debugPrint('Permission ${permission.toString()}: ${status.toString()}');
        
        if (!status.isGranted) {
          deniedPermissions.add(_getPermissionName(permission));
        }
      }
    }

    if (deniedPermissions.isNotEmpty) {
      _setError('Required permissions denied: ${deniedPermissions.join(', ')}. Please grant these permissions in your device settings.');
      return false;
    }

    return true;
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.location:
      case Permission.locationWhenInUse:
        return 'Location';
      case Permission.bluetooth:
        return 'Bluetooth';
      case Permission.bluetoothScan:
        return 'Bluetooth Scan';
      case Permission.bluetoothConnect:
        return 'Bluetooth Connect';
      case Permission.bluetoothAdvertise:
        return 'Bluetooth Advertise';
      case Permission.nearbyWifiDevices:
        return 'Nearby WiFi Devices';
      default:
        return permission.toString();
    }
  }

  String _generateDeviceId() {
    final random = Random();
    return 'device_${random.nextInt(10000).toString().padLeft(4, '0')}';
  }

  Future<Map<String, bool>> checkPermissionStatus() async {
    final permissions = [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ];

    final Map<String, bool> status = {};
    for (final permission in permissions) {
      status[_getPermissionName(permission)] = await permission.isGranted;
    }
    
    return status;
  }

  Future<bool> openAppSettings() async {
    return await Permission.bluetooth.request().isGranted;
  }

  Future<void> startDiscovery() async {
    try {
      // Don't start if already discovering or advertising
      if (_status == P2PConnectionStatus.discovering ||
          _status == P2PConnectionStatus.advertising) {
        return;
      }

      if (!await _checkAndRequestPermissions()) {
        _setError('Required permissions not granted');
        return;
      }

      _currentDeviceId = _generateDeviceId();
      _discoveredDevices.clear();
      _updateStatus(P2PConnectionStatus.discovering);

      await Nearby().startDiscovery(
        _currentDeviceId!,
        _strategy,
        onEndpointFound: (String id, String name, String serviceId) {
          _discoveredDevices[id] = PeerDevice(
            id: id,
            name: name,
            discoveredAt: DateTime.now(),
          );
          notifyListeners();
        },
        onEndpointLost: (String? id) {
          _discoveredDevices.remove(id);
          notifyListeners();
        },
        serviceId: _serviceId,
      );
    } catch (e) {
      _setError('Failed to start discovery: $e');
    }
  }

  Future<void> startAdvertising() async {
    try {
      // Don't start if already discovering or advertising
      if (_status == P2PConnectionStatus.discovering ||
          _status == P2PConnectionStatus.advertising) {
        return;
      }

      if (!await _checkAndRequestPermissions()) {
        _setError('Required permissions not granted');
        return;
      }

      _currentDeviceId = _generateDeviceId();
      _updateStatus(P2PConnectionStatus.advertising);

      await Nearby().startAdvertising(
        _currentDeviceId!,
        _strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          _handleConnectionInitiated(id, info);
        },
        onConnectionResult: (String id, Status status) {
          _handleConnectionResult(id, status);
        },
        onDisconnected: (String id) {
          _handleDisconnection(id);
        },
        serviceId: _serviceId,
      );
    } catch (e) {
      _setError('Failed to start advertising: $e');
    }
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      _updateStatus(P2PConnectionStatus.connecting);

      await Nearby().requestConnection(
        _currentDeviceId ?? _generateDeviceId(),
        deviceId,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          _handleConnectionInitiated(id, info);
        },
        onConnectionResult: (String id, Status status) {
          _handleConnectionResult(id, status);
        },
        onDisconnected: (String id) {
          _handleDisconnection(id);
        },
      );
    } catch (e) {
      _setError('Failed to connect to device: $e');
    }
  }

  void _handleConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (String endpointId, Payload payload) {
        _handlePayloadReceived(endpointId, payload);
      },
    );
  }

  void _handleConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      final device = _discoveredDevices[id];
      if (device != null) {
        _connectedDevices[id] = device.copyWith(isConnected: true);
        _discoveredDevices.remove(id);
      }
      _updateStatus(P2PConnectionStatus.connected);
    } else {
      _setError('Connection failed with status: ${status.toString()}');
    }
  }

  void _handleDisconnection(String id) {
    final device = _connectedDevices.remove(id);
    if (device != null) {
      _discoveredDevices[id] = device.copyWith(isConnected: false);
    }
    
    if (_connectedDevices.isEmpty) {
      _updateStatus(P2PConnectionStatus.disconnected);
    }
    
    notifyListeners();
  }

  void _handlePayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      final messageString = String.fromCharCodes(payload.bytes!);
      debugPrint('Received message from $endpointId: $messageString');
      
      // Try to parse as JSON for payment messages
      try {
        final Map<String, dynamic> message = jsonDecode(messageString);
        if (onMessageReceived != null) {
          onMessageReceived!(endpointId, message);
        }
      } catch (e) {
        // If not JSON, treat as regular text message
        debugPrint('Received plain text message: $messageString');
        if (onMessageReceived != null) {
          onMessageReceived!(endpointId, {'type': 'text', 'content': messageString});
        }
      }
    }
  }

  Future<void> sendMessage(String deviceId, String message) async {
    try {
      await Nearby().sendBytesPayload(deviceId, Uint8List.fromList(message.codeUnits));
    } catch (e) {
      _setError('Failed to send message: $e');
    }
  }

  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      await Nearby().disconnectFromEndpoint(deviceId);
      _handleDisconnection(deviceId);
    } catch (e) {
      _setError('Failed to disconnect: $e');
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await Nearby().stopDiscovery();
      _discoveredDevices.clear();
      _updateStatus(P2PConnectionStatus.disconnected);
    } catch (e) {
      _setError('Failed to stop discovery: $e');
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await Nearby().stopAdvertising();
      _updateStatus(P2PConnectionStatus.disconnected);
    } catch (e) {
      _setError('Failed to stop advertising: $e');
    }
  }

  Future<void> stopAll() async {
    try {
      await Future.wait([
        Nearby().stopDiscovery(),
        Nearby().stopAdvertising(),
        ...(_connectedDevices.keys.map((id) => Nearby().disconnectFromEndpoint(id))),
      ]);
      
      _discoveredDevices.clear();
      _connectedDevices.clear();
      _updateStatus(P2PConnectionStatus.disconnected);
    } catch (e) {
      _setError('Failed to stop all connections: $e');
    }
  }

  @override
  void dispose() {
    stopAll();
    super.dispose();
  }
}