import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/cart_service.dart';
import 'package:vlog/Utils/parse_utils.dart';
import 'package:vlog/Utils/delivery_fee_utils.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:vlog/Models/delivery_address_model.dart';
import 'package:vlog/presentation/home.dart';
import 'package:vlog/presentation/screen/delivery_schedule_page.dart';
import 'package:vlog/presentation/screen/delivery_tracking_page.dart';

// Red color scheme (matching home page)
const Color primaryColor = Color(0xFFE53E3E);
const Color primaryColorLight = Color(0xFFFC8181);

class CheckoutConfirmationPage extends StatefulWidget {
  /// Address chosen in ChoiceAddress (used for delivery details).
  final DeliveryAddressModel? selectedAddress;

  const CheckoutConfirmationPage({super.key, this.selectedAddress});

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

  /// Loaded from StorageService (user name, phone) and selectedAddress.
  String _fullName = 'Customer';
  String _phone = '';
  String _address = '123 Main Street';
  String _city = 'Istanbul';

  @override
  void initState() {
    super.initState();
    _loadDeliveryDetails();
  }

  /// Loads auth user (name, phone) from StorageService and chosen address from ChoiceAddress.
  Future<void> _loadDeliveryDetails() async {
    final user = await StorageService.getUser();
    final addr = widget.selectedAddress;
    if (!mounted) return;
    setState(() {
      // Auth user name: name, full_name, or first_name + last_name
      final name = user?['name']?.toString().trim();
      final fullName = user?['full_name']?.toString().trim();
      final first = user?['first_name']?.toString().trim() ?? '';
      final last = user?['last_name']?.toString().trim() ?? '';
      _fullName = (name?.isNotEmpty == true)
          ? name!
          : (fullName?.isNotEmpty == true)
              ? fullName!
              : '$first $last'.trim().isEmpty
                  ? 'Customer'
                  : '$first $last'.trim();
      // Auth user phone; fallback to address phone if present
      _phone = user?['phone']?.toString().trim() ??
          user?['phone_number']?.toString().trim() ??
          '';
      if (addr != null) {
        _address = addr.fullAddress;
        _city = addr.city.isNotEmpty ? addr.city : _city;
        if (_phone.isEmpty && addr.phone != null && addr.phone!.trim().isNotEmpty) {
          _phone = addr.phone!.trim();
        }
      }
      if (_phone.isEmpty) _phone = '+90 555 123 4567';
    });
  }

