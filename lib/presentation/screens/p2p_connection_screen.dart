import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isiza_pay/services/p2p_service.dart';
import 'package:isiza_pay/core/di/providers.dart';
import '../screens/payment_send_screen.dart';

class P2PConnectionScreen extends ConsumerWidget {
  final String deviceId;
  final String? deviceName;

  const P2PConnectionScreen({
    super.key,
    required this.deviceId,
    this.deviceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p2pService = ref.watch(p2pServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Connected to ${deviceName ?? deviceId}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildConnectionStatus(p2pService),
          _buildActionButtons(context, p2pService),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(P2PService service) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              service.status.toString().split('.').last.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(service.status),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Device ID: $deviceId'),
            if (deviceName != null) Text('Device Name: $deviceName'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, P2PService service) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: service.connectedDevices.containsKey(deviceId)
                    ? () => _navigateToPaymentSend(context)
                    : null,
                child: const Text('Send Payment'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: service.connectedDevices.containsKey(deviceId)
                    ? () => _sendTestMessage(service)
                    : null,
                child: const Text('Send Test Message'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _disconnect(service),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Disconnect'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(P2PConnectionStatus status) {
    switch (status) {
      case P2PConnectionStatus.connected:
        return Colors.green;
      case P2PConnectionStatus.connecting:
        return Colors.orange;
      case P2PConnectionStatus.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToPaymentSend(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PaymentSendScreen(),
      ),
    );
  }

  void _sendTestMessage(P2PService service) {
    service.sendMessage(deviceId, 'Hello from ${service.currentDeviceId}!');
  }

  void _disconnect(P2PService service) {
    service.disconnectFromDevice(deviceId);
  }
}