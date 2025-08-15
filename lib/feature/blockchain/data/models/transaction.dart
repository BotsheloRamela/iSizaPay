// lib/features/blockchain/data/models/transaction_model.dart
import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  final String hash;
  final String previousHash;

  TransactionModel({
    required String id,
    required String senderAddress,
    required String receiverAddress,
    required double amount,
    required DateTime timestamp,
    String status = 'pending',
    required this.hash,
    required this.previousHash,
  }) : super(
          id: id,
          sender: senderAddress,
          receiver: receiverAddress,
          amount: amount,
          timestamp: timestamp,
          status: status,
        );

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderAddress': sender,
        'receiverAddress': receiver,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
        'hash': hash,
        'previousHash': previousHash,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'],
        senderAddress: map['senderAddress'],
        receiverAddress: map['receiverAddress'],
        amount: map['amount'],
        timestamp: DateTime.parse(map['timestamp']),
        status: map['status'] ?? 'pending',
        hash: map['hash'],
        previousHash: map['previousHash'],
      );

  factory TransactionModel.fromEntity(TransactionEntity entity, {required String hash, required String previousHash}) {
    return TransactionModel(
      id: entity.id,
      senderAddress: entity.sender,
      receiverAddress: entity.receiver,
      amount: entity.amount,
      timestamp: entity.timestamp,
      status: entity.status,
      hash: hash,
      previousHash: previousHash,
    );
  }
}
