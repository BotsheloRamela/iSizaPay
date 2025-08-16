import 'package:isiza_pay/domain/enums/payment_request_status.dart';

class PaymentRequest {
  final String id;
  final String fromDevice;
  final String toDevice;
  final num amount;
  final String description;
  final DateTime timestamp;
  final PaymentRequestStatus status;

  PaymentRequest({
    required this.id,
    required this.fromDevice,
    required this.toDevice,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.status = PaymentRequestStatus.pending,
  });

  PaymentRequest copyWith({
    PaymentRequestStatus? status,
  }) {
    return PaymentRequest(
      id: id,
      fromDevice: fromDevice,
      toDevice: toDevice,
      amount: amount,
      description: description,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromDevice': fromDevice,
      'toDevice': toDevice,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      id: json['id'] as String,
      fromDevice: json['fromDevice'] as String,
      toDevice: json['toDevice'] as String,
      amount: json['amount'] as num,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: PaymentRequestStatus.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => PaymentRequestStatus.pending,
      ),
    );
  }
}