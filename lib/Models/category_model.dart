import 'package:vlog/Utils/parse_utils.dart';

// Category Model for API response
class CategoryModel {
  final int id;
  final String name;
  final String image;
  final String createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: parseInt(map['id']),
      name: map['name']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'created_at': createdAt,
    };
  }
}

// Categories Response Model (with pagination)
class CategoriesResponse {
  final List<CategoryModel> data;
  final PaginationLinks links;
  final PaginationMeta meta;

  CategoriesResponse({
    required this.data,
    required this.links,
    required this.meta,
  });

  factory CategoriesResponse.fromMap(Map<String, dynamic> map) {
    final dataList = map['data'] as List<dynamic>? ?? [];
    final categories = dataList
        .map((item) => CategoryModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return CategoriesResponse(
      data: categories,
      links: PaginationLinks.fromMap(map['links'] as Map<String, dynamic>? ?? {}),
      meta: PaginationMeta.fromMap(map['meta'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// Pagination Links Model (reused from product_model if needed, or define here)
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

// Pagination Meta Model (reused from product_model if needed, or define here)
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
      currentPage: parseInt(map['current_page'], 1),
      from: parseInt(map['from'], 1),
      lastPage: parseInt(map['last_page'], 1),
      path: map['path']?.toString() ?? '',
      perPage: parseInt(map['per_page'], 10),
      to: parseInt(map['to'], 10),
      total: parseInt(map['total']),
    );
  }
}

// Legacy FCategoryModel for backward compatibility (kept for existing code)
class FCategoryModel {
  final String name;
  final String image;

  FCategoryModel({required this.name, required this.image});
}

// Default categories fallback
List<FCategoryModel> fcategory = [
  FCategoryModel(name: "Women", image: 'assets/fs.jpg'),
  FCategoryModel(name: "Men", image: 'assets/man.jpg'),
  FCategoryModel(name: "Kids", image: 'assets/kids.jpg'),
  FCategoryModel(name: "Shoes", image: 'assets/shoesa.webp'),
  FCategoryModel(name: "Accessories", image: 'assets/acces.webp'),
];

List<String> filterCategory = [
  "Filter",
  "Rating",
  "Size",
  "Color",
  "Price",
  "Brand",
];
