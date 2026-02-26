import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Models/user_model.dart';
import 'package:vlog/Models/product_model.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/cart_service.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:vlog/Utils/recently_viewed_service.dart';
import 'package:vlog/Utils/wishlist_service.dart';
import 'package:vlog/presentation/screen/cart_page.dart';
import 'package:vlog/presentation/screen/detail_screen.dart';
import 'package:vlog/presentation/screen/profile_settings_page.dart';
import 'package:vlog/presentation/screen/settings_page.dart';
import 'package:vlog/presentation/screen/delivery_tracking_page.dart';
import 'package:vlog/presentation/screen/orders_history_page.dart';
import 'package:vlog/presentation/addressess/choiceAddress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// ---------- MAIN SCREEN ----------
class ProfileScreen extends StatefulWidget {
  final String? token;
  final UserModel? user;

  const ProfileScreen({super.key, this.token, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _localProfileName;
  String? _localProfileImagePath;
  String? _authUserName;
  String? _profileAvatarUrl;

  List<ProductModel> _relatedProducts = [];
  bool _isLoadingRelated = true;
  int? _addingProductId;

  @override
  void initState() {
    super.initState();
    _loadLocalProfile();
    _fetchRelatedProducts();
  }

  Future<void> _fetchRelatedProducts() async {
    setState(() => _isLoadingRelated = true);
    try {
      final recent = await RecentlyViewedService.getRecentlyViewed();
      if (recent.isEmpty) {
        if (mounted) {
          setState(() {
          _relatedProducts = [];
          _isLoadingRelated = false;
        });
        }
        return;
      }
      final categoryIds = recent.map((e) => e['categoryId']!).where((id) => id > 0).toSet().toList();
      final excludeIds = recent.map((e) => e['productId']!).where((id) => id > 0).toSet();
      final all = <ProductModel>[];
      final auth = AuthService();
      for (final catId in categoryIds) {
        try {
          final resp = await auth.getProductsByCategory(categoryId: catId, page: 1);
          for (final p in resp.data) {
            if (!excludeIds.contains(p.id) && !all.any((x) => x.id == p.id)) {
              all.add(p);
            }
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
        _relatedProducts = all.take(8).toList();
        _isLoadingRelated = false;
      });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _relatedProducts = [];
        _isLoadingRelated = false;
      });
      }
    }
  }

