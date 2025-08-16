import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isiza_pay/core/di/providers.dart';

class PaymentSendScreen extends ConsumerStatefulWidget {
  final String? recipientDeviceId;
  final String? recipientDeviceName;

  const PaymentSendScreen({
    super.key,
    this.recipientDeviceId,
    this.recipientDeviceName,
  });

  @override
  ConsumerState<PaymentSendScreen> createState() => _PaymentSendScreenState();
}

class _PaymentSendScreenState extends ConsumerState<PaymentSendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedRecipientId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedRecipientId = widget.recipientDeviceId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p2pService = ref.watch(p2pServiceProvider);
    final blockchainState = ref.watch(blockchainViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Payment'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Balance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${blockchainState.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Recipient',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRecipientId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Choose a connected device',
                ),
                items: p2pService.connectedDevices.entries
                    .map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRecipientId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a recipient';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Amount',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter amount',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > blockchainState.balance) {
                    return 'Insufficient balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Description (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter payment description',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: blockchainState.isLoading || _isProcessing ? null : _sendPaymentRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Request Payment'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: blockchainState.isLoading || _isProcessing ? null : _sendPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: blockchainState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Send Direct'),
                    ),
                  ),
                ],
              ),
              if (blockchainState.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Error: ${blockchainState.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _sendPaymentRequest() async {
    if (!_formKey.currentState!.validate() || _selectedRecipientId == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text.trim();
    final paymentService = ref.read(paymentServiceProvider);
    final p2pService = ref.read(p2pServiceProvider);
    
    try {
      final fromDeviceId = p2pService.currentDeviceId;
      if (fromDeviceId == null) {
        throw Exception('Device not connected. Please check P2P connection.');
      }

      await paymentService.createPaymentRequest(
        fromDevice: fromDeviceId,
        toDevice: _selectedRecipientId!,
        amount: amount,
        description: description.isEmpty ? 'Payment request' : description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment request of \$${amount.toStringAsFixed(2)} sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send payment request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _sendPayment() async {
    if (!_formKey.currentState!.validate() || _selectedRecipientId == null) {
      return;
    }

    final amount = double.parse(_amountController.text);
    final blockchainNotifier = ref.read(blockchainViewModelProvider.notifier);
    
    try {
      await blockchainNotifier.createTransaction(
        receiverPublicKey: _selectedRecipientId!,
        amount: amount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Direct payment of \$${amount.toStringAsFixed(2)} sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}