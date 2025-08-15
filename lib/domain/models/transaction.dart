
enum TransactionStatus {
  pendingOffline,      // Created offline, not yet submitted to blockchain
  pendingBlockchain,   // Submitted to blockchain, awaiting confirmation
  confirmed,           // Confirmed on blockchain
  failed,              // Failed blockchain submission or confirmation
  rejected,            // Rejected by network
}

class Transaction {
  final String id;
  final String fromDevice;
  final String toDevice;
  final num amount;
  final DateTime timestamp;
  final String signature;
  final bool trustFloatUsed;
  final TransactionStatus status;
  final String? blockchainTxId;    // Solana transaction ID when submitted
  final String? blockchainError;   // Error message if failed
  final DateTime? confirmedAt;     // When confirmed on blockchain

  Transaction({
    required this.id,
    required this.fromDevice,
    required this.toDevice,
    required this.amount,
    required this.timestamp,
    required this.signature,
    this.trustFloatUsed = false,
    this.status = TransactionStatus.pendingOffline,
    this.blockchainTxId,
    this.blockchainError,
    this.confirmedAt,
  });

  Transaction copyWith({
    TransactionStatus? status,
    String? blockchainTxId,
    String? blockchainError,
    DateTime? confirmedAt,
  }) {
    return Transaction(
      id: id,
      fromDevice: fromDevice,
      toDevice: toDevice,
      amount: amount,
      timestamp: timestamp,
      signature: signature,
      trustFloatUsed: trustFloatUsed,
      status: status ?? this.status,
      blockchainTxId: blockchainTxId ?? this.blockchainTxId,
      blockchainError: blockchainError ?? this.blockchainError,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      fromDevice: json['fromDevice'] as String,
      toDevice: json['toDevice'] as String,
      amount: json['amount'] as num,
      timestamp: DateTime.parse(json['timestamp'] as String),
      signature: json['signature'] as String,
      trustFloatUsed: json['trustFloatUsed'] as bool? ?? false,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pendingOffline,
      ),
      blockchainTxId: json['blockchainTxId'] as String?,
      blockchainError: json['blockchainError'] as String?,
      confirmedAt: json['confirmedAt'] != null 
        ? DateTime.parse(json['confirmedAt'] as String)
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromDevice': fromDevice,
      'toDevice': toDevice,
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
}