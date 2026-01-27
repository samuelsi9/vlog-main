import 'package:flutter/material.dart';
import '../Models/menu_item_model.dart';
import '../Models/order_model.dart';

class RestaurantCartItem {
  final MenuItem menuItem;
  int quantity;
  final Map<String, String> selectedVariations; // variationId -> optionId
  final Map<String, double> variationPrices; // variationId -> additional price

  RestaurantCartItem({
    required this.menuItem,
    this.quantity = 1,
    this.selectedVariations = const {},
    this.variationPrices = const {},
  });

  double get basePrice => menuItem.price;
  double get totalVariationPrice =>
      variationPrices.values.fold(0.0, (sum, price) => sum + price);
  double get unitPrice => basePrice + totalVariationPrice;
  double get totalPrice => unitPrice * quantity;
}

class RestaurantCartService extends ChangeNotifier {
  static final RestaurantCartService _instance = RestaurantCartService._internal();
  factory RestaurantCartService() => _instance;
  RestaurantCartService._internal();

  String? _restaurantId;
  final List<RestaurantCartItem> _items = [];

  String? get restaurantId => _restaurantId;
  List<RestaurantCartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  void addItem({
    required MenuItem menuItem,
    int quantity = 1,
    Map<String, String> selectedVariations = const {},
    Map<String, double> variationPrices = const {},
  }) {
    // Vérifier si c'est le même restaurant
    if (_restaurantId != null && _restaurantId != menuItem.restaurantId) {
      // Demander à l'utilisateur s'il veut vider le panier
      clearCart();
    }

    _restaurantId = menuItem.restaurantId;

    // Vérifier si l'item existe déjà avec les mêmes variations
    final existingIndex = _items.indexWhere((item) =>
        item.menuItem.id == menuItem.id &&
        _mapsEqual(item.selectedVariations, selectedVariations));

    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(RestaurantCartItem(
        menuItem: menuItem,
        quantity: quantity,
        selectedVariations: selectedVariations,
        variationPrices: variationPrices,
      ));
    }
    notifyListeners();
  }

  void removeItem(RestaurantCartItem item) {
    _items.remove(item);
    if (_items.isEmpty) {
      _restaurantId = null;
    }
    notifyListeners();
  }

  void updateQuantity(RestaurantCartItem item, int quantity) {
    if (quantity <= 0) {
      removeItem(item);
    } else {
      item.quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _restaurantId = null;
    notifyListeners();
  }

  List<OrderItem> toOrderItems() {
    return _items.map((item) {
      return OrderItem(
        productId: item.menuItem.id,
        name: item.menuItem.name,
        price: item.unitPrice,
        quantity: item.quantity,
        selectedOptions: item.selectedVariations.isNotEmpty 
            ? item.selectedVariations 
            : null,
      );
    }).toList();
  }

  bool _mapsEqual(Map<String, String> map1, Map<String, String> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }
}

