# VLog - Food & Product Delivery App

A comprehensive Flutter-based delivery application that combines e-commerce shopping with restaurant food delivery. Users can browse products, order from restaurants, track deliveries in real-time, and manage their accounts seamlessly.

## 📱 About the App

**VLog** is a modern delivery app that serves as both an e-commerce platform and a food delivery service. The app allows users to:
- Shop for products from various categories
- Order food from multiple restaurants
- Track deliveries in real-time
- Manage orders, addresses, and payment methods
- Access customer support and FAQs

## 🏗️ App Architecture

### Data Models (8 Total)

The app uses **8 data models** to structure and manage data:

1. **`category_model.dart`** - Product categories and subcategories
2. **`delivery_address_model.dart`** - User delivery addresses with location data
3. **`menu_item_model.dart`** - Restaurant menu items and food products
4. **`model.dart`** - General product/item models for e-commerce items
5. **`order_model.dart`** - Order structure with items, status, payment, and delivery info
6. **`restaurant_model.dart`** - Restaurant information, ratings, and delivery details
7. **`subcategory_models.dart`** - Subcategory classifications for products
8. **`user_model.dart`** - User profile and account information

## 📺 Screen Documentation

### 🏠 Main Navigation Screens

#### 1. **MainScreen (Home Navigation)**
- **Location**: `lib/presentation/home.dart`
- **Purpose**: Main navigation hub with bottom navigation bar
- **Features**:
  - Bottom navigation with 5 tabs: Home, Search, Wishlist, Support, Profile
  - Manages navigation between main app sections
  - Initializes delivery tracking service

#### 2. **Realhome (Home Screen)**
- **Location**: `lib/presentation/realhome.dart`
- **Purpose**: Main home screen displaying products and categories
- **Features**:
  - Product categories grid
  - Featured products carousel
  - Product cards with images, prices, and ratings
  - Quick access to product details
  - Shopping cart integration
  - Smooth page transitions

#### 3. **SearchPage**
- **Location**: `lib/presentation/screen/search_page.dart`
- **Purpose**: Search functionality for products and items
- **Features**:
  - Real-time search with filtering
  - Search history
  - Product suggestions
  - Category-based search

#### 4. **WishlistPage**
- **Location**: `lib/presentation/screen/wishlist_page.dart`
- **Purpose**: Manage saved favorite products
- **Features**:
  - View all wishlisted items
  - Remove items from wishlist
  - Quick add to cart from wishlist
  - Empty state handling

#### 5. **SupportQAPage**
- **Location**: `lib/presentation/screen/support_qa_page.dart`
- **Purpose**: Customer support and FAQ section
- **Features**:
  - Categorized FAQs (Orders, Shipping, Returns, Products, Payment, Account)
  - Question submission form
  - Search within FAQs
  - Contact support options

#### 6. **ProfileScreen**
- **Location**: `lib/presentation/screen/profilepage.dart`
- **Purpose**: User profile and account management
- **Features**:
  - User profile display with avatar
  - Quick actions: Delivery Tracking, Payment Methods, Addresses, Order History
  - Recently viewed products
  - Settings access
  - Shopping cart access

---

### 🔐 Authentication Screens

#### 7. **LoginPage**
- **Location**: `lib/presentation/auth/login_page.dart`
- **Purpose**: User login authentication
- **Features**:
  - Email/password login
  - Google Sign-In integration
  - Apple Sign-In integration (iOS)
  - Forgot password link
  - Registration navigation

#### 8. **RegisterPage**
- **Location**: `lib/presentation/auth/register_page.dart`
- **Purpose**: New user registration
- **Features**:
  - Email/password registration
  - Social authentication options
  - Form validation
  - Terms and conditions

#### 9. **ForgotPasswordPage**
- **Location**: `lib/presentation/auth/forgot_password_page.dart`
- **Purpose**: Password recovery initiation
- **Features**:
  - Email input for password reset
  - Reset link sending
  - Success confirmation

#### 10. **ResetPasswordPage**
- **Location**: `lib/presentation/auth/reset_password_page.dart`
- **Purpose**: Password reset with token
- **Features**:
  - Token-based password reset
  - New password confirmation
  - Deep link handling

