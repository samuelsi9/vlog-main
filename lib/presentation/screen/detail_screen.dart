import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Models/model.dart';
import 'package:vlog/Models/product_detail_model.dart';
import 'package:vlog/Models/product_model.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/wishlist_service.dart';
import 'package:vlog/Utils/cart_service.dart';
import 'package:vlog/Utils/parse_utils.dart';
import 'package:vlog/Utils/recently_viewed_service.dart';
import 'package:vlog/presentation/screen/cart_page.dart';

class Detail extends StatefulWidget {
  final itemModel? ecom;
  final int? productId;

  const Detail({super.key, this.ecom, this.productId})
      : assert(ecom != null || productId != null, 'Either ecom or productId must be provided');

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  int currentIndex = 0;
  int quantity = 1;
  bool _descriptionExpanded = false;
  ProductDetailModel? _productDetail;
  bool _isLoading = true;
  bool _isAddingToCart = false;
  String? _addingRelatedProductKey;
  String? _error;
  List<ProductModel> _similarProducts = [];
  bool _isLoadingSimilar = false;
  final AuthService _authService = AuthService();

  static const Color primaryColor = Color(0xFFE53E3E);
  static const Color primaryColorLight = Color(0xFFFC8181);
  static const Color uberBlack = Color(0xFF000000);

  // ─── Preset kg amounts shown as quick-select buttons ───
  static const List<int> _kgPresets = [10, 15, 20, 30];

