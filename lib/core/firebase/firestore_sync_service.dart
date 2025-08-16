import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isiza_pay/domain/entities/event_transaction.dart';
import 'package:isiza_pay/domain/entities/vendor_info.dart';
import 'package:isiza_pay/domain/entities/event_product.dart';
import 'package:isiza_pay/core/firebase/firebase_config.dart';

class FirestoreSyncService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  // Store offline transaction in Firestore
  static Future<void> storeOfflineTransaction(
    EventTransactionEntity transaction,
  ) async {
    try {
      await FirebaseConfig.offlineTransactionsCollection.doc(transaction.id).set({
        ...transaction.toJson(),
        'syncStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to store offline transaction: $e');
    }
  }

  // Get all pending offline transactions
  static Future<List<EventTransactionEntity>> getPendingOfflineTransactions() async {
    try {
      final querySnapshot = await FirebaseConfig.offlineTransactionsCollection
          .where('syncStatus', isEqualTo: 'pending')
          .orderBy('createdAt')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return EventTransactionEntity.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get pending offline transactions: $e');
    }
  }

  // Update transaction sync status
  static Future<void> updateTransactionSyncStatus(
    String transactionId,
    String status,
    {String? solanaSignature, String? errorMessage}
  ) async {
    try {
      final updateData = {
        'syncStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (solanaSignature != null) {
        updateData['solanaSignature'] = solanaSignature;
      }

      if (errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }

      await FirebaseConfig.offlineTransactionsCollection
          .doc(transactionId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update transaction sync status: $e');
    }
  }

  // Move transaction to synced collection
  static Future<void> moveToSyncedTransactions(
    EventTransactionEntity transaction,
    String solanaSignature,
  ) async {
    try {
      // Add to synced transactions
      await FirebaseConfig.syncedTransactionsCollection.doc(transaction.id).set({
        ...transaction.toJson(),
        'solanaSignature': solanaSignature,
        'syncedAt': FieldValue.serverTimestamp(),
        'status': 'confirmed',
      });

      // Remove from offline transactions
      await FirebaseConfig.offlineTransactionsCollection
          .doc(transaction.id)
          .delete();
    } catch (e) {
      throw Exception('Failed to move transaction to synced: $e');
    }
  }

  // Store vendor event data
  static Future<void> storeVendorEventData(
    VendorInfoEntity vendorInfo,
  ) async {
    try {
      await FirebaseConfig.vendorEventsCollection.doc(vendorInfo.id).set({
        ...vendorInfo.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': vendorInfo.isEventModeActive,
      });
    } catch (e) {
      throw Exception('Failed to store vendor event data: $e');
    }
  }

  // Get active vendor events
  static Future<List<VendorInfoEntity>> getActiveVendorEvents() async {
    try {
      final querySnapshot = await FirebaseConfig.vendorEventsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('lastUpdated', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return VendorInfoEntity.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get active vendor events: $e');
    }
  }

  // Store customer connection
  static Future<void> storeCustomerConnection(
    String vendorId,
    String customerId,
    Map<String, dynamic> connectionData,
  ) async {
    try {
      await FirebaseConfig.customerConnectionsCollection
          .doc('${vendorId}_$customerId')
          .set({
        'vendorId': vendorId,
        'customerId': customerId,
        'connectedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        ...connectionData,
      });
    } catch (e) {
      throw Exception('Failed to store customer connection: $e');
    }
  }

  // Get customer connections for a vendor
  static Future<List<Map<String, dynamic>>> getCustomerConnections(
    String vendorId,
  ) async {
    try {
      final querySnapshot = await FirebaseConfig.customerConnectionsCollection
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('lastActivity', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get customer connections: $e');
    }
  }

  // Batch update multiple transactions
  static Future<void> batchUpdateTransactions(
    List<Map<String, dynamic>> updates,
  ) async {
    try {
      final batch = _firestore.batch();
      
      for (final update in updates) {
        final docRef = FirebaseConfig.offlineTransactionsCollection
            .doc(update['transactionId']);
        batch.update(docRef, update['data']);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update transactions: $e');
    }
  }

  // Listen to transaction status changes
  static Stream<DocumentSnapshot> listenToTransactionStatus(
    String transactionId,
  ) {
    return FirebaseConfig.offlineTransactionsCollection
        .doc(transactionId)
        .snapshots();
  }

  // Listen to vendor event changes
  static Stream<QuerySnapshot> listenToVendorEvents() {
    return FirebaseConfig.vendorEventsCollection
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // Get transaction history for a user
  static Future<List<EventTransactionEntity>> getTransactionHistory(
    String userId,
    {String? userType} // 'customer' or 'vendor'
  ) async {
    try {
      Query query;
      
      if (userType == 'customer') {
        query = FirebaseConfig.syncedTransactionsCollection
            .where('customerId', isEqualTo: userId);
      } else if (userType == 'vendor') {
        query = FirebaseConfig.syncedTransactionsCollection
            .where('vendorId', isEqualTo: userId);
      } else {
        // Get all transactions for user (both customer and vendor)
        query = FirebaseConfig.syncedTransactionsCollection
            .where(Filter.or(
              Filter.equalTo('customerId', userId),
              Filter.equalTo('vendorId', userId),
            ));
      }
      
      final querySnapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return EventTransactionEntity.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get transaction history: $e');
    }
  }
}
