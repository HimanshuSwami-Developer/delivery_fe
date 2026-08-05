/// DRF's `PageNumberPagination` wraps list responses as
/// `{"count", "next", "previous", "results": [...]}`. A handful of
/// endpoints (search, wishlist, addresses) return a bare list instead —
/// this accepts either.
List<dynamic> extractResults(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  return const [];
}
