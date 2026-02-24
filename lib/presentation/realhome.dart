import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Models/category_model.dart';
import 'package:vlog/Models/model.dart';
import 'package:vlog/Models/product_model.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:vlog/Utils/cart_service.dart';
import 'package:vlog/Utils/wishlist_service.dart';
import 'package:vlog/presentation/category_items.dart';
import 'package:vlog/presentation/screen/detail_screen.dart';
import 'package:vlog/presentation/screen/cart_page.dart';
import 'package:vlog/presentation/screen/search_page.dart';
class _BannerSlide {
  final String image;
  final String label;
  final String title;
  const _BannerSlide({required this.image, required this.label, required this.title});
}

// Smooth page transition utility
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final AxisDirection direction;

  SmoothPageRoute({required this.child, this.direction = AxisDirection.left})
    : super(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => child,
      );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: _getBeginOffset(), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  Offset _getBeginOffset() {
    switch (direction) {
      case AxisDirection.up:
        return const Offset(0, 1);
      case AxisDirection.down:
        return const Offset(0, -1);
      case AxisDirection.right:
        return const Offset(-1, 0);
      case AxisDirection.left:
        return const Offset(1, 0);
    }
  }
}

class Realhome extends StatefulWidget {
  const Realhome({super.key});

  @override
  State<Realhome> createState() => _RealhomeState();
}

class _RealhomeState extends State<Realhome> {
  // Beautiful red gradient colors
  static const Color primaryColor = Color(0xFFE53E3E);
  static const Color primaryColorLight = Color(0xFFFC8181);
  static const Color uberBlack = Color(0xFF000000);
  static const Color _appBarColor = Color(0xFF1E3A5F); // dark blue
  static const List<Color> _categoryColors = [
    Color(0xFFFFCDD2), // soft red
    Color(0xFFBBDEFB), // soft blue
    Color(0xFFC8E6C9), // soft green
    Color(0xFFFFE0B2), // soft amber
    Color(0xFFE1BEE7), // soft purple
    Color(0xFFB2EBF2), // soft cyan
    Color(0xFFFFCC80), // soft orange
    Color(0xFFF8BBD9), // soft pink
  ];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerPageController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  static const List<_BannerSlide> _bannerSlides = [
    _BannerSlide(image: 'assets/home0.jpg', label: 'Special Offer', title: 'Up to 40% Off\nFresh Groceries'),
    _BannerSlide(image: 'assets/home1.jpg', label: 'Fresh Deals', title: 'Up to 30% Off\nDaily Essentials'),
    _BannerSlide(image: 'assets/home2.jpg', label: 'Autumn Fresh', title: 'Up to 35% Off\nOrganic Produce'),
    _BannerSlide(image: 'assets/home3.jpg', label: 'Best Sellers', title: 'Up to 25% Off\nPopular Items'),
    _BannerSlide(image: 'assets/home4.jpg', label: 'Weekend Sale', title: 'Up to 50% Off\nSelect Products'),
    _BannerSlide(image: 'assets/home5.jpg', label: 'New Arrivals', title: 'Up to 20% Off\nLatest Products'),
    _BannerSlide(image: 'assets/home6.jpg', label: 'Hot Deals', title: 'Up to 45% Off\nFresh Groceries'),
    _BannerSlide(image: 'assets/home7.jpg', label: 'Autumn Fresh Deals', title: 'Up to 40% Off\nFresh Groceries'),
    _BannerSlide(image: 'assets/home8.jpg', label: 'Limited Time', title: 'Up to 40% Off\nFresh Groceries'),
  ];

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  bool _hasError = false;
  bool _hasCategoryError = false;

  // Pagination: use current_page and last_page from API (Laravel paginate(10))
  int _currentPage = 0;
  int _lastPage = 1;
  bool _isLoadingMore = false;

  // Loading indicator when adding product to cart
  int? _addingProductId;

