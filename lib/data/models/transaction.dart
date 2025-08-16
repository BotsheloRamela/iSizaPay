
import 'package:isiza_pay/domain/entities/transaction.dart';
import 'package:isiza_pay/domain/enums/transaction_status.dart';

class TransactionModel extends TransactionEntity {
  final String hash;
  final String blockHash;

  TransactionModel({
    required super.id,
    required String senderAddress,
    required String receiverAddress,
    required super.amount,
    required super.timestamp,
    required super.signature,
    required super.previousBlockHash,
    TransactionStatus? status,
    super.blockchainTxId,
    super.blockchainError,
    super.confirmedAt,
    required this.hash,
    required this.blockHash,
  }) : super(
          senderPublicKey: senderAddress,
          receiverPublicKey: receiverAddress,
          status: status ?? TransactionStatus.pendingOffline,
        );

  factory TransactionModel.fromEntity(TransactionEntity entity, {required String hash, required String blockHash}) {
    return TransactionModel(
      id: entity.id,
      senderAddress: entity.senderPublicKey,
      receiverAddress: entity.receiverPublicKey,
      amount: entity.amount,
      timestamp: entity.timestamp,
      signature: entity.signature,
      previousBlockHash: entity.previousBlockHash,
      status: entity.status,
      blockchainTxId: entity.blockchainTxId,
      blockchainError: entity.blockchainError,
      confirmedAt: entity.confirmedAt,
      hash: hash,
      blockHash: blockHash,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, senderPublicKey: $senderPublicKey, receiverPublicKey: $receiverPublicKey, amount: $amount, timestamp: $timestamp, status: $status, signature: $signature, hash: $hash, blockHash: $blockHash)';
  }

  @override
  Map<String, dynamic> toJson() => {
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
        'hash': hash,
        'blockHash': blockHash,
      };

  static TransactionModel fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      senderAddress: json['senderPublicKey'],
      receiverAddress: json['receiverPublicKey'],
      amount: json['amount'],
      timestamp: DateTime.parse(json['timestamp']),
      signature: json['signature'],
      previousBlockHash: json['previousBlockHash'],
      status: TransactionStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => TransactionStatus.pendingOffline),
      blockchainTxId: json['blockchainTxId'],
      blockchainError: json['blockchainError'],
      confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
      hash: json['hash'],
      blockHash: json['blockHash'],
    );
  }
}