---

### 🛍️ Shopping & Product Screens

#### 11. **DetailScreen (Product Detail)**
- **Location**: `lib/presentation/screen/detail_screen.dart`
- **Purpose**: Detailed product information view
- **Features**:
  - Product images gallery
  - Product description and specifications
  - Price and rating display
  - Size and color options
  - Add to cart functionality
  - Add to wishlist
  - Quantity selector

#### 12. **CartPage**
- **Location**: `lib/presentation/screen/cart_page.dart`
- **Purpose**: Shopping cart management
- **Features**:
  - View all cart items
  - Update quantities
  - Remove items
  - Subtotal calculation
  - Delivery fee display
  - Total price calculation
  - Proceed to checkout

#### 13. **CategoryItems**
- **Location**: `lib/presentation/category_items.dart`
- **Purpose**: Display products by category
- **Features**:
  - Category-based product listing
  - Grid/list view options
  - Product filtering
  - Quick product access

---

### 🍔 Restaurant & Food Delivery Screens

#### 14. **RestaurantsHomePage**
- **Location**: `lib/presentation/restaurants/restaurants_home_page.dart`
- **Purpose**: Browse available restaurants
- **Features**:
  - Restaurant listings with ratings
  - Filter by cuisine type
  - Search restaurants
  - Delivery time estimates
  - Restaurant images and details

#### 15. **RestaurantDetailPage**
- **Location**: `lib/presentation/restaurants/restaurant_detail_page.dart`
- **Purpose**: Individual restaurant information and menu
- **Features**:
  - Restaurant information display
  - Menu categories
  - Menu items listing
  - Add items to cart
  - Delivery fee and time
  - Restaurant ratings and reviews

#### 16. **MenuItemDetailPage**
- **Location**: `lib/presentation/restaurants/menu_item_detail_page.dart`
- **Purpose**: Detailed food item information
- **Features**:
  - Food item images
  - Description and ingredients
  - Customization options
  - Price and size options
  - Add to cart
  - Special instructions

#### 17. **RestaurantCartPage**
- **Location**: `lib/presentation/screen/restaurant_cart_page.dart`
- **Purpose**: Cart for restaurant orders
- **Features**:
  - Restaurant-specific cart
  - Menu item management
  - Quantity adjustments
  - Special instructions per item

#### 18. **RestaurantSearchPage**
- **Location**: `lib/presentation/restaurants/restaurant_search_page.dart`
- **Purpose**: Search for restaurants
- **Features**:
  - Restaurant search functionality
  - Filter by location, cuisine, rating
  - Quick restaurant access

---

### 💳 Checkout & Order Screens

#### 19. **CheckoutConfirmationPage**
- **Location**: `lib/presentation/screen/checkout_confirmation_page.dart`
- **Purpose**: Final checkout and order placement
- **Features**:
  - Order summary review
  - Delivery details confirmation
  - **Delivery schedule selection (REQUIRED)**
  - Payment method selection
  - Order notes
  - **Minimum order validation (₺2000)**
  - Order confirmation dialog
  - Receipt generation

#### 20. **DeliverySchedulePage**
- **Location**: `lib/presentation/screen/delivery_schedule_page.dart`
- **Purpose**: Select delivery date and time
- **Features**:
  - Calendar date picker
  - Time slot selection
  - Available delivery windows
  - Schedule confirmation

#### 21. **ReceiptPage**
- **Location**: `lib/presentation/screen/receipt_page.dart`
- **Purpose**: Order receipt display
- **Features**:
  - Order details
  - Itemized list
  - Pricing breakdown
  - Delivery information
  - Order number
  - Print/share options

#### 22. **OrdersHistoryPage (Transaction History)**
- **Location**: `lib/presentation/screen/orders_history_page.dart`
- **Purpose**: View all past orders and transactions
- **Features**:
  - Complete order history
  - Statistics dashboard (Total Orders, Completed, Total Spent)
  - Filter by status (All, Pending, Completed, Cancelled)
  - Order details with status
  - Quick order tracking access
  - Empty state handling
  - Pull-to-refresh