  /// Build image widget: handles empty, network URLs, asset paths, and API relative paths.
  Widget _buildImage(String imageUrl, {double? width, double? height}) {
    if (imageUrl.isEmpty) {
      return Container(
        width: width ?? 50,
        height: height ?? 50,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 28),
      );
    }
    String trimmed = imageUrl.trim();
    // API relative paths (e.g. /storage/products/...) need base URL
    if (trimmed.startsWith('/') && !trimmed.startsWith('//')) {
      final base = AuthService().baseUrl;
      trimmed = base.endsWith('/') ? '$base${trimmed.substring(1)}' : '$base$trimmed';
    }
    final isNetwork = trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('www.') ||
        trimmed.contains('://');
    if (isNetwork) {
      return Image.network(
        trimmed,
        width: width ?? 50,
        height: height ?? 50,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width ?? 50,
            height: height ?? 50,
            color: Colors.grey[200],
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
          );
        },
        errorBuilder: (context, _, __) => Container(
          width: width ?? 50,
          height: height ?? 50,
          color: Colors.grey[200],
          child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 28),
        ),
      );
    }
    return Image.asset(
      trimmed,
      width: width ?? 50,
      height: height ?? 50,
      fit: BoxFit.cover,
      errorBuilder: (context, _, __) => Container(
        width: width ?? 50,
        height: height ?? 50,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 28),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = Provider.of<CartService>(context, listen: false);

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

    if (widget.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final addressId = int.tryParse(widget.selectedAddress!.id) ?? 0;
    if (addressId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid delivery address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final auth = AuthService();
      final paymentMethod = _selectedPaymentMethod == 'cod' ? 'cash_on_delivery' : _selectedPaymentMethod;
      final d = _selectedDeliveryDate!;
      final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final deliveryTime = '$dateStr $_selectedDeliveryTime';
      final response = await auth.placeOrder(
        addressId: addressId,
        paymentMethod: paymentMethod,
        deliveryTime: deliveryTime,
      );

      if (!mounted) return;
      final message = response['message']?.toString() ?? '';
      if (message != 'Order placed successfully') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isEmpty ? 'Order could not be placed.' : message),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final order = response['order'] is Map ? response['order'] as Map<String, dynamic> : <String, dynamic>{};
      final orderId = order['id']?.toString() ?? '';

      cart.clearCart();

      if (!mounted) return;
      _showOrderSuccessDialog(context, orderId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showOrderSuccessDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Lottie.asset(
                  'assets/lottie/OrderPlace.json',
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order placed successfully',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Thanks for your order',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              if (orderId.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Order ID : $orderId',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DeliveryTrackingPage(orderId: orderId.isNotEmpty ? orderId : null),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Track Order'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => MainScreen(token: null),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
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
                              '₺${(cart.totalPrice + calculateDeliveryFee(cart.totalPrice)).toStringAsFixed(2)}',
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
                                        child: _buildImage(
                                          ci.item.image,
                                          width: 50,
                                          height: 50,
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
                                              'Qty: ${formatQtyWithUnit(ci.quantity, ci.unitType)} × ₺${ci.item.price}',
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
                                Builder(
                                  builder: (_) {
                                    final fee = calculateDeliveryFee(cart.totalPrice);
                                    final pct = getDeliveryFeePercent(cart.totalPrice);
                                    return Text(
                                      pct != null
                                          ? '₺${fee.toStringAsFixed(2)} (${pct.toStringAsFixed(0)}%)'
                                          : '₺${fee.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
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
                                  '₺${(cart.totalPrice + calculateDeliveryFee(cart.totalPrice)).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
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
                                        style: TextStyle(
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
                                      _buildFeeChip(context, '1–750 ₺', '₺355'),
                                      _buildFeeChip(context, '751–1500 ₺', '₺500'),
                                      _buildFeeChip(context, '1501–2500 ₺', '₺750'),
                                      _buildFeeChip(context, 'From ₺2501 and above', '25% ★★★', isBest: true),
                                    ],
                                  ),
                                ],
                              ),
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
                              value: _fullName,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone Number',
                              value: _phone,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              icon: Icons.home_outlined,
                              label: 'Address',
                              value: widget.selectedAddress?.buildingNumber.isNotEmpty == true
                                  ? widget.selectedAddress!.buildingNumber
                                  : _address,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              icon: Icons.location_city_outlined,
                              label: 'City',
                              value: _city,
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
                            InkWell(
                              onTap: () => setState(() => _selectedPaymentMethod = 'cod'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
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
                                    setState(() => _selectedPaymentMethod = value!);
                                  },
                                  activeColor: primaryColor,
                                  secondary: Icon(
                                    Icons.money,
                                    color: _selectedPaymentMethod == 'cod' ? primaryColor : Colors.grey[600],
                                    size: 28,
                                  ),
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
                          final bool hasDeliverySchedule = _selectedDeliveryDate != null && _selectedDeliveryTime != null;

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
                          final bool hasDeliverySchedule = _selectedDeliveryDate != null && _selectedDeliveryTime != null;
                          final bool canPlaceOrder = hasDeliverySchedule && cart.cartItems.isNotEmpty;

                          final String buttonText = !hasDeliverySchedule ? 'Select Delivery Time' : 'Place Order';

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

  Widget _buildFeeChip(BuildContext context, String label, String value, {bool isBest = false}) {
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
