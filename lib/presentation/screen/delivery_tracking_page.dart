import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Utils/delivery_tracking_service.dart';

class DeliveryTrackingPage extends StatefulWidget {
  final String? orderId;
  final String? trackingNumber;

  const DeliveryTrackingPage({
    super.key,
    this.orderId,
    this.trackingNumber,
  });

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trackingService = Provider.of<DeliveryTrackingService>(context, listen: false);
      trackingService.initializeDemoData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingService = Provider.of<DeliveryTrackingService>(context);
    DeliveryOrder? order;

    if (widget.orderId != null) {
      order = trackingService.getOrderById(widget.orderId!);
    } else if (widget.trackingNumber != null) {
      order = trackingService.getOrderByTrackingNumber(widget.trackingNumber!);
    }

    final activeOrders = trackingService.activeOrders;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Suivi de livraison',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: order != null
          ? _buildOrderTrackingView(order)
          : activeOrders.isEmpty
              ? _buildEmptyState()
              : _buildOrdersList(activeOrders),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          const Text(
            "Aucune livraison en cours",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Vos commandes en cours apparaîtront ici",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<DeliveryOrder> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(DeliveryOrder order) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryTrackingPage(orderId: order.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    order.itemImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.shopping_cart, size: 30),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.itemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.statusText,
                        style: TextStyle(
                          fontSize: 13,
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${order.totalPrice.toStringAsFixed(0)}€",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: order.progressPercentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(order.status),
              ),
            ),
            if (order.trackingNumber != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    "Suivi: ${order.trackingNumber}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTrackingView(DeliveryOrder order) {
    final steps = [
      DeliveryStatus.pending,
      DeliveryStatus.confirmed,
      DeliveryStatus.preparing,
      DeliveryStatus.ready,
      DeliveryStatus.outForDelivery,
      DeliveryStatus.delivered,
    ];

    final currentStepIndex = steps.indexOf(order.status);
    final isCancelled = order.status == DeliveryStatus.cancelled;
    final showMap = order.status == DeliveryStatus.outForDelivery;

    return Stack(
      children: [
        // Map View (Uber-like design)
        if (showMap) _buildMapView(order),
        
        // Bottom Sheet with Details
        DraggableScrollableSheet(
          initialChildSize: showMap ? 0.4 : 0.95,
          minChildSize: showMap ? 0.3 : 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: _buildOrderDetails(order, steps, currentStepIndex, isCancelled),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMapView(DeliveryOrder order) {
    return Container(
      height: double.infinity,
      color: Colors.grey[200],
      child: Stack(
        children: [
          // Placeholder Map (can be replaced with Google Maps)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              image: DecorationImage(
                image: AssetImage('assets/produt.jpeg'),
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
            ),
            child: Container(
              color: Colors.blue[50]?.withOpacity(0.3),
              child: CustomPaint(
                painter: MapRoutePainter(),
              ),
            ),
          ),
          
          // Top Info Bar
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(order.itemImage),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ),
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.itemName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              order.estimatedDelivery != null
                                  ? "Arrives in ${_getTimeRemaining(order.estimatedDelivery!)}"
                                  : "On the way",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.estimatedDelivery != null
                          ? "${_getMinutesRemaining(order.estimatedDelivery!)} min"
                          : "Soon",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Markers
          Positioned(
            left: 50,
            top: 200,
            child: _buildMapMarker(
              icon: Icons.store,
              color: Colors.blue,
              label: "Store",
            ),
          ),
          Positioned(
            right: 80,
            top: 300,
            child: _buildMapMarker(
              icon: Icons.delivery_dining,
              color: Colors.green,
              label: "Driver",
              isPulsing: true,
            ),
          ),
          Positioned(
            left: 100,
            bottom: 250,
            child: _buildMapMarker(
              icon: Icons.home,
              color: Colors.red,
              label: "You",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapMarker({
    required IconData icon,
    required Color color,
    required String label,
    bool isPulsing = false,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isPulsing)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                ),
              ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(
    DeliveryOrder order,
    List<DeliveryStatus> steps,
    int currentStepIndex,
    bool isCancelled,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Info Card
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
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    order.itemImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.shopping_cart, size: 40),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.itemName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Quantité: ${order.quantity}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Commande: ${order.orderNumber}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${order.totalPrice.toStringAsFixed(0)}€",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Progress Bar
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progression',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${(order.progressPercentage * 100).toInt()}%",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(order.status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: order.progressPercentage,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(order.status),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Timeline
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statut de la commande',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...steps.map((status) {
                  final index = steps.indexOf(status);
                  final isActive = index <= currentStepIndex && !isCancelled;
                  final isCurrent = index == currentStepIndex && !isCancelled;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? _getStatusColor(status) : Colors.grey[300],
                              ),
                              child: isActive
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            if (index < steps.length - 1)
                              Container(
                                width: 2,
                                height: 40,
                                color: isActive && !isCurrent ? _getStatusColor(status) : Colors.grey[300],
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusText(status),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: isActive ? Colors.black : Colors.grey[400],
                                ),
                              ),
                              if (isCurrent && order.estimatedDelivery != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Livraison estimée: ${_formatTime(order.estimatedDelivery!)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Delivery Info
          if (order.status == DeliveryStatus.outForDelivery && order.deliveryPersonName != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Votre livreur',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.deliveryPersonName!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (order.deliveryPersonPhone != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            order.deliveryPersonPhone!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Delivery Address
          const SizedBox(height: 16),
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
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adresse de livraison',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.deliveryAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (order.trackingNumber != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Numéro de suivi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.trackingNumber!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.grey;
      case DeliveryStatus.confirmed:
        return Colors.blue;
      case DeliveryStatus.preparing:
        return Colors.orange;
      case DeliveryStatus.ready:
        return Colors.purple;
      case DeliveryStatus.outForDelivery:
        return Colors.green;
      case DeliveryStatus.delivered:
        return Colors.green[700]!;
      case DeliveryStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Commande passée';
      case DeliveryStatus.confirmed:
        return 'Commande confirmée';
      case DeliveryStatus.preparing:
        return 'En préparation';
      case DeliveryStatus.ready:
        return 'Prête pour la livraison';
      case DeliveryStatus.outForDelivery:
        return 'En cours de livraison';
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String _getTimeRemaining(DateTime estimatedDelivery) {
    final now = DateTime.now();
    final difference = estimatedDelivery.difference(now);
    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min";
    } else {
      return "${difference.inHours}h ${difference.inMinutes % 60}min";
    }
  }

  int _getMinutesRemaining(DateTime estimatedDelivery) {
    final now = DateTime.now();
    final difference = estimatedDelivery.difference(now);
    return difference.inMinutes > 0 ? difference.inMinutes : 0;
  }
}

// Custom Painter for Map Route
class MapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[400]!
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Draw a curved route from top-left to bottom-right
    path.moveTo(size.width * 0.2, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      size.width * 0.7,
      size.height * 0.7,
    );

    canvas.drawPath(path, paint);

    // Draw dashed line effect
    final dashPaint = Paint()
      ..color = Colors.blue[300]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw dots along the path
    for (double t = 0; t <= 1; t += 0.05) {
      final x = _quadraticBezierX(size.width * 0.2, size.width * 0.5, size.width * 0.7, t);
      final y = _quadraticBezierY(size.height * 0.3, size.height * 0.5, size.height * 0.7, t);
      canvas.drawCircle(Offset(x, y), 3, dashPaint);
    }
  }

  double _quadraticBezierX(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  double _quadraticBezierY(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