  // Returns true when the current product is sold by kg
  bool get _isKgProduct {
    final unit = _productDetail?.unitType.toLowerCase().trim() ?? '';
    return unit == 'kg';
  }

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _fetchProductDetail();
    } else {
      _isLoading = false;
      if (widget.ecom != null) {
        RecentlyViewedService.addViewed(0, widget.ecom!.categoryId);
        _fetchSimilarProducts(widget.ecom!.categoryId);
      }
    }
  }

  void _showSnackBar(String message, Color color, {IconData icon = Icons.info_outline}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.fixed,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
  }

  String _getCartErrorMessage(String error) {
    final isAuth = error.contains('authenticated') || error.contains('Authentication');
    final isNetwork = error.contains('connection') || error.contains('timeout');
    if (isAuth) return "Please log in to add items to cart";
    if (isNetwork) return "No internet connection. Please try again";
    return "Couldn't add to cart. Please try again";
  }

  String _getWishlistErrorMessage(String error) {
    final isAuth = error.contains('authenticated') || error.contains('Authentication');
    final isNetwork = error.contains('connection') || error.contains('timeout');
    if (isAuth) return "Please log in to save to wishlist";
    if (isNetwork) return "No internet connection. Please try again";
    return "Couldn't update wishlist. Please try again";
  }

  Color _getErrorColor(String error) {
    final isAuth = error.contains('authenticated') || error.contains('Authentication');
    return isAuth ? Colors.orange : Colors.red;
  }

  Future<void> _fetchProductDetail() async {
    if (widget.productId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final productDetail = await _authService.getProductDetail(widget.productId!);
      RecentlyViewedService.addViewed(productDetail.id, productDetail.categoryId);
      if (!mounted) return;
      setState(() {
        _productDetail = productDetail;
        _isLoading = false;
      });
      _fetchSimilarProducts(productDetail.categoryId, excludeProductId: productDetail.id);
    } catch (e) {
      setState(() {
        _error = 'Unable to load product. Please try again.';
        _isLoading = false;
      });
      if (mounted) {
        _showSnackBar('Unable to load product. Please try again.', Colors.red, icon: Icons.wifi_off_rounded);
      }
    }
  }

  Future<void> _fetchSimilarProducts(int categoryId, {int? excludeProductId}) async {
    setState(() => _isLoadingSimilar = true);
    try {
      final response = await _authService.getProductsByCategory(categoryId: categoryId, page: 1);
      if (!mounted) return;
      final list = response.data
          .where((p) => excludeProductId == null || p.id != excludeProductId)
          .take(10)
          .toList();
      setState(() {
        _similarProducts = list;
        _isLoadingSimilar = false;
      });
    } catch (_) {
      if (mounted) setState(() { _similarProducts = []; _isLoadingSimilar = false; });
    }
  }

  itemModel _productToItemModel(ProductModel p) {
    return itemModel(
      name: p.name,
      description: p.description,
      price: p.price.toInt(),
      categoryId: p.categoryId,
      image: p.image,
      rating: p.rating,
      review: '',
      fcolor: const [Colors.red, Colors.blue, Colors.green],
      size: const ['S', 'M', 'L', 'XL'],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, dynamic iconColor) {
    final color = iconColor == Colors.amber ? Colors.amber[700] : Colors.grey[600];
    return Column(
      children: [
        Icon(icon, size: 22, color: color ?? Colors.grey[600]),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  itemModel get _currentProduct {
    if (_productDetail != null) return _productDetail!.toItemModel();
    if (widget.ecom != null) return widget.ecom!;
    throw StateError('Neither productDetail nor ecom is available');
  }

  Widget _buildImage(String imageUrl, {double? height, double? width}) {
    if (imageUrl.isEmpty) {
      return Container(height: height, width: width, color: Colors.grey[200], child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30));
    }
    final trimmedUrl = imageUrl.trim();
    final isNetworkImage = trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://') || trimmedUrl.startsWith('www.') || trimmedUrl.contains('://');
    if (isNetworkImage) {
      return Image.network(trimmedUrl, height: height, width: width, fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(height: height, width: width, color: Colors.grey[200],
            child: Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, color: primaryColor)));
        },
        errorBuilder: (context, error, stackTrace) => Container(height: height, width: width, color: Colors.grey[200], child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30)),
      );
    } else {
      return Image.asset(trimmedUrl, height: height, width: width, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(height: height, width: width, color: Colors.grey[200], child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30)),
      );
    }
  }

  // ─── Quick preset kg selector row ───────────────────────
  Widget _buildKgPresets() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kgPresets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final preset = _kgPresets[i];
          final isSelected = quantity == preset;
          return GestureDetector(
            onTap: () => setState(() => quantity = preset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: primaryColor.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                '${preset}kg',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Navigator.pop(context)),
        ),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (_error != null && _productDetail == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade300)),
                const SizedBox(height: 24),
                const Text("Oops! Something went wrong", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A202C))),
                const SizedBox(height: 10),
                Text("We couldn't load this product.\nPlease check your connection and try again.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, height: 52,
                  child: ElevatedButton(onPressed: _fetchProductDetail,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.refresh_rounded, size: 20), SizedBox(width: 8), Text("Try Again", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, height: 52,
                  child: OutlinedButton(onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[700], side: BorderSide(color: Colors.grey[300]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("Go Back", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentProduct = _currentProduct;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Product Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A202C))),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))]),
          child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3748), size: 18), onPressed: () => Navigator.pop(context)),
        ),
        actions: [
          Consumer<WishlistService>(
            builder: (context, wishlistService, child) {
              final productId = widget.productId ?? _productDetail?.id;
              final effectiveId = productId ?? 0;
              final isInWishlist = wishlistService.isInWishlist(effectiveId);
              final isToggling = wishlistService.isToggling(effectiveId);
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))]),
                child: IconButton(
                  icon: isToggling
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Icon(isInWishlist ? Icons.favorite : Icons.favorite_border, color: isInWishlist ? Colors.red : Colors.black),
                  onPressed: productId == null ? null : () async {
                    try {
                      await wishlistService.toggleWishlist(productId);
                      if (mounted) {
                        _showSnackBar(isInWishlist ? "${currentProduct.name} removed from wishlist" : "${currentProduct.name} added to wishlist ❤️",
                          primaryColor, icon: isInWishlist ? Icons.favorite_border : Icons.favorite);
                      }
                    } catch (e) {
                      if (mounted) {
                        _showSnackBar(_getWishlistErrorMessage(e.toString()), _getErrorColor(e.toString()),
                          icon: e.toString().contains('authenticated') ? Icons.lock_outline : Icons.error_outline);
                      }
                    }
                  },
                ),
              );
            },
          ),
          Consumer<CartService>(
            builder: (context, cartService, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))]),
                    child: IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                    ),
                  ),
                  if (cartService.itemCount > 0)
                    Positioned(right: 8, top: 4,
                      child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                        child: Text("${cartService.itemCount}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)))),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: size.height * 0.42,
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned.fill(child: Hero(tag: currentProduct.image, child: _buildImage(currentProduct.image))),
                    Positioned(bottom: 0, left: 0, right: 0, height: 80,
                      child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.2)]))),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentProduct.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A202C), letterSpacing: -0.5, height: 1.2)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("₺${currentProduct.price}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A202C), letterSpacing: -0.5)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Text("1 ${getDisplayUnit(_productDetail?.unitType)}", style: TextStyle(fontSize: 13, color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    _buildInfoChip(Icons.inventory_2_outlined, 'Delivered', Colors.grey),
                    const SizedBox(width: 16),
                    _buildInfoChip(Icons.access_time, 'Quick delivery', Colors.grey),
                    const SizedBox(width: 16),
                    _buildInfoChip(Icons.star, '${currentProduct.rating} reviews', Colors.amber),
                  ]),
                  const SizedBox(height: 24),
                  const Text("Description", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A202C))),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final desc = currentProduct.description;
                      final overflow = desc.length > 120 && !_descriptionExpanded;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(overflow ? '${desc.substring(0, 120)}...' : desc, style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5)),
                          if (desc.length > 120)
                            GestureDetector(
                              onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
                              child: Padding(padding: const EdgeInsets.only(top: 6),
                                child: Text(_descriptionExpanded ? 'See less' : 'See more...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor))),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("You may also like", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A202C), letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  _buildSimilarProducts(),
                ],
              ),
            ),
          ],
        ),
      ),
      // ─── Bottom bar with optional kg presets ────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Quick kg preset buttons (only for kg products) ──
              if (_isKgProduct) ...[
                _buildKgPresets(),
                const SizedBox(height: 12),
              ],
              // ── Quantity selector + Add to cart button ──
              Row(
                children: [
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () { if (quantity > 1) setState(() => quantity--); },
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(26), bottomLeft: Radius.circular(26)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Icon(Icons.remove, size: 22, color: quantity > 1 ? const Color(0xFF2D3748) : Colors.grey[400]),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            formatQtyWithUnit(quantity, _productDetail?.unitType),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => quantity++),
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(26), bottomRight: Radius.circular(26)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.12),
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(26), bottomRight: Radius.circular(26)),
                              ),
                              child: Icon(Icons.add, size: 22, color: primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primaryColor, primaryColorLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (_isAddingToCart) return;
                            setState(() => _isAddingToCart = true);
                            final cartService = Provider.of<CartService>(context, listen: false);
                            try {
                              if (widget.productId != null) {
                                for (int i = 0; i < quantity; i++) {
                                  await cartService.addToCartByProductId(widget.productId!);
                                }
                              } else {
                                for (int i = 0; i < quantity; i++) {
                                  await cartService.addToCart(currentProduct);
                                }
                              }
                              if (mounted) {
                                _showSnackBar("$quantity x ${currentProduct.name} added to cart", primaryColor, icon: Icons.check_circle_outline);
                              }
                            } catch (e) {
                              if (mounted) {
                                _showSnackBar(_getCartErrorMessage(e.toString()), _getErrorColor(e.toString()),
                                  icon: e.toString().contains('authenticated') ? Icons.lock_outline : Icons.error_outline);
                              }
                            } finally {
                              if (mounted) setState(() => _isAddingToCart = false);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isAddingToCart)
                                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              else
                                const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                "Add • ₺${(currentProduct.price * quantity).toStringAsFixed(0)}",
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<itemModel> _getSimilarProductsFallback() {
    final currentProduct = _currentProduct;
    return itemC
        .where((item) => item.categoryId == currentProduct.categoryId && item.name != currentProduct.name)
        .take(10)
        .toList();
  }

  Widget _buildSimilarProducts() {
    final hasApiProducts = _similarProducts.isNotEmpty;
    final fallbackItems = _getSimilarProductsFallback();
    final useApi = hasApiProducts;
    final itemCount = useApi ? _similarProducts.length : fallbackItems.length;

    if (_isLoadingSimilar && !useApi) {
      return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: primaryColor)));
    }
    if (itemCount == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (useApi) return _buildSimilarProductCard(_similarProducts[index], index, itemCount);
          return _buildSimilarItemModelCard(fallbackItems[index], index, itemCount);
        },
      ),
    );
  }

  Widget _buildSimilarProductCard(ProductModel product, int index, int total) {
    return Consumer2<CartService, WishlistService>(
      builder: (context, cartService, wishlistService, child) {
        final itemForCart = _productToItemModel(product);
        final isInCart = cartService.isInCart(itemForCart);
        final isInWishlist = wishlistService.isInWishlist(product);
        final isToggling = wishlistService.isToggling(product.id);

        return Container(
          width: 160,
          margin: EdgeInsets.only(right: index == total - 1 ? 0 : 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Detail(productId: product.id))),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(children: [
                  ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: _buildImage(product.image, height: 120, width: double.infinity)),
                  Positioned(top: 8, right: 8,
                    child: InkWell(
                      onTap: () async {
                        try {
                          await wishlistService.toggleWishlist(product);
                          if (context.mounted) {
                            _showSnackBar(isInWishlist ? "${product.name} removed from wishlist" : "${product.name} added to wishlist ❤️",
                              primaryColor, icon: isInWishlist ? Icons.favorite_border : Icons.favorite);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            _showSnackBar(_getWishlistErrorMessage(e.toString()), _getErrorColor(e.toString()),
                              icon: e.toString().contains('authenticated') ? Icons.lock_outline : Icons.error_outline);
                          }
                        }
                      },
                      child: Container(padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
                        child: isToggling
                            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[700]))
                            : Icon(isInWishlist ? Icons.favorite : Icons.favorite_border, color: isInWishlist ? Colors.red : Colors.grey[700], size: 16),
                      ),
                    ),
                  ),
                ]),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: uberBlack), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [Icon(Icons.star, color: Colors.amber[700], size: 12), const SizedBox(width: 2), Text(product.rating.toString(), style: TextStyle(fontSize: 10, color: Colors.grey[600]))]),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                          Text("₺${product.price.toStringAsFixed(0)}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                          const SizedBox(width: 4),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                            child: Text("1${getDisplayUnit(product.unitType)}", style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w500))),
                        ]),
                        InkWell(
                          onTap: () async {
                            if (_addingRelatedProductKey == 'pid_${product.id}') return;
                            setState(() => _addingRelatedProductKey = 'pid_${product.id}');
                            try {
                              await cartService.addToCartByProductId(product.id);
                              if (mounted) _showSnackBar("${product.name} added to cart", primaryColor, icon: Icons.check_circle_outline);
                            } catch (e) {
                              if (mounted) {
                                _showSnackBar(_getCartErrorMessage(e.toString()), _getErrorColor(e.toString()),
                                icon: e.toString().contains('authenticated') ? Icons.lock_outline : Icons.error_outline);
                              }
                            } finally {
                              if (mounted) setState(() => _addingRelatedProductKey = null);
                            }
                          },
                          child: Container(width: 28, height: 28, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
                            child: Center(child: _addingRelatedProductKey == 'pid_${product.id}'
                                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[700]))
                                : isInCart ? const Icon(Icons.check, color: Colors.white, size: 16) : const Icon(Icons.add, color: Colors.white, size: 16))),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimilarItemModelCard(itemModel product, int index, int total) {
    return Consumer2<CartService, WishlistService>(
      builder: (context, cartService, wishlistService, child) {
        final isInCart = cartService.isInCart(product);
        final isInWishlist = wishlistService.isInWishlist(0);

        return Container(
          width: 160,
          margin: EdgeInsets.only(right: index == total - 1 ? 0 : 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Detail(ecom: product))),
            borderRadius: BorderRadius.circular(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: _buildImage(product.image, height: 120, width: double.infinity)),
                Positioned(top: 8, right: 8,
                  child: Container(padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
                    child: Icon(isInWishlist ? Icons.favorite : Icons.favorite_border, color: isInWishlist ? Colors.red : Colors.grey[700], size: 16))),
              ]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: uberBlack), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [Icon(Icons.star, color: Colors.amber[700], size: 12), const SizedBox(width: 2), Text("${product.rating} (${product.review})", style: TextStyle(fontSize: 10, color: Colors.grey[600]))]),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text("₺${product.price}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                        const SizedBox(width: 4),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                          child: Text("1piece", style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w500))),
                      ]),
                      InkWell(
                        onTap: () async {
                          final key = '${product.name}_${product.image}';
                          if (_addingRelatedProductKey == key) return;
                          setState(() => _addingRelatedProductKey = key);
                          try {
                            await cartService.addToCart(product);
                            if (mounted) _showSnackBar("${product.name} added to cart", primaryColor, icon: Icons.check_circle_outline);
                          } catch (e) {
                            if (mounted) {
                              _showSnackBar(_getCartErrorMessage(e.toString()), _getErrorColor(e.toString()),
                              icon: e.toString().contains('authenticated') ? Icons.lock_outline : Icons.error_outline);
                            }
                          } finally {
                            if (mounted) setState(() => _addingRelatedProductKey = null);
                          }
                        },
                        child: Container(width: 28, height: 28, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
                          child: Center(child: _addingRelatedProductKey == '${product.name}_${product.image}'
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[700]))
                              : isInCart ? const Icon(Icons.check, color: Colors.white, size: 16) : const Icon(Icons.add, color: Colors.white, size: 16))),
                      ),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:vlog/Models/model.dart';
