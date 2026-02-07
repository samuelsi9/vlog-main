import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/order_model.dart';
import '../../Utils/order_service.dart';
import '../restaurants/restaurants_home_page.dart';

class _TimelineStep {
  final String title;
  final String subtitle;
  const _TimelineStep(this.title, this.subtitle);
}

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  @override
  Widget build(BuildContext context) {
    final orderService = Provider.of<OrderService>(context);
    final order = orderService.getOrderById(widget.orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Suivi de commande')),
        body: const Center(child: Text('Commande introuvable')),
      );
    }

    const timelineSteps = [
      _TimelineStep('Pending', 'Your order has been placed and is waiting for confirmation'),
      _TimelineStep('Confirmed', 'Your order got confirmed'),
      _TimelineStep('Preparing', 'We started preparing your order'),
      _TimelineStep('Shipped', 'Your order is on the way'),
      _TimelineStep('Delivered', 'Enjoy your meal. Don\'t forget to rate us!'),
    ];
    final currentStepIndex = _statusToTimelineIndex(order.status);
    final isCompleted = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Status',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.grey[700]),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.phone, color: Colors.grey[700]),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & status chip
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  Icon(Icons.receipt_long, color: Colors.grey[700], size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.storeName,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.red.withOpacity(0.1)
                          : _chipColor(order.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCancelled ? 'Cancelled' : _statusChipText(order.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCancelled ? Colors.red : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Restaurant info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child:
                          order.storeImage != null &&
                              order.storeImage!.isNotEmpty
                          ? Image.asset(
                              order.storeImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.restaurant,
                                  size: 40,
                                  color: Colors.grey[400],
                                );
                              },
                            )
                          : Icon(
                              Icons.restaurant,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.storeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.statusText,
                          style: TextStyle(
                            fontSize: 14,
                            color: isCancelled ? Colors.red : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order details
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Détails de la commande',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Text(
                            "${item.quantity}x",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
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
                  _buildPriceRow("Sous-total", order.subtotal),
                  _buildPriceRow("Frais de livraison", order.shippingFee),
                  _buildPriceRow("TVA", order.tax),
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
                        "${order.total.toStringAsFixed(2)}€",
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

            const SizedBox(height: 16),

            // Delivery address
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adresse de livraison',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.deliveryAddress.fullAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (order.deliveryAddress.instructions != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Note: ${order.deliveryAddress.instructions}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order status timeline (Pending → Confirmed → Preparing → Shipped → Delivered)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order progress',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(timelineSteps.length, (index) {
                    final step = timelineSteps[index];
                    final isReached = index <= currentStepIndex && !isCancelled;
                    final isCurrent = index == currentStepIndex && !isCancelled;
                    final isLast = index == timelineSteps.length - 1;
                    return _buildTimelineRow(
                      context: context,
                      title: step.title,
                      subtitle: step.subtitle,
                      isCompleted: isReached && !isCurrent,
                      isCurrent: isCurrent,
                      isPending: !isReached || isCancelled,
                      showLine: !isLast,
                      order: order,
                      index: index,
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            if (!isCompleted && !isCancelled)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Annuler la commande"),
                          content: const Text(
                            "Êtes-vous sûr de vouloir annuler cette commande?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Non",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                orderService.cancelOrder(order.id);
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Oui, annuler",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Annuler la commande",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Back to home button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RestaurantsHomePage(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Retour à l'accueil",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
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
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            "${amount.toStringAsFixed(2)}€",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Maps OrderStatus to timeline step index (Pending=0 .. Delivered=4).
  static int _statusToTimelineIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.processing:
        return 2;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  Widget _buildTimelineRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
    required bool isPending,
    required bool showLine,
    required Order order,
    required int index,
  }) {
    final green = const Color(0xFF4CAF50);
    final grey = Colors.grey;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? green : (isCurrent ? green.withOpacity(0.3) : grey[300]),
                ),
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: isCompleted ? Colors.white : (isPending ? grey[400] : green),
                ),
              ),
              if (showLine)
                Container(
                  width: 2,
                  height: 44,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? green : grey[300],
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPending ? grey[500] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: grey[600],
                      height: 1.3,
                    ),
                  ),
                  if (isCurrent && order.estimatedDelivery != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Estimated delivery: ${_formatTime(order.estimatedDelivery!)}',
                      style: TextStyle(fontSize: 12, color: grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusChipText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Preparing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _chipColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return const Color(0xFF4CAF50);
      case OrderStatus.delivered:
        return Colors.green[700]!;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
