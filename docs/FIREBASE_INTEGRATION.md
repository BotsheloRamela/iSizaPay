# Firebase Integration for iSizaPay Solana Sync

## 🚀 **Overview**

This document describes the Firebase backend integration for iSizaPay, which handles the offline/online transaction syncing between your Flutter app and the Solana blockchain.

## 🏗️ **Architecture**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Firebase       │    │   Solana        │
│                 │    │   Backend        │    │   Blockchain    │
├─────────────────┤    ├──────────────────┤    ├─────────────────┤
│ • Offline       │───▶│ • Cloud          │───▶│ • Transaction   │
│   Transactions  │    │   Functions      │    │   Settlement    │
│ • Local Storage │    │ • Firestore      │    │ • Balance       │
│ • Event Mode    │    │ • Sync Service   │    │   Updates       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🔥 **Firebase Components**

### **1. Cloud Functions (`functions/index.js`)**
- **`syncOfflineTransactionsToSolana`**: Main sync function for offline transactions
- **`createSolanaTransaction`**: Creates Solana transaction objects
- **`validateSolanaTransaction`**: Validates transaction status on Solana
- **`getSolanaBalance`**: Retrieves wallet balances
- **`syncVendorEventData`**: Syncs vendor event information
- **`processBatchTransactions`**: Processes multiple transactions in batches

### **2. Firestore Collections**
- **`offline_transactions`**: Stores pending offline transactions
- **`synced_transactions`**: Stores successfully synced transactions
- **`vendor_events`**: Stores vendor event mode data
- **`customer_connections`**: Stores customer-vendor connections

### **3. Flutter Services**
- **`FirebaseConfig`**: Firebase initialization and configuration
- **`FirebaseFunctionsService`**: Calls Cloud Functions
- **`FirestoreSyncService`**: Handles Firestore operations
- **`TransactionSyncService`**: Main orchestration service

## 📱 **Flutter Integration**

### **Dependencies Added**
```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_firestore: ^5.5.0
  firebase_functions: ^5.3.0
  cloud_firestore: ^5.5.0
```

### **Initialization**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase configuration
  await FirebaseConfig.initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

## 🔄 **Transaction Flow**

### **Offline Mode**
1. **User makes payment** → Transaction stored locally
2. **Transaction queued** → Added to `offline_transactions` collection
3. **Status: `pending`** → Waiting for online sync

### **Online Sync**
1. **App comes online** → `TransactionSyncService` triggers
2. **Cloud Function called** → `syncOfflineTransactionsToSolana`
3. **Solana transaction created** → Using customer's private key
4. **Transaction sent** → To Solana network
5. **Status updated** → Moved to `synced_transactions` collection

### **Status Tracking**
- **`pending`**: Waiting for sync
- **`syncing`**: Currently being processed
- **`confirmed`**: Successfully synced to Solana
- **`failed`**: Sync failed, can retry

## 🛠️ **Setup Instructions**

### **1. Firebase Project Setup**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init

# Select Functions and Firestore
```

### **2. Configure Firebase**
```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Deploy functions
firebase deploy --only functions
```

### **3. Update Configuration**
Replace placeholder values in `lib/core/firebase/firebase_options.dart`:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-actual-api-key',
  appId: 'your-actual-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-storage-bucket',
);
```

### **4. Solana RPC Configuration**
Update the RPC endpoint in `functions/index.js`:
```javascript
const solanaConnection = new Connection(
  'https://your-preferred-rpc-endpoint.com',
  'confirmed'
);
```

## 📊 **Usage Examples**

### **Store Offline Transaction**
```dart
final transaction = EventTransactionEntity(
  id: 'tx_123',
  customerId: 'customer_456',
  vendorId: 'vendor_789',
  products: [product1, product2],
  totalAmount: 25.50,
  timestamp: DateTime.now(),
  status: 'pending',
);

await TransactionSyncService().storeOfflineTransaction(transaction);
```

### **Manual Sync**
```dart
// Trigger manual sync
await TransactionSyncService().manualSync();

// Check sync status
final stats = await TransactionSyncService().getSyncStatistics();
print('Pending transactions: ${stats['firestorePending']}');
```

### **Listen to Transaction Status**
```dart
TransactionSyncService().listenToTransactionStatus('tx_123')
  .listen((snapshot) {
    final data = snapshot.data();
    print('Transaction status: ${data?['syncStatus']}');
  });
```

## 🔒 **Security Considerations**

### **Private Key Handling**
- **NEVER store private keys in Firebase**
- **Use secure key management** (e.g., Flutter Secure Storage)
- **Sign transactions locally** before sending to Cloud Functions

### **Authentication**
- Implement Firebase Authentication for user management
- Use security rules in Firestore
- Validate user permissions in Cloud Functions

### **Rate Limiting**
- Implement rate limiting in Cloud Functions
- Monitor API usage and costs
- Set appropriate quotas and limits

## 📈 **Performance Optimization**

### **Batch Processing**
- Process transactions in batches (default: 10)
- Use Firestore batch operations
- Implement retry logic for failed transactions

### **Offline Support**
- Enable Firestore offline persistence
- Queue transactions locally
- Sync when connection is restored

### **Caching**
- Cache frequently accessed data
- Use Firestore snapshots for real-time updates
- Implement local-first architecture

## 🧪 **Testing**

### **Local Testing**
```bash
# Start Firebase emulator
firebase emulators:start

# Test Cloud Functions locally
firebase functions:shell
```

### **Integration Testing**
- Test offline/online transitions
- Verify transaction syncing
- Check error handling and retry logic

## 🚨 **Troubleshooting**

### **Common Issues**
1. **Firebase not initialized**: Check initialization order
2. **Cloud Functions failing**: Check function logs and dependencies
3. **Transaction sync issues**: Verify Solana RPC endpoint
4. **Permission errors**: Check Firestore security rules

### **Debug Commands**
```bash
# View function logs
firebase functions:log

# Check Firestore data
firebase firestore:get

# Test functions locally
firebase emulators:start
```

## 🔮 **Future Enhancements**

### **Advanced Features**
- **Multi-chain support**: Ethereum, Polygon, etc.
- **Smart contract integration**: Custom Solana programs
- **Advanced analytics**: Transaction metrics and insights
- **Webhook support**: Real-time notifications

### **Scalability**
- **Load balancing**: Multiple RPC endpoints
- **Caching layer**: Redis for performance
- **Queue management**: Advanced job queuing
- **Monitoring**: Comprehensive logging and alerts

## 📚 **Additional Resources**

- [Firebase Documentation](https://firebase.google.com/docs)
- [Solana Web3.js](https://docs.solana.com/developing/clients/javascript-api)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

## 🆘 **Support**

For issues or questions:
1. Check Firebase console logs
2. Review Cloud Function execution logs
3. Verify Firestore security rules
4. Test with Firebase emulator
5. Check Solana RPC endpoint status
