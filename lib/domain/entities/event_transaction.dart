import 'package:isiza_pay/domain/entities/event_product.dart';

class EventTransactionEntity {
  final String id;
  final String customerId;
  final String vendorId;
  final List<EventProductEntity> products;
  final num totalAmount;
  final DateTime timestamp;
  final String status; // 'pending', 'completed', 'failed'
  final String? transactionHash;
  final String? errorMessage;

  EventTransactionEntity({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.products,
    required this.totalAmount,
    required this.timestamp,
    required this.status,
    this.transactionHash,
    this.errorMessage,
  });

  EventTransactionEntity copyWith({
    String? id,
    String? customerId,
    String? vendorId,
    List<EventProductEntity>? products,
    num? totalAmount,
    DateTime? timestamp,
    String? status,
    String? transactionHash,
    String? errorMessage,
  }) {
    return EventTransactionEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vendorId: vendorId ?? this.vendorId,
      products: products ?? this.products,
      totalAmount: totalAmount ?? this.totalAmount,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      transactionHash: transactionHash ?? this.transactionHash,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'EventTransactionEntity(id: $id, customerId: $customerId, vendorId: $vendorId, totalAmount: $totalAmount, status: $status)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'vendorId': vendorId,
      'products': products.map((p) => p.toJson()).toList(),
      'totalAmount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'transactionHash': transactionHash,
      'errorMessage': errorMessage,
    };
  }

  factory EventTransactionEntity.fromJson(Map<String, dynamic> json) {
    return EventTransactionEntity(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      vendorId: json['vendorId'] as String,
      products: (json['products'] as List)
          .map((p) => EventProductEntity.fromJson(p as Map<String, dynamic>))
          .toList(),
      totalAmount: json['totalAmount'] as num,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      transactionHash: json['transactionHash'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
