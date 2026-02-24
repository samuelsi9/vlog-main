import 'package:vlog/Utils/parse_utils.dart';

/// Single line item within an order (from GET /api/orders response).
class OrderHistoryItemModel {
  final int id;
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String? unitType; // e.g. "kg", "piece", "liter"

  OrderHistoryItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.unitType,
  });

  factory OrderHistoryItemModel.fromMap(Map<String, dynamic> map) {
    final ut = map['unit_type']?.toString().trim().toLowerCase() ??
        map['unitType']?.toString().trim().toLowerCase();
    return OrderHistoryItemModel(
      id: parseInt(map['id']),
      productId: parseInt(map['product_id'] ?? map['productId']),
      name: map['name']?.toString() ?? '',
      price: parseDouble(map['price']),
      quantity: parseInt(map['quantity'], 1),
      subtotal: parseDouble(map['subtotal']),
      unitType: ut?.isNotEmpty == true ? ut : null,
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
      id: parseInt(map['id']),
      totalAmount: parseDouble(map['total_amount'] ?? map['totalAmount']),
      status: map['status']?.toString().toLowerCase() ?? 'pending',
      paymentMethod: map['payment_method']?.toString() ?? map['paymentMethod'] ?? '',
      paymentStatus: map['payment_status']?.toString() ?? map['paymentStatus'] ?? '',
      notes: map['notes']?.toString(),
      deliveryFee: parseDouble(map['delivery_fee'] ?? map['deliveryFee']),
      grandTotal: parseDouble(map['grand_total'] ?? map['grandTotal']),
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
  final String? unitType; // e.g. "kg", "piece", "liter"

  SingleOrderItemModel({
    required this.productId,
    required this.name,
    this.image,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.unitType,
  });

  factory SingleOrderItemModel.fromMap(Map<String, dynamic> map) {
    final ut = map['unit_type']?.toString().trim().toLowerCase() ??
        map['unitType']?.toString().trim().toLowerCase();
    return SingleOrderItemModel(
      productId: parseInt(map['product_id'] ?? map['productId']),
      name: map['name']?.toString() ?? '',
      image: map['image']?.toString(),
      price: parseDouble(map['price']),
      quantity: parseInt(map['quantity'], 1),
      subtotal: parseDouble(map['subtotal']),
      unitType: ut?.isNotEmpty == true ? ut : null,
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
      id: parseInt(map['id']),
      status: map['status']?.toString().toLowerCase() ?? 'pending',
      subtotal: map['subtotal'] != null ? parseDouble(map['subtotal']) : null,
      deliveryFee: map['delivery_fee'] != null ? parseDouble(map['delivery_fee']) : null,
      total: map['total'] != null ? parseDouble(map['total']) : null,
      deliveryDate: map['delivery_date']?.toString(),
      deliveryTime: map['delivery_time']?.toString(),
      createdAt: map['created_at']?.toString() ?? map['createdAt'] ?? '',
      items: items,
    );
  }

  double get effectiveTotal => total ?? (subtotal ?? 0) + (deliveryFee ?? 0);
  double get effectiveSubtotal => subtotal ?? items.fold(0.0, (s, i) => s + i.subtotal);

  SingleOrderHistoryModel copyWith({String? status}) {
    return SingleOrderHistoryModel(
      id: id,
      status: status ?? this.status,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      deliveryDate: deliveryDate,
      deliveryTime: deliveryTime,
      createdAt: createdAt,
      items: items,
    );
  }
}
