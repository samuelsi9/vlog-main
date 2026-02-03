import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Models/order_history_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadOrder();
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

  String _statusDisplay(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return 'Completed';
      case 'canceled':
      case 'cancelled':
      case 'cancel':
        return 'Canceled';
      default:
        return 'Ongoing';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return _statusCompleted;
      case 'canceled':
      case 'cancelled':
      case 'cancel':
        return _statusCanceled;
      default:
        return _statusOngoing;
    }
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

  String _formatDeliveryDate(String? deliveryDate, String? deliveryTime) {
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
                          // Rows per item
                          ..._order!.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
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
                          // DPH (delivery fee) row
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
                          // PRICE (+ DPH) total row
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
                                '₺${_order!.effectiveTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Delivery message
                          Center(
                            child: Text(
                              _order!.deliveryDate != null && _order!.deliveryDate!.isNotEmpty
                                  ? 'Your order will be delivered by ${_formatDeliveryDate(_order!.deliveryDate, _order!.deliveryTime)}'
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