  Future<void> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? authName;
    String? avatarUrl;
    final isLoggedIn = await StorageService.isLoggedIn();
    if (isLoggedIn) {
      final user = await StorageService.getUser();
      if (user != null) {
        final name = user['name']?.toString().trim();
        final fullName = user['full_name']?.toString().trim();
        final first = user['first_name']?.toString().trim() ?? '';
        final last = user['last_name']?.toString().trim() ?? '';
        final email = user['email']?.toString().trim();
        if (name != null && name.isNotEmpty) {
          authName = name;
        } else if (fullName != null && fullName.isNotEmpty) {
          authName = fullName;
        } else if ('$first $last'.trim().isNotEmpty) {
          authName = '$first $last'.trim();
        } else if (email != null && email.isNotEmpty) {
          authName = email;
        }
        avatarUrl = user['avatar']?.toString().trim() ??
            user['image']?.toString().trim();
      }
    }
    if (!mounted) return;
    setState(() {
      _localProfileName = prefs.getString('profile_name');
      _localProfileImagePath = prefs.getString('profile_image_path');
      _authUserName = authName;
      _profileAvatarUrl = avatarUrl ?? prefs.getString('profile_avatar_url');
    });
  }

  Future<void> _saveProfile(String name, String? imagePath, [String? avatarUrl]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    if (imagePath != null) {
      await prefs.setString('profile_image_path', imagePath);
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      await prefs.setString('profile_avatar_url', avatarUrl);
      final user = await StorageService.getUser();
      if (user != null) {
        user['avatar'] = avatarUrl;
        await StorageService.saveUser(user);
      }
    }
    if (!mounted) return;
    setState(() {
      _localProfileName = name;
      _localProfileImagePath = imagePath;
      _profileAvatarUrl = avatarUrl ?? _profileAvatarUrl;
    });
  }

  /// Same auth user name as Realhome top bar: StorageService user (name → full_name → first+last → email).
  String get _displayName {
    if (_authUserName != null && _authUserName!.isNotEmpty) {
      return _authUserName!;
    }
    if (widget.user?.name != null && widget.user!.name.isNotEmpty) {
      return widget.user!.name;
    }
    return "Guest User";
  }

  bool get _hasProfileImage {
    if (_localProfileImagePath != null && _localProfileImagePath!.isNotEmpty) {
      try {
        File(_localProfileImagePath!);
        return true;
      } catch (_) {
        return false;
      }
    }
    if (_profileAvatarUrl != null &&
        _profileAvatarUrl!.isNotEmpty &&
        (_profileAvatarUrl!.startsWith('http://') || _profileAvatarUrl!.startsWith('https://'))) {
      return true;
    }
    if (widget.user?.image != null &&
        widget.user!.image.isNotEmpty &&
        !widget.user!.image.startsWith('assets/')) {
      return true;
    }
    return false;
  }

  ImageProvider? get _profileImage {
    if (_localProfileImagePath != null && _localProfileImagePath!.isNotEmpty) {
      try {
        return FileImage(File(_localProfileImagePath!));
      } catch (_) {
        return null;
      }
    }
    if (_profileAvatarUrl != null &&
        _profileAvatarUrl!.isNotEmpty &&
        (_profileAvatarUrl!.startsWith('http://') || _profileAvatarUrl!.startsWith('https://'))) {
      return NetworkImage(_profileAvatarUrl!);
    }
    if (widget.user?.image != null &&
        widget.user!.image.isNotEmpty &&
        !widget.user!.image.startsWith('assets/')) {
      return NetworkImage(widget.user!.image);
    }
    return null;
  }

  // Color scheme matching the app
  static const Color primaryColor = Color(0xFFE53E3E);
  static const Color primaryColorLight = Color(0xFFFC8181);
  static const Color uberBlack = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern header with gradient
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColorLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                  children: [
                    // Top bar with settings and cart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        const Text(
                          "Profile",
                          style: TextStyle(
                            fontSize: 28,
                          fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                IconButton(
                              icon: const Icon(Icons.settings_outlined,
                                  color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                Consumer<CartService>(
                  builder: (context, cartService, child) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                                      icon: const Icon(Icons.shopping_cart_outlined,
                                          color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CartPage(),
                              ),
                            );
                          },
                        ),
                        if (cartService.itemCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                            color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${cartService.itemCount}",
                                            style: TextStyle(
                                              color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
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
                    const SizedBox(height: 30),
                    // Profile section
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileSettingsPage(
                              currentName: _displayName,
                              currentImage: _profileAvatarUrl ??
                                  _localProfileImagePath ??
                                  widget.user?.image,
                              onSave: _saveProfile,
                            ),
                          ),
                        );
                        await _loadLocalProfile();
                      },
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: _hasProfileImage ? null : Colors.grey.shade300,
                                  backgroundImage: _hasProfileImage ? _profileImage : null,
                                  child: _hasProfileImage
                                      ? null
                                      : Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey.shade600,
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user?.role ?? "User",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Menu options section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: uberBlack,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
            _buildMenuOption(
              context,
              Icons.local_shipping,
                      "Delivery Tracking",
                      "Track your orders in real-time",
                      primaryColor,
              () {
                Navigator.push(
                  context,
                          MaterialPageRoute(
                              builder: (_) => const DeliveryTrackingPage()),
                        );
                      },
                    ),
                    _buildMenuOption(
                      context,
                      Icons.payment,
                      "Payment Methods",
                      "Manage your payment options",
                      Colors.blue,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Payment methods coming soon"),
                          ),
                        );
                      },
                    ),
                    _buildMenuOption(
                      context,
                      Icons.location_on,
                      "Delivery Addresses",
                      "Manage your delivery locations",
                      Colors.green,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChoiceAddress(fromCheckout: false),
                          ),
                        );
                      },
                    ),
                    _buildMenuOption(
                      context,
                      Icons.history,
                      "Order History",
                      "View your past orders",
                      Colors.orange,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrdersHistoryPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Recently Viewed",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: uberBlack,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Related products (based on recently viewed categories)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _isLoadingRelated
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator(color: primaryColor)),
                      ),
                    )
                  : _relatedProducts.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No related products yet",
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "View some products to see recommendations here",
                                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildRelatedProductCard(_relatedProducts[index]),
                            childCount: _relatedProducts.length,
                          ),
                        ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl, {double? height}) {
    if (imageUrl.isEmpty) {
      return Container(
        height: height ?? 120,
        width: double.infinity,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
      );
    }
    final trimmed = imageUrl.trim();
    final isNetwork = trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.contains('://');
    return SizedBox(
      height: height ?? 120,
      width: double.infinity,
      child: isNetwork
          ? Image.network(trimmed, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, color: Colors.grey[400]),
            ))
          : Image.asset(trimmed, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, color: Colors.grey[400]),
            )),
    );
  }

  Widget _buildRelatedProductCard(ProductModel product) {
    return Consumer2<CartService, WishlistService>(
      builder: (context, cartService, wishlistService, _) {
        final isInWishlist = wishlistService.isInWishlist(product);
        final isToggling = wishlistService.isToggling(product.id);
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Detail(productId: product.id)),
            );
            if (mounted) _fetchRelatedProducts();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    children: [
                      _buildProductImage(product.image, height: 120),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () async {
                            try {
                              await wishlistService.toggleWishlist(product);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isInWishlist
                                        ? "${product.name} removed from wishlist"
                                        : "${product.name} added to wishlist"),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Wishlist: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: isToggling
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[700]),
                                  )
                                : Icon(
                                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                                    size: 16,
                                    color: isInWishlist ? Colors.red : Colors.grey[700],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: uberBlack,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.amber[700], size: 11),
                                  const SizedBox(width: 2),
                                  Text(
                                    product.rating.toString(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.amber[900]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "₺${product.price.toStringAsFixed(0)}",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                                    overflow: TextOverflow.ellipsis,
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
                                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () async {
                                  if (_addingProductId == product.id) return;
                                  setState(() => _addingProductId = product.id);
                                  try {
                                    await cartService.addToCartByProductId(product.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("${product.name} added to cart"),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor: primaryColor,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      final msg = e.toString().replaceAll('Exception: ', '');
                                      final isAuth = msg.contains('authenticated') || msg.contains('Authentication');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isAuth ? "Sign in to add to cart" : "Failed: $msg"),
                                          backgroundColor: isAuth ? Colors.orange : Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _addingProductId = null);
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(10),
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
                                        : const Icon(Icons.add, color: Colors.white, size: 18),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
      onTap: onTap,
        borderRadius: BorderRadius.circular(20),
      child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
              offset: const Offset(0, 2),
                spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
                width: 56,
                height: 56,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 17,
                      fontWeight: FontWeight.w600,
                        color: uberBlack,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 14,
                      color: Colors.grey[600],
                        height: 1.3,
                      ),
                  ),
                ],
              ),
            ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
