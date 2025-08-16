import 'dart:async';
import 'package:isiza_pay/domain/entities/event_transaction.dart';
import 'package:isiza_pay/domain/entities/vendor_info.dart';
import 'package:isiza_pay/core/firebase/firestore_sync_service.dart';
import 'package:isiza_pay/core/firebase/firebase_functions_service.dart';
import 'package:isiza_pay/core/utils/logger.dart';

class TransactionSyncService {
  static final TransactionSyncService _instance = TransactionSyncService._internal();
  factory TransactionSyncService() => _instance;
  TransactionSyncService._internal();

  Timer? _syncTimer;
  bool _isSyncing = false;
  final List<EventTransactionEntity> _pendingTransactions = [];

  // Initialize the sync service
  void initialize() {
    // Start periodic sync every 30 seconds when online
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isSyncing) {
        _syncPendingTransactions();
      }
    });
  }

  // Dispose resources
  void dispose() {
    _syncTimer?.cancel();
  }

  // Store offline transaction locally and in Firestore
  Future<void> storeOfflineTransaction(EventTransactionEntity transaction) async {
    try {
      // Store locally
      _pendingTransactions.add(transaction);
      
      // Store in Firestore for persistence
      await FirestoreSyncService.storeOfflineTransaction(transaction);
      
      AppLogger.i('Offline transaction stored: ${transaction.id}');
    } catch (e) {
      AppLogger.e('Failed to store offline transaction: $e');
      rethrow;
    }
  }

  // Sync all pending transactions to Solana
  Future<void> _syncPendingTransactions() async {
    if (_pendingTransactions.isEmpty) return;
    
    _isSyncing = true;
    
    try {
      AppLogger.i('Starting sync of ${_pendingTransactions.length} pending transactions');
      
      // Get all pending transactions from Firestore
      final pendingTransactions = await FirestoreSyncService.getPendingOfflineTransactions();
      
      if (pendingTransactions.isEmpty) {
        _isSyncing = false;
        return;
      }

      // Process transactions in batches
      const batchSize = 10;
      for (int i = 0; i < pendingTransactions.length; i += batchSize) {
        final batch = pendingTransactions.skip(i).take(batchSize).toList();
        await _processTransactionBatch(batch);
      }

      // Clear local pending transactions
      _pendingTransactions.clear();
      
      AppLogger.i('Sync completed successfully');
    } catch (e) {
      AppLogger.e('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Process a batch of transactions
  Future<void> _processTransactionBatch(List<EventTransactionEntity> transactions) async {
    try {
      // Update status to 'syncing'
      for (final transaction in transactions) {
        await FirestoreSyncService.updateTransactionSyncStatus(
          transaction.id,
          'syncing',
        );
      }

      // Call Cloud Function to sync to Solana
      final result = await FirebaseFunctionsService.syncOfflineTransactionsToSolana(transactions);
      
      if (result['success'] == true) {
        // Move successful transactions to synced collection
        for (final transaction in transactions) {
          final solanaSignature = result['signatures']?[transaction.id];
          if (solanaSignature != null) {
            await FirestoreSyncService.moveToSyncedTransactions(
              transaction,
              solanaSignature,
            );
          }
        }
      } else {
        // Update failed transactions
        for (final transaction in transactions) {
          await FirestoreSyncService.updateTransactionSyncStatus(
            transaction.id,
            'failed',
            errorMessage: result['error'] ?? 'Unknown error',
          );
        }
      }
    } catch (e) {
      AppLogger.e('Failed to process transaction batch: $e');
      
      // Mark all transactions as failed
      for (final transaction in transactions) {
        await FirestoreSyncService.updateTransactionSyncStatus(
          transaction.id,
          'failed',
          errorMessage: e.toString(),
        );
      }
    }
  }

  // Manual sync trigger
  Future<void> manualSync() async {
    if (_isSyncing) {
      AppLogger.w('Sync already in progress');
      return;
    }
    
    await _syncPendingTransactions();
  }

  // Get sync status
  bool get isSyncing => _isSyncing;
  int get pendingTransactionCount => _pendingTransactions.length;

  // Sync vendor event data
  Future<void> syncVendorEventData(VendorInfoEntity vendorInfo) async {
    try {
      // Store in Firestore
      await FirestoreSyncService.storeVendorEventData(vendorInfo);
      
      // Call Cloud Function to sync to Solana
      await FirebaseFunctionsService.syncVendorEventData(vendorInfo);
      
      AppLogger.i('Vendor event data synced: ${vendorInfo.id}');
    } catch (e) {
      AppLogger.e('Failed to sync vendor event data: $e');
      rethrow;
    }
  }

  // Get transaction history
  Future<List<EventTransactionEntity>> getTransactionHistory(
    String userId, {
    String? userType,
  }) async {
    try {
      return await FirestoreSyncService.getTransactionHistory(userId, userType: userType);
    } catch (e) {
      AppLogger.e('Failed to get transaction history: $e');
      rethrow;
    }
  }

  // Listen to transaction status changes
  Stream<DocumentSnapshot> listenToTransactionStatus(String transactionId) {
    return FirestoreSyncService.listenToTransactionStatus(transactionId);
  }

  // Listen to vendor event changes
  Stream<QuerySnapshot> listenToVendorEvents() {
    return FirestoreSyncService.listenToVendorEvents();
  }

  // Retry failed transactions
  Future<void> retryFailedTransactions() async {
    try {
      final failedTransactions = await FirestoreSyncService.getPendingOfflineTransactions();
      final retryableTransactions = failedTransactions
          .where((tx) => tx.status == 'failed')
          .toList();
      
      if (retryableTransactions.isNotEmpty) {
        AppLogger.i('Retrying ${retryableTransactions.length} failed transactions');
        await _processTransactionBatch(retryableTransactions);
      }
    } catch (e) {
      AppLogger.e('Failed to retry transactions: $e');
    }
  }

  // Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    try {
      final pendingCount = _pendingTransactions.length;
      final pendingFirestore = await FirestoreSyncService.getPendingOfflineTransactions();
      
      return {
        'localPending': pendingCount,
        'firestorePending': pendingFirestore.length,
        'isSyncing': _isSyncing,
        'lastSyncAttempt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.e('Failed to get sync statistics: $e');
      return {};
    }
  }
}
