/// DRF's `DecimalField` serializes as a JSON *string* by default (e.g.
/// `"4.5"`, not `4.5`) to avoid float rounding surprises — every model
/// backed by one (`Product.rating`, `DeliveryPartner.rating`) needs this
/// instead of a plain `as num?` cast.
double asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
