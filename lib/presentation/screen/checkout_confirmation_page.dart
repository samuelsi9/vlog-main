import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Utils/cart_service.dart';
import 'package:vlog/presentation/screen/receipt_page.dart';
import 'package:vlog/presentation/screen/delivery_schedule_page.dart';

// Red color scheme (matching home page)
const Color primaryColor = Color(0xFFE53E3E);
const Color primaryColorLight = Color(0xFFFC8181);

class CheckoutConfirmationPage extends StatefulWidget {
  const CheckoutConfirmationPage({super.key});

  @override
  State<CheckoutConfirmationPage> createState() =>
      _CheckoutConfirmationPageState();
}

class _CheckoutConfirmationPageState extends State<CheckoutConfirmationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  String _selectedPaymentMethod = 'cod';
  DateTime? _selectedDeliveryDate;
  String? _selectedDeliveryTime;
  
  // Default delivery details (can be loaded from user profile or preferences)
  final String _defaultFullName = 'Customer';
  final String _defaultPhone = '+90 555 123 4567';
  final String _defaultAddress = '123 Main Street';
  final String _defaultCity = 'Istanbul';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _placeOrder(BuildContext context) {
    final cart = Provider.of<CartService>(context, listen: false);
    const double minimumOrderAmount = 2000.0;
    final double totalWithDelivery = cart.totalPrice + 250;
    
    // Validate minimum order amount
    if (totalWithDelivery < minimumOrderAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum order amount is ₺${minimumOrderAmount.toStringAsFixed(2)}. Please add more items.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate delivery schedule is selected
    if (_selectedDeliveryDate == null || _selectedDeliveryTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a delivery date and time before proceeding.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show success dialog with better message
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order Confirmed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your order has been successfully placed!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order Total: ₺${totalWithDelivery.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'You will receive a confirmation email shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Save cart items before clearing
              final savedItems = List<CartItem>.from(cart.cartItems);
              final savedSubtotal = cart.totalPrice;
              
              // Navigate to receipt page with saved items
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ReceiptPage(
                    customerName: _defaultFullName,
                    restaurantName: "Vlog Store",
                    restaurantAddress: _defaultAddress,
                    orderDate: DateTime.now(),
                    savings: 0.0, // You can calculate savings based on promotions
                    deliveryDate: _selectedDeliveryDate,
                    deliveryTimeSlot: _selectedDeliveryTime,
                    orderItems: savedItems,
                    orderSubtotal: savedSubtotal,
                  ),
                ),
              );
              // Clear cart after navigation
              cart.clearCart();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColorLight],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'View Receipt',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Section at the top
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '₺${(cart.totalPrice + 250).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Order Summary Section
                      Container(
                        padding: const EdgeInsets.all(20),
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
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shopping_cart_outlined, color: primaryColor, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'Order Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (cart.cartItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Your cart is empty.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              ...cart.cartItems.map(
                                (ci) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          ci.item.image,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ci.item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Qty: ${ci.quantity} × ₺${ci.item.price}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₺${ci.totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₺${cart.totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Delivery Fee',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₺250',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '₺${(cart.totalPrice + 250).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Delivery Details Section
                      Container(
                        padding: const EdgeInsets.all(20),
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
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, color: primaryColor, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delivery Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildDetailRow(
                              icon: Icons.person_outline,
                              label: 'Full Name',
                              value: _defaultFullName,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone Number',
                              value: _defaultPhone,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              icon: Icons.home_outlined,
                              label: 'Address',
                              value: _defaultAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              icon: Icons.location_city_outlined,
                              label: 'City',
                              value: _defaultCity,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Delivery Schedule Section
                      Container(
                        padding: const EdgeInsets.all(20),
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
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule, color: primaryColor, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delivery Schedule',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DeliverySchedulePage(
                                      initialDate: _selectedDeliveryDate,
                                      initialTimeSlot: _selectedDeliveryTime,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    _selectedDeliveryDate = result['date'] as DateTime?;
                                    _selectedDeliveryTime = result['timeSlot'] as String?;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedDeliveryDate != null && _selectedDeliveryTime != null
                                        ? primaryColor
                                        : Colors.red[300]!,
                                    width: _selectedDeliveryDate != null && _selectedDeliveryTime != null ? 2 : 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedDeliveryDate != null && _selectedDeliveryTime != null
                                          ? Icons.calendar_today
                                          : Icons.calendar_today_outlined,
                                      color: _selectedDeliveryDate != null && _selectedDeliveryTime != null
                                          ? primaryColor
                                          : Colors.red[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedDeliveryDate != null &&
                                                    _selectedDeliveryTime != null
                                                ? '${_formatDate(_selectedDeliveryDate!)} • $_selectedDeliveryTime'
                                                : 'Select delivery date and time *',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: _selectedDeliveryDate != null && _selectedDeliveryTime != null
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: _selectedDeliveryDate != null && _selectedDeliveryTime != null
                                                  ? Colors.black87
                                                  : Colors.red[700],
                                            ),
                                          ),
                                          if (_selectedDeliveryDate == null || _selectedDeliveryTime == null)
                                            const SizedBox(height: 4),
                                          if (_selectedDeliveryDate == null || _selectedDeliveryTime == null)
                                            Text(
                                              'Required: Choose when you want your order delivered',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: _selectedDeliveryDate != null && _selectedDeliveryTime != null
                                          ? Colors.grey[400]
                                          : Colors.red[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment Method Section
                      Container(
                        padding: const EdgeInsets.all(20),
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
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payment_outlined, color: primaryColor, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedPaymentMethod == 'cod'
                                      ? primaryColor
                                      : Colors.grey[300]!,
                                  width: _selectedPaymentMethod == 'cod' ? 2 : 1,
                                ),
                              ),
                              child: RadioListTile<String>(
                                value: 'cod',
                                groupValue: _selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                },
                                activeColor: primaryColor,
                                title: const Text(
                                  'Cash on Delivery',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text(
                                  'Pay in cash when your order is delivered',
                                  style: TextStyle(fontSize: 12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Order Notes Section
                      Container(
                        padding: const EdgeInsets.all(20),
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
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note_outlined, color: primaryColor, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'Order Notes (Optional)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                hintText: 'Add any special instructions...',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                              ),
                              minLines: 3,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),

                      // Validation warnings
                      Builder(
                        builder: (context) {
                          const double minimumOrderAmount = 2000.0;
                          final double totalWithDelivery = cart.totalPrice + 250;
                          final bool meetsMinimumAmount = totalWithDelivery >= minimumOrderAmount;
                          final bool hasDeliverySchedule = _selectedDeliveryDate != null && _selectedDeliveryTime != null;

                          // Show minimum amount warning
                          if (!meetsMinimumAmount) {
                            final double remainingAmount = minimumOrderAmount - totalWithDelivery;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Minimum Order Required',
                                          style: TextStyle(
                                            color: Colors.orange[900],
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Add ₺${remainingAmount.toStringAsFixed(2)} more to place your order',
                                          style: TextStyle(
                                            color: Colors.orange[800],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Show delivery schedule warning
                          if (!hasDeliverySchedule) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, color: Colors.red[700], size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Delivery Schedule Required',
                                          style: TextStyle(
                                            color: Colors.red[900],
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Please select a delivery date and time to proceed',
                                          style: TextStyle(
                                            color: Colors.red[800],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 24),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              // Place Order Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColorLight],
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
                      child: Builder(
                        builder: (context) {
                          const double minimumOrderAmount = 2000.0;
                          final double totalWithDelivery = cart.totalPrice + 250;
                          final bool meetsMinimumAmount = totalWithDelivery >= minimumOrderAmount;
                          final bool hasDeliverySchedule = _selectedDeliveryDate != null && _selectedDeliveryTime != null;
                          final bool canPlaceOrder = meetsMinimumAmount && 
                                                     hasDeliverySchedule && 
                                                     cart.cartItems.isNotEmpty;

                          String buttonText = 'Place Order';
                          if (!meetsMinimumAmount) {
                            buttonText = 'Minimum: ₺${minimumOrderAmount.toStringAsFixed(2)}';
                          } else if (!hasDeliverySchedule) {
                            buttonText = 'Select Delivery Time';
                          }

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: canPlaceOrder ? () => _placeOrder(context) : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      canPlaceOrder ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                      color: canPlaceOrder ? Colors.white : Colors.grey[400],
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      buttonText,
                                      style: TextStyle(
                                        color: canPlaceOrder ? Colors.white : Colors.grey[400],
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final day = date.day;
    return '$weekday, $month $day';
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