// import 'package:vlog/Models/product_detail_model.dart';
// import 'package:vlog/Models/product_model.dart';
// import 'package:vlog/Data/apiservices.dart';
// import 'package:vlog/Utils/wishlist_service.dart';
// import 'package:vlog/Utils/cart_service.dart';
// import 'package:vlog/Utils/parse_utils.dart';
// import 'package:vlog/Utils/recently_viewed_service.dart';
// import 'package:vlog/presentation/screen/cart_page.dart';

// class Detail extends StatefulWidget {
//   final itemModel? ecom;
//   final int? productId;

//   const Detail({super.key, this.ecom, this.productId})
//       : assert(ecom != null || productId != null, 'Either ecom or productId must be provided');

//   @override
//   State<Detail> createState() => _DetailState();
// }

// class _DetailState extends State<Detail> {
//   int currentIndex = 0;
//   int quantity = 1;
//   bool _descriptionExpanded = false;
//   ProductDetailModel? _productDetail;
//   bool _isLoading = true;
//   bool _isAddingToCart = false;
//   String? _addingRelatedProductKey;
//   String? _error;
//   List<ProductModel> _similarProducts = [];
//   bool _isLoadingSimilar = false;
//   final AuthService _authService = AuthService();

//   static const Color primaryColor = Color(0xFFE53E3E);
//   static const Color primaryColorLight = Color(0xFFFC8181);
//   static const Color uberBlack = Color(0xFF000000);

