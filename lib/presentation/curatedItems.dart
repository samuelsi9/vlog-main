import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Models/model.dart';
import 'package:vlog/Utils/wishlist_service.dart';

class Curateditems extends StatelessWidget {
  final itemModel eCommerceItems;
  final Size size;
  const Curateditems({
    super.key,
    required this.eCommerceItems,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final wishlistService = Provider.of<WishlistService>(context);
    final isInWishlist = wishlistService.isInWishlist(eCommerceItems);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage(eCommerceItems.image),
            ),
          ),
          height: size.height * 0.25,
          width: size.width * 0.5,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () {
                  wishlistService.toggleWishlist(eCommerceItems);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isInWishlist
                            ? "${eCommerceItems.name} removed from wishlist"
                            : "${eCommerceItems.name} added to wishlist",
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black26,
                  child: Icon(
                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: isInWishlist ? Colors.red : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "#",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black26,
              ),
            ),
            SizedBox(width: 5),
            Icon(Icons.star, color: Colors.amber, size: 17),
            Text(eCommerceItems.rating.toString()),
            Text(
              "(${eCommerceItems.review})",
              style: TextStyle(color: Colors.black26),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "₺${eCommerceItems.price.toString()}.00",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.pink,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
