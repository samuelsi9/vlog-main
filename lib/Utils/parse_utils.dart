/// Safe parsing for JSON values from Laravel/API (handles int, double, or string).
library;

double parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int parseInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Formats quantity with unit for display (e.g. "1kg", "5kg", "2x" for piece).
String formatQtyWithUnit(int quantity, String? unitType) {
  final u = (unitType ?? '').trim().toLowerCase();
  if (u.isEmpty || u == 'piece' || u == 'pcs' || u == 'pc') {
    return '${quantity}x';
  }
  return '$quantity$u';
}
