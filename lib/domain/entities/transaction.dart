import 'package:isiza_pay/domain/enums/transaction_status.dart';

class TransactionEntity {
  final String id;
  final String senderPublicKey;
  final String receiverPublicKey;
  final num amount;
  final DateTime timestamp;
  final String signature;
  final String previousBlockHash;
  final TransactionStatus status;
  final String? blockchainTxId;
  final String? blockchainError;
  final DateTime? confirmedAt;

  TransactionEntity({
    required this.id,
    required this.senderPublicKey,
    required this.receiverPublicKey,
    required this.amount,
    required this.timestamp,
    required this.signature,
    required this.previousBlockHash,
    this.status = TransactionStatus.pendingOffline,
    this.blockchainTxId,
    this.blockchainError,
    this.confirmedAt,
  });

  TransactionEntity copyWith({
    String? id,
    String? senderPublicKey,
    String? receiverPublicKey,
    num? amount,
    DateTime? timestamp,
    String? signature,
    String? previousBlockHash,
    TransactionStatus? status,
    String? blockchainTxId,
    String? blockchainError,
    DateTime? confirmedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      senderPublicKey: senderPublicKey ?? this.senderPublicKey,
      receiverPublicKey: receiverPublicKey ?? this.receiverPublicKey,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      signature: signature ?? this.signature,
      previousBlockHash: previousBlockHash ?? this.previousBlockHash,
      status: status ?? this.status,
      blockchainTxId: blockchainTxId ?? this.blockchainTxId,
      blockchainError: blockchainError ?? this.blockchainError,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  @override
  String toString() {
    return 'TransactionEntity(id: $id, senderPublicKey: $senderPublicKey, receiverPublicKey: $receiverPublicKey, amount: $amount, timestamp: $timestamp, signature: $signature, previousBlockHash: $previousBlockHash, status: $status, blockchainTxId: $blockchainTxId, blockchainError: $blockchainError, confirmedAt: $confirmedAt)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderPublicKey': senderPublicKey,
      'receiverPublicKey': receiverPublicKey,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'signature': signature,
      'previousBlockHash': previousBlockHash,
      'status': status.name,
      'blockchainTxId': blockchainTxId,
      'blockchainError': blockchainError,
      'confirmedAt': confirmedAt?.toIso8601String(),
    };
  }

  factory TransactionEntity.fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'] as String,
      senderPublicKey: json['senderPublicKey'] as String,
      receiverPublicKey: json['receiverPublicKey'] as String,
      amount: json['amount'] as num,
      timestamp: DateTime.parse(json['timestamp'] as String),
      signature: json['signature'] as String,
      previousBlockHash: json['previousBlockHash'] as String,
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
