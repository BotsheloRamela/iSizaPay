import 'package:isiza_pay/domain/entities/event_product.dart';
import 'package:isiza_pay/domain/entities/event_transaction.dart';
import 'package:isiza_pay/domain/entities/vendor_info.dart';

abstract class EventModeRepository {
  // Beacon Management
  Future<void> startEventMode(String vendorId, String vendorName, String description);
  Future<void> stopEventMode(String vendorId);
  Future<bool> isEventModeActive(String vendorId);
  
  // Vendor Discovery
  Future<List<VendorInfoEntity>> discoverNearbyVendors();
  Future<VendorInfoEntity?> getVendorInfo(String vendorId);
  
  // Product Management
  Future<void> addProduct(EventProductEntity product);
  Future<void> updateProduct(EventProductEntity product);
  Future<void> removeProduct(String productId);
  Future<List<EventProductEntity>> getVendorProducts(String vendorId);
  
  // Transaction Management
  Future<EventTransactionEntity> createTransaction(EventTransactionEntity transaction);
  Future<void> updateTransactionStatus(String transactionId, String status);
  Future<List<EventTransactionEntity>> getVendorTransactions(String vendorId);
  Future<List<EventTransactionEntity>> getCustomerTransactions(String customerId);
  
  // Connection Management
  Future<void> connectToVendor(String vendorId, String customerId);
  Future<void> disconnectFromVendor(String vendorId, String customerId);
  Future<List<String>> getConnectedCustomers(String vendorId);
  
  // Local Storage
  Future<void> saveTransactionLocally(EventTransactionEntity transaction);
  Future<List<EventTransactionEntity>> getPendingTransactions();
  Future<void> clearCompletedTransactions();
}