//   @override
//   void initState() {
//     super.initState();
//     if (widget.productId != null) {
//       _fetchProductDetail();
//     } else {
//       _isLoading = false;
//       if (widget.ecom != null) {
//         RecentlyViewedService.addViewed(0, widget.ecom!.categoryId);
//         _fetchSimilarProducts(widget.ecom!.categoryId);
//       }
//     }
//   }

//   // ✅ Beautiful snackbar helper
//   void _showSnackBar(String message, Color color, {IconData icon = Icons.info_outline}) {
//   if (!mounted) return;
//   ScaffoldMessenger.of(context)
//     ..hideCurrentSnackBar()
//     ..showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(icon, color: Colors.white, size: 20),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 message,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w500,
//                   fontSize: 13,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.fixed, // ✅ use fixed instead of floating
//         // ❌ remove margin completely — it causes the off screen error
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         duration: const Duration(seconds: 2),
//         dismissDirection: DismissDirection.horizontal,
//       ),
//     );
// }

//   // ✅ Helper to get friendly error message for cart
//   String _getCartErrorMessage(String error) {
//     final isAuth = error.contains('authenticated') || error.contains('Authentication');
//     final isNetwork = error.contains('connection') || error.contains('timeout');
//     if (isAuth) return "Please log in to add items to cart";
//     if (isNetwork) return "No internet connection. Please try again";
//     return "Couldn't add to cart. Please try again";
//   }

//   // ✅ Helper to get friendly error message for wishlist
//   String _getWishlistErrorMessage(String error) {
//     final isAuth = error.contains('authenticated') || error.contains('Authentication');
//     final isNetwork = error.contains('connection') || error.contains('timeout');
//     if (isAuth) return "Please log in to save to wishlist";
//     if (isNetwork) return "No internet connection. Please try again";
//     return "Couldn't update wishlist. Please try again";
//   }

//   // ✅ Helper to get error color
//   Color _getErrorColor(String error) {
//     final isAuth = error.contains('authenticated') || error.contains('Authentication');
//     return isAuth ? Colors.orange : Colors.red;
//   }

//   Future<void> _fetchProductDetail() async {
//     if (widget.productId == null) return;

//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final productDetail = await _authService.getProductDetail(widget.productId!);
//       RecentlyViewedService.addViewed(productDetail.id, productDetail.categoryId);
//       if (!mounted) return;
//       setState(() {
//         _productDetail = productDetail;
//         _isLoading = false;
//       });
//       _fetchSimilarProducts(productDetail.categoryId, excludeProductId: productDetail.id);
//     } catch (e) {
//       // ✅ Friendly error
//       setState(() {
//         _error = 'Unable to load product. Please try again.';
//         _isLoading = false;
//       });
//       if (mounted) {
//         _showSnackBar(
//           'Unable to load product. Please try again.',
//           Colors.red,
//           icon: Icons.wifi_off_rounded,
//         );
//       }

//       // ❌ Old raw error
//       // setState(() {
//       //   _error = e.toString();
//       //   _isLoading = false;
//       // });
//       // if (mounted) {
//       //   ScaffoldMessenger.of(context).showSnackBar(
//       //     SnackBar(
//       //       content: Text('Failed to load product: ${e.toString()}'),
//       //       backgroundColor: Colors.red,
//       //     ),
//       //   );
//       // }
//     }
//   }

//   Future<void> _fetchSimilarProducts(int categoryId, {int? excludeProductId}) async {
//     setState(() => _isLoadingSimilar = true);
//     try {
//       final response = await _authService.getProductsByCategory(categoryId: categoryId, page: 1);
//       if (!mounted) return;
//       final list = response.data
//           .where((p) => excludeProductId == null || p.id != excludeProductId)
//           .take(10)
//           .toList();
//       setState(() {
//         _similarProducts = list;
//         _isLoadingSimilar = false;
//       });
//     } catch (_) {
//       if (mounted) {
//         setState(() {
//           _similarProducts = [];
//           _isLoadingSimilar = false;
//         });
//       }
//     }
//   }

//   itemModel _productToItemModel(ProductModel p) {
//     return itemModel(
//       name: p.name,
//       description: p.description,
//       price: p.price.toInt(),
//       categoryId: p.categoryId,
//       image: p.image,
//       rating: p.rating,
//       review: '',
//       fcolor: const [Colors.red, Colors.blue, Colors.green],
//       size: const ['S', 'M', 'L', 'XL'],
//     );
//   }

//   Widget _buildInfoChip(IconData icon, String label, dynamic iconColor) {
//     final color = iconColor == Colors.amber ? Colors.amber[700] : Colors.grey[600];
//     return Column(
//       children: [
//         Icon(icon, size: 22, color: color ?? Colors.grey[600]),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ],
//     );
//   }

