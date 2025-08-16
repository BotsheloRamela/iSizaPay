import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isiza_pay/domain/entities/event_product.dart';
import 'package:isiza_pay/domain/entities/event_transaction.dart';
import 'package:isiza_pay/domain/entities/vendor_info.dart';
import 'package:isiza_pay/domain/repositories/event_mode_repository.dart';

class EventModeRepositoryImpl implements EventModeRepository {
  static const String _vendorsKey = 'event_mode_vendors';
  static const String _productsKey = 'event_mode_products';
  static const String _transactionsKey = 'event_mode_transactions';
  static const String _connectionsKey = 'event_mode_connections';

  @override
  Future<void> startEventMode(String vendorId, String vendorName, String description) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create vendor info
    final vendor = VendorInfoEntity(
      id: vendorId,
      name: vendorName,
      description: description,
      publicKey: 'vendor_key_$vendorId',
      isEventModeActive: true,
      eventModeStartedAt: DateTime.now(),
      supportedPaymentMethods: ['blockchain'],
      location: 'Event Location',
      rating: 5.0,
      totalTransactions: 0,
    );

    // Get existing vendors
    final vendorsJson = prefs.getStringList(_vendorsKey) ?? [];
    final vendors = vendorsJson
        .map((v) => VendorInfoEntity.fromJson(jsonDecode(v)))
        .where((v) => v.id != vendorId)
        .toList();
    
    // Add new vendor
    vendors.add(vendor);
    
    // Save back to storage
    final vendorsJsonList = vendors.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList(_vendorsKey, vendorsJsonList);
  }

  @override
  Future<void> stopEventMode(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final vendorsJson = prefs.getStringList(_vendorsKey) ?? [];
    final vendors = vendorsJson
        .map((v) => VendorInfoEntity.fromJson(jsonDecode(v)))
        .map((v) => v.id == vendorId 
            ? v.copyWith(isEventModeActive: false)
            : v)
        .toList();
    
    final vendorsJsonList = vendors.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList(_vendorsKey, vendorsJsonList);
  }

  @override
  Future<bool> isEventModeActive(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final vendorsJson = prefs.getStringList(_vendorsKey) ?? [];
    final vendor = vendorsJson
        .map((v) => VendorInfoEntity.fromJson(jsonDecode(v)))
        .where((v) => v.id == vendorId)
        .firstOrNull;
    
    return vendor?.isEventModeActive ?? false;
  }

  @override
  Future<List<VendorInfoEntity>> discoverNearbyVendors() async {
    final prefs = await SharedPreferences.getInstance();
    
    final vendorsJson = prefs.getStringList(_vendorsKey) ?? [];
    return vendorsJson
        .map((v) => VendorInfoEntity.fromJson(jsonDecode(v)))
        .where((v) => v.isEventModeActive)
        .toList();
  }

  @override
  Future<VendorInfoEntity?> getVendorInfo(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final vendorsJson = prefs.getStringList(_vendorsKey) ?? [];
    return vendorsJson
        .map((v) => VendorInfoEntity.fromJson(jsonDecode(v)))
        .where((v) => v.id == vendorId)
        .firstOrNull;
  }

  @override
  Future<void> addProduct(EventProductEntity product) async {
    final prefs = await SharedPreferences.getInstance();
    
    final productsJson = prefs.getStringList(_productsKey) ?? [];
    final products = productsJson
        .map((p) => EventProductEntity.fromJson(jsonDecode(p)))
        .where((p) => p.id != product.id)
        .toList();
    
    products.add(product);
    
    final productsJsonList = products.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_productsKey, productsJsonList);
  }

  @override
  Future<void> updateProduct(EventProductEntity product) async {
    await addProduct(product); // This will replace the existing product
  }

  @override
  Future<void> removeProduct(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final productsJson = prefs.getStringList(_productsKey) ?? [];
    final products = productsJson
        .map((p) => EventProductEntity.fromJson(jsonDecode(p)))
        .where((p) => p.id != productId)
        .toList();
    
    final productsJsonList = products.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_productsKey, productsJsonList);
  }

  @override
  Future<List<EventProductEntity>> getVendorProducts(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final productsJson = prefs.getStringList(_productsKey) ?? [];
    return productsJson
        .map((p) => EventProductEntity.fromJson(jsonDecode(p)))
        .where((p) => p.vendorId == vendorId && p.isActive)
        .toList();
  }

  @override
  Future<EventTransactionEntity> createTransaction(EventTransactionEntity transaction) async {
    final prefs = await SharedPreferences.getInstance();
    
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    final transactions = transactionsJson
        .map((t) => EventTransactionEntity.fromJson(jsonDecode(t)))
        .toList();
    
    transactions.add(transaction);
    
    final transactionsJsonList = transactions.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_transactionsKey, transactionsJsonList);
    
    return transaction;
  }

  @override
  Future<void> updateTransactionStatus(String transactionId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    final transactions = transactionsJson
        .map((t) => EventTransactionEntity.fromJson(jsonDecode(t)))
        .map((t) => t.id == transactionId 
            ? t.copyWith(status: status)
            : t)
        .toList();
    
    final transactionsJsonList = transactions.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_transactionsKey, transactionsJsonList);
  }

  @override
  Future<List<EventTransactionEntity>> getVendorTransactions(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    return transactionsJson
        .map((t) => EventTransactionEntity.fromJson(jsonDecode(t)))
        .where((t) => t.vendorId == vendorId)
        .toList();
  }

  @override
  Future<List<EventTransactionEntity>> getCustomerTransactions(String customerId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    return transactionsJson
        .map((t) => EventTransactionEntity.fromJson(jsonDecode(t)))
        .where((t) => t.customerId == customerId)
        .toList();
  }

  @override
  Future<void> connectToVendor(String vendorId, String customerId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final connectionsJson = prefs.getStringList(_connectionsKey) ?? [];
    final connections = connectionsJson
        .where((c) => !c.startsWith('$vendorId:$customerId'))
        .toList();
    
    connections.add('$vendorId:$customerId');
    
    await prefs.setStringList(_connectionsKey, connections);
  }

  @override
  Future<void> disconnectFromVendor(String vendorId, String customerId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final connectionsJson = prefs.getStringList(_connectionsKey) ?? [];
    final connections = connectionsJson
        .where((c) => c != '$vendorId:$customerId')
        .toList();
    
    await prefs.setStringList(_connectionsKey, connections);
  }

  @override
  Future<List<String>> getConnectedCustomers(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final connectionsJson = prefs.getStringList(_connectionsKey) ?? [];
    return connectionsJson
        .where((c) => c.startsWith('$vendorId:'))
        .map((c) => c.split(':')[1])
        .toList();
  }

  @override
  Future<void> saveTransactionLocally(EventTransactionEntity transaction) async {
    // For now, just save to the same storage
    await createTransaction(transaction);
  }

  @override
  Future<List<EventTransactionEntity>> getPendingTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    return transactionsJson
        .map((t) => EventTransactionEntity.fromJson(jsonDecode(t)))
        .where((t) => t.status == 'pending')
        .toList();
  }

  @override
  Future<void> clearCompletedTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    
    final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
    final transactions = transactionsJson
        .map((t) => EventTransactionEntity.fromJson(jsonDecode(t)))
        .where((t) => t.status != 'completed')
        .toList();
    
    final transactionsJsonList = transactions.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_transactionsKey, transactionsJsonList);
  }
}
