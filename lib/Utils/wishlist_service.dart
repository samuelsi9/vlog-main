import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Models/wishlist_model.dart';

class WishlistService extends ChangeNotifier {
  static final WishlistService _instance = WishlistService._internal();
  factory WishlistService() => _instance;
  WishlistService._internal();

  List<WishlistItemModel> _items = [];
  bool _loading = false;
  String? _error;
  bool _hasMore = true;
  final Set<int> _togglingProductIds = {};

  List<WishlistItemModel> get wishlist => List.unmodifiable(_items);
  bool get loading => _loading;
  /// True while add/remove for this product is in progress.
  bool isToggling(int productId) => _togglingProductIds.contains(productId);
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// Load wishlist from API (paginated). Call on init or refresh.
  Future<void> fetchWishlist({int page = 1}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final auth = AuthService();
      final response = await auth.fetchWishlist(page: page);
      _items = response.data;
      _hasMore = response.meta != null &&
          response.meta!.currentPage < response.meta!.lastPage;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Add product to wishlist via API. Refreshes list from response.
  Future<void> addToWishlist(int productId) async {
    try {
      final auth = AuthService();
      final response = await auth.addToWishlist(productId);
      _items = response.data;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove wishlist entry by its id (wishlist item id, not product id).
  Future<void> removeFromWishlist(int wishlistId) async {
    try {
      final auth = AuthService();
      await auth.removeFromWishlist(wishlistId);
      _items.removeWhere((e) => e.id == wishlistId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a product is in the wishlist by product id.
  bool isInWishlistByProductId(int productId) {
    return _items.any((e) => e.product.id == productId);
  }

  /// Check if a product is in the wishlist. Accepts product id (int) or object with .id (e.g. ProductModel).
  bool isInWishlist(dynamic productOrId) {
    if (productOrId == null) return false;
    final id = _productIdFrom(productOrId);
    return id != null && id > 0 && isInWishlistByProductId(id);
  }

  /// Toggle wishlist: add if not present, remove if present. Accepts product id (int) or object with .id.
  Future<void> toggleWishlist(dynamic productOrId) async {
    final id = _productIdFrom(productOrId);
    if (id == null || id <= 0) return;
    if (_togglingProductIds.contains(id)) return; // Already toggling, ignore double-tap
    _togglingProductIds.add(id);
    notifyListeners();
    try {
      if (isInWishlistByProductId(id)) {
        final wishlistId = getWishlistIdByProductId(id);
        if (wishlistId != null) await removeFromWishlist(wishlistId);
      } else {
        await addToWishlist(id);
      }
    } finally {
      _togglingProductIds.remove(id);
      notifyListeners();
    }
  }

  static int? _productIdFrom(dynamic productOrId) {
    if (productOrId is int) return productOrId;
    try {
      final id = (productOrId as dynamic).id;
      if (id is int) return id;
    } catch (_) {}
    return null;
  }

  /// Get wishlist item id for a product (for remove). Returns null if not in list.
  int? getWishlistIdByProductId(int productId) {
    try {
      return _items.firstWhere((e) => e.product.id == productId).id;
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
