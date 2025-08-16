class VendorInfoEntity {
  final String id;
  final String name;
  final String description;
  final String publicKey;
  final bool isEventModeActive;
  final DateTime? eventModeStartedAt;
  final List<String> supportedPaymentMethods;
  final String? location;
  final double? rating;
  final int totalTransactions;

  VendorInfoEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.publicKey,
    this.isEventModeActive = false,
    this.eventModeStartedAt,
    this.supportedPaymentMethods = const [],
    this.location,
    this.rating,
    this.totalTransactions = 0,
  });

  VendorInfoEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? publicKey,
    bool? isEventModeActive,
    DateTime? eventModeStartedAt,
    List<String>? supportedPaymentMethods,
    String? location,
    double? rating,
    int? totalTransactions,
  }) {
    return VendorInfoEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      publicKey: publicKey ?? this.publicKey,
      isEventModeActive: isEventModeActive ?? this.isEventModeActive,
      eventModeStartedAt: eventModeStartedAt ?? this.eventModeStartedAt,
      supportedPaymentMethods: supportedPaymentMethods ?? this.supportedPaymentMethods,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      totalTransactions: totalTransactions ?? this.totalTransactions,
    );
  }

  @override
  String toString() {
    return 'VendorInfoEntity(id: $id, name: $name, isEventModeActive: $isEventModeActive)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'publicKey': publicKey,
      'isEventModeActive': isEventModeActive,
      'eventModeStartedAt': eventModeStartedAt?.toIso8601String(),
      'supportedPaymentMethods': supportedPaymentMethods,
      'location': location,
      'rating': rating,
      'totalTransactions': totalTransactions,
    };
  }

  factory VendorInfoEntity.fromJson(Map<String, dynamic> json) {
    return VendorInfoEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      publicKey: json['publicKey'] as String,
      isEventModeActive: json['isEventModeActive'] as bool? ?? false,
      eventModeStartedAt: json['eventModeStartedAt'] != null
          ? DateTime.parse(json['eventModeStartedAt'] as String)
          : null,
      supportedPaymentMethods: (json['supportedPaymentMethods'] as List?)
          ?.map((e) => e as String)
          .toList() ?? [],
      location: json['location'] as String?,
      rating: json['rating'] as double?,
      totalTransactions: json['totalTransactions'] as int? ?? 0,
    );
  }
}
