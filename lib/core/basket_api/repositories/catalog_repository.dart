import 'package:dio/dio.dart';
import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/pagination.dart';

/// Categories/products/stock — public read (browse/search/PDP), admin
/// write (products/categories/inventory screens). See `catalog/views.py`.
class CatalogRepository {
  CatalogRepository(this._client);

  final ApiClient _client;

  /// Uploads an image file straight to Cloudinary (`ImageUploadView` —
  /// admin-only) and returns its `secure_url`. This is the *only* way
  /// photos get into the app now — every admin form that needs a photo
  /// (category/product/banner) uploads through here first, then saves the
  /// returned URL, instead of taking a hand-typed image URL.
  Future<String> uploadImage(List<int> bytes, String filename) async {
    try {
      final form = FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: filename)});
      final response = await _client.dio.post('/images/upload/', data: form);
      return response.data['url'] as String;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

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

  /// [key] is the category's slug — `CategoryViewSet.lookup_field = "key"`,
  /// not the numeric id.
  Future<ApiCategory> updateCategory(String key, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.patch('/categories/$key/', data: data);
      return ApiCategory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteCategory(String key) async {
    try {
      await _client.dio.delete('/categories/$key/');
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<ApiSubcategory>> fetchSubcategories({int? categoryId}) async {
    try {
      final response = await _client.dio.get('/subcategories/', queryParameters: {'category': ?categoryId});
      return extractResults(response.data).map((e) => ApiSubcategory.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiSubcategory> createSubcategory(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/subcategories/', data: data);
      return ApiSubcategory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiSubcategory> updateSubcategory(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.patch('/subcategories/$id/', data: data);
      return ApiSubcategory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteSubcategory(int id) async {
    try {
      await _client.dio.delete('/subcategories/$id/');
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

  Future<ApiProduct> setProductActive(int id, bool isActive) async {
    try {
      final response = await _client.dio.patch('/products/$id/', data: {'is_active': isActive});
      return ApiProduct.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _client.dio.delete('/products/$id/');
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Attaches an already-uploaded (Cloudinary) photo to a product's PDP
  /// gallery — separate from `main_image_url`, which stays the card/list
  /// photo. [order] controls its position in the gallery slider.
  Future<ApiProductImage> addProductImage(int productId, String imageUrl, {int order = 0}) async {
    try {
      final response = await _client.dio.post('/product-images/', data: {
        'product': productId,
        'image_url': imageUrl,
        'order': order,
      });
      return ApiProductImage.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteProductImage(int imageId) async {
    try {
      await _client.dio.delete('/product-images/$imageId/');
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// [state] is 'healthy' | 'low' | 'out_of_stock'. [ordering] is any of
  /// `ProductStockViewSet.ordering_fields` (prefix with '-' to reverse),
  /// e.g. 'on_hand' or '-on_hand'.
  Future<PagedResult<ApiProductStock>> fetchStocks({
    String? category,
    String? state,
    String? search,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.dio.get('/stocks/', queryParameters: {
        'category': ?category,
        'state': ?state,
        if (search != null && search.isNotEmpty) 'search': search,
        'ordering': ?ordering,
        'page': page,
        'page_size': pageSize,
      });
      return extractPaged(response.data, (e) => ApiProductStock.fromJson(e));
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Totals across *every* stock row, ignoring whatever category/state/
  /// search filter and page the table itself is currently showing — see
  /// `ProductStockViewSet.summary`.
  Future<StockSummary> fetchStocksSummary() async {
    try {
      final response = await _client.dio.get('/stocks/summary/');
      return StockSummary.fromJson(response.data as Map<String, dynamic>);
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

  /// One review per (product, user) — server-enforced. Use [updateReview]
  /// once the signed-in user already has one for this product (see
  /// `BasketCubit.submitProductReview`, which decides which to call).
  Future<ApiProductReview> submitReview({required int productId, required int rating, String comment = ''}) async {
    try {
      final response = await _client.dio.post('/reviews/', data: {
        'product': productId,
        'rating': rating,
        'comment': comment,
      });
      return ApiProductReview.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiProductReview> updateReview(int reviewId, {required int rating, String comment = ''}) async {
    try {
      final response = await _client.dio.patch('/reviews/$reviewId/', data: {
        'rating': rating,
        'comment': comment,
      });
      return ApiProductReview.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
