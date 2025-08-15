import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/p2p_service.dart';
import '../widgets/error_dialog.dart';
import 'p2p_connection_screen.dart';

class P2PDiscoveryScreen extends StatefulWidget {
  const P2PDiscoveryScreen({super.key});

  @override
  State<P2PDiscoveryScreen> createState() => _P2PDiscoveryScreenState();
}

class _P2PDiscoveryScreenState extends State<P2PDiscoveryScreen> {
  late P2PService _p2pService;

  @override
  void initState() {
    super.initState();
    _p2pService = Provider.of<P2PService>(context, listen: false);
    _p2pService.addListener(_handleServiceErrors);
  }

  @override
  void dispose() {
    _p2pService.removeListener(_handleServiceErrors);
    super.dispose();
  }

  void _handleServiceErrors() {
    if (_p2pService.status == P2PConnectionStatus.error && 
        _p2pService.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ErrorDialog.show(
            context,
            title: 'P2P Error',
            message: _p2pService.errorMessage!,
            onRetry: () {
              if (_p2pService.status == P2PConnectionStatus.error) {
                _p2pService.startDiscovery();
              }
            },
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Discovery'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<P2PService>(
            builder: (context, service, child) {
              return PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'start_discovery',
                    child: Text('Start Discovery'),
                  ),
                  const PopupMenuItem(
                    value: 'start_advertising',
                    child: Text('Start Advertising'),
                  ),
                  const PopupMenuItem(
                    value: 'stop_all',
                    child: Text('Stop All'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<P2PService>(
        builder: (context, service, child) {
          return Column(
            children: [
              _buildStatusCard(service),
              _buildDeviceIdCard(service),
              Expanded(
                child: _buildDeviceList(service),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<P2PService>(
        builder: (context, service, child) {
          return FloatingActionButton(
            onPressed: service.status == P2PConnectionStatus.disconnected
                ? _startDiscoveryWithPermissionGuide
                : null,
            child: const Icon(Icons.search),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(P2PService service) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (service.status) {
      case P2PConnectionStatus.disconnected:
        statusColor = Colors.grey;
        statusIcon = Icons.cloud_off;
        statusText = 'Disconnected';
        break;
      case P2PConnectionStatus.discovering:
        statusColor = Colors.blue;
        statusIcon = Icons.search;
        statusText = 'Discovering...';
        break;
      case P2PConnectionStatus.advertising:
        statusColor = Colors.orange;
        statusIcon = Icons.broadcast_on_personal;
        statusText = 'Advertising...';
        break;
      case P2PConnectionStatus.connecting:
        statusColor = Colors.yellow.shade700;
        statusIcon = Icons.sync;
        statusText = 'Connecting...';
        break;
      case P2PConnectionStatus.connected:
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done;
        statusText = 'Connected (${service.connectedDevices.length} devices)';
        break;
      case P2PConnectionStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Error: ${service.errorMessage ?? "Unknown error"}';
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          if (service.status == P2PConnectionStatus.discovering ||
              service.status == P2PConnectionStatus.advertising ||
              service.status == P2PConnectionStatus.connecting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceIdCard(P2PService service) {
    if (service.currentDeviceId == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_android, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Text(
            'Your Device ID: ${service.currentDeviceId}',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(P2PService service) {
    final discoveredDevices = service.discoveredDevices.values.toList();
    final connectedDevices = service.connectedDevices.values.toList();

    if (discoveredDevices.isEmpty && connectedDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No devices found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start discovery to find nearby devices',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (connectedDevices.isNotEmpty) ...[
          _buildSectionHeader('Connected Devices', Icons.link, Colors.green),
          ...connectedDevices.map((device) => _buildDeviceCard(device, true)),
          const SizedBox(height: 16),
        ],
        if (discoveredDevices.isNotEmpty) ...[
          _buildSectionHeader('Discovered Devices', Icons.search, Colors.blue),
          ...discoveredDevices.map((device) => _buildDeviceCard(device, false)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(PeerDevice device, bool isConnected) {
    final timeSinceDiscovery = DateTime.now().difference(device.discoveredAt);
    final timeText = timeSinceDiscovery.inMinutes < 1
        ? '${timeSinceDiscovery.inSeconds}s ago'
        : '${timeSinceDiscovery.inMinutes}m ago';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isConnected ? Colors.green : Colors.blue,
          child: Icon(
            isConnected ? Icons.link : Icons.devices,
            color: Colors.white,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${device.id}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'Discovered $timeText',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: isConnected
            ? IconButton(
                icon: const Icon(Icons.link_off, color: Colors.red),
                onPressed: () => _p2pService.disconnectFromDevice(device.id),
                tooltip: 'Disconnect',
              )
            : IconButton(
                icon: const Icon(Icons.link, color: Colors.blue),
                onPressed: _p2pService.status == P2PConnectionStatus.discovering ||
                        _p2pService.status == P2PConnectionStatus.advertising
                    ? () => _p2pService.connectToDevice(device.id)
                    : null,
                tooltip: 'Connect',
              ),
        onTap: () {
          if (isConnected) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => P2PConnectionScreen(
                  deviceId: device.id,
                  deviceName: device.name,
                ),
              ),
            );
          } else {
            _showDeviceDetails(device, isConnected);
          }
        },
      ),
    );
  }

  void _showDeviceDetails(PeerDevice device, bool isConnected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Device ID', device.id),
            _buildDetailRow('Status', isConnected ? 'Connected' : 'Discovered'),
            _buildDetailRow('Discovered', device.discoveredAt.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!isConnected)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _p2pService.connectToDevice(device.id);
              },
              child: const Text('Connect'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDiscoveryWithPermissionGuide() async {
    final shouldProceed = await PermissionGuideDialog.show(context);
    if (shouldProceed) {
      _p2pService.startDiscovery();
    }
  }

  Future<void> _startAdvertisingWithPermissionGuide() async {
    final shouldProceed = await PermissionGuideDialog.show(context);
    if (shouldProceed) {
      _p2pService.startAdvertising();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'start_discovery':
        _startDiscoveryWithPermissionGuide();
        break;
      case 'start_advertising':
        _startAdvertisingWithPermissionGuide();
        break;
      case 'stop_all':
        _p2pService.stopAll();
        break;
    }
  }
}