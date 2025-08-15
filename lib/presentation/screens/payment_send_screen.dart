import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/payment_service.dart';
import '../../services/p2p_service.dart';
import 'dart:convert';

class PaymentSendScreen extends StatefulWidget {
  final String? recipientDeviceId;
  final String? recipientDeviceName;

  const PaymentSendScreen({
    super.key,
    this.recipientDeviceId,
    this.recipientDeviceName,
  });

  @override
  State<PaymentSendScreen> createState() => _PaymentSendScreenState();
}

class _PaymentSendScreenState extends State<PaymentSendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedRecipientId;
  String? _selectedRecipientName;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedRecipientId = widget.recipientDeviceId;
    _selectedRecipientName = widget.recipientDeviceName;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Payment'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer2<PaymentService, P2PService>(
        builder: (context, paymentService, p2pService, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Balance Card
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.green.shade600),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '\$${paymentService.balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Recipient Selector
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Send to',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildRecipientDropdown(p2pService),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                    suffixText: 'USD',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    if (amount > paymentService.balance) {
                      return 'Insufficient balance';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),

                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                    hintText: 'What is this payment for?',
                  ),
                  maxLines: 2,
                  maxLength: 100,
                  onChanged: (value) => setState(() {}),
                ),

                const SizedBox(height: 24),

                // Send Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _canSendPayment() && !_isProcessing
                        ? () => _sendPaymentRequest(paymentService, p2pService)
                        : null,
                    icon: _isProcessing
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send),
                    label: Text(_isProcessing ? 'Sending...' : 'Send Payment Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Transaction Preview
                if (_shouldShowPreview()) _buildTransactionPreview(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipientDropdown(P2PService p2pService) {
    final connectedDevices = p2pService.connectedDevices.values.toList();

    if (connectedDevices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No connected devices. Connect to a device first.',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedRecipientId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Select recipient',
      ),
      items: connectedDevices.map((device) {
        return DropdownMenuItem<String>(
          value: device.id,
          child: Text('${device.name} (${device.id})'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRecipientId = value;
          _selectedRecipientName = connectedDevices
              .firstWhere((device) => device.id == value)
              .name;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a recipient';
        }
        return null;
      },
    );
  }

  Widget _buildTransactionPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'Transaction Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreviewRow('To', _selectedRecipientName!),
          _buildPreviewRow('Amount', '\$${amount.toStringAsFixed(2)}'),
          if (_descriptionController.text.isNotEmpty)
            _buildPreviewRow('Description', _descriptionController.text),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSendPayment() {
    return _selectedRecipientId != null &&
        _amountController.text.isNotEmpty &&
        (double.tryParse(_amountController.text) ?? 0) > 0;
  }

  bool _shouldShowPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return amount > 0 && _selectedRecipientName != null;
  }

  Future<void> _sendPaymentRequest(PaymentService paymentService, P2PService p2pService) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.isEmpty
          ? 'Payment request'
          : _descriptionController.text;

      // Create payment request
      final request = paymentService.createPaymentRequest(
        fromDevice: p2pService.currentDeviceId!,
        toDevice: _selectedRecipientId!,
        amount: amount,
        description: description,
      );

      // Send payment request via P2P
      final message = paymentService.getPaymentRequestMessage(request);
      await p2pService.sendMessage(_selectedRecipientId!, jsonEncode(message));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment request sent to $_selectedRecipientName'),
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
}