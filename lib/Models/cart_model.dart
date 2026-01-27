class CartItemModel {
  final int id;
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String? image;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.image,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as int? ?? 0,
      productId: map['product_id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 1,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      image: map['image'] as String?,
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
    final itemsList = map['items'] as List<dynamic>? ?? [];
    final cartItems = itemsList
        .map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return CartModel(
      cartId: map['cart_id'] as int? ?? 0,
      items: cartItems,
      deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
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
