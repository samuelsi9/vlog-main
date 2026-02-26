import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Models/model.dart';
import 'package:vlog/Models/product_model.dart';
import 'package:vlog/Models/subcategory_models.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/wishlist_service.dart';
import 'package:vlog/presentation/screen/detail_screen.dart'; // Pour aller aux détails

const Color _primaryRed = Color(0xFFE53E3E);

class CategoryItems extends StatefulWidget {
  final String category;
  final List<itemModel>? categoItems; // Made optional for API fetching
  final int? categoryId; // Category ID to fetch from API

  const CategoryItems({
    super.key,
    required this.category,
    this.categoItems,
    this.categoryId,
  });

  @override
  State<CategoryItems> createState() => _CategoryItemsState();
}

class _CategoryItemsState extends State<CategoryItems> {
  List<ProductModel> _products = [];
  List<itemModel> _items = [];
  bool _isLoading = true;
  bool _hasError = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // If categoryId is provided, fetch from API
    // Otherwise, use the provided categoItems
    if (widget.categoryId != null) {
      _fetchProductsByCategory();
    } else if (widget.categoItems != null) {
      _items = widget.categoItems!;
      _isLoading = false;
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchProductsByCategory() async {
    if (widget.categoryId == null) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _authService.getProductsByCategory(
        categoryId: widget.categoryId!,
        page: 1,
      );

      if (mounted) {
        setState(() {
          _products = response.data;
          // Convert ProductModel to itemModel for compatibility
          _items = _products.map((product) => _productToItemModel(product)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products by category: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          // Fallback to provided items if available
          if (widget.categoItems != null) {
            _items = widget.categoItems!;
          }
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
  Widget _buildImage(String imageUrl, {double? height, double? width}) {
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
                color: _primaryRed,
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
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.category),
        ),
        body: Center(
          child: CircularProgressIndicator(color: _primaryRed),
        ),
      );
    }

    // Show error state
    if (_hasError && _items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.category),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to fetch products for this category',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchProductsByCategory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // 🔹 Récupérer les sous-catégories liées à cette catégorie
    final categoryId = widget.categoryId ?? getCategoryIdFromName(widget.category);
    final subList = subCategories
        .where((sub) => sub.categoryId == categoryId)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back_ios_new),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: TextField(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(5),
                          hintText: widget.category,
                          hintStyle: const TextStyle(color: Colors.black38),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 SUBCATEGORIES SECTION (design moderne)
            if (subList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Subcategories",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 🧭 Liste horizontale stylée
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: subList.length,
                        itemBuilder: (context, index) {
                          final sub = subList[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryItems(
                                    category: sub.name,
                                    categoItems: sub.items,
                                  ),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 15),
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade300,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Image ronde avec ombre
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade400,
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        sub.image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Nom de la sous-catégorie
                                  Text(
                                    sub.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // 🔹 PRODUCTS SECTION
            if (_items.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    itemCount: _items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      // Get product ID and product if available from API
                      final product = widget.categoryId != null && index < _products.length
                          ? _products[index]
                          : null;
                      final productId = product?.id;
                      
                      return GestureDetector(
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: _buildImage(
                                        item.image,
                                        width: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: productId != null
                                          ? Consumer<WishlistService>(
                                              builder: (context, wishlistService, child) {
                                                final isInWishlist = wishlistService.isInWishlist(productId);
                                                final isToggling = wishlistService.isToggling(productId);
                                                return InkWell(
                                                  onTap: () async {
                                                    try {
                                                      await wishlistService.toggleWishlist(productId);
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              isInWishlist
                                                                  ? "${item.name} removed from wishlist"
                                                                  : "${item.name} added to wishlist",
                                                            ),
                                                            duration: const Duration(seconds: 1),
                                                          ),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('Wishlist: ${e.toString()}'),
                                                            backgroundColor: Colors.red,
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
                                                            isInWishlist ? Icons.favorite : Icons.favorite_border,
                                                            color: isInWishlist ? Colors.red : Colors.grey[700],
                                                            size: 18,
                                                          ),
                                                  ),
                                                );
                                              },
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      "₺${item.price}",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "1${product?.unitType ?? 'piece'}",
                                        style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🔹 Helper pour obtenir l'ID à partir du nom de catégorie
  int getCategoryIdFromName(String name) {
    switch (name.toLowerCase()) {
      case "women":
        return 1;
      case "man":
        return 2;
      case "kids":
        return 3;
      default:
        return 0;
    }
  }
}
