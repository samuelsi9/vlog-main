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
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      image: map['image'] as String? ?? '',
      categoryId: map['category_id'] as int? ?? 0,
      subcategoryId: map['subcategory_id'] as int? ?? 0,
      createdAt: map['created_at'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.0, // Default to 4.0 if not provided
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
      currentPage: map['current_page'] as int? ?? 1,
      from: map['from'] as int? ?? 1,
      lastPage: map['last_page'] as int? ?? 1,
      path: map['path'] as String? ?? '',
      perPage: map['per_page'] as int? ?? 10,
      to: map['to'] as int? ?? 10,
      total: map['total'] as int? ?? 0,
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
