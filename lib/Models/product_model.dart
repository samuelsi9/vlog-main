import 'package:vlog/Utils/parse_utils.dart';

class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String image;
  final int categoryId;
  final int subcategoryId;
  final String createdAt;
  final double rating; // Rating with default value
  final String unitType; // e.g. "piece", "kg", "liter"

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.categoryId,
    required this.subcategoryId,
    required this.createdAt,
    this.rating = 4.0, // Default rating value
    this.unitType = 'piece',
  });

  /// Parses numeric value from JSON (handles int, double, or string from Laravel).
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: _toInt(map['id']),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: _toDouble(map['price']),
      image: map['image']?.toString() ?? '',
      categoryId: _toInt(map['category_id']),
      subcategoryId: _toInt(map['subcategory_id']),
      createdAt: map['created_at']?.toString() ?? '',
      rating: () {
        final r = _toDouble(map['rating']);
        return r > 0 ? r.clamp(0.0, 5.0) : 4.0;
      }(),
      unitType: map['unit_type']?.toString().trim().toLowerCase() ?? 'piece',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'created_at': createdAt,
      'rating': rating,
      'unit_type': unitType,
    };
  }
}

// Pagination Links Model
class PaginationLinks {
  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  PaginationLinks({
    this.first,
    this.last,
    this.prev,
    this.next,
  });

  factory PaginationLinks.fromMap(Map<String, dynamic> map) {
    return PaginationLinks(
      first: map['first'] as String?,
      last: map['last'] as String?,
      prev: map['prev'] as String?,
      next: map['next'] as String?,
    );
  }
}

// Pagination Meta Model
class PaginationMeta {
  final int currentPage;
  final int from;
  final int lastPage;
  final String path;
  final int perPage;
  final int to;
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.from,
    required this.lastPage,
    required this.path,
    required this.perPage,
    required this.to,
    required this.total,
  });

  factory PaginationMeta.fromMap(Map<String, dynamic> map) {
    return PaginationMeta(
      currentPage: parseInt(map['current_page'], 1).clamp(1, 999),
      from: parseInt(map['from'], 1).clamp(1, 999),
      lastPage: parseInt(map['last_page'], 1).clamp(1, 999),
      path: map['path']?.toString() ?? '',
      perPage: parseInt(map['per_page'], 10).clamp(1, 100),
      to: parseInt(map['to']),
      total: parseInt(map['total']),
    );
  }
}

// Products Response Model (with pagination)
class ProductsResponse {
  final List<ProductModel> data;
  final PaginationLinks links;
  final PaginationMeta meta;

  ProductsResponse({
    required this.data,
    required this.links,
    required this.meta,
  });

  factory ProductsResponse.fromMap(Map<String, dynamic> map) {
    final dataList = map['data'] as List<dynamic>? ?? [];
    final products = dataList
        .map((item) => ProductModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return ProductsResponse(
      data: products,
      links: PaginationLinks.fromMap(map['links'] as Map<String, dynamic>? ?? {}),
      meta: PaginationMeta.fromMap(map['meta'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// Default products list (fallback when API fails)
List<ProductModel> getDefaultProducts() {
  return [
    ProductModel(
      id: 1,
      name: "Nescafe Classic",
      description: "Premium instant coffee",
      price: 145.0,
      image: 'assets/cafe.png',
      categoryId: 1,
      subcategoryId: 1,
      createdAt: DateTime.now().toIso8601String(),
      rating: 4.5,
      unitType: 'piece',
    ),
    ProductModel(
      id: 2,
      name: "Tat Tomate",
      description: "Fresh tomatoes",
      price: 30.0,
      image: 'assets/tomate.png',
      categoryId: 2,
      subcategoryId: 2,
      createdAt: DateTime.now().toIso8601String(),
      rating: 4.2,
      unitType: 'piece',
    ),
    ProductModel(
      id: 3,
      name: "Fanta",
      description: "Refreshing orange drink",
      price: 30.0,
      image: 'assets/fanta.png',
      categoryId: 2,
      subcategoryId: 2,
      createdAt: DateTime.now().toIso8601String(),
      rating: 4.0,
    ),
    ProductModel(
      id: 4,
      name: "Eggs",
      description: "Fresh eggs",
      price: 245.0,
      image: 'assets/egg.png',
      categoryId: 2,
      subcategoryId: 2,
      createdAt: DateTime.now().toIso8601String(),
      rating: 4.7,
    ),
    ProductModel(
      id: 5,
      name: "Eker",
      description: "Quality product",
      price: 45.0,
      image: 'assets/eker.png',
      categoryId: 2,
      subcategoryId: 2,
      createdAt: DateTime.now().toIso8601String(),
      rating: 4.3,
    ),
    ProductModel(
      id: 6,
      name: "Sugar",
      description: "White sugar",
      price: 45.0,
      image: 'assets/sugar.png',
      categoryId: 2,
      subcategoryId: 2,
      createdAt: DateTime.now().toIso8601String(),
      rating: 4.1,
    ),
    ProductModel(
      id: 7,
      name: "Lays",
      description: "Crispy potato chips",
      price: 345.0,
      image: 'assets/lays.png',
      categoryId: 2,
      subcategoryId: 2,
      createdAt: DateTime.now().toIso8601String(),
      rating: 4.6,
    ),
    ProductModel(
      id: 8,
      name: "Lipton",
      description: "Tea bags",
      price: 345.0,
      image: 'assets/Lipton.png',
      categoryId: 2,
      subcategoryId: 2,
      createdAt: DateTime.now().toIso8601String(),
      rating: 4.4,
    ),
  ];
}