  String _userDisplayName = 'Guest';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
    _scrollController.addListener(_onScroll);
    _loadUserName();
    _fetchProducts();
    _fetchCategories();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerPageController.addListener(() {
      final page = _bannerPageController.page;
      if (page != null && mounted) {
        final idx = page.round().clamp(0, _bannerSlides.length - 1);
        if (_currentBannerIndex != idx) setState(() => _currentBannerIndex = idx);
      }
    });
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_bannerPageController.hasClients) return;
      final next = (_currentBannerIndex + 1) % _bannerSlides.length;
      _bannerPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Load display name from authenticated user (StorageService).
  Future<void> _loadUserName() async {
    final user = await StorageService.getUser();
    if (!mounted) return;
    if (user != null) {
      final name = user['name']?.toString().trim();
      final fullName = user['full_name']?.toString().trim();
      final first = user['first_name']?.toString().trim() ?? '';
      final last = user['last_name']?.toString().trim() ?? '';
      final email = user['email']?.toString().trim();
      String authName = 'Guest';
      if (name != null && name.isNotEmpty) {
        authName = name;
      } else if (fullName != null && fullName.isNotEmpty) {
        authName = fullName;
      } else if ('$first $last'.trim().isNotEmpty) {
        authName = '$first $last'.trim();
      } else if (email != null && email.isNotEmpty) {
        authName = email;
      }
      setState(() => _userDisplayName = authName);
    }
  }

  /// Initial load: fetch page 1 only.
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final authService = AuthService();
      final response = await authService.getProducts(page: 1);

      if (mounted) {
        setState(() {
          _products = List.from(response.data);
          _applySearchFilter();
          _currentPage = response.meta.currentPage;
          _lastPage = response.meta.lastPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      if (mounted) {
        setState(() {
          _products = getDefaultProducts();
          _filteredProducts = List.from(_products);
          _currentPage = 1;
          _lastPage = 1;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// Append next page when user scrolls near bottom. Uses loading flag to prevent duplicate requests.
  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;
    if (_searchController.text.isNotEmpty) return; // Only paginate full list, not search results

    setState(() => _isLoadingMore = true);

    try {
      final authService = AuthService();
      final nextPage = _currentPage + 1;
      final response = await authService.getProducts(page: nextPage);

      if (!mounted) return;
      setState(() {
        _products.addAll(response.data);
        _applySearchFilter();
        _currentPage = response.meta.currentPage;
        _lastPage = response.meta.lastPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Error loading more products: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) _loadMore();
  }

  void _applySearchFilter() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products
          .where((item) =>
              item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query))
          .toList();
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _hasCategoryError = false;
    });

    try {
      final authService = AuthService();
      final response = await authService.getCategories(page: 1);
      
      if (mounted) {
        setState(() {
          _categories = response.data;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      // Use default categories as fallback
      if (mounted) {
        setState(() {
          _categories = [];
          _isLoadingCategories = false;
          _hasCategoryError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(_applySearchFilter);
  }

  // Helper method to convert ProductModel to itemModel for compatibility
  itemModel _productToItemModel(ProductModel product) {
    return itemModel(
      name: product.name,
      description: product.description,
      price: product.price.toInt(),
      categoryId: product.categoryId,
      image: product.image,
      rating: product.rating,
      review: "Great product",
      fcolor: [Colors.red, Colors.blue, Colors.green],
      size: ["S", "M", "L", "XL"],
    );
  }

  static const Color _bannerDarkBlue = Color(0xFF1E3A5F);
  static const Color _bannerLightGreen = Color(0xFFA8E6CF);

  Widget _buildBannerSlide(_BannerSlide slide) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartPage()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _bannerDarkBlue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Left: text content
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _bannerLightGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        slide.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      slide.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        "Shop Now",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Right: product image
              Positioned(
                right: -10,
                top: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Image.asset(
                    slide.image,
                    height: 180,
                    width: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 140,
                      height: 180,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.grey[500], size: 48),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build image widget (handles both network and asset images)
  Widget _buildProductImage(String imageUrl, {double? height, double? width}) {
    if (imageUrl.isEmpty) {
      return Container(
        height: height,
        width: width ?? double.infinity,
        color: Colors.grey[200],
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: 30,
        ),
      );
    }

    // Trim whitespace and check for network URLs
    final trimmedUrl = imageUrl.trim();
    final isNetworkImage = trimmedUrl.startsWith('http://') || 
                           trimmedUrl.startsWith('https://') ||
                           trimmedUrl.startsWith('www.') ||
                           trimmedUrl.contains('://');
    
    if (isNetworkImage) {
      return Image.network(
        trimmedUrl,
        height: height,
        width: width ?? double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            width: width ?? double.infinity,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: primaryColor,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: width ?? double.infinity,
            color: Colors.grey[200],
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey[400],
              size: 30,
            ),
          );
        },
      );
    } else {
      return Image.asset(
        trimmedUrl,
        height: height,
        width: width ?? double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: width ?? double.infinity,
            color: Colors.grey[200],
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey[400],
              size: 30,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // App bar – dark blue
            Container(
              decoration: BoxDecoration(
                color: _appBarColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _appBarColor.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                children: [
                  // Welcome and user name
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _userDisplayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),



                  // Cart icon
                  Consumer<CartService>(
                    builder: (context, cartService, child) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            SmoothPageRoute(child: const CartPage()),
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                size: 22,
                                color: _appBarColor,
                              ),
                            ),
                            if (cartService.itemCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${cartService.itemCount}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                    ),
                  ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(child: const SearchPage()),
                  );
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search, color: Colors.grey[600], size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Search for items",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic,
                          color: Colors.grey[700],
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Text(
                        "Shop by category",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: uberBlack,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _isLoadingCategories
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(color: primaryColor),
                              ),
                            )
                          : _categories.isEmpty && _hasCategoryError
                              ? const SizedBox.shrink() // Hide if error and no categories
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(
                                      _categories.isEmpty ? fcategory.length : _categories.length,
                                      (index) {
                                        // Use API categories if available, otherwise fallback to default
                                        final category = _categories.isEmpty
                                            ? fcategory[index]
                                            : null;
                                        final categoryModel = _categories.isEmpty
                                            ? null
                                            : _categories[index];
                                        
                                        final categoryName = categoryModel?.name ?? category?.name ?? '';
                                        final categoryImage = categoryModel?.image ?? category?.image ?? '';
                                        final categoryId = categoryModel?.id ?? 0;

                                        return Padding(
                                          padding: EdgeInsets.only(
                                            left: index == 0 ? 16 : 12,
                                            right: index == (_categories.isEmpty ? fcategory.length : _categories.length) - 1 ? 16 : 0,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                    context,
                                    SmoothPageRoute(
                                      child: CategoryItems(
                                        category: categoryName,
                                        categoryId: categoryId,
                                      ),
                                    ),
                                  );
                                            },
                                            child: SizedBox(
                                              width: 80,
                                              child: Column(
                                                children: [
                                                  Container(
                                                    height: 80,
                                                    width: 80,
                                                    decoration: BoxDecoration(
                                                      color: _categoryColors[index % _categoryColors.length],
                                                      borderRadius: BorderRadius.circular(
                                                        12,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(
                                                            0.05,
                                                          ),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(
                                                        12,
                                                      ),
                                                      child: _buildProductImage(
                                                        categoryImage,
                                                        height: 80,
                                                        width: 80,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    categoryName,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: uberBlack,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                    ),

                    // Promotional banner – auto-scrolling carousel
                    SizedBox(
                      height: 180,
                      child: PageView.builder(
                        controller: _bannerPageController,
                        itemCount: _bannerSlides.length,
                        itemBuilder: (context, index) {
                          final slide = _bannerSlides[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildBannerSlide(slide),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _bannerSlides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentBannerIndex == i ? primaryColor : Colors.grey[300],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Featured deals section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Featured deals",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: uberBlack,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Loading indicator or Products grid
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        ),
                      )
                    else if (_filteredProducts.isEmpty && _searchController.text.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No products available",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_hasError) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Using default products",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      // Items grid - Featured deals style
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.64,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final eCommerceItems = _productToItemModel(product);

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                SmoothPageRoute(
                                  child: Detail(productId: product.id),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.grey.shade100,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image with wishlist
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(14),
                                            ),
                                        child: _buildProductImage(
                                          product.image,
                                          height: 118,
                                        ),
                                      ),
                                      // Wishlist button (uses product.id for API add/remove)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Consumer<WishlistService>(
                                          builder: (context, wishlistService, child) {
                                            final isInWishlist = wishlistService
                                                .isInWishlist(product);
                                            final isToggling = wishlistService.isToggling(product.id);
                                            return InkWell(
                                              onTap: () async {
                                                try {
                                                  await wishlistService.toggleWishlist(product);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          isInWishlist
                                                              ? "${product.name} removed from wishlist"
                                                              : "${product.name} added to wishlist",
                                                        ),
                                                        duration: const Duration(seconds: 1),
                                                        backgroundColor: primaryColor,
                                                        behavior: SnackBarBehavior.floating,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Wishlist: ${e.toString()}'),
                                                        backgroundColor: Colors.red,
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: isToggling
                                                    ? SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.grey[700],
                                                        ),
                                                      )
                                                    : Icon(
                                                        isInWishlist
                                                            ? Icons.favorite
                                                            : Icons.favorite_border,
                                                        color: isInWishlist
                                                            ? Colors.red
                                                            : Colors.grey[700],
                                                        size: 18,
                                                      ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Content
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Price section
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Row(
                                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                                            textBaseline: TextBaseline.alphabetic,
                                                            children: [
                                                              Text(
                                                                "₺${eCommerceItems.price}",
                                                                style: TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight: FontWeight.w700,
                                                                  color: primaryColor,
                                                                  letterSpacing: -0.4,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 6),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.amber.shade100,
                                                                  borderRadius: BorderRadius.circular(6),
                                                                ),
                                                                child: Text(
                                                                  "1${product.unitType}",
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    color: Colors.amber.shade900,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Add to cart button
                                                    Consumer<CartService>(
                                                      builder: (context, cartService, child) {
                                                        final isInCart =
                                                            cartService.isInCart(
                                                              eCommerceItems,
                                                            );
                                                        final cartItem =
                                                            isInCart
                                                            ? cartService.cartItems.firstWhere(
                                                                (item) =>
                                                                    item.item.name ==
                                                                        eCommerceItems
                                                                            .name &&
                                                                    item.item.image ==
                                                                        eCommerceItems
                                                                            .image,
                                                              )
                                                            : null;
                                                        return GestureDetector(
                                                          onTap: () async {
                                                            if (_addingProductId == product.id) return;
                                                            setState(() => _addingProductId = product.id);
                                                            try {
                                                              // Use product ID from ProductModel
                                                              await cartService.addToCartByProductId(product.id);
                                                              
                                                              if (mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      "${product.name} added to cart",
                                                                    ),
                                                                    duration:
                                                                        const Duration(
                                                                          seconds:
                                                                              1,
                                                                        ),
                                                                    backgroundColor:
                                                                        primaryColor,
                                                                    behavior:
                                                                        SnackBarBehavior
                                                                            .floating,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            10,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            } catch (e) {
                                                              if (mounted) {
                                                                final errorMessage = e.toString().replaceAll('Exception: ', '');
                                                                final isAuthError = errorMessage.contains('authenticated') || 
                                                                                    errorMessage.contains('Authentication');
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      isAuthError
                                                                          ? "You must be authenticated to add items to cart"
                                                                          : "Failed to add to cart: $errorMessage",
                                                                    ),
                                                                    duration:
                                                                        const Duration(
                                                                          seconds:
                                                                              3,
                                                                        ),
                                                                    backgroundColor:
                                                                        isAuthError ? Colors.orange : Colors.red,
                                                                    behavior:
                                                                        SnackBarBehavior
                                                                            .floating,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            10,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            } finally {
                                                              if (mounted) setState(() => _addingProductId = null);
                                                            }
                                                          },
                                                          child: Container(
                                                            width: 34,
                                                            height: 34,
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  primaryColor,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10,
                                                                  ),
                                                            ),
                                                            child: Center(
                                                              child: _addingProductId == product.id
                                                                  ? const SizedBox(
                                                                      width: 18,
                                                                      height: 18,
                                                                      child: CircularProgressIndicator(
                                                                        strokeWidth: 2,
                                                                        color: Colors.white,
                                                                      ),
                                                                    )
                                                                  : isInCart &&
                                                                      cartItem !=
                                                                          null
                                                                  ? Text(
                                                                      "${cartItem.quantity}",
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    )
                                                                  : const Icon(
                                                                      Icons.add,
                                                                      color: Colors
                                                                          .white,
                                                                      size: 18,
                                                                    ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                // Product name
                                                Text(
                                                  eCommerceItems.name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: uberBlack,
                                                    letterSpacing: -0.3,
                                                    height: 1.25,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                // Rating
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      color: Colors.amber[700],
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "${eCommerceItems.rating.toString()} (${eCommerceItems.review})",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Load more footer: show indicator when fetching next page
                    if (_filteredProducts.isNotEmpty && _currentPage < _lastPage && _isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: primaryColor)),
                      )
                    else if (_filteredProducts.isNotEmpty && _currentPage >= _lastPage && _lastPage > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            "You've seen all products",
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Show message if no results
                    if (_filteredProducts.isEmpty &&
                        _searchController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No items found",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Try searching with different keywords",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating cart button - Featured deals style
      floatingActionButton: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.itemCount == 0) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(child: const CartPage()),
                );
              },
              backgroundColor: uberBlack,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                "View cart (${cartService.itemCount})",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