#### 23. **OrderTrackingPage**
- **Location**: `lib/presentation/screen/order_tracking_page.dart`
- **Purpose**: Track individual order status
- **Features**:
  - Order status timeline
  - Current order stage
  - Estimated delivery time
  - Order details
  - Contact support option

#### 24. **DeliveryTrackingPage**
- **Location**: `lib/presentation/screen/delivery_tracking_page.dart`
- **Purpose**: Real-time delivery tracking
- **Features**:
  - Live delivery map
  - Delivery route visualization
  - Driver location tracking
  - Delivery progress stages
  - Estimated arrival time
  - Contact driver option

---

### 👤 Profile & Settings Screens

#### 25. **ProfileSettingsPage**
- **Location**: `lib/presentation/screen/profile_settings_page.dart`
- **Purpose**: Edit user profile information
- **Features**:
  - Update profile name
  - Change profile picture
  - Image picker integration
  - Save profile changes

#### 26. **SettingsPage**
- **Location**: `lib/presentation/screen/settings_page.dart`
- **Purpose**: App and account settings
- **Features**:
  - Account settings
  - Notification preferences
  - Language settings
  - Delete account option
  - Logout functionality

---

### 📍 Address Management Screens

#### 27. **DeliveryAddressPage**
- **Location**: `lib/presentation/restaurants/delivery_address_page.dart`
- **Purpose**: Manage delivery addresses
- **Features**:
  - List of saved addresses
  - Set default address
  - Edit/delete addresses
  - Add new address

#### 28. **AddEditAddressPage**
- **Location**: `lib/presentation/restaurants/add_edit_address_page.dart`
- **Purpose**: Add or edit delivery address
- **Features**:
  - Address form (street, city, postal code, country)
  - Location picker
  - Address validation
  - Save address

---

### 💬 Support & Communication Screens

#### 29. **MessagePage**
- **Location**: `lib/presentation/screen/message_page.dart`
- **Purpose**: Customer support messaging
- **Features**:
  - Message list
  - Support conversations
  - New message creation

#### 30. **ChatDetailPage**
- **Location**: `lib/presentation/screen/chat_detail_page.dart`
- **Purpose**: Individual chat conversation
- **Features**:
  - Message thread
  - Send/receive messages
  - Support agent communication
  - File attachments

---

## 🎯 Key Features

### Order Requirements
- **Minimum Order Amount**: ₺2000 (including delivery fees)
- **Delivery Schedule**: **REQUIRED** - Users must select delivery date and time before checkout
- Visual warnings and validation messages guide users

### Order Management
- Complete order history with filtering
- Real-time order tracking
- Delivery status updates
- Order statistics dashboard

### Shopping Features
- Product browsing by category
- Search functionality
- Wishlist management
- Shopping cart with quantity management
- Product details with images and specifications

### Restaurant Features
- Restaurant browsing and search
- Menu viewing
- Food item customization
- Restaurant-specific cart
- Delivery time estimates

### User Management
- Profile management with photo upload
- Multiple delivery addresses
- Order history access
- Settings and preferences
- Account deletion option

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase account (for Google/Apple authentication)

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd vlog
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase** (for Google/Apple authentication)
   
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   flutterfire configure
   ```

4. **Initialize Firebase in main.dart**

   After running `flutterfire configure`, uncomment the Firebase initialization in `lib/main.dart`:
   
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'firebase_options.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     runApp(const MyApp());
   }
   ```

## 📦 Dependencies

### Core Dependencies
- `flutter`: Flutter SDK
- `provider: ^6.0.0`: State management
- `shared_preferences: ^2.3.2`: Local data storage

### Authentication
- `firebase_core: ^3.6.0`: Firebase core functionality
- `firebase_auth: ^5.3.1`: Firebase authentication
- `google_sign_in: ^6.2.1`: Google Sign-In integration
- `sign_in_with_apple: ^6.1.1`: Apple Sign-In integration

### UI & Utilities
- `dio: ^5.9.0`: HTTP client
- `url_launcher: ^6.3.1`: Launch URLs
- `uni_links: ^0.5.1`: Deep linking
- `image_picker: ^1.0.7`: Image selection
- `shimmer: ^3.0.0`: Loading animations

## 🏃 Running the App

