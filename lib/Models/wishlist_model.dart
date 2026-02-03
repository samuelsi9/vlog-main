import 'package:vlog/Models/product_model.dart';

/// Single wishlist entry from GET /api/wishlist (data array item).
class WishlistItemModel {
  final int id;
  final String? createdAt;
  final ProductModel product;

  WishlistItemModel({
    required this.id,
    this.createdAt,
    required this.product,
  });

  factory WishlistItemModel.fromMap(Map<String, dynamic> map) {
    final productMap = map['product'];
    final product = productMap is Map<String, dynamic>
        ? ProductModel.fromMap(productMap)
        : ProductModel(
            id: 0,
            name: '',
            description: '',
            price: 0.0,
            image: '',
            categoryId: 0,
            subcategoryId: 0,
            createdAt: '',
          );

    return WishlistItemModel(
      id: (map['id'] ?? 0) as int,
      createdAt: map['created_at']?.toString(),
      product: product,
    );
  }
}

/// Paginated wishlist response: { data, links, meta }.
class WishlistResponse {
  final List<WishlistItemModel> data;
  final WishlistLinks? links;
  final WishlistMeta? meta;

  WishlistResponse({
    required this.data,
    this.links,
    this.meta,
  });

  factory WishlistResponse.fromMap(Map<String, dynamic> map) {
    final dataList = map['data'];
    final list = dataList is List
        ? (dataList)
            .map((e) => WishlistItemModel.fromMap(
                e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
            .toList()
        : <WishlistItemModel>[];

    return WishlistResponse(
      data: list,
      links: map['links'] is Map<String, dynamic>
          ? WishlistLinks.fromMap(map['links'] as Map<String, dynamic>)
          : null,
      meta: map['meta'] is Map<String, dynamic>
          ? WishlistMeta.fromMap(map['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class WishlistLinks {
  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  WishlistLinks({this.first, this.last, this.prev, this.next});

  factory WishlistLinks.fromMap(Map<String, dynamic> map) {
    return WishlistLinks(
      first: map['first']?.toString(),
      last: map['last']?.toString(),
      prev: map['prev']?.toString(),
      next: map['next']?.toString(),
    );
  }
}

class WishlistMeta {
  final int currentPage;
  final int from;
  final int lastPage;
  final String path;
  final int perPage;
  final int to;
  final int total;

  WishlistMeta({
    required this.currentPage,
    required this.from,
    required this.lastPage,
    required this.path,
    required this.perPage,
    required this.to,
    required this.total,
  });

  factory WishlistMeta.fromMap(Map<String, dynamic> map) {
    return WishlistMeta(
      currentPage: (map['current_page'] ?? 1) as int,
      from: (map['from'] ?? 1) as int,
      lastPage: (map['last_page'] ?? 1) as int,
      path: map['path']?.toString() ?? '',
      perPage: (map['per_page'] ?? 10) as int,
      to: (map['to'] ?? 0) as int,
      total: (map['total'] ?? 0) as int,
    );
  }
}
