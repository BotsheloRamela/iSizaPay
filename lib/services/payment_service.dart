import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:isiza_pay/domain/entities/payment_request.dart';
import 'package:isiza_pay/domain/entities/transaction.dart';
import 'package:isiza_pay/domain/enums/payment_request_status.dart';
import 'package:isiza_pay/domain/enums/transaction_status.dart';

class PaymentService extends ChangeNotifier {
  final List<TransactionEntity> _transactions = [];
  final List<PaymentRequest> _paymentRequests = [];
  final List<PaymentRequest> _incomingRequests = [];
  
  num _confirmedBalance = 1000.0; // Starting balance for demo - only confirmed transactions
  
  // P2P Service for sending messages between devices
  dynamic _p2pService;
  
  // Blockchain ViewModel for submitting transactions to blockchain
  dynamic _blockchainViewModel;
  
  // Callback for blockchain transaction creation
  Function(TransactionEntity)? onBlockchainTransactionCreated;
  
  List<TransactionEntity> get transactions => List.unmodifiable(_transactions);
  List<PaymentRequest> get paymentRequests => List.unmodifiable(_paymentRequests);
  List<PaymentRequest> get incomingRequests => List.unmodifiable(_incomingRequests);
  
  // Confirmed balance - only includes blockchain-confirmed transactions
  num get confirmedBalance => _confirmedBalance;
  
  // Available balance - includes pending incoming transactions (trust float)
  num get availableBalance {
    final pendingIncoming = _transactions
        .where((t) => t.status == TransactionStatus.pendingOffline && t.receiverPublicKey == getCurrentDeviceId())
        .map((t) => t.amount)
        .fold<num>(0, (sum, amount) => sum + amount);
    
    return _confirmedBalance + pendingIncoming;
  }
  
  // For backward compatibility and display
  num get balance => availableBalance;
  
  // Separate getters for different transaction types
  List<TransactionEntity> get confirmedTransactions =>
    _transactions.where((t) => t.status == TransactionStatus.confirmed).toList();

  List<TransactionEntity> get pendingTransactions =>
    _transactions.where((t) => t.status != TransactionStatus.confirmed).toList();

  // Initialize P2P service reference
  void setP2PService(dynamic p2pService) {
    _p2pService = p2pService;
  }

  // Initialize blockchain viewmodel reference
  void setBlockchainViewModel(dynamic blockchainViewModel) {
    _blockchainViewModel = blockchainViewModel;
  }

  String? getCurrentDeviceId() {
    // Get current device ID from P2P service
    return _p2pService?.currentDeviceId;
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

  Future<PaymentRequest> createPaymentRequest({
    required String fromDevice,
    required String toDevice,
    required num amount,
    required String description,
  }) async {
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

    // Send payment request to target device via P2P
    await _sendPaymentRequestToDevice(request, toDevice);

    return request;
  }

  void receivePaymentRequest(PaymentRequest request) {
    // Add to incoming requests if not already present
    if (!_incomingRequests.any((r) => r.id == request.id)) {
      _incomingRequests.add(request);
      notifyListeners();
    }
  }

  Future<TransactionEntity> acceptPaymentRequest(String requestId, String currentDeviceId) async {
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

    // Create blockchain transaction via the blockchain viewmodel
    try {
      TransactionEntity? createdTransaction;
      
      if (_blockchainViewModel != null) {
        // Store callback to capture the created transaction
        Function(TransactionEntity)? originalCallback = _blockchainViewModel.onTransactionCreated;
        
        // Temporarily override the callback to capture the transaction
        _blockchainViewModel.onTransactionCreated = (transaction) {
          createdTransaction = transaction;
          // Call the original callback if it exists
          if (originalCallback != null) {
            originalCallback(transaction);
          }
        };
        
        // Use blockchain system to create the transaction
        await _blockchainViewModel.createTransaction(
          receiverPublicKey: request.fromDevice,
          amount: request.amount,
        );
        
        // Restore the original callback
        _blockchainViewModel.onTransactionCreated = originalCallback;
        
        debugPrint('PaymentService: Blockchain transaction created for payment request $requestId');
        
        // Send the blockchain transaction to the original requester
        if (createdTransaction != null) {
          await _sendTransactionToDevice(createdTransaction!, request.fromDevice);
        }
      } else {
        // Fallback to local transaction processing if blockchain is not available
        final transactionId = _generateTransactionId();
        final transaction = TransactionEntity(
          id: transactionId,
          senderPublicKey: currentDeviceId,
          receiverPublicKey: request.fromDevice,
          amount: request.amount,
          timestamp: DateTime.now(),
          signature: _generateSignature(transactionId, currentDeviceId, request.fromDevice, request.amount),
          previousBlockHash: '0',
        );

        _processTransaction(transaction);
        
        // Send the actual transaction to the original requester
        await _sendTransactionToDevice(transaction, request.fromDevice);
      }

      // Send payment response to original requester
      await _sendPaymentResponseToDevice(requestId, true, request.fromDevice);
    } catch (blockchainError) {
      debugPrint('PaymentService: Blockchain transaction failed: $blockchainError');
      // Mark request as failed
      _incomingRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.failed);
      notifyListeners();
      throw Exception('Failed to process blockchain transaction: $blockchainError');
    }

    // Update request status to completed
    _incomingRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.completed);
    notifyListeners();

