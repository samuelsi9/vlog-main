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
    this.isDefault = false,
  });

  String get fullAddress => '$street, $postalCode $city, $country';

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
      isDefault: map['isDefault'] ?? false,
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
      'isDefault': isDefault,
    };
  }
}







