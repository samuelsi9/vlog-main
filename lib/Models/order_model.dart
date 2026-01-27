enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

class Order {
  final String id;
  final String userId;
  final String storeId;
  final String storeName;
  final String? storeImage;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double tax;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final DeliveryAddress deliveryAddress;
  final PaymentMethod paymentMethod;
  final String? trackingId;

  Order({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.storeName,
    this.storeImage,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.tax,
    required this.total,
    required this.status,
    required this.createdAt,
    this.estimatedDelivery,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.trackingId,
  });

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      storeId: map['storeId']?.toString() ?? map['restaurantId']?.toString() ?? '',
      storeName: map['storeName']?.toString() ?? map['restaurantName']?.toString() ?? '',
      storeImage: map['storeImage']?.toString() ?? map['restaurantImage']?.toString(),
      items: (map['items'] as List? ?? [])
          .map((item) => OrderItem.fromMap(item))
          .toList(),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      shippingFee: (map['shippingFee'] ?? map['deliveryFee'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${map['status']}',
        orElse: () => OrderStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      estimatedDelivery: map['estimatedDelivery'] != null
          ? DateTime.parse(map['estimatedDelivery'])
          : null,
      deliveryAddress: DeliveryAddress.fromMap(map['deliveryAddress'] ?? {}),
      paymentMethod: PaymentMethod.fromMap(map['paymentMethod'] ?? {}),
      trackingId: map['trackingId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'storeId': storeId,
      'storeName': storeName,
      'storeImage': storeImage,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'tax': tax,
      'total': total,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
      'deliveryAddress': deliveryAddress.toMap(),
      'paymentMethod': paymentMethod.toMap(),
      'trackingId': trackingId,
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final Map<String, String>? selectedOptions; // For product variations

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.selectedOptions,
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId']?.toString() ?? map['menuItemId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      imageUrl: map['imageUrl']?.toString(),
      selectedOptions: map['selectedOptions'] != null 
          ? Map<String, String>.from(map['selectedOptions'])
          : map['selectedVariations'] != null
              ? Map<String, String>.from(map['selectedVariations'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'selectedOptions': selectedOptions,
    };
  }
}

class DeliveryAddress {
  final String id;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final String? instructions;

  DeliveryAddress({
    required this.id,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    this.latitude,
    this.longitude,
    this.instructions,
  });

  String get fullAddress => '$street, $postalCode $city, $country';

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      id: map['id']?.toString() ?? '',
      street: map['street']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      postalCode: map['postalCode']?.toString() ?? '',
      country: map['country']?.toString() ?? 'France',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      instructions: map['instructions']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'instructions': instructions,
    };
  }
}

class PaymentMethod {
  final String type; // 'card', 'cash', 'paypal', etc.
  final String? cardLast4;
  final String? cardBrand;

  PaymentMethod({
    required this.type,
    this.cardLast4,
    this.cardBrand,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      type: map['type']?.toString() ?? 'cash',
      cardLast4: map['cardLast4']?.toString(),
      cardBrand: map['cardBrand']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'cardLast4': cardLast4,
      'cardBrand': cardBrand,
    };
  }
}

