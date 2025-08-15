import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/payment_service.dart';
import '../../services/p2p_service.dart';
import 'dart:convert';

class PaymentReceiveScreen extends StatefulWidget {
  const PaymentReceiveScreen({super.key});

  @override
  State<PaymentReceiveScreen> createState() => _PaymentReceiveScreenState();
}

class _PaymentReceiveScreenState extends State<PaymentReceiveScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Payments'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer2<PaymentService, P2PService>(
        builder: (context, paymentService, p2pService, child) {
          return Column(
            children: [
              _buildBalanceCard(paymentService),
              _buildIncomingRequestsSection(paymentService, p2pService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(PaymentService paymentService) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 48,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                'Current Balance',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$${paymentService.balance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.green.shade900,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingRequestsSection(PaymentService paymentService, P2PService p2pService) {
    final incomingRequests = paymentService.incomingRequests
        .where((request) => request.status == PaymentRequestStatus.pending)
        .toList();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.inbox, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Incoming Payment Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                if (incomingRequests.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${incomingRequests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: incomingRequests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: incomingRequests.length,
                    itemBuilder: (context, index) {
                      final request = incomingRequests[index];
                      return _buildPaymentRequestCard(request, paymentService, p2pService);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No Payment Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see incoming payment requests here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRequestCard(PaymentRequest request, PaymentService paymentService, P2PService p2pService) {
    final timeSinceRequest = DateTime.now().difference(request.timestamp);
    final timeText = timeSinceRequest.inMinutes < 1
        ? '${timeSinceRequest.inSeconds}s ago'
        : timeSinceRequest.inHours < 1
            ? '${timeSinceRequest.inMinutes}m ago'
            : '${timeSinceRequest.inHours}h ago';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.request_quote, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Request',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'From: ${request.fromDevice}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${request.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            if (request.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectPaymentRequest(request, paymentService, p2pService),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: paymentService.balance >= request.amount
                        ? () => _showAcceptDialog(request, paymentService, p2pService)
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (paymentService.balance < request.amount)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Insufficient balance to fulfill this request',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAcceptDialog(PaymentRequest request, PaymentService paymentService, P2PService p2pService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Payment Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to send \$${request.amount.toStringAsFixed(2)} to ${request.fromDevice}.'),
            const SizedBox(height: 12),
            if (request.description.isNotEmpty) ...[
              Text('Description: ${request.description}'),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Balance:'),
                      Text('\$${paymentService.balance.toStringAsFixed(2)}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('After Payment:'),
                      Text('\$${(paymentService.balance - request.amount).toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _acceptPaymentRequest(request, paymentService, p2pService);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept & Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptPaymentRequest(PaymentRequest request, PaymentService paymentService, P2PService p2pService) async {
    try {
      // Accept the payment request (this creates and processes the transaction)
      paymentService.acceptPaymentRequest(request.id, p2pService.currentDeviceId!);

      // Send response back to requester
      final responseMessage = paymentService.getPaymentResponseMessage(request.id, true);
      await p2pService.sendMessage(request.fromDevice, jsonEncode(responseMessage));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of \$${request.amount.toStringAsFixed(2)} sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectPaymentRequest(PaymentRequest request, PaymentService paymentService, P2PService p2pService) async {
    try {
      // Reject the payment request
      paymentService.rejectPaymentRequest(request.id);

      // Send response back to requester
      final responseMessage = paymentService.getPaymentResponseMessage(request.id, false);
      await p2pService.sendMessage(request.fromDevice, jsonEncode(responseMessage));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject payment request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}