// services/auth_service.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:vlog/Utils/api_exception.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:vlog/Models/product_model.dart';
import 'package:vlog/Models/product_detail_model.dart';
import 'package:vlog/Models/category_model.dart';
import 'package:vlog/Models/cart_model.dart';
import 'package:vlog/Models/delivery_address_model.dart';
import 'package:vlog/Models/order_history_model.dart';
import 'package:vlog/Models/wishlist_model.dart';
import 'package:vlog/Models/notification_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' as sign_in_with_apple;

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://www.wgraole.com',
       // Change to your base URL
      headers: {'Accept': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  AuthService() {
    // Add interceptor to automatically include token in headers
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Do not attach token for public endpoints (no auth required)
          final path = options.uri.path;
          if (path.contains('users/checkEmail') || path.contains('users/reset-password')) {
            return handler.next(options);
          }

          // Get token from secure storage
          final token = await StorageService.getToken();
          final tokenType = await StorageService.getTokenType();

          // Add Authorization header if token exists
          if (token != null && token.isNotEmpty) {
            final authHeader = tokenType != null
                ? '$tokenType $token'
                : 'Bearer $token';
            options.headers['Authorization'] = authHeader;
            options.headers['Accept'] = 'application/json';
            // Debug: Print token status (remove in production)
            print('🔑 Token added to request: ${options.uri}');
          } else {
            print('⚠️ No token found for request: ${options.uri}');
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 unauthorized - token might be expired
          if (error.response?.statusCode == 401) {
            print('❌ 401 Unauthorized - Token may be expired or invalid');
            // Clear stored token on unauthorized
            await StorageService.clearAll();
          }
          return handler.next(error);
        },
      ),
    );
  }

  String get baseUrl => _dio.options.baseUrl;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        '/api/register',
        data: {
          "name": name,
          "email": email,
          "role_id": role,
          "password": password,
          "phone": phone,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        
        // Extract token and user data from response
        final accessToken = data['access_token'] as String?;
        final tokenType = data['token_type'] as String? ?? 'Bearer';
        final user = data['user'] as Map<String, dynamic>?;

        // Save token and user data to secure storage
        if (accessToken != null && accessToken.isNotEmpty) {
          await StorageService.saveToken(accessToken);
          await StorageService.saveTokenType(tokenType);

          if (user != null) {
            await StorageService.saveUser(user);
          }
        }

        print('Registration successful: $user');
        return data; // Return full response with token and user
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error: $e');
      rethrow;
    }
    return {};
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Extract token and user data from response
        final accessToken = data['access_token'] as String?;
        final tokenType = data['token_type'] as String? ?? 'Bearer';
        final user = data['user'] as Map<String, dynamic>?;

        // Save token and user data to secure storage
        if (accessToken != null && accessToken.isNotEmpty) {
          await StorageService.saveToken(accessToken);
          await StorageService.saveTokenType(tokenType);

          if (user != null) {
            await StorageService.saveUser(user);
          }
        }

        return data; // { access_token, token_type, user }
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during login: $e');
      rethrow;
    }
    return {};
  }

  /// Returns the provider initiation URL (e.g., GET /auth/google)
  String getOAuthInitiationUrl(String provider) {
    return '${_dio.options.baseUrl}/api/auth/$provider';
  }

  /// Checks if the given email exists. Returns map with [exists] (bool) and [message] (String).
  /// Call POST /api/users/checkEmail with body { "email": email }.
  /// Never throws: on network/API error returns {} so caller can show a message.
  Future<Map<String, dynamic>> checkEmail({required String email}) async {
    try {
      final response = await _dio.post(
        '/api/checkEmail',
        data: {'email': email},
      );
      print('checkEmail statusCode: ${response.statusCode}, data: ${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) {
          return raw;
        }
        if (raw is Map) {
          return Map<String, dynamic>.from(raw);
        }
        print('checkEmail unexpected type: ${raw.runtimeType}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e, stack) {
      print('Unexpected error during check email: $e');
      print('$stack');
      return {};
    }
    return {};
  }

  /// Reset password with email (no token). POST api/users/reset-password.
  /// Body: email, password, password_confirmation.
  /// Success response: { "message": "Password updated successfully" }.
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        '/api/reset-password',
        data: {
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) return raw;
        if (raw is Map) return Map<String, dynamic>.from(raw);
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e, stack) {
      print('Unexpected error during reset password: $e');
      print('$stack');
      rethrow;
    }
    return {};
  }

  Future<String> logout() async {
    try {
      // Token will be automatically included via interceptor
      await _dio.post('/api/logout');

      // Clear stored token and user data after successful logout
      await StorageService.clearAll();

      return "Logged out successfully";
    } on DioException catch (e) {
      await StorageService.clearAll();
      ApiErrorHandler.handle(e);
    } catch (e) {
      // Even if logout fails, clear local storage
      await StorageService.clearAll();
      print('Unexpected error during logout: $e');
      rethrow;
    }
  }

  /// Max avatar file size in bytes (2048 KB = 2 MB).
  static const int _maxAvatarSizeBytes = 2048 * 1024;

  /// Upload user avatar. POST /api/users/me/avatar with auth token.
  /// [file] - Image file (must be <= 2048 KB).
  /// Returns { "message": "Avatar updated successfully", "avatar": "https://..." }.
  /// Throws if file size > 2048 KB with message about allowed size.
  Future<Map<String, dynamic>> uploadAvatar(File file) async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please log in first.');
    }

    final fileLength = await file.length();
    if (fileLength > _maxAvatarSizeBytes) {
      throw Exception(
        'Image size must be 2048 KB or less. Your image is ${(fileLength / 1024).toStringAsFixed(0)} KB.',
      );
    }

    try {
      final filename = file.path.split(RegExp(r'[/\\]')).last;
      if (filename.isEmpty) {
        throw Exception('Invalid file path');
      }

      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          file.path,
          filename: filename,
        ),
      });

      final response = await _dio.post(
        '/api/users/me/avatar',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return data;
        }
        return {'message': 'Avatar updated successfully', 'avatar': null};
      }
      throw Exception('Failed to upload avatar: ${response.statusCode}');
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to upload avatar: $e');
    }
  }

  /// Fetch products with pagination
  /// [page] - Page number (default: 1)
  /// Returns ProductsResponse with data, links, and meta
  Future<ProductsResponse> getProducts({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/api/products',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ProductsResponse.fromMap(data);
      } else {
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during get products: $e');
      rethrow;
    }
  }

  /// Fetches all products by requesting every page (API uses paginate(10)).
  /// Returns a single list of all products.
  Future<List<ProductModel>> getAllProducts() async {
    final all = <ProductModel>[];
    int page = 1;
    int lastPage = 1;
    do {
      final response = await getProducts(page: page);
      all.addAll(response.data);
      lastPage = response.meta.lastPage;
      page++;
    } while (page <= lastPage);
    return all;
  }

  /// Fetch products by category
  /// [categoryId] - Category ID to filter by
  /// [page] - Page number (default: 1)
  Future<ProductsResponse> getProductsByCategory({
    required int categoryId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/api/products',
        queryParameters: {
          'category_id': categoryId,
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ProductsResponse.fromMap(data);
      } else {
        throw Exception('Failed to fetch products by category: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during get products by category: $e');
      rethrow;
    }
  }

  /// Fetch single product by ID
  /// [productId] - Product ID
  Future<ProductModel> getProductById(int productId) async {
    try {
      final response = await _dio.get('/api/products/$productId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ProductModel.fromMap(data);
      } else {
        throw Exception('Failed to fetch product: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during get product by ID: $e');
      rethrow;
    }
  }

  /// Fetch product details by ID for detail screen
  /// [productId] - Product ID
  /// Returns ProductDetailModel with default rating
  Future<ProductDetailModel> getProductDetail(int productId) async {
    try {
      final response = await _dio.get('/api/products/$productId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ProductDetailModel.fromMap(data);
      } else {
        throw Exception('Failed to fetch product details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during get product detail: $e');
      rethrow;
    }
  }

  // ================= CATEGORY API METHODS =================

  /// Fetch categories with pagination
  /// [page] - Page number (default: 1)
  /// Returns CategoriesResponse with data, links, and meta
  Future<CategoriesResponse> getCategories({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/api/categories',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return CategoriesResponse.fromMap(data);
      } else {
        throw Exception('Failed to fetch categories: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during get categories: $e');
      rethrow;
    }
  }

  // ================= ADDRESS API =================

  /// Create a new address for the authenticated user.
  /// [street], [buildingNumber], [apartmentNumber], [city] are required.
  /// [latitude], [longitude] are optional; [isDefault] defaults to false.
  /// Uses the user's token via AuthService interceptor.
  Future<Map<String, dynamic>> createAddress({
    required String street,
    required String buildingNumber,
    required String apartmentNumber,
    required String city,
    required double latitude,
    required double longitude,
    bool isDefault = false,
    String? receiverName,
    String? label,
    String? addressType,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }

      // Use label (e.g. address type: Home, Office, Friend's house) for the API label field
      final labelValue = label ?? addressType ?? "Home";
      final data = <String, dynamic>{
        'street': "none for now",
        'building_number': buildingNumber,
        'apartment_number': "none for now",
        'city': "lefkosia",
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
        'label': labelValue,
      };
      if (receiverName != null && receiverName.isNotEmpty) data['receiver_name'] = receiverName;
      if (addressType != null && addressType.isNotEmpty) data['address_type'] = addressType;

      final response = await _dio.post(
        '/api/addresses',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        return data;
      } else {
        throw Exception('Failed to create address: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during create address: $e');
      rethrow;
    }
  }

  /// Get list of addresses for the authenticated user.
  Future<List<DeliveryAddressModel>> getAddresses() async {
    return allMyAddresses();
  }

  /// Fetches all addresses for the current user from GET /api/addresses.
  /// Response shape: { "data": [ { id, user_id, street, building_number, apartment_number, city, is_default, latitude, longitude, label, created_at, updated_at } ] }
  Future<List<DeliveryAddressModel>> allMyAddresses() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }
      final response = await _dio.get('/api/addresses');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          final list = data['data'] as List;
          return list
              .map((e) => DeliveryAddressModel.fromApiMap(
                  e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
              .toList();
        }
        if (data is List) {
          final list = data;
          return list
              .map((e) => DeliveryAddressModel.fromApiMap(
                  e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
              .toList();
        }
        return [];
      }
      return [];
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during allMyAddresses: $e');
      rethrow;
    }
  }

  /// Marks an address as "in use" (default for delivery).
  /// Calls PUT /api/addresses/{id}/use with the user's auth token.
  Future<void> useAddress(String id) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }
      final response = await _dio.post('/api/addresses/$id/use');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to set address as default: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during useAddress: $e');
      rethrow;
    }
  }

  /// Deletes an address. DELETE /api/addresses/{id}.
  /// Returns response data, e.g. { "message": "Address deleted successfully" }.
  Future<Map<String, dynamic>> deleteAddress(String id) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }
      final response = await _dio.delete('/api/addresses/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete address: ${response.statusCode}');
      }
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return <String, dynamic>{};
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during deleteAddress: $e');
      rethrow;
    }
  }

  // ================= ORDERS API =================

  /// Place an order. POST /api/orders with auth token.
  /// Body: address_id (int), payment_method (e.g. "cash_on_delivery"), delivery_time (e.g. "11:00-12:00").
  /// Returns { "message": "Order placed successfully", "order": { id, subtotal, delivery_fee, grand_total, status, payment_method, payment_status, delivery_time } }
  Future<Map<String, dynamic>> placeOrder({
    required int addressId,
    required String paymentMethod,
    required String deliveryTime,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }
      final response = await _dio.post(
        '/api/orders',
        data: {
          'address_id': addressId,
          'payment_method': paymentMethod,
          'delivery_time': deliveryTime,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) return data;
        return <String, dynamic>{};
      }
      throw Exception('Failed to place order: ${response.statusCode}');
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during placeOrder: $e');
      rethrow;
    }
  }

  /// Fetches all order history for the current user. GET /api/orders with auth token.
  /// Response: { "data": [ { id, total_amount, status, payment_method, payment_status, delivery_fee, grand_total, created_at, items: [...] } ] }
  Future<List<AllOrderHistoryModel>> getAllOrderHistory() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }
      final response = await _dio.get('/api/orders');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          final list = data['data'] as List;
          return list
              .map((e) => AllOrderHistoryModel.fromMap(
                  e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
              .toList();
        }
        if (data is List) {
          final list = data;
          return list
              .map((e) => AllOrderHistoryModel.fromMap(
                  e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
              .toList();
        }
        return [];
      }
      return [];
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during getAllOrderHistory: $e');
      rethrow;
    }
  }

  /// Fetches a single order by id. GET /api/orders/{id} with auth token.
  /// Response: { id, status, subtotal, delivery_fee, total, delivery_date, delivery_time, created_at, items: [...] }
  Future<SingleOrderHistoryModel> getSingleOrderHistory(String orderId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }
      final response = await _dio.get('/api/orders/$orderId');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return SingleOrderHistoryModel.fromMap(data);
        }
        throw Exception('Invalid order response');
      }
      throw Exception('Failed to fetch order: ${response.statusCode}');
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during getSingleOrderHistory: $e');
      rethrow;
    }
  }

  /// Cancels an order. POST http://127.0.0.1:8000/api/orders/{id}/cancel
  /// Response: { "message": "Order cancelled successfully", "order": { "id": 3, "status": "cancelled" } }
  /// Returns the response body so the UI can update local state immediately.
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }
      final response = await _dio.post('/api/orders/$orderId/cancel');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to cancel order: ${response.statusCode}');
      }
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {'message': 'Order cancelled successfully', 'order': {'id': int.tryParse(orderId), 'status': 'cancelled'}};
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during cancelOrder: $e');
      rethrow;
    }
  }

  // ================= WISHLIST API =================

  /// Fetches wishlist for the current user. GET /api/wishlist?page=1 with auth token.
  /// Response: { data: [...], links, meta } (paginated).
  Future<WishlistResponse> fetchWishlist({int page = 1}) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }
      final response = await _dio.get(
        '/api/wishlist',
        queryParameters: {'page': page},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return WishlistResponse.fromMap(data);
        }
        return WishlistResponse(data: []);
      }
      return WishlistResponse(data: []);
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during fetchWishlist: $e');
      rethrow;
    }
  }

  /// Adds a product to wishlist. POST /api/wishlist with body { product_id: productId }.
  /// Returns paginated wishlist response.
  Future<WishlistResponse> addToWishlist(int productId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }
      final response = await _dio.post(
        '/api/wishlist',
        data: {'product_id': productId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return WishlistResponse.fromMap(data);
        }
        return WishlistResponse(data: []);
      }
      throw Exception('Failed to add to wishlist: ${response.statusCode}');
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during addToWishlist: $e');
      rethrow;
    }
  }

  /// Removes an item from wishlist. DELETE /api/wishlist/{wishlistId}.
  /// Response: { message, deleted_id }.
  Future<void> removeFromWishlist(int wishlistId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }
      final response = await _dio.delete('/api/wishlist/$wishlistId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove from wishlist: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during removeFromWishlist: $e');
      rethrow;
    }
  }

  // ================= CART API METHODS =================

  /// Get user's cart
  /// Returns CartModel with items, delivery fee, and total
  Future<CartModel> getCart() async {
    try {
      // Verify token exists before making request
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }

      final response = await _dio.get(
        '/api/cart',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final raw = response.data['data'];
        Map<String, dynamic> data;
        if (raw is Map) {
          data = raw as Map<String, dynamic>;
          if (data['cart'] is Map) {
            data = data['cart'] as Map<String, dynamic>;
          }
        } else {
          data = <String, dynamic>{};
        }
        return CartModel.fromMap(data);
      } else {
        throw Exception('Failed to fetch cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('❌ Unexpected error during get cart: $e');
      rethrow;
    }
  }

  /// Add product to cart
  /// [productId] - Product ID to add
  /// Returns updated CartModel
  Future<CartModel> addToCart(int productId) async {
    try {
      // Verify token exists before making request
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }

      final response = await _dio.post(
        '/api/cart',
        data: {'product_id': productId},
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>;
        return CartModel.fromMap(data);
      } else {
        throw Exception('Failed to add to cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('❌ Unexpected error during add to cart: $e');
      rethrow;
    }
  }

  /// Update cart item quantity
  /// [cartItemId] - Cart item ID to update
  /// [quantity] - New quantity (must be > 0)
  /// Returns updated CartModel
  Future<CartModel> updateCartItemQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      if (quantity < 1) {
        throw Exception('Quantity must be at least 1');
      }

      // Verify token exists before making request
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }

      final response = await _dio.put(
        '/api/cart/$cartItemId',
        data: {'quantity': quantity},
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return CartModel.fromMap(data);
      } else {
        throw Exception('Failed to update cart item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('❌ Unexpected error during update cart item: $e');
      rethrow;
    }
  }

  /// Remove item from cart
  /// [cartItemId] - Cart item ID to remove
  /// Returns updated CartModel
  Future<CartModel> removeFromCart(int cartItemId) async {
    try {
      // Verify token exists before making request
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }

      final response = await _dio.delete(
        '/api/cart/$cartItemId',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return CartModel.fromMap(data);
      } else {
        throw Exception('Failed to remove from cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('❌ Unexpected error during remove from cart: $e');
      rethrow;
    }
  }

  // ================= NOTIFICATIONS API =================

  /// Fetches user notifications. GET /api/usernotify with auth token.
  /// Response: { "notifications": [ { id, title, message, order_id, read_at, created_at } ] }
  Future<List<NotificationModel>> viewNotification() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return [];
      }
      final response = await _dio.get('/api/usernotify');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['notifications'] is List) {
          final list = data['notifications'] as List;
          return list
              .map((e) => NotificationModel.fromMap(
                  e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
              .toList();
        }
        return [];
      }
      return [];
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during viewNotification: $e');
      rethrow;
    }
  }

  /// Marks a notification as read. POST /api/notify/{id}/read with auth token.
  Future<void> markAsRead(String notificationId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }
      final response = await _dio.post('/api/notify/$notificationId/read');
      if (response.statusCode != 200 && response.statusCode != 204) {
        print('markAsRead unexpected status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Unexpected error during markAsRead: $e');
      rethrow;
    }
  }
  

  /// POST token (Google id_token) to backend. Body: { "token": idToken }. Response same format as register.
  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final baseUrl = AuthService().baseUrl;
    final url = '$baseUrl/api/googlelogin';
    try {
      final dio = Dio(BaseOptions(
        headers: {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final response = await dio.post(
        url,
        data: {'token': idToken},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        print('========== Google Login API response ==========');
        print('access_token: ${data['access_token']}');
        print('token_type: ${data['token_type']}');
        print('user: ${data['user']}');
        print('Full response: $data');
        print('================================================');
        return data;
      }
      print('Google login unexpected status: ${response.statusCode}');
      return response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Google login API error: $e');
      rethrow;
    }
  }

  /// Google Sign-In: gets id_token, sends to backend, prints user info and API response in console.
  static Future<void> signInWithGoogle() async {
  try {
    // Use WEB CLIENT ID here (NOT iOS client ID)
    await GoogleSignIn.instance.initialize(
      serverClientId: '626509355552-6ind67045ui3ap5p0rjfjp9bcub09jm5.apps.googleusercontent.com',
    );

    final GoogleSignInAccount user =
        await GoogleSignIn.instance.authenticate();

    final String? idToken = user.authentication.idToken;

    print('========== Google Sign-In ==========');
    print('Name:  ${user.displayName}');
    print('Email: ${user.email}');
    print('Id:    ${user.id}');
    print('Photo: ${user.photoUrl}');
    print('ID Token (full, as sent):');
    final String tokenStr = idToken ?? '(null)';
    const int chunkSize = 200;
    for (int i = 0; i < tokenStr.length; i += chunkSize) {
    final end = (i + chunkSize < tokenStr.length) ? i + chunkSize : tokenStr.length;
     print(tokenStr.substring(i, end));
    }
    print('====================================');

    if (idToken == null || idToken.isEmpty) {
      throw Exception('ID Token is null');
    }

    final Map<String, dynamic> apiResponse = await googleLogin(idToken);
    if (apiResponse.isNotEmpty) {
      final accessToken = apiResponse['access_token'] as String?;
      final tokenType = apiResponse['token_type'] as String? ?? 'Bearer';
      final userData = apiResponse['user'] as Map<String, dynamic>?;
      if (accessToken != null && accessToken.isNotEmpty) {
        await StorageService.saveToken(accessToken);
        await StorageService.saveTokenType(tokenType);
        if (userData != null) {
          await StorageService.saveUser(userData);
        }
      }
    }
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) {
      print('Google Sign-In canceled');
    } else {
      print('Google Sign-In error: $e');
    }
  } catch (e) {
    print('Google Sign-In error: $e');
    rethrow;
    }
  }

  /// Apple Sign-In: sends identity_token to Laravel backend.
  /// Backend should verify token with Apple, create/find user, return { access_token, token_type, user }.
  /// Body: { identity_token, authorization_code?, email?, name? }
  static Future<Map<String, dynamic>> appleLogin({
    required String identityToken,
    String? authorizationCode,
    String? email,
    String? name,
  }) async {
    final baseUrl = AuthService().baseUrl;
    final url = '$baseUrl/api/applelogin';
    try {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final data = <String, dynamic>{
        'identity_token': identityToken,
        if (authorizationCode != null) 'authorization_code': authorizationCode,
        if (email != null && email.isNotEmpty) 'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
      };
      final response = await dio.post(url, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {};
      }
      return response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};
    } on DioException catch (e) {
      ApiErrorHandler.handle(e);
    } catch (e) {
      print('Apple login API error: $e');
      rethrow;
    }
    return {};
  }

  /// Sign in with Apple: gets credential, sends to Laravel, saves token and navigates.
  static Future<void> signInWithApple() async {
    try {
      final credential = await sign_in_with_apple.SignInWithApple.getAppleIDCredential(
        scopes: [
          sign_in_with_apple.AppleIDAuthorizationScopes.email,
          sign_in_with_apple.AppleIDAuthorizationScopes.fullName,
        ],
      );
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Apple identity token is empty');
      }
      final name = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      final email = credential.email;
      final apiResponse = await appleLogin(
        identityToken: identityToken,
        authorizationCode: credential.authorizationCode,
        email: email?.isNotEmpty == true ? email : null,
        name: name.isNotEmpty ? name : null,
      );
      if (apiResponse.isNotEmpty) {
        final accessToken = apiResponse['access_token'] as String?;
        final tokenType = apiResponse['token_type'] as String? ?? 'Bearer';
        final userData = apiResponse['user'] as Map<String, dynamic>?;
        if (accessToken != null && accessToken.isNotEmpty) {
          await StorageService.saveToken(accessToken);
          await StorageService.saveTokenType(tokenType);
          if (userData != null) {
            await StorageService.saveUser(userData);
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Clear entire cart
  /// Returns empty CartModel
  // Future<CartModel> clearCart() async {
  //   try {
  //     final response = await _dio.delete('/api/cart');

  //     if (response.statusCode == 200) {
  //       // Return empty cart
  //       return CartModel(
  //         cartId: 0,
  //         items: [],
  //         deliveryFee: 0.0,
  //         total: 0.0,
  //       );
  //     } else {
  //       throw Exception('Failed to clear cart: ${response.statusCode}');
  //     }
  //   } on DioException catch (e) {
  //     print('Clear cart failed: ${e.response?.data}');
  //     rethrow;
  //   } catch (e) {
  //     print('Unexpected error during clear cart: $e');
  //     rethrow;
  //   }
  // }
}
