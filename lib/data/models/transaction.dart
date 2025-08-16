
import 'package:isiza_pay/domain/entities/transaction.dart';
import 'package:isiza_pay/domain/enums/transaction_status.dart';

class TransactionModel extends TransactionEntity {
  final String hash;
  final String previousHash;

  TransactionModel({
    required String id,
    required String senderAddress,
    required String receiverAddress,
    required num amount,
    required DateTime timestamp,
    required TransactionStatus status,
    required String signature,
    required bool trustFloatUsed,
    required this.hash,
    required this.previousHash,
  }) : super(
          id: id,
          sender: senderAddress,
          receiver: receiverAddress,
          amount: amount,
          timestamp: timestamp,
          status: TransactionStatus.pendingOffline,
          signature: signature,
          trustFloatUsed: trustFloatUsed,
        );

  factory TransactionModel.fromEntity(TransactionEntity entity, {required String hash, required String previousHash}) {
    return TransactionModel(
      id: entity.id,
      senderAddress: entity.sender,
      receiverAddress: entity.receiver,
      amount: entity.amount,
      timestamp: entity.timestamp,
      status: entity.status,
      signature: entity.signature,
      trustFloatUsed: entity.trustFloatUsed,
      hash: hash,
      previousHash: previousHash,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, sender: $sender, receiver: $receiver, amount: $amount, timestamp: $timestamp, status: $status, signature: $signature, trustFloatUsed: $trustFloatUsed, hash: $hash, previousHash: $previousHash)';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'receiver': receiver,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'signature': signature,
        'trustFloatUsed': trustFloatUsed,
        'hash': hash,
        'previousHash': previousHash,
      };

  static TransactionModel fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      senderAddress: json['sender'],
      receiverAddress: json['receiver'],
      amount: json['amount'],
      timestamp: DateTime.parse(json['timestamp']),
      status: TransactionStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => TransactionStatus.pendingOffline),
      signature: json['signature'],
      trustFloatUsed: json['trustFloatUsed'] ?? false,
      hash: json['hash'],
      previousHash: json['previousHash'],
    );
  }
}
