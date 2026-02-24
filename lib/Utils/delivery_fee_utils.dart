/// Tiered delivery fee (commission) calculation.
/// - 1–750 ₺: 355 ₺
/// - 751–1500 ₺: 500 ₺
/// - 1501–2500 ₺: 750 ₺
/// - 2501+ ₺: 25%
const double tierHighPercent = 0.25;

double calculateDeliveryFee(double subtotal) {
  if (subtotal <= 750) {
    return 355;
  }
  if (subtotal <= 1500) {
    return 500;
  }
  if (subtotal <= 2500) {
    return 750;
  }
  return subtotal * tierHighPercent;
}

/// For subtotal > 2500: returns 25 (fixed rate). Null for fixed-fee tiers.
double? getDeliveryFeePercent(double subtotal) {
  if (subtotal <= 2500 || subtotal <= 0) return null;
  return 25;
}
