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
  
  num _balance = 1000.0; // Starting balance for demo

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<PaymentRequest> get paymentRequests => List.unmodifiable(_paymentRequests);
  List<PaymentRequest> get incomingRequests => List.unmodifiable(_incomingRequests);
  num get balance => _balance;

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

    if (amount > _balance) {
      throw ArgumentError('Insufficient balance');
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

  void acceptPaymentRequest(String requestId, String currentDeviceId) {
    final requestIndex = _incomingRequests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return;

    final request = _incomingRequests[requestIndex];
    
    // Check if we have sufficient balance to send
    if (request.amount > _balance) {
      // Update request status to failed
      _incomingRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.failed);
      notifyListeners();
      throw ArgumentError('Insufficient balance to fulfill payment request');
    }

    // Update request status to accepted
    _incomingRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.accepted);

    // Create and process transaction
    final transaction = Transaction(
      id: _generateTransactionId(),
      fromDevice: currentDeviceId,
      toDevice: request.fromDevice,
      amount: request.amount,
      timestamp: DateTime.now(),
      signature: _generateSignature(_generateTransactionId(), currentDeviceId, request.fromDevice, request.amount),
    );

    _processTransaction(transaction);

    // Update request status to completed
    _incomingRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.completed);
    notifyListeners();
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

    if (amount > _balance) {
      throw ArgumentError('Insufficient balance');
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
    // Add to transactions and update balance
    _transactions.add(transaction);
    _balance += transaction.amount;
    notifyListeners();
  }

  void _processTransaction(Transaction transaction) {
    // Deduct from balance and add to transactions
    _transactions.add(transaction);
    _balance -= transaction.amount;
    notifyListeners();
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