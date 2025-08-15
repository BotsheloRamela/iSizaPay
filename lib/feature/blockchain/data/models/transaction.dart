// lib/features/blockchain/data/models/transaction_model.dart
import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  TransactionModel({
    required super.id,
    required super.sender,
    required super.receiver,
    required super.amount,
    required super.timestamp,
    super.status,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sender': sender,
        'receiver': receiver,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'],
        sender: map['sender'],
        receiver: map['receiver'],
        amount: map['amount'],
        timestamp: DateTime.parse(map['timestamp']),
        status: map['status'] ?? 'pending',
      );
}