    // Return a dummy transaction object since the real one is handled by blockchain
    return TransactionEntity(
      id: 'blockchain_tx',
      senderPublicKey: currentDeviceId,
      receiverPublicKey: request.fromDevice,
      amount: request.amount,
      timestamp: DateTime.now(),
      signature: 'blockchain_signature',
      previousBlockHash: '0',
    );
  }

  Future<void> rejectPaymentRequest(String requestId) async {
    final requestIndex = _incomingRequests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return;

    final request = _incomingRequests[requestIndex];
    _incomingRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.rejected);
    
    // Send rejection response to original requester
    await _sendPaymentResponseToDevice(requestId, false, request.fromDevice);
    
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

  TransactionEntity createDirectTransaction({
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

    final transaction = TransactionEntity(
      id: _generateTransactionId(),
      senderPublicKey: fromDevice,
      receiverPublicKey: toDevice,
      amount: amount,
      timestamp: DateTime.now(),
      signature: _generateSignature(_generateTransactionId(), fromDevice, toDevice, amount),
      previousBlockHash: '0',
    );

    _processTransaction(transaction);
    return transaction;
  }

  void receiveTransaction(TransactionEntity transaction) {
    // Add to transactions as pending (no balance update until confirmed)
    _transactions.add(transaction);
    debugPrint('PaymentService: Received transaction ${transaction.id} - Amount: ${transaction.amount}');

    // Find and complete any corresponding payment request
    // Look for pending requests where we are the requester (fromDevice) and the transaction
    // is coming from the device we requested payment from (toDevice)
    final requestIndex = _paymentRequests.indexWhere((r) =>
      r.fromDevice == transaction.receiverPublicKey && // We are the receiver of the payment
      r.toDevice == transaction.senderPublicKey && // The sender is who we requested from  
      r.amount == transaction.amount &&
      r.status == PaymentRequestStatus.pending
    );

    if (requestIndex != -1) {
      final request = _paymentRequests[requestIndex];
      _paymentRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.completed);
      debugPrint('PaymentService: Completed payment request ${request.id} with received transaction ${transaction.id}');
    } else {
      debugPrint('PaymentService: No matching payment request found for transaction ${transaction.id}');
    }

    notifyListeners();
  }

  // Method to add blockchain transactions to PaymentService transaction list
  void addBlockchainTransaction(TransactionEntity transaction) {
    // Check if transaction already exists to avoid duplicates
    final exists = _transactions.any((t) => t.id == transaction.id);
    if (!exists) {
      _transactions.add(transaction);
      debugPrint('PaymentService: Added blockchain transaction ${transaction.id} to transaction history');
      notifyListeners();
    }
  }

  void _processTransaction(TransactionEntity transaction) {
    // Add to transactions as pending (no balance update until confirmed)
    _transactions.add(transaction);
    // Note: Balance is not deducted until blockchain confirmation
    notifyListeners();
  }

  // Blockchain synchronization methods

  /// Get all transactions that need to be submitted to blockchain
  List<TransactionEntity> getPendingBlockchainTransactions() {
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
      if (transaction.senderPublicKey == getCurrentDeviceId()) {
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

  // P2P Message sending methods
  Future<void> _sendPaymentRequestToDevice(PaymentRequest request, String toDeviceId) async {
    if (_p2pService == null) {
      debugPrint('PaymentService: P2P service not available, cannot send payment request');
      return;
    }

    try {
      final message = getPaymentRequestMessage(request);
      final messageString = jsonEncode(message);
      await _p2pService.sendMessage(toDeviceId, messageString);
      debugPrint('PaymentService: Sent payment request ${request.id} to device $toDeviceId');
    } catch (e) {
      debugPrint('PaymentService: Failed to send payment request: $e');
      // Mark request as failed since we couldn't send it
      final requestIndex = _paymentRequests.indexWhere((r) => r.id == request.id);
      if (requestIndex != -1) {
        _paymentRequests[requestIndex] = request.copyWith(status: PaymentRequestStatus.failed);
        notifyListeners();
      }
    }
  }

  Future<void> _sendPaymentResponseToDevice(String requestId, bool accepted, String toDeviceId) async {
    if (_p2pService == null) {
      debugPrint('PaymentService: P2P service not available, cannot send payment response');
      return;
    }

    try {
      final message = getPaymentResponseMessage(requestId, accepted);
      final messageString = jsonEncode(message);
      await _p2pService.sendMessage(toDeviceId, messageString);
      debugPrint('PaymentService: Sent payment response for $requestId (accepted: $accepted) to device $toDeviceId');
    } catch (e) {
      debugPrint('PaymentService: Failed to send payment response: $e');
    }
  }

  Future<void> _sendTransactionToDevice(TransactionEntity transaction, String toDeviceId) async {
    if (_p2pService == null) {
      debugPrint('PaymentService: P2P service not available, cannot send transaction');
      return;
    }

    try {
      final message = getTransactionMessage(transaction);
      final messageString = jsonEncode(message);
      await _p2pService.sendMessage(toDeviceId, messageString);
      debugPrint('PaymentService: Sent transaction ${transaction.id} to device $toDeviceId');
    } catch (e) {
      debugPrint('PaymentService: Failed to send transaction: $e');
    }
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

  Map<String, dynamic> getTransactionMessage(TransactionEntity transaction) {
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
        debugPrint('PaymentService: Received payment response for $requestId (accepted: $accepted)');
        if (accepted) {
          completePaymentRequest(requestId);
        } else {
          failPaymentRequest(requestId);
        }
        break;
      case 'transaction':
        final transaction = TransactionEntity.fromJson(data);
        receiveTransaction(transaction);
        break;
    }
  }
}