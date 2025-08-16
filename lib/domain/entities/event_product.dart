class EventProductEntity {
  final String id;
  final String name;
  final String description;
  final num price;
  final int availableQuantity;
  final String vendorId;
  final DateTime createdAt;
  final bool isActive;

  EventProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.availableQuantity,
    required this.vendorId,
    required this.createdAt,
    this.isActive = true,
  });

  EventProductEntity copyWith({
    String? id,
    String? name,
    String? description,
    num? price,
    int? availableQuantity,
    String? vendorId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return EventProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      vendorId: vendorId ?? this.vendorId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'EventProductEntity(id: $id, name: $name, price: $price, availableQuantity: $availableQuantity, vendorId: $vendorId)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'availableQuantity': availableQuantity,
      'vendorId': vendorId,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory EventProductEntity.fromJson(Map<String, dynamic> json) {
    return EventProductEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as num,
      availableQuantity: json['availableQuantity'] as int,
      vendorId: json['vendorId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
