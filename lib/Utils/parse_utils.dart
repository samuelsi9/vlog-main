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

/// Returns display string for unit (kg→kg, gram/grams→g, piece→piece).
String getDisplayUnit(String? unitType) {
  final u = (unitType ?? '').trim().toLowerCase();
  if (u == 'kg') return 'kg';
  if (u == 'gram' || u == 'grams') return 'g';
  if (u.isEmpty || u == 'piece' || u == 'pcs' || u == 'pc') return 'piece';
  return u;
}

/// Formats quantity with unit for display (e.g. "1kg", "5kg", "500g", "2x" for piece).
String formatQtyWithUnit(int quantity, String? unitType) {
  final u = (unitType ?? '').trim().toLowerCase();
  if (u.isEmpty || u == 'piece' || u == 'pcs' || u == 'pc') {
    return '${quantity}x';
  }
  final display = (u == 'gram' || u == 'grams') ? 'g' : u;
  return '$quantity$display';
}
