import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Utils/wishlist_service.dart';
import 'package:vlog/presentation/screen/detail_screen.dart';

const Color _primaryRed = Color(0xFFE53E3E);

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistService>().fetchWishlist();
    });
  }

  Widget _buildImage(String imageUrl, {double? height, double? width}) {
    if (imageUrl.isEmpty) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
      );
    }
    final trimmed = imageUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: Icon(Icons.broken_image, color: Colors.grey[400], size: 30),
        ),
      );
    }
    return Image.asset(
      trimmed,
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Wishlist",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          Consumer<WishlistService>(
            builder: (context, ws, _) {
              if (!ws.loading) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
              );
            },
          ),
        ],
      ),
      body: Consumer<WishlistService>(
        builder: (context, wishlistService, child) {
          if (wishlistService.loading && wishlistService.wishlist.isEmpty) {
            return Center(child: CircularProgressIndicator(color: _primaryRed));
          }
          if (wishlistService.error != null && wishlistService.wishlist.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      wishlistService.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        wishlistService.clearError();
                        wishlistService.fetchWishlist();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final wishlist = wishlistService.wishlist;

          if (wishlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Your wishlist is empty",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Add items to your wishlist to see them here",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => wishlistService.fetchWishlist(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final item = wishlist[index];
                final p = item.product;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Detail(productId: p.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImage(p.image, width: 80, height: 80),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      p.rating.toString(),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      "₺${p.price.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.pink,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "1${p.unitType}",
                                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            onPressed: () async {
                              try {
                                await wishlistService.removeFromWishlist(item.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("${p.name} removed from wishlist"),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to remove: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
