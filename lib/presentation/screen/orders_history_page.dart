import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Models/order_history_model.dart';
import 'single_order_history_page.dart';

/// Poll every 15 seconds so order list updates in real time.
const Duration _orderHistoryPollInterval = Duration(seconds: 15);

const Color _tabSelected = Color(0xFF4CAF50); // green when selected
// Distinct colors per status (text and background)
const Color _statusPendingBg = Color(0xFFFFF3E0);      // orange tint
const Color _statusPendingText = Color(0xFFE65100);
const Color _statusConfirmedBg = Color(0xFFE3F2FD);    // blue tint
const Color _statusConfirmedText = Color(0xFF1565C0);
const Color _statusPreparingBg = Color(0xFFFFF8E1);    // amber tint
const Color _statusPreparingText = Color(0xFFF57C00);
const Color _statusShippedBg = Color(0xFFE8F5E9);      // light green
const Color _statusShippedText = Color(0xFF2E7D32);
const Color _statusDeliveredBg = Color(0xFFE8F5E9);   // green
const Color _statusDeliveredText = Color(0xFF1B5E20);
const Color _statusCanceledBg = Color(0xFFFFEBEE);     // red tint
const Color _statusCanceledText = Color(0xFFC62828);

class OrdersHistoryPage extends StatefulWidget {
  const OrdersHistoryPage({super.key});

  @override
  State<OrdersHistoryPage> createState() => _OrdersHistoryPageState();
}

class _OrdersHistoryPageState extends State<OrdersHistoryPage> {
  String _selectedFilter = 'all'; // 'all', 'completed', 'in_progress', 'canceled'
  List<AllOrderHistoryModel> _orders = [];
  bool _loading = true;
  String? _error;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
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
    _pollTimer = Timer.periodic(_orderHistoryPollInterval, (_) {
      if (!mounted) return;
      _refreshOrders();
    });
  }

  /// Silent refresh for polling – no loading overlay, just update list.
  Future<void> _refreshOrders() async {
    try {
      final auth = AuthService();
      final list = await auth.getAllOrderHistory();
      if (!mounted) return;
      setState(() => _orders = list);
    } catch (_) {
      // Keep previous data on poll error
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AuthService();
      final list = await auth.getAllOrderHistory();
      if (!mounted) return;
      setState(() {
        _orders = list;
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

  List<AllOrderHistoryModel> get _filteredOrders {
    switch (_selectedFilter) {
      case 'completed':
        return _orders.where((o) => o.isDelivered).toList();
      case 'in_progress':
        return _orders.where((o) => o.isInProgress).toList();
      case 'canceled':
        return _orders.where((o) => o.isCanceled).toList();
      default:
        return _orders;
    }
  }

  /// Show the real status from the API (e.g. pending, confirmed, delivered).
  String _statusDisplay(AllOrderHistoryModel order) {
    final s = order.status.toLowerCase();
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

  Color _statusColor(AllOrderHistoryModel order) {
    final s = order.status.toLowerCase();
    if (s == 'delivered' || s == 'completed') return _statusDeliveredText;
    if (s == 'canceled' || s == 'cancelled' || s == 'cancel') return _statusCanceledText;
    if (s == 'out_for_delivery' || s == 'shipped') return _statusShippedText;
    if (s == 'confirmed') return _statusConfirmedText;
    if (s == 'processing' || s == 'preparing') return _statusPreparingText;
    return _statusPendingText;
  }

  Color _statusBackgroundColor(AllOrderHistoryModel order) {
    final s = order.status.toLowerCase();
    if (s == 'delivered' || s == 'completed') return _statusDeliveredBg;
    if (s == 'canceled' || s == 'cancelled' || s == 'cancel') return _statusCanceledBg;
    if (s == 'out_for_delivery' || s == 'shipped') return _statusShippedBg;
    if (s == 'confirmed') return _statusConfirmedBg;
    if (s == 'processing' || s == 'preparing') return _statusPreparingBg;
    return _statusPendingBg;
  }

  String _formatCreatedAt(String createdAt) {
    if (createdAt.isEmpty) return '—';
    try {
      final dt = DateTime.tryParse(createdAt);
      if (dt == null) return createdAt;
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Orders History',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _tabSelected),
            )
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
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadOrders,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Tab bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _tabChip('all', 'All'),
                          const SizedBox(width: 10),
                          _tabChip('completed', 'Completed'),
                          const SizedBox(width: 10),
                          _tabChip('in_progress', 'In Progress'),
                          const SizedBox(width: 10),
                          _tabChip('canceled', 'Canceled'),
                        ],
                      ),
                    ),
                    // Order list
                    Expanded(
                      child: _filteredOrders.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadOrders,
                              color: _tabSelected,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: _filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final order = _filteredOrders[index];
                                  return _buildOrderCard(order);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _tabChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _tabSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? _tabSelected : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(AllOrderHistoryModel order) {
    final statusBgColor = _statusBackgroundColor(order);
    final statusTextColor = _statusColor(order);
    final statusLabel = _statusDisplay(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SingleOrderHistoryPage(orderId: order.id.toString()),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status tag – different background and text color per status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Order ID
                Text(
                  'Order ${order.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Delivery date (created_at)
                Text(
                  'Delivery date: ${_formatCreatedAt(order.createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items: ${order.items.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Price: ₺${order.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Your order history will appear here'
                : 'No ${_selectedFilter.replaceAll('_', ' ')} orders',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