### Development Mode
```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d android
flutter run -d ios
flutter run -d web
```

### Build for Production

**Android**
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

**Web**
```bash
flutter build web --release
```

## 📁 Project Structure

```
lib/
├── Data/
│   └── apiservices.dart          # API services
├── Models/                       # 8 Data Models
│   ├── category_model.dart       # Category models
│   ├── delivery_address_model.dart # Delivery address models
│   ├── menu_item_model.dart      # Menu item models
│   ├── model.dart                # Product/item models
│   ├── order_model.dart          # Order models
│   ├── restaurant_model.dart     # Restaurant models
│   ├── subcategory_models.dart   # Subcategory models
│   └── user_model.dart           # User models
├── presentation/
│   ├── auth/                     # Authentication screens
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   ├── forgot_password_page.dart
│   │   └── reset_password_page.dart
│   ├── restaurants/              # Restaurant screens
│   │   ├── restaurants_home_page.dart
│   │   ├── restaurant_detail_page.dart
│   │   ├── menu_item_detail_page.dart
│   │   ├── checkout_page.dart
│   │   ├── delivery_address_page.dart
│   │   └── add_edit_address_page.dart
│   ├── screen/                   # Main app screens
│   │   ├── cart_page.dart
│   │   ├── checkout_confirmation_page.dart
│   │   ├── detail_screen.dart
│   │   ├── search_page.dart
│   │   ├── wishlist_page.dart
│   │   ├── support_qa_page.dart
│   │   ├── profilepage.dart
│   │   ├── settings_page.dart
│   │   ├── orders_history_page.dart
│   │   ├── order_tracking_page.dart
│   │   ├── delivery_tracking_page.dart
│   │   ├── delivery_schedule_page.dart
│   │   ├── receipt_page.dart
│   │   └── ...
│   ├── home.dart                 # Main navigation
│   ├── realhome.dart             # Home screen
│   └── curatedItems.dart         # Product cards
└── Utils/
    ├── cart_service.dart         # Cart state management
    ├── wishlist_service.dart     # Wishlist management
    ├── order_service.dart        # Order management
    └── delivery_tracking_service.dart # Delivery tracking
```

## ✨ Key Features Details

### Minimum Order Amount
- Users must have at least **₺2000** in their cart (including delivery fees) to proceed to checkout
- Visual indicators show remaining amount needed
- Checkout button is disabled until minimum is met
- Warning messages guide users

### Delivery Schedule Requirement
- **MANDATORY**: Users must select a delivery date and time before confirming order
- Visual indicators (red border, asterisk) show required field
- Validation prevents checkout without schedule selection
- Warning messages if schedule not selected

### Order History & Tracking
- Complete transaction history with statistics
- Filter orders by status (All, Pending, Completed, Cancelled)
- Real-time order tracking
- Delivery status updates
- Order details and receipts

### Account Management
- Profile customization with photo upload
- Multiple delivery addresses
- Order history access
- Settings and preferences
- Account deletion option

## 🔧 Configuration

### App Constants
- **Minimum order amount**: ₺2000.00 (defined in checkout page)
- **Delivery fee**: ₺250 (configurable)
- **Delivery schedule**: Required before checkout

### Environment Variables
- Firebase configuration is handled through `firebase_options.dart` (generated by FlutterFire CLI)

## 📊 App Statistics

- **Total Screens**: 30+ screens
- **Data Models**: 8 models
- **Main Features**: E-commerce shopping + Restaurant delivery
- **Navigation Tabs**: 5 main sections (Home, Search, Wishlist, Support, Profile)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👤 Author

Your Name

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for authentication services
- All package contributors

## 📞 Support

For support, email your-email@example.com or create an issue in the repository.

## 🔮 Future Enhancements

- [ ] Payment gateway integration
- [ ] Push notifications
- [ ] Product reviews and ratings system
- [ ] Social media sharing
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Advanced search filters
- [ ] Product recommendations
- [ ] Live chat support
- [ ] Order cancellation and returns
- [ ] Real-time driver tracking
- [ ] Multiple payment methods

---

**Note**: Make sure to configure Firebase properly before using Google/Apple authentication features. The app will function with email/password authentication without Firebase, but social login requires Firebase setup.
