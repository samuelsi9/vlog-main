import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores recently viewed products for "related products" recommendations.
/// Each entry: { productId: int, categoryId: int }.
/// Used to fetch products in same categories, excluding already-viewed ones.
class RecentlyViewedService {
  static const String _key = 'recently_viewed_products';
  static const int _maxItems = 20;

  /// Add a viewed product. Call when user opens product detail.
  static Future<void> addViewed(int productId, int categoryId) async {
    if (categoryId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final list = _load(prefs);
    // Avoid duplicates: remove existing entry for same productId (if id > 0)
    if (productId > 0) list.removeWhere((e) => e['productId'] == productId);
    list.insert(0, {'productId': productId, 'categoryId': categoryId});
    // Keep most recent
    while (list.length > _maxItems) {
      list.removeLast();
    }
    await prefs.setString(_key, jsonEncode(list));
  }

  /// Get recently viewed entries, most recent first.
  static Future<List<Map<String, int>>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    return _load(prefs);
  }

  static List<Map<String, int>> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => (e as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt())))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
