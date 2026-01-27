import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/restaurant_model.dart';
import '../../Models/order_model.dart';
import '../../Utils/restaurant_cart_service.dart';
import '../../Utils/order_service.dart';
import '../../Utils/delivery_address_service.dart';
import '../screen/order_tracking_page.dart';
import 'delivery_address_page.dart';

class CheckoutPage extends StatefulWidget {
  final Restaurant restaurant;

  const CheckoutPage({super.key, required this.restaurant});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  PaymentMethod? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = PaymentMethod(type: 'cash');
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<RestaurantCartService>(context);
    final orderService = Provider.of<OrderService>(context);
    final addressService = Provider.of<DeliveryAddressService>(context);
    
    final subtotal = cartService.subtotal;
    final tax = subtotal * 0.10;
    final total = subtotal + widget.restaurant.deliveryFee + tax;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Commande",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adresse de livraison
            _buildSection(
              "Adresse de livraison",
              addressService.selectedAddress != null
                  ? addressService.selectedAddress!.fullAddress
                  : "Aucune adresse sélectionnée",
              Icons.location_on,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeliveryAddressPage()),
                ).then((_) => setState(() {}));
              },
            ),
            
            const SizedBox(height: 24),
            
            // Récapitulatif de commande
            const Text(
              "Récapitulatif",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ...cartService.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${item.quantity}x ${item.menuItem.name}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            "${item.totalPrice.toStringAsFixed(2)}€",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildPriceRow("Sous-total", subtotal),
                  _buildPriceRow("Frais de livraison", widget.restaurant.deliveryFee),
                  _buildPriceRow("TVA (10%)", tax),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${total.toStringAsFixed(2)}€",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Méthode de paiement
            const Text(
              "Méthode de paiement",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodOption(
              'cash',
              'Espèces',
              Icons.money,
              'Payer à la livraison',
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodOption(
              'card',
              'Carte bancaire',
              Icons.credit_card,
              'Paiement sécurisé',
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: addressService.selectedAddress != null
                ? () async {
                    final orderItems = cartService.toOrderItems();
                    final deliveryAddress = DeliveryAddress(
                      id: addressService.selectedAddress!.id,
                      street: addressService.selectedAddress!.street,
                      city: addressService.selectedAddress!.city,
                      postalCode: addressService.selectedAddress!.postalCode,
                      country: addressService.selectedAddress!.country,
                      latitude: addressService.selectedAddress!.latitude,
                      longitude: addressService.selectedAddress!.longitude,
                      instructions: addressService.selectedAddress!.instructions,
                    );

                    await orderService.placeOrder(
                      userId: 'user1', // À remplacer par l'ID utilisateur réel
                      restaurant: widget.restaurant,
                      items: orderItems,
                      deliveryAddress: deliveryAddress,
                      paymentMethod: _selectedPaymentMethod!,
                    );

                    cartService.clearCart();

                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingPage(
                            orderId: orderService.currentOrder!.id,
                          ),
                        ),
                        (route) => route.isFirst,
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              addressService.selectedAddress != null
                  ? "Confirmer la commande - ${total.toStringAsFixed(2)}€"
                  : "Sélectionner une adresse",
              style: TextStyle(
                color: addressService.selectedAddress != null ? Colors.white : Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.black),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            "${amount.toStringAsFixed(2)}€",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String title, IconData icon, String subtitle) {
    final isSelected = _selectedPaymentMethod?.type == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = PaymentMethod(type: value);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.black : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.black),
          ],
        ),
      ),
    );
  }
}







