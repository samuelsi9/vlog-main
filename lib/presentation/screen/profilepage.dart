import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Models/user_model.dart';
import 'package:vlog/Models/model.dart';
import 'package:vlog/Utils/cart_service.dart';
import 'package:vlog/presentation/screen/cart_page.dart';
import 'package:vlog/presentation/screen/detail_screen.dart';
import 'package:vlog/presentation/screen/profile_settings_page.dart';
import 'package:vlog/presentation/screen/settings_page.dart';
import 'package:vlog/presentation/screen/delivery_tracking_page.dart';
import 'package:vlog/presentation/screen/orders_history_page.dart';
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
  // Use items from the existing itemModel list
  List<itemModel> get recentItems => itemC.take(4).toList();

  String? _localProfileName;
  String? _localProfileImagePath;

  @override
  void initState() {
    super.initState();
    _loadLocalProfile();
  }

  Future<void> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localProfileName = prefs.getString('profile_name');
      _localProfileImagePath = prefs.getString('profile_image_path');
    });
  }

  Future<void> _saveProfile(String name, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    if (imagePath != null) {
      await prefs.setString('profile_image_path', imagePath);
    }
    setState(() {
      _localProfileName = name;
      _localProfileImagePath = imagePath;
    });
  }

  String get _displayName {
    if (_localProfileName != null && _localProfileName!.isNotEmpty) {
      return _localProfileName!;
    }
    return widget.user?.name ?? "Guest User";
  }

  ImageProvider get _profileImage {
    // Priority: local image path > user model image > default asset
    if (_localProfileImagePath != null && _localProfileImagePath!.isNotEmpty) {
      try {
        return FileImage(File(_localProfileImagePath!));
      } catch (e) {
        // If file doesn't exist, fall back to default
        return const AssetImage('assets/man.jpg');
      }
    }
    if (widget.user?.image != null &&
        widget.user!.image.isNotEmpty &&
        !widget.user!.image.startsWith('assets/')) {
      return NetworkImage(widget.user!.image);
    }
    return const AssetImage('assets/man.jpg');
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
                              currentImage:
                                  _localProfileImagePath ?? widget.user?.image,
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
                                  backgroundImage: _profileImage,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Addresses coming soon"),
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

            // Recently viewed items grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final item = recentItems[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Detail(ecom: item),
                      ),
                    );
                  },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
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
                          borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                          ),
                              child: Stack(
                                children: [
                                  Image.asset(
                            item.image,
                                    height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.favorite_border,
                                        size: 16,
                                        color: Colors.grey[700],
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                            item.name,
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[50],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: Colors.amber[700],
                                                size: 11,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                item.rating.toString(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.amber[900],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                            "₺${item.price}",
                                            style: TextStyle(
                                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                              letterSpacing: -0.5,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Consumer<CartService>(
                                          builder:
                                              (context, cartService, child) {
                                            return Material(
                                              color: primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: InkWell(
                                                onTap: () {
                                    cartService.addToCart(item);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "${item.name} added to cart",
                                        ),
                                                      duration: const Duration(
                                                          seconds: 1),
                                                      backgroundColor:
                                                          primaryColor,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                10),
                                                      ),
                                      ),
                                    );
                                  },
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: primaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                ),
                              );
                            },
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
                  childCount: recentItems.length,
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
