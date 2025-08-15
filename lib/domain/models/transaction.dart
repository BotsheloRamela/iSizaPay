
class Transaction {
  final String id;
  final String fromDevice;
  final String toDevice;
  final num amount;
  final DateTime timestamp;
  final String signature;
  final bool trustFloatUsed;

  Transaction({
    required this.id,
    required this.fromDevice,
    required this.toDevice,
    required this.amount,
    required this.timestamp,
    required this.signature,
    this.trustFloatUsed = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      fromDevice: json['fromDevice'] as String,
      toDevice: json['toDevice'] as String,
      amount: json['amount'] as num,
      timestamp: DateTime.parse(json['timestamp'] as String),
      signature: json['signature'] as String,
      trustFloatUsed: json['trustFloatUsed'] as bool? ?? false,
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
    };
  }
}