// lib/features/blockchain/domain/entities/transaction_entity.dart
import 'package:isiza_pay/domain/enums/transaction_status.dart';

class TransactionEntity {
  final String id;
  final String sender;
  final String receiver;
  final num amount;
  final DateTime timestamp;
  final String signature;
  final bool trustFloatUsed;
  final TransactionStatus status;
  final String? blockchainTxId;    // Solana transaction ID when submitted
  final String? blockchainError;   // Error message if failed
  final DateTime? confirmedAt;     // When confirmed on blockchain

  TransactionEntity({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.timestamp,
    required this.signature,
    this.trustFloatUsed = false,
    this.status = TransactionStatus.pendingOffline,
    this.blockchainTxId,
    this.blockchainError,
    this.confirmedAt,
  });

  TransactionEntity copyWith({
    String? id,
    String? sender,
    String? receiver,
    num? amount,
    DateTime? timestamp,
    String? signature,
    bool? trustFloatUsed,
    TransactionStatus? status,
    String? blockchainTxId,
    String? blockchainError,
    DateTime? confirmedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      signature: signature ?? this.signature,
      trustFloatUsed: trustFloatUsed ?? this.trustFloatUsed,
      status: status ?? this.status,
      blockchainTxId: blockchainTxId ?? this.blockchainTxId,
      blockchainError: blockchainError ?? this.blockchainError,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  @override
  String toString() {
    return 'TransactionEntity(id: $id, sender: $sender, receiver: $receiver, amount: $amount, timestamp: $timestamp, signature: $signature, trustFloatUsed: $trustFloatUsed, status: $status, blockchainTxId: $blockchainTxId, blockchainError: $blockchainError, confirmedAt: $confirmedAt)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'receiver': receiver,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'signature': signature,
      'trustFloatUsed': trustFloatUsed,
      'status': status.name,
      'blockchainTxId': blockchainTxId,
      'blockchainError': blockchainError,
      'confirmedAt': confirmedAt?.toIso8601String(),
    };
  }

  factory TransactionEntity.fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'] as String,
      sender: json['sender'] as String,
      receiver: json['receiver'] as String,
      amount: json['amount'] as num,
      timestamp: DateTime.parse(json['timestamp'] as String),
      signature: json['signature'] as String,
      trustFloatUsed: json['trustFloatUsed'] as bool? ?? false,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => TransactionStatus.pendingOffline,
      ),
      blockchainTxId: json['blockchainTxId'] as String?,
      blockchainError: json['blockchainError'] as String?,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
    );
  }
}
