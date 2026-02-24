import 'package:vlog/Models/model.dart';
import 'package:vlog/Models/cart_model.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:flutter/material.dart';

class CartItem {
  final itemModel item;
  int quantity;
  int? cartItemId; // ID from API for deletion
  final String? unitType; // e.g. "kg", "piece" - from product

  CartItem({required this.item, this.quantity = 1, this.cartItemId, this.unitType});

  double get totalPrice => (item.price * quantity).toDouble();
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _cartItems = [];
  final AuthService _authService = AuthService();
  CartModel? _apiCart;
  bool _isLoading = false;
  String? _error;

  List<CartItem> get cartItems => _cartItems;
  CartModel? get apiCart => _apiCart;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice.toDouble());

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await StorageService.isLoggedIn();
  }

  /// Fetch cart from API
  Future<void> fetchCart() async {
    // Check authentication first
    final isAuth = await isAuthenticated();
    if (!isAuth) {
      _error = 'You must be authenticated to view your cart';
      _isLoading = false;
      notifyListeners();
      throw Exception('Authentication required');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cart = await _authService.getCart();
      _apiCart = cart;
      
      // Convert API cart items to local CartItem format for compatibility
      _cartItems.clear();
      for (var apiItem in cart.items) {
        // Create itemModel from CartItemModel
        final item = itemModel(
          name: apiItem.name,
          description: '',
          price: apiItem.price.toInt(),
          categoryId: apiItem.productId,
          image: apiItem.image ?? '',
          rating: 4.0,
          review: '',
          fcolor: [Colors.red, Colors.blue, Colors.green],
          size: ['S', 'M', 'L', 'XL'],
        );
        
        _cartItems.add(CartItem(
          item: item,
          quantity: apiItem.quantity,
          cartItemId: apiItem.id,
          unitType: apiItem.unitType,
        ));
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching cart: $e');
    }
  }

  /// Add product to cart via API using product ID
  /// This is the preferred method when you have the product ID
  Future<void> addToCartByProductId(int productId) async {
    // Check authentication first
    final isAuth = await isAuthenticated();
    if (!isAuth) {
      throw Exception('You must be authenticated to add items to cart');
    }

    try {
      _isLoading = true;
      notifyListeners();

      final cart = await _authService.addToCart(productId);
      _apiCart = cart;
      
      // Update local cart items from API response
      await fetchCart();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error adding to cart by product ID: $e');
      rethrow;
    }
  }

  /// Add product to cart via API (legacy method for itemModel)
  /// Note: This requires productId to be stored in itemModel somehow
  /// For ProductModel, use addToCartByProductId instead
  Future<void> addToCart(itemModel item) async {
    // Check authentication first
    final isAuth = await isAuthenticated();
    if (!isAuth) {
      throw Exception('You must be authenticated to add items to cart');
    }

    try {
      // Try to get product ID from item
      // If itemModel doesn't have productId, we'll need to find it another way
      // For now, we'll use a fallback approach
      debugPrint('⚠️ addToCart(itemModel) called - Consider using addToCartByProductId instead');
      
      // Fallback: Add to local cart if we can't determine product ID
      final existingIndex = _cartItems.indexWhere(
        (cartItem) =>
            cartItem.item.name == item.name && cartItem.item.image == item.image,
      );

      if (existingIndex != -1) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(item: item));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(CartItem cartItem) async {
    // Check authentication first
    final isAuth = await isAuthenticated();
    if (!isAuth) {
      throw Exception('You must be authenticated to remove items from cart');
    }

    try {
      // Use stored cart item ID if available, otherwise try to find it
      int? cartItemId = cartItem.cartItemId;
      
      if (cartItemId == null) {
        // Fallback: Find the API cart item ID by name
        final apiItem = _apiCart?.items.firstWhere(
          (item) => item.name == cartItem.item.name,
          orElse: () => throw Exception('Item not found in API cart'),
        );
        cartItemId = apiItem?.id;
      }

      if (cartItemId != null) {
        await _removeFromCartAPI(cartItemId);
      } else {
        // Fallback to local removal
        _cartItems.remove(cartItem);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      // Fallback to local removal
      _cartItems.remove(cartItem);
      notifyListeners();
    }
  }

  Future<void> _removeFromCartAPI(int cartItemId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final cart = await _authService.removeFromCart(cartItemId);
      _apiCart = cart;
      
      // Update local cart items
      await fetchCart();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error removing from cart: $e');
    }
  }

  Future<void> updateQuantity(CartItem cartItem, int quantity) async {
    // Check authentication first
    final isAuth = await isAuthenticated();
    if (!isAuth) {
      throw Exception('You must be authenticated to update cart items');
    }

    if (quantity <= 0) {
      await removeFromCart(cartItem);
      return;
    }

    try {
      // Use stored cart item ID if available, otherwise try to find it
      int? cartItemId = cartItem.cartItemId;
      
      if (cartItemId == null) {
        // Fallback: Find the API cart item ID by name
        final apiItem = _apiCart?.items.firstWhere(
          (item) => item.name == cartItem.item.name,
          orElse: () => throw Exception('Item not found in API cart'),
        );
        cartItemId = apiItem?.id;
      }

      if (cartItemId != null) {
        await _updateQuantityAPI(cartItemId, quantity);
      } else {
        // Fallback to local update
        cartItem.quantity = quantity;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      // Fallback to local update
      cartItem.quantity = quantity;
      notifyListeners();
    }
  }

  Future<void> _updateQuantityAPI(int cartItemId, int quantity) async {
    try {
      _isLoading = true;
      notifyListeners();

      final cart = await _authService.updateCartItemQuantity(
        cartItemId: cartItemId,
        quantity: quantity,
      );
      _apiCart = cart;
      
      // Update local cart items
      await fetchCart();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating cart quantity: $e');
    }
  }

  void clearCart() {
    _cartItems.clear();
    _apiCart = null;
    notifyListeners();
  }

  bool isInCart(itemModel item) {
    return _cartItems.any(
      (cartItem) =>
          cartItem.item.name == item.name && cartItem.item.image == item.image,
    );
  }

  /// Initialize cart from API on app start
  Future<void> initialize() async {
    await fetchCart();
  }
}
