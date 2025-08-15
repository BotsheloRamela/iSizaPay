import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../domain/models/transaction.dart';

enum PaymentRequestStatus {
  pending,
  accepted,
  rejected,
  completed,
  failed,
}

class PaymentRequest {
  final String id;
  final String fromDevice;
  final String toDevice;
  final num amount;
  final String description;
  final DateTime timestamp;
  final PaymentRequestStatus status;

  PaymentRequest({
    required this.id,
    required this.fromDevice,
    required this.toDevice,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.status = PaymentRequestStatus.pending,
  });

  PaymentRequest copyWith({
    PaymentRequestStatus? status,
  }) {
    return PaymentRequest(
      id: id,
      fromDevice: fromDevice,
      toDevice: toDevice,
      amount: amount,
      description: description,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromDevice': fromDevice,
      'toDevice': toDevice,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'] as String,
      fromDevice: json['fromDevice'] as String,
      toDevice: json['toDevice'] as String,
      amount: json['amount'] as num,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: PaymentRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentRequestStatus.pending,
      ),
    );
  }
}

class PaymentService extends ChangeNotifier {
  final List<Transaction> _transactions = [];
  final List<PaymentRequest> _paymentRequests = [];
  final List<PaymentRequest> _incomingRequests = [];
  
  num _confirmedBalance = 1000.0; // Starting balance for demo - only confirmed transactions
  
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<PaymentRequest> get paymentRequests => List.unmodifiable(_paymentRequests);
  List<PaymentRequest> get incomingRequests => List.unmodifiable(_incomingRequests);
  
  // Confirmed balance - only includes blockchain-confirmed transactions
  num get confirmedBalance => _confirmedBalance;
  
  // Available balance - includes pending incoming transactions (trust float)
  num get availableBalance {
    final pendingIncoming = _transactions
        .where((t) => t.status == TransactionStatus.pendingOffline && t.toDevice == getCurrentDeviceId())
        .map((t) => t.amount)
        .fold<num>(0, (sum, amount) => sum + amount);
    
    return _confirmedBalance + pendingIncoming;
  }
  
  // For backward compatibility and display
  num get balance => availableBalance;
  
  // Separate getters for different transaction types
  List<Transaction> get confirmedTransactions => 
    _transactions.where((t) => t.status == TransactionStatus.confirmed).toList();
  
  List<Transaction> get pendingTransactions => 
    _transactions.where((t) => t.status != TransactionStatus.confirmed).toList();
  
  String? getCurrentDeviceId() {
    // This would be implemented to get current device ID
    // For now returning null, should be injected from P2PService
    return null;
  }

  String _generateTransactionId() {
    final random = Random();
    return 'tx_${random.nextInt(1000000).toString().padLeft(6, '0')}';
  }

  String _generatePaymentRequestId() {
    final random = Random();
    return 'pr_${random.nextInt(1000000).toString().padLeft(6, '0')}';
  }

  String _generateSignature(String transactionId, String fromDevice, String toDevice, num amount) {
    // Simple signature generation for demo - in real app would use cryptographic signing
    final data = '$transactionId$fromDevice$toDevice$amount';
    return data.hashCode.toString();
  }

  PaymentRequest createPaymentRequest({
    required String fromDevice,
    required String toDevice,
    required num amount,
    required String description,
  }) {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }

    if (amount > _confirmedBalance) {
      throw ArgumentError('Insufficient confirmed balance');
    }

    final request = PaymentRequest(
      id: _generatePaymentRequestId(),
      fromDevice: fromDevice,
      toDevice: toDevice,
      amount: amount,
      description: description,
      timestamp: DateTime.now(),
    );

