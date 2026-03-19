import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Models/order_history_model.dart';
import 'single_order_history_page.dart';

/// Poll every 15 seconds so order list updates in real time.
const Duration _orderHistoryPollInterval = Duration(seconds: 15);

const Color _tabSelected = Color(0xFF4CAF50);
const Color _primaryRed = Color(0xFFE53E3E);

const Color _statusPendingBg = Color(0xFFFFF3E0);
const Color _statusPendingText = Color(0xFFE65100);
const Color _statusConfirmedBg = Color(0xFFE3F2FD);
const Color _statusConfirmedText = Color(0xFF1565C0);
const Color _statusPreparingBg = Color(0xFFFFF8E1);
const Color _statusPreparingText = Color(0xFFF57C00);
const Color _statusShippedBg = Color(0xFFE8F5E9);
const Color _statusShippedText = Color(0xFF2E7D32);
const Color _statusDeliveredBg = Color(0xFFE8F5E9);
const Color _statusDeliveredText = Color(0xFF1B5E20);
const Color _statusCanceledBg = Color(0xFFFFEBEE);
const Color _statusCanceledText = Color(0xFFC62828);

// ─────────────────────────────────────────────
//  Beautiful snackbar helper
// ─────────────────────────────────────────────
enum _SnackType { success, warning, error, info }

void _showSnack(
  BuildContext context,
  String message, {
  _SnackType type = _SnackType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final config = {
    _SnackType.success: (
      icon: Icons.check_circle_rounded,
      bg: const Color(0xFF1B5E20),
      accent: const Color(0xFF4CAF50),
    ),
    _SnackType.warning: (
      icon: Icons.info_rounded,
      bg: const Color(0xFF4A3000),
      accent: const Color(0xFFFFC107),
    ),
    _SnackType.error: (
      icon: Icons.error_rounded,
      bg: const Color(0xFF5C0A0A),
      accent: const Color(0xFFEF5350),
    ),
    _SnackType.info: (
      icon: Icons.info_outline_rounded,
      bg: const Color(0xFF0D2340),
      accent: const Color(0xFF42A5F5),
    ),
  }[type]!;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: config.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: config.accent.withOpacity(0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: config.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: config.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

// ─────────────────────────────────────────────

class OrdersHistoryPage extends StatefulWidget {
  const OrdersHistoryPage({super.key});

  @override
  State<OrdersHistoryPage> createState() => _OrdersHistoryPageState();
}

class _OrdersHistoryPageState extends State<OrdersHistoryPage> {
  String _selectedFilter = 'all';
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
      // Keep previous data on poll error – silently ignored
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
      // dev error: e.toString().replaceAll('Exception: ', '')
      if (!mounted) return;
      setState(() {
        _error = "We couldn't load your orders right now.\nPlease check your connection and try again.";
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

  String _formatCreatedAtTime(String createdAt) {
    if (createdAt.isEmpty) return '—';
    try {
      final dt = DateTime.tryParse(createdAt);
      if (dt == null) return createdAt;
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
          ? const Center(child: CircularProgressIndicator(color: _primaryRed))
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // ── Tab bar ──
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
                    // ── Order list ──
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

  // ── Error full-screen state ──
  Widget _buildErrorState() {
    // dev error stored in _error (raw exception after replaceAll)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 38, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            const Text(
              "Couldn't load your orders",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
            ),
          ],
        ),
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
                // ── Status badge ──
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
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (order.createdAt.isNotEmpty) ...[
                  Text(
                    'Delivery date: ${_formatCreatedAt(order.createdAt)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Placed at: ${_formatCreatedAtTime(order.createdAt)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
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
                      '₺${order.grandTotal.toStringAsFixed(2)}',
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
    // Friendly label per active filter tab
    final String subtitle;
    switch (_selectedFilter) {
      case 'completed':
        subtitle = "You haven't completed any orders yet";
        break;
      case 'in_progress':
        subtitle = "No orders are currently in progress";
        break;
      case 'canceled':
        subtitle = "You don't have any canceled orders";
        break;
      default:
        // dev: _selectedFilter == 'all' and list is empty
        subtitle = "Your order history will show up here once you place your first order";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded, size: 44, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            const Text(
              'No orders here',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}