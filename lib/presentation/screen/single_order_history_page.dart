import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Models/order_history_model.dart';

/// Poll every 15 seconds so single order updates in real time.
const Duration _singleOrderPollInterval = Duration(seconds: 15);

// Colors from the reference: white bg, dark grey text, orange status
const Color _textPrimary = Color(0xFF333333);
const Color _textLabel = Color(0xFF999999);
const Color _statusOngoing = Color(0xFFFFA500);
const Color _statusCompleted = Color(0xFF4CAF50);
const Color _statusCanceled = Color(0xFFE57373);

class SingleOrderHistoryPage extends StatefulWidget {
  final String orderId;

  const SingleOrderHistoryPage({super.key, required this.orderId});

  @override
  State<SingleOrderHistoryPage> createState() => _SingleOrderHistoryPageState();
}

class _SingleOrderHistoryPageState extends State<SingleOrderHistoryPage> {
  SingleOrderHistoryModel? _order;
  bool _loading = true;
  String? _error;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_singleOrderPollInterval, (_) {
      if (!mounted) return;
      _refreshOrder();
    });
  }

  /// Silent refresh for polling – no loading overlay, just update order.
  Future<void> _refreshOrder() async {
    try {
      final auth = AuthService();
      final order = await auth.getSingleOrderHistory(widget.orderId);
      if (!mounted) return;
      setState(() => _order = order);
    } catch (_) {
      // Keep previous data on poll error
    }
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AuthService();
      final order = await auth.getSingleOrderHistory(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Show the actual status from the API instead of "Ongoing".
  String _statusDisplay(String status) {
    final s = status.toLowerCase();
    switch (s) {
      case 'delivered':
      case 'completed':
        return 'Delivered';
      case 'canceled':
      case 'cancelled':
      case 'cancel':
        return 'Canceled';
      case 'out_for_delivery':
      case 'shipped':
        return 'Shipped';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
      case 'preparing':
        return 'Preparing';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'delivered' || s == 'completed') return _statusCompleted;
    if (s == 'canceled' || s == 'cancelled' || s == 'cancel') return _statusCanceled;
    if (s == 'out_for_delivery' || s == 'shipped') return const Color(0xFF2E7D32);
    if (s == 'confirmed') return const Color(0xFF1565C0);
    if (s == 'processing' || s == 'preparing') return const Color(0xFFF57C00);
    return _statusOngoing;
  }

  String _formatOrderDate(String createdAt) {
    if (createdAt.isEmpty) return '—';
    try {
      final dt = DateTime.tryParse(createdAt);
      if (dt == null) return createdAt;
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  String _formatDeliveryDate(String? deliveryDate) {
    if (deliveryDate == null || deliveryDate.isEmpty) return '—';
    try {
      final dt = DateTime.tryParse(deliveryDate);
      if (dt != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {}
    return deliveryDate;
  }

  String _formatDeliveryDateTime(String? deliveryDate, String? deliveryTime) {
    if (deliveryDate != null && deliveryDate.isNotEmpty) {
      try {
        final dt = DateTime.tryParse(deliveryDate);
        if (dt != null) {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
        }
      } catch (_) {}
    }
    if (deliveryTime != null && deliveryTime.isNotEmpty) return 'By $deliveryTime';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'HISTORY OF ORDER',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _statusOngoing))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _textPrimary),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadOrder,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Order not found', style: TextStyle(color: _textPrimary)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order ID (small, label style)
                          Text(
                            'Order #${_order!.id}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textLabel,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Product name or order title (bold)
                          Text(
                            _order!.items.isNotEmpty
                                ? _order!.items.first.name
                                : 'Order #${_order!.id}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          if (_order!.items.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '+ ${_order!.items.length - 1} more item${_order!.items.length > 2 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textLabel,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          // ORDERED ON and STATUS row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ORDERED ON',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _textLabel,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatOrderDate(_order!.createdAt),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'STATUS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _textLabel,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _statusDisplay(_order!.status),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor(_order!.status),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          // Table header
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'PACKAGE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _textLabel,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'QTY',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _textLabel,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'PRICE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _textLabel,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'SUBTOTAL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _textLabel,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Rows per item (all API item fields: product_id, name, image, price, quantity, subtotal)
                          ..._order!.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        if (item.image != null && item.image!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 10),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                item.image!,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  width: 48,
                                                  height: 48,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
                                                ),
                                              ),
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: _textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '₺${item.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '₺${item.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          // Order subtotal (from API)
                          if (_order!.subtotal != null && _order!.subtotal! > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'SUBTOTAL',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textLabel,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₺${_order!.subtotal!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          // DPH / Delivery fee (from API delivery_fee)
                          if (_order!.deliveryFee != null && _order!.deliveryFee! > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'DPH',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textLabel,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₺${_order!.deliveryFee!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          // Total (from API total)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'PRICE (+ DPH)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _textLabel,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₺${(_order!.total ?? _order!.effectiveTotal).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Delivery date (from API delivery_date)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'DELIVERY DATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _textLabel,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _formatDeliveryDate(_order!.deliveryDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Delivery time (from API delivery_time)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'DELIVERY TIME',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _textLabel,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _order!.deliveryTime ?? '—',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Delivery message
                          Center(
                            child: Text(
                              _order!.deliveryDate != null && _order!.deliveryDate!.isNotEmpty
                                  ? 'Your order will be delivered by ${_formatDeliveryDateTime(_order!.deliveryDate, _order!.deliveryTime)}'
                                  : _order!.deliveryTime != null && _order!.deliveryTime!.isNotEmpty
                                      ? 'Delivery time: ${_order!.deliveryTime}'
                                      : 'Your order will be delivered soon.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: _textLabel,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Yellow line at bottom (from reference)
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: _statusOngoing.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
