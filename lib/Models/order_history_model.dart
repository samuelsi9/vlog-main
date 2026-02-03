/// Single line item within an order (from GET /api/orders response).
class OrderHistoryItemModel {
  final int id;
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;

  OrderHistoryItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderHistoryItemModel.fromMap(Map<String, dynamic> map) {
    return OrderHistoryItemModel(
      id: (map['id'] ?? 0) as int,
      productId: (map['product_id'] ?? map['productId'] ?? 0) as int,
      name: map['name']?.toString() ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? 0) as int,
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
    );
  }
}

/// Order from GET /api/orders (all order history).
class AllOrderHistoryModel {
  final int id;
  final double totalAmount;
  final String status; // e.g. "pending", "delivered", "canceled"
  final String paymentMethod;
  final String paymentStatus;
  final String? notes;
  final double deliveryFee;
  final double grandTotal;
  final String createdAt;
  final List<OrderHistoryItemModel> items;

  AllOrderHistoryModel({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.notes,
    required this.deliveryFee,
    required this.grandTotal,
    required this.createdAt,
    required this.items,
  });

  factory AllOrderHistoryModel.fromMap(Map<String, dynamic> map) {
    final itemsList = map['items'];
    final items = itemsList is List
        ? (itemsList)
            .map((e) => OrderHistoryItemModel.fromMap(
                e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
            .toList()
        : <OrderHistoryItemModel>[];

    return AllOrderHistoryModel(
      id: (map['id'] ?? 0) as int,
      totalAmount: (map['total_amount'] ?? map['totalAmount'] ?? 0.0).toDouble(),
      status: map['status']?.toString().toLowerCase() ?? 'pending',
      paymentMethod: map['payment_method']?.toString() ?? map['paymentMethod'] ?? '',
      paymentStatus: map['payment_status']?.toString() ?? map['paymentStatus'] ?? '',
      notes: map['notes']?.toString(),
      deliveryFee: (map['delivery_fee'] ?? map['deliveryFee'] ?? 0.0).toDouble(),
      grandTotal: (map['grand_total'] ?? map['grandTotal'] ?? 0.0).toDouble(),
      createdAt: map['created_at']?.toString() ?? map['createdAt'] ?? '',
      items: items,
    );
  }

  /// For tab filtering: "delivered" -> Completed, "canceled"/"cancelled" -> Canceled, "pending" etc -> In Progress
  bool get isDelivered =>
      status == 'delivered' || status == 'completed';
  bool get isCanceled =>
      status == 'canceled' || status == 'cancelled' || status == 'cancel';
  bool get isInProgress =>
      status == 'pending' || status == 'processing' || status == 'confirmed' ||
      status == 'shipped' || status == 'out_for_delivery';
}

/// Single item within GET /api/orders/{id} response (includes image).
class SingleOrderItemModel {
  final int productId;
  final String name;
  final String? image;
  final double price;
  final int quantity;
  final double subtotal;

  SingleOrderItemModel({
    required this.productId,
    required this.name,
    this.image,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory SingleOrderItemModel.fromMap(Map<String, dynamic> map) {
    return SingleOrderItemModel(
      productId: (map['product_id'] ?? map['productId'] ?? 0) as int,
      name: map['name']?.toString() ?? '',
      image: map['image']?.toString(),
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? 0) as int,
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
    );
  }
}

/// Single order detail from GET /api/orders/{id}.
class SingleOrderHistoryModel {
  final int id;
  final String status;
  final double? subtotal;
  final double? deliveryFee;
  final double? total;
  final String? deliveryDate;
  final String? deliveryTime;
  final String createdAt;
  final List<SingleOrderItemModel> items;

  SingleOrderHistoryModel({
    required this.id,
    required this.status,
    this.subtotal,
    this.deliveryFee,
    this.total,
    this.deliveryDate,
    this.deliveryTime,
    required this.createdAt,
    required this.items,
  });

  factory SingleOrderHistoryModel.fromMap(Map<String, dynamic> map) {
    final itemsList = map['items'];
    final items = itemsList is List
        ? (itemsList)
            .map((e) => SingleOrderItemModel.fromMap(
                e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
            .toList()
        : <SingleOrderItemModel>[];

    return SingleOrderHistoryModel(
      id: (map['id'] ?? 0) as int,
      status: map['status']?.toString().toLowerCase() ?? 'pending',
      subtotal: map['subtotal'] != null ? (map['subtotal'] as num).toDouble() : null,
      deliveryFee: map['delivery_fee'] != null ? (map['delivery_fee'] as num).toDouble() : null,
      total: map['total'] != null ? (map['total'] as num).toDouble() : null,
      deliveryDate: map['delivery_date']?.toString(),
      deliveryTime: map['delivery_time']?.toString(),
      createdAt: map['created_at']?.toString() ?? map['createdAt'] ?? '',
      items: items,
    );
  }

  double get effectiveTotal => total ?? (subtotal ?? 0) + (deliveryFee ?? 0);
  double get effectiveSubtotal => subtotal ?? items.fold(0.0, (s, i) => s + i.subtotal);
}
