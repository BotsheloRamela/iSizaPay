import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_functions/firebase_functions.dart';

class FirebaseConfig {
  static FirebaseFirestore? _firestore;
  static FirebaseFunctions? _functions;

  // Initialize Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    
    // Initialize Firestore
    _firestore = FirebaseFirestore.instance;
    
    // Initialize Cloud Functions
    _functions = FirebaseFunctions.instance;
    
    // Configure Firestore settings for offline support
    _firestore!.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Get Firestore instance
  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw StateError('Firebase not initialized. Call FirebaseConfig.initialize() first.');
    }
    return _firestore!;
  }

  // Get Cloud Functions instance
  static FirebaseFunctions get functions {
    if (_functions == null) {
      throw StateError('Firebase not initialized. Call FirebaseConfig.initialize() first.');
    }
    return _functions!;
  }

  // Collection references for transaction syncing
  static CollectionReference<Map<String, dynamic>> get offlineTransactionsCollection =>
      firestore.collection('offline_transactions');
      
  static CollectionReference<Map<String, dynamic>> get syncedTransactionsCollection =>
      firestore.collection('synced_transactions');
      
  static CollectionReference<Map<String, dynamic>> get vendorEventsCollection =>
      firestore.collection('vendor_events');
      
  static CollectionReference<Map<String, dynamic>> get customerConnectionsCollection =>
      firestore.collection('customer_connections');
}