//   itemModel get _currentProduct {
//     if (_productDetail != null) return _productDetail!.toItemModel();
//     if (widget.ecom != null) return widget.ecom!;
//     throw StateError('Neither productDetail nor ecom is available');
//   }

//   Widget _buildImage(String imageUrl, {double? height, double? width}) {
//     if (imageUrl.isEmpty) {
//       return Container(
//         height: height,
//         width: width,
//         color: Colors.grey[200],
//         child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
//       );
//     }

//     final trimmedUrl = imageUrl.trim();
//     final isNetworkImage = trimmedUrl.startsWith('http://') ||
//         trimmedUrl.startsWith('https://') ||
//         trimmedUrl.startsWith('www.') ||
//         trimmedUrl.contains('://');

//     if (isNetworkImage) {
//       return Image.network(
//         trimmedUrl,
//         height: height,
//         width: width,
//         fit: BoxFit.cover,
//         loadingBuilder: (context, child, loadingProgress) {
//           if (loadingProgress == null) return child;
//           return Container(
//             height: height,
//             width: width,
//             color: Colors.grey[200],
//             child: Center(
//               child: CircularProgressIndicator(
//                 value: loadingProgress.expectedTotalBytes != null
//                     ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
//                     : null,
//                 color: primaryColor,
//               ),
//             ),
//           );
//         },
//         errorBuilder: (context, error, stackTrace) {
//           return Container(
//             height: height,
//             width: width,
//             color: Colors.grey[200],
//             child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
//           );
//         },
//       );
//     } else {
//       return Image.asset(
//         trimmedUrl,
//         height: height,
//         width: width,
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return Container(
//             height: height,
//             width: width,
//             color: Colors.grey[200],
//             child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
//           );
//         },
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;

//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: Colors.grey[50],
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: Center(child: CircularProgressIndicator(color: primaryColor)),
//       );
//     }

//     // ❌ Old plain error state (replaced with beautiful version below)
//     // if (_error != null && _productDetail == null) {
//     //   return Scaffold(
//     //     body: Center(
//     //       child: Column(
//     //         mainAxisAlignment: MainAxisAlignment.center,
//     //         children: [
//     //           Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
//     //           const SizedBox(height: 16),
//     //           Text('Error loading product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//     //           const SizedBox(height: 8),
//     //           Text(_error!, style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
//     //           const SizedBox(height: 24),
//     //           ElevatedButton(onPressed: _fetchProductDetail, child: const Text('Retry')),
//     //         ],
//     //       ),
//     //     ),
//     //   );
//     // }

//     // ✅ Beautiful error state
//     if (_error != null && _productDetail == null) {
//       return Scaffold(
//         backgroundColor: Colors.grey[50],
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     color: Colors.red.shade50,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade300),
//                 ),
//                 const SizedBox(height: 24),
//                 const Text(
//                   "Oops! Something went wrong",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF1A202C),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   "We couldn't load this product.\nPlease check your connection and try again.",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
//                 ),
//                 const SizedBox(height: 32),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 52,
//                   child: ElevatedButton(
//                     onPressed: _fetchProductDetail,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryColor,
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     ),
//                     child: const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.refresh_rounded, size: 20),
//                         SizedBox(width: 8),
//                         Text("Try Again", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 52,
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.grey[700],
//                       side: BorderSide(color: Colors.grey[300]!),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     ),
//                     child: const Text("Go Back", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     final currentProduct = _currentProduct;

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text(
//           'Product Details',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
//         ),
//         centerTitle: true,
//         leading: Container(
//           margin: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.95),
//             shape: BoxShape.circle,
//             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))],
//           ),
//           child: IconButton(
//             icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3748), size: 18),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         actions: [
//           Consumer<WishlistService>(
//             builder: (context, wishlistService, child) {
//               final productId = widget.productId ?? _productDetail?.id;
//               final effectiveId = productId ?? 0;
//               final isInWishlist = wishlistService.isInWishlist(effectiveId);
//               final isToggling = wishlistService.isToggling(effectiveId);
//               return Container(
//                 margin: const EdgeInsets.only(right: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.95),
//                   shape: BoxShape.circle,
//                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))],
//                 ),
//                 child: IconButton(
//                   icon: isToggling
//                       ? SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
//                         )
//                       : Icon(
//                           isInWishlist ? Icons.favorite : Icons.favorite_border,
//                           color: isInWishlist ? Colors.red : Colors.black,
//                         ),
//                   onPressed: productId == null
//                       ? null
//                       : () async {
//                           try {
//                             await wishlistService.toggleWishlist(productId);
//                             if (mounted) {
//                               // ✅ Friendly wishlist success
//                               _showSnackBar(
//                                 isInWishlist
//                                     ? "${currentProduct.name} removed from wishlist"
//                                     : "${currentProduct.name} added to wishlist ❤️",
//                                 primaryColor,
//                                 icon: isInWishlist ? Icons.favorite_border : Icons.favorite,
//                               );
//                               // ❌ Old
//                               // ScaffoldMessenger.of(context).showSnackBar(
//                               //   SnackBar(
//                               //     content: Text(isInWishlist ? "... removed" : "... added"),
//                               //     backgroundColor: primaryColor,
//                               //   ),
//                               // );
//                             }
//                           } catch (e) {
//                             if (mounted) {
//                               // ✅ Friendly wishlist error
//                               _showSnackBar(
//                                 _getWishlistErrorMessage(e.toString()),
//                                 _getErrorColor(e.toString()),
//                                 icon: e.toString().contains('authenticated')
//                                     ? Icons.lock_outline
//                                     : Icons.error_outline,
//                               );
//                               // ❌ Old raw error
//                               // ScaffoldMessenger.of(context).showSnackBar(
//                               //   SnackBar(
//                               //     content: Text('Wishlist: ${e.toString()}'),
//                               //     backgroundColor: Colors.red,
//                               //   ),
//                               // );
//                             }
//                           }
//                         },
//                 ),
//               );
//             },
//           ),
//           Consumer<CartService>(
//             builder: (context, cartService, child) {
//               return Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   Container(
//                     margin: const EdgeInsets.only(right: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.95),
//                       shape: BoxShape.circle,
//                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))],
//                     ),
//                     child: IconButton(
//                       icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
//                       onPressed: () {
//                         Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
//                       },
//                     ),
//                   ),
//                   if (cartService.itemCount > 0)
//                     Positioned(
//                       right: 8,
//                       top: 4,
//                       child: Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
//                         child: Center(
//                           child: Text(
//                             "${cartService.itemCount}",
//                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               height: size.height * 0.42,
//               width: double.infinity,
//               margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(24),
//                 child: Stack(
//                   children: [
//                     Positioned.fill(
//                       child: Hero(tag: currentProduct.image, child: _buildImage(currentProduct.image)),
//                     ),
//                     Positioned(
//                       bottom: 0,
//                       left: 0,
//                       right: 0,
//                       height: 80,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                             colors: [Colors.transparent, Colors.black.withOpacity(0.2)],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             Container(
//               margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     currentProduct.name,
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1A202C),
//                       letterSpacing: -0.5,
//                       height: 1.2,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Text(
//                         "₺${currentProduct.price}",
//                         style: const TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF1A202C),
//                           letterSpacing: -0.5,
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                         decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
//                         child: Text(
//                           "1 ${getDisplayUnit(_productDetail?.unitType)}",
//                           style: TextStyle(fontSize: 13, color: Colors.orange.shade800, fontWeight: FontWeight.w600),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       _buildInfoChip(Icons.inventory_2_outlined, 'Delivered', Colors.grey),
//                       const SizedBox(width: 16),
//                       _buildInfoChip(Icons.access_time, 'Quick delivery', Colors.grey),
//                       const SizedBox(width: 16),
//                       _buildInfoChip(Icons.star, '${currentProduct.rating} reviews', Colors.amber),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
//                   const Text(
//                     "Description",
//                     style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
//                   ),
//                   const SizedBox(height: 10),
//                   LayoutBuilder(
//                     builder: (context, constraints) {
//                       final desc = currentProduct.description;
//                       final overflow = desc.length > 120 && !_descriptionExpanded;
//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             overflow ? '${desc.substring(0, 120)}...' : desc,
//                             style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
//                           ),
//                           if (desc.length > 120)
//                             GestureDetector(
//                               onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
//                               child: Padding(
//                                 padding: const EdgeInsets.only(top: 6),
//                                 child: Text(
//                                   _descriptionExpanded ? 'See less' : 'See more...',
//                                   style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 32),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "You may also like",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A202C), letterSpacing: -0.5),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildSimilarProducts(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: Container(
//         padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, -4))],
//         ),
//         child: SafeArea(
//           child: Row(
//             children: [
//               Container(
//                 height: 52,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(26),
//                   border: Border.all(color: Colors.grey[200]!, width: 1),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Material(
//                       color: Colors.transparent,
//                       child: InkWell(
//                         onTap: () {
//                           if (quantity > 1) setState(() => quantity--);
//                         },
//                         borderRadius: const BorderRadius.only(topLeft: Radius.circular(26), bottomLeft: Radius.circular(26)),
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                           child: Icon(Icons.remove, size: 22, color: quantity > 1 ? const Color(0xFF2D3748) : Colors.grey[400]),
//                         ),
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 24),
//                       child: Text(
//                         formatQtyWithUnit(quantity, _productDetail?.unitType),
//                         style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
//                       ),
//                     ),
//                     Material(
//                       color: Colors.transparent,
//                       child: InkWell(
//                         onTap: () => setState(() => quantity++),
//                         borderRadius: const BorderRadius.only(topRight: Radius.circular(26), bottomRight: Radius.circular(26)),
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                           decoration: BoxDecoration(
//                             color: primaryColor.withOpacity(0.12),
//                             borderRadius: const BorderRadius.only(topRight: Radius.circular(26), bottomRight: Radius.circular(26)),
//                           ),
//                           child: Icon(Icons.add, size: 22, color: primaryColor),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Container(
//                   height: 56,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [primaryColor, primaryColorLight],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
//                   ),
//                   child: Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       onTap: () async {
//                         if (_isAddingToCart) return;
//                         setState(() => _isAddingToCart = true);
//                         final cartService = Provider.of<CartService>(context, listen: false);
//                         try {
//                           if (widget.productId != null) {
//                             for (int i = 0; i < quantity; i++) {
//                               await cartService.addToCartByProductId(widget.productId!);
//                             }
//                           } else {
//                             for (int i = 0; i < quantity; i++) {
//                               await cartService.addToCart(currentProduct);
//                             }
//                           }
//                           if (mounted) {
//                             // ✅ Friendly cart success
//                             _showSnackBar(
//                               "$quantity x ${currentProduct.name} added to cart",
//                               primaryColor,
//                               icon: Icons.check_circle_outline,
//                             );
//                             // ❌ Old
//                             // ScaffoldMessenger.of(context).showSnackBar(
//                             //   SnackBar(
//                             //     content: Text("$quantity x ${currentProduct.name} added to cart"),
//                             //     backgroundColor: primaryColor,
//                             //     behavior: SnackBarBehavior.floating,
//                             //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             //   ),
//                             // );
//                           }
//                         } catch (e) {
//                           if (mounted) {
//                             // ✅ Friendly cart error
//                             _showSnackBar(
//                               _getCartErrorMessage(e.toString()),
//                               _getErrorColor(e.toString()),
//                               icon: e.toString().contains('authenticated')
//                                   ? Icons.lock_outline
//                                   : Icons.error_outline,
//                             );
//                             // ❌ Old raw error
//                             // final errorMessage = e.toString().replaceAll('Exception: ', '');
//                             // final isAuthError = errorMessage.contains('authenticated') || errorMessage.contains('Authentication');
//                             // ScaffoldMessenger.of(context).showSnackBar(
//                             //   SnackBar(
//                             //     content: Text(isAuthError
//                             //         ? "You must be authenticated to add items to cart"
//                             //         : "Failed to add to cart: $errorMessage"),
//                             //     backgroundColor: isAuthError ? Colors.orange : Colors.red,
//                             //     behavior: SnackBarBehavior.floating,
//                             //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             //   ),
//                             // );
//                           }
//                         } finally {
//                           if (mounted) setState(() => _isAddingToCart = false);
//                         }
//                       },
//                       borderRadius: BorderRadius.circular(16),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           if (_isAddingToCart)
//                             const SizedBox(
//                               width: 22,
//                               height: 22,
//                               child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                             )
//                           else
//                             const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
//                           const SizedBox(width: 8),
//                           Text(
//                             "Add • ₺${(currentProduct.price * quantity).toStringAsFixed(0)}",
//                             style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   List<itemModel> _getSimilarProductsFallback() {
//     final currentProduct = _currentProduct;
//     return itemC
//         .where((item) => item.categoryId == currentProduct.categoryId && item.name != currentProduct.name)
//         .take(10)
//         .toList();
//   }

//   Widget _buildSimilarProducts() {
//     final hasApiProducts = _similarProducts.isNotEmpty;
//     final fallbackItems = _getSimilarProductsFallback();
//     final useApi = hasApiProducts;
//     final itemCount = useApi ? _similarProducts.length : fallbackItems.length;

//     if (_isLoadingSimilar && !useApi) {
//       return const SizedBox(
//         height: 220,
//         child: Center(child: CircularProgressIndicator(color: primaryColor)),
//       );
//     }
//     if (itemCount == 0) return const SizedBox.shrink();

//     return SizedBox(
//       height: 220,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: itemCount,
//         itemBuilder: (context, index) {
//           if (useApi) return _buildSimilarProductCard(_similarProducts[index], index, itemCount);
//           return _buildSimilarItemModelCard(fallbackItems[index], index, itemCount);
//         },
//       ),
//     );
//   }

//   Widget _buildSimilarProductCard(ProductModel product, int index, int total) {
//     return Consumer2<CartService, WishlistService>(
//       builder: (context, cartService, wishlistService, child) {
//         final itemForCart = _productToItemModel(product);
//         final isInCart = cartService.isInCart(itemForCart);
//         final isInWishlist = wishlistService.isInWishlist(product);
//         final isToggling = wishlistService.isToggling(product.id);

//         return Container(
//           width: 160,
//           margin: EdgeInsets.only(right: index == total - 1 ? 0 : 12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.grey[200]!, width: 1),
//             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
//           ),
//           child: InkWell(
//             onTap: () {
//               Navigator.push(context, MaterialPageRoute(builder: (context) => Detail(productId: product.id)));
//             },
//             borderRadius: BorderRadius.circular(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Stack(
//                   children: [
//                     ClipRRect(
//                       borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//                       child: _buildImage(product.image, height: 120, width: double.infinity),
//                     ),
//                     Positioned(
//                       top: 8,
//                       right: 8,
//                       child: InkWell(
//                         onTap: () async {
//                           try {
//                             await wishlistService.toggleWishlist(product);
//                             if (context.mounted) {
//                               // ✅ Friendly wishlist success
//                               _showSnackBar(
//                                 isInWishlist
//                                     ? "${product.name} removed from wishlist"
//                                     : "${product.name} added to wishlist ❤️",
//                                 primaryColor,
//                                 icon: isInWishlist ? Icons.favorite_border : Icons.favorite,
//                               );
//                               // ❌ Old
//                               // ScaffoldMessenger.of(context).showSnackBar(
//                               //   SnackBar(
//                               //     content: Text(isInWishlist ? "... removed" : "... added"),
//                               //     backgroundColor: primaryColor,
//                               //     behavior: SnackBarBehavior.floating,
//                               //   ),
//                               // );
//                             }
//                           } catch (e) {
//                             if (context.mounted) {
//                               // ✅ Friendly wishlist error
//                               _showSnackBar(
//                                 _getWishlistErrorMessage(e.toString()),
//                                 _getErrorColor(e.toString()),
//                                 icon: e.toString().contains('authenticated') ? Icons.lock_outline : Icons.error_outline,
//                               );
//                               // ❌ Old raw error
//                               // ScaffoldMessenger.of(context).showSnackBar(
//                               //   SnackBar(
//                               //     content: Text('Wishlist: ${e.toString()}'),
//                               //     backgroundColor: Colors.red,
//                               //     behavior: SnackBarBehavior.floating,
//                               //   ),
//                               // );
//                             }
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             shape: BoxShape.circle,
//                             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
//                           ),
//                           child: isToggling
//                               ? SizedBox(
//                                   width: 16,
//                                   height: 16,
//                                   child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[700]),
//                                 )
//                               : Icon(
//                                   isInWishlist ? Icons.favorite : Icons.favorite_border,
//                                   color: isInWishlist ? Colors.red : Colors.grey[700],
//                                   size: 16,
//                                 ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(10),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               product.name,
//                               style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: uberBlack),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             Row(
//                               children: [
//                                 Icon(Icons.star, color: Colors.amber[700], size: 12),
//                                 const SizedBox(width: 2),
//                                 Text(product.rating.toString(), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
//                               ],
//                             ),
//                           ],
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Row(
//                               crossAxisAlignment: CrossAxisAlignment.baseline,
//                               textBaseline: TextBaseline.alphabetic,
//                               children: [
//                                 Text(
//                                   "₺${product.price.toStringAsFixed(0)}",
//                                   style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
//                                   decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
//                                   child: Text(
//                                     "1${getDisplayUnit(product.unitType)}",
//                                     style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             InkWell(
//                               onTap: () async {
//                                 if (_addingRelatedProductKey == 'pid_${product.id}') return;
//                                 setState(() => _addingRelatedProductKey = 'pid_${product.id}');
//                                 try {
//                                   await cartService.addToCartByProductId(product.id);
//                                   if (mounted) {
//                                     // ✅ Friendly cart success
//                                     _showSnackBar(
//                                       "${product.name} added to cart",
//                                       primaryColor,
//                                       icon: Icons.check_circle_outline,
//                                     );
//                                     // ❌ Old
//                                     // ScaffoldMessenger.of(context).showSnackBar(
//                                     //   SnackBar(content: Text("${product.name} added to cart"), backgroundColor: primaryColor),
//                                     // );
//                                   }
//                                 } catch (e) {
//                                   if (mounted) {
//                                     // ✅ Friendly cart error
//                                     _showSnackBar(
//                                       _getCartErrorMessage(e.toString()),
//                                       _getErrorColor(e.toString()),
//                                       icon: e.toString().contains('authenticated') ? Icons.lock_outline : Icons.error_outline,
//                                     );
//                                     // ❌ Old raw error
//                                     // final errorMessage = e.toString().replaceAll('Exception: ', '');
//                                     // final isAuthError = errorMessage.contains('authenticated') || errorMessage.contains('Authentication');
//                                     // ScaffoldMessenger.of(context).showSnackBar(
//                                     //   SnackBar(
//                                     //     content: Text(isAuthError ? "You must be authenticated..." : "Failed to add to cart: $errorMessage"),
//                                     //     backgroundColor: isAuthError ? Colors.orange : Colors.red,
//                                     //   ),
//                                     // );
//                                   }
//                                 } finally {
//                                   if (mounted) setState(() => _addingRelatedProductKey = null);
//                                 }
//                               },
//                               child: Container(
//                                 width: 28,
//                                 height: 28,
//                                 decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
//                                 child: Center(
//                                   child: _addingRelatedProductKey == 'pid_${product.id}'
//                                       ? SizedBox(
//                                           width: 16,
//                                           height: 16,
//                                           child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[700]),
//                                         )
//                                       : isInCart
//                                           ? const Icon(Icons.check, color: Colors.white, size: 16)
//                                           : const Icon(Icons.add, color: Colors.white, size: 16),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSimilarItemModelCard(itemModel product, int index, int total) {
//     return Consumer2<CartService, WishlistService>(
//       builder: (context, cartService, wishlistService, child) {
//         final isInCart = cartService.isInCart(product);
//         final isInWishlist = wishlistService.isInWishlist(0);

//         return Container(
//           width: 160,
//           margin: EdgeInsets.only(right: index == total - 1 ? 0 : 12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.grey[200]!, width: 1),
//             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
//           ),
//           child: InkWell(
//             onTap: () {
//               Navigator.push(context, MaterialPageRoute(builder: (context) => Detail(ecom: product)));
//             },
//             borderRadius: BorderRadius.circular(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Stack(
//                   children: [
//                     ClipRRect(
//                       borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//                       child: _buildImage(product.image, height: 120, width: double.infinity),
//                     ),
//                     Positioned(
//                       top: 8,
//                       right: 8,
//                       child: Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
//                         ),
//                         child: Icon(
//                           isInWishlist ? Icons.favorite : Icons.favorite_border,
//                           color: isInWishlist ? Colors.red : Colors.grey[700],
//                           size: 16,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(10),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               product.name,
//                               style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: uberBlack),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             Row(
//                               children: [
//                                 Icon(Icons.star, color: Colors.amber[700], size: 12),
//                                 const SizedBox(width: 2),
//                                 Text(
//                                   "${product.rating.toString()} (${product.review})",
//                                   style: TextStyle(fontSize: 10, color: Colors.grey[600]),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Row(
//                               crossAxisAlignment: CrossAxisAlignment.baseline,
//                               textBaseline: TextBaseline.alphabetic,
//                               children: [
//                                 Text(
//                                   "₺${product.price}",
//                                   style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
//                                   decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
//                                   child: Text(
//                                     "1piece",
//                                     style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             InkWell(
//                               onTap: () async {
//                                 final key = '${product.name}_${product.image}';
//                                 if (_addingRelatedProductKey == key) return;
//                                 setState(() => _addingRelatedProductKey = key);
//                                 try {
//                                   await cartService.addToCart(product);
//                                   if (mounted) {
//                                     // ✅ Friendly cart success
//                                     _showSnackBar(
//                                       "${product.name} added to cart",
//                                       primaryColor,
//                                       icon: Icons.check_circle_outline,
//                                     );
//                                     // ❌ Old
//                                     // ScaffoldMessenger.of(context).showSnackBar(
//                                     //   SnackBar(content: Text("${product.name} added to cart"), backgroundColor: primaryColor),
//                                     // );
//                                   }
//                                 } catch (e) {
//                                   if (mounted) {
//                                     // ✅ Friendly cart error
//                                     _showSnackBar(
//                                       _getCartErrorMessage(e.toString()),
//                                       _getErrorColor(e.toString()),
//                                       icon: e.toString().contains('authenticated') ? Icons.lock_outline : Icons.error_outline,
//                                     );
//                                     // ❌ Old raw error
//                                     // final errorMessage = e.toString().replaceAll('Exception: ', '');
//                                     // final isAuthError = errorMessage.contains('authenticated') || errorMessage.contains('Authentication');
//                                     // ScaffoldMessenger.of(context).showSnackBar(
//                                     //   SnackBar(
//                                     //     content: Text(isAuthError ? "You must be authenticated..." : "Failed to add to cart: $errorMessage"),
//                                     //     backgroundColor: isAuthError ? Colors.orange : Colors.red,
//                                     //   ),
//                                     // );
//                                   }
//                                 } finally {
//                                   if (mounted) setState(() => _addingRelatedProductKey = null);
//                                 }
//                               },
//                               child: Container(
//                                 width: 28,
//                                 height: 28,
//                                 decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
//                                 child: Center(
//                                   child: _addingRelatedProductKey == '${product.name}_${product.image}'
//                                       ? SizedBox(
//                                           width: 16,
//                                           height: 16,
//                                           child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[700]),
//                                         )
//                                       : isInCart
//                                           ? const Icon(Icons.check, color: Colors.white, size: 16)
//                                           : const Icon(Icons.add, color: Colors.white, size: 16),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }