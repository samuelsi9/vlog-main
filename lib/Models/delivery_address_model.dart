class DeliveryAddressModel {
  final String id;
  final String userId;
  final String label; // "Maison", "Bureau", etc.
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;
  final String? instructions;
  final String? phone;
  final bool isDefault;

  DeliveryAddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.instructions,
    this.phone,
    this.isDefault = false,
  });

  DeliveryAddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? street,
    String? city,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? instructions,
    String? phone,
    bool? isDefault,
  }) {
    return DeliveryAddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      instructions: instructions ?? this.instructions,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get fullAddress => '$street, ${postalCode.isNotEmpty ? "$postalCode " : ""}$city${country.isNotEmpty ? ", $country" : ""}'.trim();

  factory DeliveryAddressModel.fromMap(Map<String, dynamic> map) {
    return DeliveryAddressModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      street: map['street']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      postalCode: map['postalCode']?.toString() ?? '',
      country: map['country']?.toString() ?? 'France',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      instructions: map['instructions']?.toString(),
      phone: map['phone']?.toString(),
      isDefault: map['isDefault'] ?? false,
    );
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  /// From API response: { "data": [ { id, user_id, street, building_number, apartment_number, city, is_default, latitude, longitude, label, ... } ] }
  factory DeliveryAddressModel.fromApiMap(Map<String, dynamic> map) {
    final building = map['building_number']?.toString() ?? '';
    final apartment = map['apartment_number']?.toString() ?? '';
    final streetPart = map['street']?.toString() ?? '';
    final street = [streetPart, building, apartment].where((e) => e.isNotEmpty).join(', ');
    return DeliveryAddressModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      label: map['address_type']?.toString() ?? map['label']?.toString() ?? 'Address',
      street: street.isEmpty ? streetPart : street,
      city: map['city']?.toString() ?? '',
      postalCode: map['postal_code']?.toString() ?? map['postalCode']?.toString() ?? '',
      country: map['country']?.toString() ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      instructions: map['instructions']?.toString() ?? map['nearby_landmark']?.toString(),
      phone: map['phone']?.toString(),
      isDefault: _toBool(map['is_default']) || _toBool(map['isDefault']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'instructions': instructions,
      'phone': phone,
      'isDefault': isDefault,
    };
  }
}







