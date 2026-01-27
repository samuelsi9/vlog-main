import 'package:vlog/Models/model.dart';
import 'package:flutter/material.dart';

class WishlistService extends ChangeNotifier {
  static final WishlistService _instance = WishlistService._internal();
  factory WishlistService() => _instance;
  WishlistService._internal();

  final List<itemModel> _wishlist = [];

  List<itemModel> get wishlist => _wishlist;

  bool isInWishlist(itemModel item) {
    return _wishlist.any(
      (product) => product.name == item.name && product.image == item.image,
    );
  }

  void addToWishlist(itemModel item) {
    if (!isInWishlist(item)) {
      _wishlist.add(item);
      notifyListeners();
    }
  }

  void removeFromWishlist(itemModel item) {
    _wishlist.removeWhere(
      (product) => product.name == item.name && product.image == item.image,
    );
    notifyListeners();
  }

  void toggleWishlist(itemModel item) {
    if (isInWishlist(item)) {
      removeFromWishlist(item);
    } else {
      addToWishlist(item);
    }
  }

  void clearWishlist() {
    _wishlist.clear();
    notifyListeners();
  }
}
