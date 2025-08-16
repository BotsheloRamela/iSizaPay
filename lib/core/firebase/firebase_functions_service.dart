import 'package:firebase_functions/firebase_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isiza_pay/domain/entities/event_transaction.dart';
import 'package:isiza_pay/domain/entities/vendor_info.dart';
import 'package:isiza_pay/core/firebase/firebase_config.dart';

class FirebaseFunctionsService {
  static final FirebaseFunctions _functions = FirebaseConfig.functions;
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  // Call Cloud Function to sync offline transactions to Solana
  static Future<Map<String, dynamic>> syncOfflineTransactionsToSolana(
    List<EventTransactionEntity> offlineTransactions,
  ) async {
    try {
      // Prepare transaction data for Cloud Function
      final transactionData = offlineTransactions.map((tx) => {
        'id': tx.id,
        'customerId': tx.customerId,
        'vendorId': tx.vendorId,
        'products': tx.products.map((p) => p.toJson()).toList(),
        'totalAmount': tx.totalAmount,
        'timestamp': tx.timestamp.toIso8601String(),
        'status': tx.status,
        'transactionHash': tx.transactionHash,
      }).toList();

      // Call Cloud Function
      final callable = _functions.httpsCallable('syncOfflineTransactionsToSolana');
      final result = await callable.call({
        'transactions': transactionData,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to sync transactions to Solana: $e');
    }
  }

  // Call Cloud Function to create Solana transaction
  static Future<Map<String, dynamic>> createSolanaTransaction(
    EventTransactionEntity transaction,
    String senderPrivateKey,
    String receiverPublicKey,
  ) async {
    try {
      final callable = _functions.httpsCallable('createSolanaTransaction');
      final result = await callable.call({
        'transaction': transaction.toJson(),
        'senderPrivateKey': senderPrivateKey,
        'receiverPublicKey': receiverPublicKey,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create Solana transaction: $e');
    }
  }

  // Call Cloud Function to validate Solana transaction
  static Future<Map<String, dynamic>> validateSolanaTransaction(
    String transactionSignature,
  ) async {
    try {
      final callable = _functions.httpsCallable('validateSolanaTransaction');
      final result = await callable.call({
        'transactionSignature': transactionSignature,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to validate Solana transaction: $e');
    }
  }

  // Call Cloud Function to get Solana balance
  static Future<Map<String, dynamic>> getSolanaBalance(
    String publicKey,
  ) async {
    try {
      final callable = _functions.httpsCallable('getSolanaBalance');
      final result = await callable.call({
        'publicKey': publicKey,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get Solana balance: $e');
    }
  }

  // Call Cloud Function to sync vendor event data
  static Future<Map<String, dynamic>> syncVendorEventData(
    VendorInfoEntity vendorInfo,
  ) async {
    try {
      final callable = _functions.httpsCallable('syncVendorEventData');
      final result = await callable.call({
        'vendorInfo': vendorInfo.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to sync vendor event data: $e');
    }
  }

  // Call Cloud Function to process batch transactions
  static Future<Map<String, dynamic>> processBatchTransactions(
    List<EventTransactionEntity> transactions,
  ) async {
    try {
      final callable = _functions.httpsCallable('processBatchTransactions');
      final result = await callable.call({
        'transactions': transactions.map((tx) => tx.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to process batch transactions: $e');
    }
  }

  // Call Cloud Function to get transaction status
  static Future<Map<String, dynamic>> getTransactionStatus(
    String transactionId,
  ) async {
    try {
      final callable = _functions.httpsCallable('getTransactionStatus');
      final result = await callable.call({
        'transactionId': transactionId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get transaction status: $e');
    }
  }
}
