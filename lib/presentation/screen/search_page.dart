import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Models/model.dart';
import 'package:vlog/Models/category_model.dart';
import 'package:vlog/Models/product_model.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/cart_service.dart';
import 'package:vlog/Utils/wishlist_service.dart';
import 'package:vlog/presentation/screen/detail_screen.dart';
import 'package:vlog/presentation/category_items.dart';

// Red color scheme (matching home page)
const Color primaryColor = Color(0xFFE53E3E);
const Color primaryColorLight = Color(0xFFFC8181);
const Color uberBlack = Color(0xFF000000);

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<itemModel> _searchResults = [];
  bool _isSearching = false;
  final List<String> _recentSearches = ['Wing'];
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  bool _hasCategoryError = false;
  List<ProductModel> _allProducts = [];
  final AuthService _authService = AuthService();

  // Helper method to build image provider (handles both network and asset images)
  ImageProvider _buildImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }

    final trimmedUrl = imageUrl.trim();
    final isNetworkImage = trimmedUrl.startsWith('http://') || 
                           trimmedUrl.startsWith('https://') ||
                           trimmedUrl.startsWith('www.') ||
                           trimmedUrl.contains('://');
    
    if (isNetworkImage) {
      return NetworkImage(trimmedUrl);
    } else {
      return AssetImage(trimmedUrl);
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _isSearching = _searchController.text.isNotEmpty;
      });
    });
    _fetchCategories();
    _fetchProducts().then((_) {
      // After fetching products, convert them to itemModel and set as initial results
      if (mounted) {
        setState(() {
          _searchResults = _allProducts.map((product) => _productToItemModel(product)).toList();
        });
      }
    });
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _hasCategoryError = false;
    });

    try {
      final response = await _authService.getCategories(page: 1);
      
      if (mounted) {
        setState(() {
          _categories = response.data;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) {
        setState(() {
          _categories = [];
          _isLoadingCategories = false;
          _hasCategoryError = true;
        });
      }
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await _authService.getProducts(page: 1);
      if (mounted) {
        setState(() {
          _allProducts = response.data;
          // Convert to itemModel for search results
          _searchResults = _allProducts.map((product) => _productToItemModel(product)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      // Fallback to itemC if API fails
      if (mounted) {
        setState(() {
          _searchResults = itemC;
        });
      }
    }
  }

  // Helper method to convert ProductModel to itemModel
  itemModel _productToItemModel(ProductModel product) {
    return itemModel(
      name: product.name,
      description: product.description,
      price: product.price.toInt(),
      categoryId: product.categoryId,
      image: product.image,
      rating: product.rating,
      review: '',
      fcolor: [Colors.red, Colors.blue, Colors.green],
      size: ['S', 'M', 'L', 'XL'],
    );
  }

  // Helper method to build image widget (handles both network and asset images)
  Widget _buildCategoryImage(String imageUrl, {double? height, double? width}) {
    if (imageUrl.isEmpty) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: 30,
        ),
      );
    }

    final trimmedUrl = imageUrl.trim();
    final isNetworkImage = trimmedUrl.startsWith('http://') || 
                           trimmedUrl.startsWith('https://') ||
                           trimmedUrl.startsWith('www.') ||
                           trimmedUrl.contains('://');
    
    if (isNetworkImage) {
      return Image.network(
        trimmedUrl,
        height: height,
        width: width,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            width: width,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: width,
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
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: width,
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        // Show all products from API, fallback to itemC if no products
        _searchResults = _allProducts.isNotEmpty
            ? _allProducts.map((product) => _productToItemModel(product)).toList()
            : itemC;
        _isSearching = false;
      } else {
        // Search through API products, fallback to itemC if no products
        if (_allProducts.isNotEmpty) {
          _searchResults = _allProducts
              .where(
                (product) =>
                    product.name.toLowerCase().contains(query.toLowerCase()) ||
                    product.description.toLowerCase().contains(query.toLowerCase()),
              )
              .map((product) => _productToItemModel(product))
              .toList();
        } else {
          // Fallback to itemC if API products not loaded
          _searchResults = itemC
              .where(
                (item) =>
                    item.name.toLowerCase().contains(query.toLowerCase()) ||
                    item.description.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
        }
        _isSearching = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: uberBlack,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Search products...",
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(color: Colors.black, fontSize: 15),
            onChanged: _performSearch,
          ),
        ),
        titleSpacing: 8,
      ),
      body: _isSearching
          ? (_searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "No products found",
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Try searching with different keywords",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Text(
                            "${_searchResults.length} ${_searchResults.length == 1 ? 'product' : 'products'} found",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          // Find the corresponding ProductModel to get the product ID
                          final product = _allProducts.firstWhere(
                            (p) => p.name == item.name && p.image == item.image,
                            orElse: () => _allProducts.isNotEmpty ? _allProducts[0] : ProductModel(
                              id: 0,
                              name: item.name,
                              description: item.description,
                              price: item.price.toDouble(),
                              image: item.image,
                              categoryId: item.categoryId,
                              subcategoryId: 0,
                              createdAt: '',
                            ),
                          );
                          final productId = _allProducts.isNotEmpty ? product.id : null;
                          
                          return Consumer2<CartService, WishlistService>(
                            builder: (context, cartService, wishlistService, child) {
                              final isInWishlist = wishlistService.isInWishlist(
                                item,
                              );

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => productId != null
                                          ? Detail(productId: productId)
                                          : Detail(ecom: item),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Product Image
                                      Expanded(
                                        flex: 3,
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topLeft: Radius.circular(16),
                                                      topRight: Radius.circular(16),
                                                    ),
                                                image: DecorationImage(
                                                  image: _buildImageProvider(item.image),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            // Wishlist Button
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: InkWell(
                                                onTap: () {
                                                  wishlistService.toggleWishlist(
                                                    item,
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        isInWishlist
                                                            ? "${item.name} removed from wishlist"
                                                            : "${item.name} added to wishlist",
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 1,
                                                      ),
                                                      backgroundColor: primaryColor,
                                                      behavior:
                                                          SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    isInWishlist
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color: isInWishlist
                                                        ? Colors.red
                                                        : Colors.grey[700],
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Product Info
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    color: Colors.amber[700],
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      "${item.rating.toString()} (${item.review})",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[700],
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      "₺${item.price}",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: primaryColor,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () async {
                                                      try {
                                                        await cartService.addToCart(item);
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                "${item.name} added to cart",
                                                              ),
                                                              duration: const Duration(
                                                                seconds: 1,
                                                              ),
                                                              backgroundColor:
                                                                  primaryColor,
                                                              behavior: SnackBarBehavior
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
                                                              duration: const Duration(
                                                                seconds: 3,
                                                              ),
                                                              backgroundColor:
                                                                  isAuthError ? Colors.orange : Colors.red,
                                                              behavior: SnackBarBehavior
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
                                                      }
                                                    },
                                                    child: Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: primaryColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.add,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                    ),
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
                          );
                        },
                      ),
                    ),
                  ],
                ))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent searches
                  if (_recentSearches.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Text(
                        "Recent searches",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _recentSearches.map((search) {
                          return InkWell(
                            onTap: () {
                              _searchController.text = search;
                              _performSearch(search);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    search,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Categories section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Categories",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingCategories
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _categories.isEmpty && _hasCategoryError
                          ? const SizedBox.shrink()
                          : SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _categories.isEmpty ? fcategory.length : _categories.length,
                                itemBuilder: (context, index) {
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

                                  return InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryItems(
                                            category: categoryName,
                                            categoryId: categoryId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 80,
                                      margin: EdgeInsets.only(
                                        right: index == (_categories.isEmpty ? fcategory.length : _categories.length) - 1 ? 0 : 12,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 80,
                                            width: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: _buildCategoryImage(
                                                categoryImage,
                                                height: 80,
                                                width: 80,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Flexible(
                                            child: Text(
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
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                  const SizedBox(height: 24),
                  // Order again section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Order again",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final restaurants = [
                          {'name': 'Burger King', 'time': '10 min', 'image': 'assets/cafe.png'},
                          {'name': 'Taco Bell', 'time': '10 min', 'image': 'assets/tomate.png'},
                          {'name': 'Panera', 'time': '13 min', 'image': 'assets/fanta.png'},
                          {'name': "McDonald's®", 'time': '10 min', 'image': 'assets/egg.png'},
                        ];
                        final restaurant = restaurants[index];
                        // Find matching product from itemC
                        final matchingProduct = itemC.firstWhere(
                          (item) => item.image == restaurant['image'],
                          orElse: () => itemC[0],
                        );
                        
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Detail(ecom: matchingProduct),
                              ),
                            );
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: AssetImage(restaurant['image'] as String),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Flexible(
                                  child: Text(
                                    restaurant['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  restaurant['time'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Make breakfast at home section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Make breakfast at home",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final groceries = [
                          {'name': 'Milk', 'image': 'assets/Peak.jpeg'},
                          {'name': 'Cereal', 'image': 'assets/cornflake.png'},
                          {'name': 'Butter', 'image': 'assets/eker.png'},
                          {'name': 'Orange juice', 'image': 'assets/fanta.png'},
                          {'name': 'Yogurt', 'image': 'assets/labne.png'},
                        ];
                        final grocery = groceries[index];
                        // Find matching product from itemC
                        final matchingProduct = itemC.firstWhere(
                          (item) => item.image == grocery['image'],
                          orElse: () => itemC[0],
                        );
                        
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Detail(ecom: matchingProduct),
                              ),
                            );
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: _buildImageProvider(grocery['image'] as String),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Flexible(
                                  child: Text(
                                    grocery['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Top categories
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Top categories",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}
