/// DRF's `PageNumberPagination` wraps list responses as
/// `{"count", "next", "previous", "results": [...]}`. A handful of
/// endpoints (search, wishlist, addresses) return a bare list instead —
/// this accepts either.
List<dynamic> extractResults(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['results'] is List) return data['results'] as List;
  return const [];
}

/// A single page of [T], plus enough of DRF's pagination envelope
/// (`count`/`next`/`previous`) for a caller to drive real page-by-page
/// navigation instead of just flattening every page into one big list.
class PagedResult<T> {
  const PagedResult({required this.items, required this.count, required this.hasNext, required this.hasPrevious});

  final List<T> items;
  final int count;
  final bool hasNext;
  final bool hasPrevious;
}

PagedResult<T> extractPaged<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
  if (data is List) {
    final items = data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    return PagedResult(items: items, count: items.length, hasNext: false, hasPrevious: false);
  }
  if (data is Map) {
    final items = (data['results'] as List? ?? const []).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    return PagedResult(
      items: items,
      count: data['count'] as int? ?? items.length,
      hasNext: data['next'] != null,
      hasPrevious: data['previous'] != null,
    );
  }
  return PagedResult(items: <T>[], count: 0, hasNext: false, hasPrevious: false);
}