    _paymentRequests.add(request);
    notifyListeners();
    return request;
  }

  void receivePaymentRequest(PaymentRequest request) {
    // Add to incoming requests if not already present
    if (!_incomingRequests.any((r) => r.id == request.id)) {
      _incomingRequests.add(request);
      notifyListeners();
    }
  }

  Transaction acceptPaymentRequest(String requestId, String currentDeviceId) {
    final requestIndex = _incomingRequests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) throw ArgumentError('Payment request not found');

    final request = _incomingRequests[requestIndex];
    
    // Check if we have sufficient confirmed balance to send
    if (request.amount > _confirmedBalance) {
      // Update request status to failed
      _incomingRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.failed);
      notifyListeners();
      throw ArgumentError('Insufficient confirmed balance to fulfill payment request');
    }

    // Update request status to accepted
    _incomingRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.accepted);

    // Create and process transaction
    final transactionId = _generateTransactionId();
    final transaction = Transaction(
      id: transactionId,
      fromDevice: currentDeviceId,
      toDevice: request.fromDevice,
      amount: request.amount,
      timestamp: DateTime.now(),
      signature: _generateSignature(transactionId, currentDeviceId, request.fromDevice, request.amount),
    );

    _processTransaction(transaction);

    // Update request status to completed
    _incomingRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.completed);
    notifyListeners();
    
    return transaction;
  }

  void rejectPaymentRequest(String requestId) {
    final requestIndex = _incomingRequests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return;

    final request = _incomingRequests[requestIndex];
    _incomingRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.rejected);
    notifyListeners();
  }

  void completePaymentRequest(String requestId) {
    final requestIndex = _paymentRequests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return;

    final request = _paymentRequests[requestIndex];
    _paymentRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.completed);
    notifyListeners();
  }

  void failPaymentRequest(String requestId) {
    final requestIndex = _paymentRequests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return;

    final request = _paymentRequests[requestIndex];
    _paymentRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.failed);
    notifyListeners();
  }

  Transaction createDirectTransaction({
    required String fromDevice,
    required String toDevice,
    required num amount,
  }) {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }

    if (amount > _confirmedBalance) {
      throw ArgumentError('Insufficient confirmed balance');
    }

    final transaction = Transaction(
      id: _generateTransactionId(),
      fromDevice: fromDevice,
      toDevice: toDevice,
      amount: amount,
      timestamp: DateTime.now(),
      signature: _generateSignature(_generateTransactionId(), fromDevice, toDevice, amount),
    );

    _processTransaction(transaction);
    return transaction;
  }

  void receiveTransaction(Transaction transaction) {
    // Add to transactions as pending (no balance update until confirmed)
    _transactions.add(transaction);
    
    // Find and complete any corresponding payment request
    final requestIndex = _paymentRequests.indexWhere((r) => 
      r.fromDevice == transaction.toDevice && 
      r.amount == transaction.amount &&
      r.status == PaymentRequestStatus.pending
    );
    
    if (requestIndex != -1) {
      final request = _paymentRequests[requestIndex];
      _paymentRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.completed);
    }
    
    notifyListeners();
  }

  void _processTransaction(Transaction transaction) {
    // Add to transactions as pending (no balance update until confirmed)
    _transactions.add(transaction);
    // Note: Balance is not deducted until blockchain confirmation
    notifyListeners();
  }

  // Blockchain synchronization methods
  
  /// Get all transactions that need to be submitted to blockchain
  List<Transaction> getPendingBlockchainTransactions() {
    return _transactions
        .where((t) => t.status == TransactionStatus.pendingOffline)
        .toList();
  }
  
  /// Mark transaction as submitted to blockchain
  void markTransactionSubmitted(String transactionId, String blockchainTxId) {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(
        status: TransactionStatus.pendingBlockchain,
        blockchainTxId: blockchainTxId,
      );
      notifyListeners();
    }
  }
  
  /// Confirm transaction on blockchain (updates balances)
  void confirmTransaction(String transactionId, {DateTime? confirmedAt}) {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      final transaction = _transactions[index];
      _transactions[index] = transaction.copyWith(
        status: TransactionStatus.confirmed,
        confirmedAt: confirmedAt ?? DateTime.now(),
      );
      
      // Update confirmed balance based on transaction direction
      if (transaction.fromDevice == getCurrentDeviceId()) {
        // Outgoing transaction - deduct from confirmed balance
        _confirmedBalance -= transaction.amount;
      } else {
        // Incoming transaction - add to confirmed balance
        _confirmedBalance += transaction.amount;
      }
      
      notifyListeners();
    }
  }
  
  /// Mark transaction as failed
  void failTransaction(String transactionId, String error) {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(
        status: TransactionStatus.failed,
        blockchainError: error,
      );
      notifyListeners();
    }
  }
  
  /// Sync with blockchain - to be called when online
  Future<void> syncWithBlockchain() async {
    // This would be implemented to:
    // 1. Submit pending transactions to Firebase Function
    // 2. Check status of pending blockchain transactions
    // 3. Update transaction statuses and balances accordingly
    // 
    // Example implementation would call your Firebase Function here
    debugPrint('Syncing ${getPendingBlockchainTransactions().length} pending transactions with blockchain...');
  }

  void clearHistory() {
    _transactions.clear();
    _paymentRequests.clear();
    _incomingRequests.clear();
    notifyListeners();
  }

  Map<String, dynamic> getPaymentRequestMessage(PaymentRequest request) {
    return {
      'type': 'payment_request',
      'data': request.toJson(),
    };
  }

  Map<String, dynamic> getPaymentResponseMessage(String requestId, bool accepted) {
    return {
      'type': 'payment_response',
      'data': {
        'requestId': requestId,
        'accepted': accepted,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
  }

  Map<String, dynamic> getTransactionMessage(Transaction transaction) {
    return {
      'type': 'transaction',
      'data': transaction.toJson(),
    };
  }

  void handleIncomingMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final data = message['data'] as Map<String, dynamic>?;

    if (data == null) return;

    switch (type) {
      case 'payment_request':
        final request = PaymentRequest.fromJson(data);
        receivePaymentRequest(request);
        break;
      case 'payment_response':
        final requestId = data['requestId'] as String;
        final accepted = data['accepted'] as bool;
        if (accepted) {
          completePaymentRequest(requestId);
        } else {
          failPaymentRequest(requestId);
        }
        break;
      case 'transaction':
        final transaction = Transaction.fromJson(data);
        receiveTransaction(transaction);
        break;
    }
  }
}