import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isiza_pay/domain/entities/payment_request.dart';
import 'package:isiza_pay/domain/entities/transaction.dart';
import 'package:isiza_pay/domain/enums/payment_request_status.dart';
import 'package:isiza_pay/domain/enums/transaction_status.dart';
import 'package:isiza_pay/core/di/providers.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentService = ref.watch(paymentServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final paymentService = ref.watch(paymentServiceProvider);
              final pendingCount = paymentService.getPendingBlockchainTransactions().length;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pendingCount > 0)
                    IconButton(
                      onPressed: () => _syncWithBlockchain(context, paymentService),
                      icon: Stack(
                        children: [
                          const Icon(Icons.sync),
                          if (pendingCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$pendingCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      tooltip: 'Sync $pendingCount pending transactions',
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'clear_history') {
                        _showClearHistoryDialog(context, paymentService);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'clear_history',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Clear History'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final paymentService = ref.watch(paymentServiceProvider);
          return Column(
            children: [
              _buildSummaryCard(paymentService),
              _buildTransactionsList(paymentService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(dynamic paymentService) {
    final transactions = paymentService.transactions;
    final totalSent = transactions.isNotEmpty
        ? transactions
            .map<num>((dynamic t) => (t.amount as num))
            .fold<num>(0, (num sum, num amount) => sum + amount)
        : 0;
    
    final paymentRequests = paymentService.paymentRequests;
    final completedRequests = paymentRequests
        .where((r) => r.status == PaymentRequestStatus.completed)
        .length;
    
    final pendingRequests = paymentRequests
        .where((r) => r.status == PaymentRequestStatus.pending)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Available Balance',
                      '\$${paymentService.balance.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      'Confirmed Balance',
                      '\$${paymentService.confirmedBalance.toStringAsFixed(2)}',
                      Icons.verified,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Confirmed Txs',
                      '${paymentService.confirmedTransactions.length}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryItem(
                      'Pending Txs',
                      '${paymentService.pendingTransactions.length}',
                      Icons.schedule,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(dynamic paymentService) {
    final transactions = paymentService.transactions;
    final paymentRequests = paymentService.paymentRequests;

    // Combine transactions and payment requests for chronological display
    final List<dynamic> allItems = [
      ...transactions,
      ...paymentRequests,
    ];

    // Sort by timestamp (newest first)
    allItems.sort((a, b) {
      final aTime = a is TransactionEntity ? a.timestamp : (a as PaymentRequest).timestamp;
      final bTime = b is TransactionEntity ? b.timestamp : (b as PaymentRequest).timestamp;
      return bTime.compareTo(aTime);
    });

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: allItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allItems.length,
                    itemBuilder: (context, index) {
                      final item = allItems[index];
                      if (item is TransactionEntity) {
                        return _buildTransactionCard(item);
                      } else {
                        return _buildPaymentRequestCard(item as PaymentRequest);
                      }
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
            Icons.history_toggle_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
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

  Widget _buildTransactionCard(TransactionEntity transaction) {
    final isOutgoing = true; // Assuming all stored transactions are outgoing for now
    final timeSinceTransaction = DateTime.now().difference(transaction.timestamp);
    final timeText = _formatTimeDifference(timeSinceTransaction);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOutgoing ? Colors.red.shade100 : Colors.green.shade100,
          child: Icon(
            isOutgoing ? Icons.arrow_upward : Icons.arrow_downward,
            color: isOutgoing ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          isOutgoing ? 'Sent Payment' : 'Received Payment',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOutgoing ? 'To: ${transaction.receiverPublicKey}' : 'From: ${transaction.senderPublicKey}',
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isOutgoing ? "-" : "+"}\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isOutgoing ? Colors.red : Colors.green,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getTransactionStatusColor(transaction.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getTransactionStatusText(transaction.status),
                style: TextStyle(
                  fontSize: 10,
                  color: _getTransactionStatusColor(transaction.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  Widget _buildPaymentRequestCard(PaymentRequest request) {
    final timeSinceRequest = DateTime.now().difference(request.timestamp);
    final timeText = _formatTimeDifference(timeSinceRequest);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (request.status) {
      case PaymentRequestStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.schedule;
        break;
      case PaymentRequestStatus.accepted:
        statusColor = Colors.blue;
        statusText = 'Accepted';
        statusIcon = Icons.handshake;
        break;
      case PaymentRequestStatus.completed:
        statusColor = Colors.green;
        statusText = 'Completed';
        statusIcon = Icons.check_circle;
        break;
      case PaymentRequestStatus.rejected:
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      case PaymentRequestStatus.failed:
        statusColor = Colors.red;
        statusText = 'Failed';
        statusIcon = Icons.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: const Text(
          'Payment Request',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To: ${request.toDevice}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (request.description.isNotEmpty)
              Text(
                request.description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${request.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showPaymentRequestDetails(request),
      ),
    );
  }

  String _formatTimeDifference(Duration difference) {
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getTransactionStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pendingOffline:
        return Colors.orange;
      case TransactionStatus.pendingBlockchain:
        return Colors.blue;
      case TransactionStatus.confirmed:
        return Colors.green;
      case TransactionStatus.failed:
      case TransactionStatus.rejected:
        return Colors.red;
    }
  }

  String _getTransactionStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pendingOffline:
        return 'Pending';
      case TransactionStatus.pendingBlockchain:
        return 'Submitting';
      case TransactionStatus.confirmed:
        return 'Confirmed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.rejected:
        return 'Rejected';
    }
  }

  void _showTransactionDetails(TransactionEntity transaction) {
    // This would show a detailed transaction view
    // For now, we'll keep it simple
  }

  void _showPaymentRequestDetails(PaymentRequest request) {
    // This would show detailed payment request info
    // For now, we'll keep it simple
  }

  void _syncWithBlockchain(BuildContext context, dynamic paymentService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync with Blockchain'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submit ${paymentService.getPendingBlockchainTransactions().length} pending transactions to Solana blockchain?'),
            const SizedBox(height: 12),
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
                    children: [
                      Icon(Icons.info, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This requires internet connection',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Transactions will be confirmed in 10-30 seconds',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
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
              paymentService.syncWithBlockchain();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing with blockchain...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sync Now'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, dynamic paymentService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all transaction history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              paymentService.clearHistory();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction history cleared'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}