import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/cart_service.dart';
import 'package:vlog/Utils/parse_utils.dart';
import 'package:vlog/Utils/delivery_fee_utils.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:vlog/presentation/addressess/choiceAddress.dart';

// Color scheme
const Color primaryColor = Color(0xFFE53E3E);
const Color uberBlack = Color(0xFF000000);
const Color priceRed = Color(0xFFE57373); // rouge clair

// Model for vendor/store cart
class VendorCart {
  final String id;
  final String name;
  final String image;
  final String address;
  final bool isOpen;
  final String? availableAt;
  final List<CartItem> items;

  VendorCart({
    required this.id,
    required this.name,
    required this.image,
    required this.address,
    this.isOpen = true,
    this.availableAt,
    required this.items,
  });

  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;
  String _displayName = 'Guest user';
  int? _updatingCartItemId; // cartItemId being updated (quantity +/-)

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final isAuth = await StorageService.isLoggedIn();
    String displayName = 'Guest user';
    if (isAuth) {
      final user = await StorageService.getUser();
      if (user != null) {
        final name = user['name']?.toString().trim();
        final fullName = user['full_name']?.toString().trim();
        final first = user['first_name']?.toString().trim() ?? '';
        final last = user['last_name']?.toString().trim() ?? '';
        if (name != null && name.isNotEmpty) {
          displayName = name;
        } else if (fullName != null && fullName.isNotEmpty) {
          displayName = fullName;
        } else if ('$first $last'.trim().isNotEmpty) {
          displayName = '$first $last'.trim();
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _isAuthenticated = isAuth;
      _isCheckingAuth = false;
      _displayName = displayName;
    });

    if (isAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cartService = Provider.of<CartService>(context, listen: false);
        cartService.fetchCart();
      });
    }
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

    // Trim whitespace; prepend base URL for API relative paths
    String trimmedUrl = imageUrl.trim();
    if (trimmedUrl.startsWith('/') && !trimmedUrl.startsWith('//')) {
      final base = AuthService().baseUrl;
      trimmedUrl = base.endsWith('/') ? '$base${trimmedUrl.substring(1)}' : '$base$trimmedUrl';
    }
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
                color: primaryColor,
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
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: uberBlack, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Carts",
              style: TextStyle(
                color: uberBlack,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              _displayName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to orders page
            },
            child: const Text(
              "Orders",
              style: TextStyle(
                color: uberBlack,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isCheckingAuth
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : !_isAuthenticated
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Authentication Required",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "You must be authenticated to view your cart. Please login first.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Go Back",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Consumer<CartService>(
                  builder: (context, cartService, child) {
                    // Show loading if fetching cart
                    if (cartService.isLoading && cartService.cartItems.isEmpty) {
                      return Center(child: CircularProgressIndicator(color: primaryColor));
                    }

          // Show error if exists
          if (cartService.error != null && cartService.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading cart',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cartService.error ?? 'Unknown error',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => cartService.fetchCart(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final cartItems = cartService.cartItems;

          if (cartItems.isEmpty) {
            return Center(
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
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Your cart is empty",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add items to your cart to see them here",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final currentTotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
          final double deliveryFee = calculateDeliveryFee(currentTotal);
          final double totalWithFee = currentTotal + deliveryFee;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    final item = cartItem.item;
                    final itemTotal = item.price * cartItem.quantity;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: _buildImage(
                                    item.image,
                                    width: 72,
                                    height: 72,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: uberBlack,
                                              letterSpacing: -0.3,
                                              height: 1.25,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () async {
                                              try {
                                                await cartService.removeFromCart(cartItem);
                                                await cartService.fetchCart();
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Item removed from cart'),
                                                      backgroundColor: Colors.green,
                                                      duration: Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Failed to remove item: ${e.toString()}'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            customBorder: const CircleBorder(),
                                            child: Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "₺${item.price}",
                                      style: const TextStyle(
                                        color: priceRed,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (cartItem.quantity > 1) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        "₺${itemTotal.toStringAsFixed(2)} total",
                                        style: const TextStyle(
                                          color: priceRed,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final isUpdating = cartItem.cartItemId != null &&
                                          _updatingCartItemId == cartItem.cartItemId;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () async {
                                                if (cartItem.cartItemId != null) {
                                                  setState(() => _updatingCartItemId = cartItem.cartItemId);
                                                }
                                                try {
                                                  if (cartItem.quantity > 1) {
                                                    await cartService.updateQuantity(
                                                      cartItem,
                                                      cartItem.quantity - 1,
                                                    );
                                                    await cartService.fetchCart();
                                                  } else {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('You cannot decrease, you have just one'),
                                                          backgroundColor: Colors.orange,
                                                          duration: Duration(seconds: 2),
                                                        ),
                                                      );
                                                    }
                                                    await cartService.removeFromCart(cartItem);
                                                    await cartService.fetchCart();
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Failed to update: ${e.toString()}'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  if (mounted) setState(() => _updatingCartItemId = null);
                                                }
                                              },
                                              customBorder: const CircleBorder(),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.grey[300]!),
                                                ),
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 16,
                                                  color: cartItem.quantity > 1
                                                      ? uberBlack
                                                      : Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: isUpdating
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: uberBlack,
                                                    ),
                                                  )
                                                : Text(
                                                    formatQtyWithUnit(cartItem.quantity, cartItem.unitType),
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: uberBlack,
                                                    ),
                                                    softWrap: false,
                                                  ),
                                          ),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () async {
                                                if (cartItem.cartItemId != null) {
                                                  setState(() => _updatingCartItemId = cartItem.cartItemId);
                                                }
                                                try {
                                                  await cartService.updateQuantity(
                                                    cartItem,
                                                    cartItem.quantity + 1,
                                                  );
                                                  await cartService.fetchCart();
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Failed to update: ${e.toString()}'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  if (mounted) setState(() => _updatingCartItemId = null);
                                                }
                                              },
                                              customBorder: const CircleBorder(),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.grey[300]!),
                                                ),
                                                child: const Icon(
                                                  Icons.add,
                                                  size: 16,
                                                  color: uberBlack,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Subtotal",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              "₺${currentTotal.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 15,
                                color: priceRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Delivery Fee",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            Builder(
                              builder: (_) {
                                final pct = getDeliveryFeePercent(currentTotal);
                                return Text(
                                  pct != null
                                      ? "₺${deliveryFee.toStringAsFixed(2)} (${pct.toStringAsFixed(0)}%)"
                                      : "₺${deliveryFee.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: priceRed,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: uberBlack,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "₺${totalWithFee.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: priceRed,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const _DeliveryFeeInfoBox(),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, primaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ChoiceAddress(fromCheckout: true),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: const Center(
                                  child: Text(
                                    "Go to checkout",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
            },
          ),
    );
  }
}

// Detailed cart view page
class _CartDetailPage extends StatefulWidget {
  final VendorCart vendorCart;

  const _CartDetailPage({required this.vendorCart});

  @override
  State<_CartDetailPage> createState() => _CartDetailPageState();
}

class _CartDetailPageState extends State<_CartDetailPage> {
  int? _updatingCartItemId; // cartItemId being updated (quantity +/-)

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

    // Trim whitespace; prepend base URL for API relative paths
    String trimmedUrl = imageUrl.trim();
    if (trimmedUrl.startsWith('/') && !trimmedUrl.startsWith('//')) {
      final base = AuthService().baseUrl;
      trimmedUrl = base.endsWith('/') ? '$base${trimmedUrl.substring(1)}' : '$base$trimmedUrl';
    }
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
                color: primaryColor,
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: uberBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cart",
          style: TextStyle(
            color: uberBlack,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<CartService>(
        builder: (context, cartService, child) {
          // Get current cart items from the service
          final currentCartItems = cartService.cartItems;
          
          // If cart is empty, show empty state
          if (currentCartItems.isEmpty) {
            return Center(
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
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Your cart is empty",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add items to your cart to see them here",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Calculate total from current items
          final currentTotal = currentCartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: currentCartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = currentCartItems[index];
                    final item = cartItem.item;
                    final itemTotal = item.price * cartItem.quantity;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: _buildImage(
                                    item.image,
                                    width: 72,
                                    height: 72,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: uberBlack,
                                              letterSpacing: -0.3,
                                              height: 1.25,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () async {
                                              try {
                                                await cartService.removeFromCart(cartItem);
                                                await cartService.fetchCart();
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Item removed from cart'),
                                                      backgroundColor: Colors.green,
                                                      duration: Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Failed to remove item: ${e.toString()}'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            customBorder: const CircleBorder(),
                                            child: Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "₺${item.price}",
                                      style: const TextStyle(
                                        color: priceRed,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (cartItem.quantity > 1) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        "₺${itemTotal.toStringAsFixed(2)} total",
                                        style: const TextStyle(
                                          color: priceRed,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final isUpdating = cartItem.cartItemId != null &&
                                          _updatingCartItemId == cartItem.cartItemId;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () async {
                                                if (cartItem.cartItemId != null) {
                                                  setState(() => _updatingCartItemId = cartItem.cartItemId);
                                                }
                                                try {
                                                  if (cartItem.quantity > 1) {
                                                    await cartService.updateQuantity(
                                                      cartItem,
                                                      cartItem.quantity - 1,
                                                    );
                                                    await cartService.fetchCart();
                                                  } else {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('You cannot decrease, you have just one'),
                                                          backgroundColor: Colors.orange,
                                                          duration: Duration(seconds: 2),
                                                        ),
                                                      );
                                                    }
                                                    await cartService.removeFromCart(cartItem);
                                                    await cartService.fetchCart();
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Failed to update: ${e.toString()}'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  if (mounted) setState(() => _updatingCartItemId = null);
                                                }
                                              },
                                              customBorder: const CircleBorder(),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.grey[300]!),
                                                ),
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 16,
                                                  color: cartItem.quantity > 1
                                                      ? uberBlack
                                                      : Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: isUpdating
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: uberBlack,
                                                    ),
                                                  )
                                                : Text(
                                                    formatQtyWithUnit(cartItem.quantity, cartItem.unitType),
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: uberBlack,
                                                    ),
                                                    softWrap: false,
                                                  ),
                                          ),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () async {
                                                if (cartItem.cartItemId != null) {
                                                  setState(() => _updatingCartItemId = cartItem.cartItemId);
                                                }
                                                try {
                                                  await cartService.updateQuantity(
                                                    cartItem,
                                                    cartItem.quantity + 1,
                                                  );
                                                  await cartService.fetchCart();
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Failed to update: ${e.toString()}'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  if (mounted) setState(() => _updatingCartItemId = null);
                                                }
                                              },
                                              customBorder: const CircleBorder(),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.grey[300]!),
                                                ),
                                                child: const Icon(
                                                  Icons.add,
                                                  size: 16,
                                                  color: uberBlack,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Subtotal",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              "₺${currentTotal.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 15,
                                color: priceRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Delivery Fee",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            Builder(
                              builder: (_) {
                                final fee = calculateDeliveryFee(currentTotal);
                                final pct = getDeliveryFeePercent(currentTotal);
                                return Text(
                                  pct != null
                                      ? "₺${fee.toStringAsFixed(2)} (${pct.toStringAsFixed(0)}%)"
                                      : "₺${fee.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: priceRed,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: uberBlack,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "₺${(currentTotal + calculateDeliveryFee(currentTotal)).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: priceRed,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const _DeliveryFeeInfoBox(),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, primaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ChoiceAddress(fromCheckout: true),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: const Center(
                                  child: Text(
                                    "Go to checkout",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeliveryFeeInfoBox extends StatelessWidget {
  const _DeliveryFeeInfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.06),
            primaryColor.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'Delivery fees',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _FeeChip(label: '1–750 ₺', value: '₺355'),
              _FeeChip(label: '751–1500 ₺', value: '₺500'),
              _FeeChip(label: '1501–2500 ₺', value: '₺750'),
              _FeeChip(label: 'From ₺2501 and above', value: '25% ★★★', isBest: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeChip extends StatelessWidget {
  const _FeeChip({required this.label, required this.value, this.isBest = false});

  final String label;
  final String value;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isBest ? primaryColor.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBest ? primaryColor.withOpacity(0.4) : primaryColor.withOpacity(0.15),
          width: isBest ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isBest ? 0.05 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: isBest ? primaryColor : Colors.grey.shade700, fontWeight: FontWeight.w500),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: '→ $value',
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
