import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/pagination.dart';

/// Categories/products/stock — public read (browse/search/PDP), admin
/// write (products/categories/inventory screens). See `catalog/views.py`.
class CatalogRepository {
  CatalogRepository(this._client);

  final ApiClient _client;

  Future<List<ApiCategory>> fetchCategories() async {
    try {
      final response = await _client.dio.get('/categories/');
      return extractResults(response.data).map((e) => ApiCategory.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiCategory> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/categories/', data: data);
      return ApiCategory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// [category]/[subcategory] are the string keys/names the Flutter state
  /// already uses (not numeric ids) — matches `ProductFilter` server-side.
  Future<List<ApiProduct>> fetchProducts({
    String? category,
    String? subcategory,
    String? band,
    String? search,
    String? ordering,
  }) async {
    try {
      final response = await _client.dio.get('/products/', queryParameters: {
        'category': ?category,
        'subcategory': ?subcategory,
        'band': ?band,
        if (search != null && search.isNotEmpty) 'search': search,
        'ordering': ?ordering,
        'page_size': 100,
      });
      return extractResults(response.data).map((e) => ApiProduct.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<ApiProduct>> searchProducts(String query) async {
    try {
      final response = await _client.dio.get('/products/search/', queryParameters: {'q': query});
      return (response.data as List).map((e) => ApiProduct.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiProduct> fetchProduct(int id) async {
    try {
      final response = await _client.dio.get('/products/$id/');
      return ApiProduct.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiProduct> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/products/', data: data);
      return ApiProduct.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiProduct> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.patch('/products/$id/', data: data);
      return ApiProduct.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<ApiProductStock>> fetchStocks({int? zone, int? product}) async {
    try {
      final response = await _client.dio.get('/stocks/', queryParameters: {
        'zone': ?zone,
        'product': ?product,
        'page_size': 200,
      });
      return extractResults(response.data).map((e) => ApiProductStock.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiProductStock> adjustStock(int stockId, int delta) async {
    try {
      final response = await _client.dio.post('/stocks/$stockId/adjust/', data: {'delta': delta});
      return ApiProductStock.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
