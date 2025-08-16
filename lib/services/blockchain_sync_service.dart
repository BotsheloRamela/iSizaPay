import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isiza_pay/domain/entities/transaction.dart';
import 'payment_service.dart';

/// Service responsible for synchronizing offline transactions with the Solana blockchain
/// via Firebase Functions
class BlockchainSyncService extends ChangeNotifier {
  final PaymentService _paymentService;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _syncError;
  
  // Firebase Function endpoint - replace with your actual endpoint
  static const String _firebaseFunctionUrl = 'https://your-region-your-project.cloudfunctions.net/submitSolanaTransaction';
  
  BlockchainSyncService(this._paymentService);
  
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncError => _syncError;
  
  /// Sync all pending transactions with the blockchain
  Future<void> syncPendingTransactions() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    
    try {
      final pendingTransactions = _paymentService.getPendingBlockchainTransactions();
      
      if (pendingTransactions.isEmpty) {
        debugPrint('No pending transactions to sync');
        return;
      }
      
      debugPrint('Syncing ${pendingTransactions.length} pending transactions...');
      
      for (final transaction in pendingTransactions) {
        await _submitTransactionToBlockchain(transaction);
        
        // Add delay between submissions to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      _lastSyncTime = DateTime.now();
      debugPrint('Sync completed successfully');
      
    } catch (e) {
      _syncError = e.toString();
      debugPrint('Sync failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  /// Submit a single transaction to the blockchain via Firebase Function
  Future<void> _submitTransactionToBlockchain(TransactionEntity transaction) async {
    try {
      final requestBody = {
        'transaction': transaction.toJson(),
        'action': 'submit',
      };
      
      // final response = await http.post(
      //   Uri.parse(_firebaseFunctionUrl),
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode(requestBody),
      // ).timeout(const Duration(seconds: 30));
      //
      // if (response.statusCode == 200) {
      //   final responseData = jsonDecode(response.body);
      //   final blockchainTxId = responseData['transactionId'] as String?;
      //
      //   if (blockchainTxId != null) {
      //     // Mark as submitted to blockchain
      //     _paymentService.markTransactionSubmitted(transaction.id, blockchainTxId);
      //
      //     // Start monitoring for confirmation
      //     _monitorTransactionConfirmation(transaction.id, blockchainTxId);
      //   } else {
      //     throw Exception('No transaction ID returned from blockchain');
      //   }
      // } else {
      //   final errorData = jsonDecode(response.body);
      //   final errorMessage = errorData['error'] ?? 'Unknown error';
      //   throw Exception('Blockchain submission failed: $errorMessage');
      // }
      
    } catch (e) {
      // Mark transaction as failed
      _paymentService.failTransaction(transaction.id, e.toString());
      rethrow;
    }
  }
  
  /// Monitor a transaction for blockchain confirmation
  Future<void> _monitorTransactionConfirmation(String transactionId, String blockchainTxId) async {
    // Poll for confirmation every 10 seconds, up to 2 minutes
    const maxAttempts = 12;
    const pollInterval = Duration(seconds: 10);
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(pollInterval);
      
      try {
        final isConfirmed = await _checkTransactionConfirmation(blockchainTxId);
        
        if (isConfirmed) {
          _paymentService.confirmTransaction(transactionId);
          debugPrint('Transaction $transactionId confirmed on blockchain');
          return;
        }
      } catch (e) {
        debugPrint('Error checking confirmation for $transactionId: $e');
        
        if (attempt == maxAttempts - 1) {
          _paymentService.failTransaction(transactionId, 'Confirmation timeout: $e');
        }
      }
    }
    
    // If we get here, transaction timed out
    _paymentService.failTransaction(transactionId, 'Transaction confirmation timeout');
  }
  
  /// Check if a transaction is confirmed on the blockchain
  Future<bool> _checkTransactionConfirmation(String blockchainTxId) async {
    final requestBody = {
      'transactionId': blockchainTxId,
      'action': 'check_confirmation',
    };
    //
    // final response = await http.post(
    //   Uri.parse(_firebaseFunctionUrl),
    //   headers: {
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode(requestBody),
    // ).timeout(const Duration(seconds: 15));
    //
    // if (response.statusCode == 200) {
    //   final responseData = jsonDecode(response.body);
    //   return responseData['confirmed'] == true;
    // } else {
    //   throw Exception('Failed to check transaction confirmation');
    // }
    return false; // Placeholder, replace with actual confirmation logic
  }
  
  /// Auto-sync service that runs periodically when online
  Timer? _autoSyncTimer;
  
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) {
      if (!_isSyncing) {
        syncPendingTransactions();
      }
    });
  }
  
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }
  
  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }
}