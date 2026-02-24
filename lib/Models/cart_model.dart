/// Parses numeric value from JSON (handles int, double, or string from Laravel).
double _cartToDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int _cartToInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class CartItemModel {
  final int id;
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String? image;
  final String? unitType; // e.g. "kg", "piece" - from product

  CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.image,
    this.unitType,
  });

  static String? _parseImage(Map<String, dynamic> map) {
    String? fromVal(dynamic v) {
      if (v == null) return null;
      if (v is String) {
        final s = v.trim();
        return s.isEmpty ? null : s;
      }
      if (v is Map<String, dynamic>) {
        for (final k in ['src', 'url', 'path']) {
          final s = fromVal(v[k]);
          if (s != null) return s;
        }
      }
      if (v is List && v.isNotEmpty) {
        return fromVal(v.first);
      }
      return v.toString().trim().isEmpty ? null : v.toString().trim();
    }
    // Top-level fields
    for (final key in ['image', 'image_url', 'photo', 'thumbnail']) {
      final s = fromVal(map[key]);
      if (s != null) return s;
    }
    // Nested under product
    if (map['product'] is Map) {
      final p = map['product'] as Map<String, dynamic>;
      for (final key in ['image', 'image_url', 'photo', 'thumbnail', 'images']) {
        final s = fromVal(p[key]);
        if (s != null) return s;
      }
    }
    return null;
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    String? unitType;
    if (map['unit_type'] != null) {
      unitType = map['unit_type']?.toString().trim().toLowerCase();
    } else if (map['product'] is Map) {
      final p = map['product'] as Map<String, dynamic>;
      unitType = p['unit_type']?.toString().trim().toLowerCase();
    }
    final image = _parseImage(map);
    return CartItemModel(
      id: _cartToInt(map['id']),
      productId: _cartToInt(map['product_id']),
      name: map['name']?.toString() ?? '',
      price: _cartToDouble(map['price']),
      quantity: _cartToInt(map['quantity']).clamp(1, 999),
      subtotal: _cartToDouble(map['subtotal']),
      image: image,
      unitType: unitType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      'image': image,
    };
  }

  CartItemModel copyWith({
    int? id,
    int? productId,
    String? name,
    double? price,
    int? quantity,
    double? subtotal,
    String? image,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      image: image ?? this.image,
    );
  }
}

class CartModel {
  final int cartId;
  final List<CartItemModel> items;
  final double deliveryFee;
  final double total;

  CartModel({
    required this.cartId,
    required this.items,
    required this.deliveryFee,
    required this.total,
  });

  factory CartModel.fromMap(Map<String, dynamic> map) {
    var itemsList = map['items'] as List<dynamic>?;
    if (itemsList == null || itemsList.isEmpty) {
      itemsList = map['cart_items'] as List<dynamic>? ?? [];
    }
    final cartItems = itemsList
        .map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return CartModel(
      cartId: _cartToInt(map['cart_id']),
      items: cartItems,
      deliveryFee: _cartToDouble(map['delivery_fee']),
      total: _cartToDouble(map['total']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cart_id': cartId,
      'items': items.map((item) => item.toMap()).toList(),
      'delivery_fee': deliveryFee,
      'total': total,
    };
  }

  // Helper getters
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isEmpty => items.isEmpty;

  CartModel copyWith({
    int? cartId,
    List<CartItemModel>? items,
    double? deliveryFee,
    double? total,
  }) {
    return CartModel(
      cartId: cartId ?? this.cartId,
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
    );
  }
}
