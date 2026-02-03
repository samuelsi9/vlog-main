// services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:vlog/Models/product_model.dart';
import 'package:vlog/Models/product_detail_model.dart';
import 'package:vlog/Models/category_model.dart';
import 'package:vlog/Models/cart_model.dart';
import 'package:vlog/Models/delivery_address_model.dart';
import 'package:vlog/Models/order_history_model.dart';
import 'package:vlog/Models/wishlist_model.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:8000', // Change to your base URL
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
          "phone":"632434556566" ,
         
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
      print('Registration failed: ${e.response?.data}');
      rethrow;
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
      print('Login failed: ${e.response?.data}');
      rethrow;
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

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        'api/auth/forgotpassword',
        data: {'email': email},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } on DioException catch (e) {
      print('Forgot password failed: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unexpected error during forgot password: $e');
      rethrow;
    }
    return {};
  }

  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final response = await _dio.put(
        'api/auth/resetpassword/$resetToken',
        data: {'password': password, 'passwordConfirm': passwordConfirm},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>; // expects token + user
      }
    } on DioException catch (e) {
      print('Reset password failed: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unexpected error during reset password: $e');
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
      // Even if logout fails on server, clear local storage
      await StorageService.clearAll();
      print('Logout failed: ${e.response?.data}');
      rethrow;
    } catch (e) {
      // Even if logout fails, clear local storage
      await StorageService.clearAll();
      print('Unexpected error during logout: $e');
      rethrow;
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
      print('Get products failed: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unexpected error during get products: $e');
      rethrow;
    }
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
      print('Get products by category failed: ${e.response?.data}');
      rethrow;
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
      print('Get product by ID failed: ${e.response?.data}');
      rethrow;
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
      print('Get product detail failed: ${e.response?.data}');
      rethrow;
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
      print('Get categories failed: ${e.response?.data}');
      rethrow;
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
    String? addressType,
    String? nearbyLandmark,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }

      final data = <String, dynamic>{
        'street': street,
        'building_number': buildingNumber,
        'apartment_number': apartmentNumber,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      };
      if (receiverName != null && receiverName.isNotEmpty) data['receiver_name'] = receiverName;
      if (addressType != null && addressType.isNotEmpty) data['address_type'] = addressType;
      if (nearbyLandmark != null && nearbyLandmark.isNotEmpty) data['nearby_landmark'] = nearbyLandmark;

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
      print('Create address failed: ${e.response?.data}');
      rethrow;
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
      if (e.response?.statusCode == 404) return [];
      print('allMyAddresses failed: ${e.response?.data}');
      rethrow;
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
      print('useAddress failed: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unexpected error during useAddress: $e');
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
      print('placeOrder failed: ${e.response?.data}');
      rethrow;
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
      if (e.response?.statusCode == 404) return [];
      print('getAllOrderHistory failed: ${e.response?.data}');
      rethrow;
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
      print('getSingleOrderHistory failed: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('Unexpected error during getSingleOrderHistory: $e');
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
      if (e.response?.statusCode == 404) return WishlistResponse(data: []);
      print('fetchWishlist failed: ${e.response?.data}');
      rethrow;
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
      print('addToWishlist failed: ${e.response?.data}');
      rethrow;
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
      print('removeFromWishlist failed: ${e.response?.data}');
      rethrow;
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
        final data = response.data['data'] as Map<String, dynamic>;
        return CartModel.fromMap(data);
      } else {
        throw Exception('Failed to fetch cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ Get cart failed: ${e.response?.statusCode}');
      print('Error data: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (e.response?.statusCode == 404) {
        // Cart might not exist yet, return empty cart
        return CartModel(
          cartId: 0,
          items: [],
          deliveryFee: 0.0,
          total: 0.0,
        );
      }
      rethrow;
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
      print('❌ Add to cart failed: ${e.response?.statusCode}');
      print('Error data: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      rethrow;
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
      print('❌ Update cart item failed: ${e.response?.statusCode}');
      print('Error data: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      rethrow;
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
      print('❌ Remove from cart failed: ${e.response?.statusCode}');
      print('Error data: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      }
      rethrow;
    } catch (e) {
      print('❌ Unexpected error during remove from cart: $e');
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
