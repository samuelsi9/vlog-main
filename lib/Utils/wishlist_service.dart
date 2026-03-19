import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Models/wishlist_model.dart';

// ─────────────────────────────────────────────
//  Internal error classifier
//  Maps raw ApiException / network errors to friendly user strings.
//  Original dev errors are documented in comments per branch.
// ─────────────────────────────────────────────
String _friendlyError(Object e) {
  final raw = e.toString().toLowerCase();

  // dev: ApiException(statusCode: null, errorCode: null, message: Network/connection error)
  if (raw.contains('network') ||
      raw.contains('connection') ||
      raw.contains('socket') ||
      raw.contains('timeout') ||
      raw.contains('statuscode: null')) {
    return "No internet connection.\nPlease check your network and try again.";
  }

  // dev: ApiException with statusCode 401 / unauthorized
  if (raw.contains('401') || raw.contains('unauthorized')) {
    return "Your session has expired. Please log in again.";
  }

  // dev: ApiException with statusCode 403 / forbidden
  if (raw.contains('403') || raw.contains('forbidden')) {
    return "You don't have permission to do that.";
  }

  // dev: ApiException with statusCode 404
  if (raw.contains('404')) {
    return "We couldn't find what you were looking for.";
  }

  // dev: ApiException with statusCode 500 or generic server error
  if (raw.contains('500') || raw.contains('server')) {
    return "Our servers are having a moment.\nPlease try again shortly.";
  }

  // dev: any other unknown exception – e.toString()
  return "Something went wrong. Please try again.";
}

// ─────────────────────────────────────────────

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
    } catch (e) {
      // dev error: e.toString() — raw exception, never shown directly to user
      _error = _friendlyError(e);
      // rethrow; // ← commented out: was causing unhandled exception overlay in Flutter debugger
    } finally {
      _loading = false;
      notifyListeners();
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
      // dev error: e.toString() — addToWishlist(productId) failed
      _error = _friendlyError(e);
      notifyListeners();
      // rethrow; // ← commented out: was causing unhandled exception overlay in Flutter debugger
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
      // dev error: e.toString() — removeFromWishlist(wishlistId) failed
      _error = _friendlyError(e);
      notifyListeners();
      // rethrow; // ← commented out: was causing unhandled exception overlay in Flutter debugger
    }
  }

  /// Check if a product is in the wishlist by product id.
  bool isInWishlistByProductId(int productId) {
    return _items.any((e) => e.product.id == productId);
  }

  /// Check if a product is in the wishlist. Accepts product id (int) or object with .id.
  bool isInWishlist(dynamic productOrId) {
    if (productOrId == null) return false;
    final id = _productIdFrom(productOrId);
    return id != null && id > 0 && isInWishlistByProductId(id);
  }

  /// Toggle wishlist: add if not present, remove if present. Accepts product id (int) or object with .id.
  Future<void> toggleWishlist(dynamic productOrId) async {
    final id = _productIdFrom(productOrId);
    if (id == null || id <= 0) return;
    if (_togglingProductIds.contains(id)) return; // ignore double-tap

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
