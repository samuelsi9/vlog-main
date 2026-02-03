import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/presentation/screen/profilepage.dart';
import 'package:vlog/presentation/realhome.dart';
import 'package:vlog/presentation/screen/wishlist_page.dart';
import 'package:vlog/presentation/screen/search_page.dart';
import 'package:vlog/presentation/screen/support_qa_page.dart';
import 'package:vlog/Utils/delivery_tracking_service.dart';
import 'package:vlog/Utils/cart_service.dart';

class MainScreen extends StatefulWidget {
  final String? token;
  const MainScreen({super.key, required this.token});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialiser les données de démonstration du service de tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trackingService = Provider.of<DeliveryTrackingService>(
        context,
        listen: false,
      );
      trackingService.initializeDemoData();
      
      // Initialize cart from API
      final cartService = Provider.of<CartService>(
        context,
        listen: false,
      );
      cartService.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List pages = [
      Realhome(),
      const SearchPage(),
      const WishlistPage(),
      const SupportQAPage(),
      ProfileScreen(),
 
    ];
    print(widget.token);
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.black38,
        selectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (value) {
          setState(() {});
          selectedIndex = value;
        },
        elevation: 0,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: "Wishlist",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: "Support",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: "Profile",
          ),
          
        ],
      ),
      body: pages[selectedIndex],
    );
  }
}
