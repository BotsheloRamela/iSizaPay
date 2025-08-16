import 'package:isiza_pay/domain/entities/event_product.dart';
import 'package:isiza_pay/domain/entities/event_transaction.dart';
import 'package:isiza_pay/domain/repositories/event_mode_repository.dart';

class PurchaseItemUseCase {
  final EventModeRepository _repository;

  PurchaseItemUseCase(this._repository);

  Future<EventTransactionEntity> execute({
    required String customerId,
    required String vendorId,
    required List<EventProductEntity> products,
  }) async {
    // Validate inputs
    if (customerId.isEmpty) {
      throw ArgumentError('Customer ID cannot be empty');
    }
    if (vendorId.isEmpty) {
      throw ArgumentError('Vendor ID cannot be empty');
    }
    if (products.isEmpty) {
      throw ArgumentError('Products list cannot be empty');
    }

    // Calculate total amount
    final totalAmount = products.fold<num>(
      0, 
      (sum, product) => sum + (product.price * 1), // Assuming quantity 1 for now
    );

    // Create transaction
    final transaction = EventTransactionEntity(
      id: _generateTransactionId(),
      customerId: customerId,
      vendorId: vendorId,
      products: products,
      totalAmount: totalAmount,
      timestamp: DateTime.now(),
      status: 'pending',
    );

    // Save transaction locally first
    await _repository.saveTransactionLocally(transaction);
    
    // Create transaction in repository
    final createdTransaction = await _repository.createTransaction(transaction);
    
    return createdTransaction;
  }

  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'event_tx_${timestamp}_$random';
  }
}
