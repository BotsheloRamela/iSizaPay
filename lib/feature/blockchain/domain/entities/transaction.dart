// lib/features/blockchain/domain/entities/transaction_entity.dart
class TransactionEntity {
  final String id;
  final String sender;
  final String receiver;
  final double amount;
  final DateTime timestamp;
  final String status;

  TransactionEntity({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.timestamp,
    this.status = 'pending',
  });
}
