import 'dart:async';
import 'package:flutter/material.dart';
import '../../Data/apiservices.dart';
import '../../Models/order_history_model.dart';

/// Polling interval for real-time order status updates.
const Duration _pollInterval = Duration(seconds: 15);
/// After an order is cancelled, show it for this long then remove automatically.
const Duration _cancelledRemovalDelay = Duration(minutes: 5);
/// How often to check whether to remove cancelled orders.
const Duration _cancelledRemovalCheckInterval = Duration(seconds: 30);

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
  List<AllOrderHistoryModel> _orders = [];
  bool _loading = true;
  String? _error;

  SingleOrderHistoryModel? _singleOrder;
  bool _singleLoading = true;
  String? _singleError;

  Timer? _pollTimer;
  Timer? _cancelledRemovalTimer;
  /// When we first saw each order as cancelled (orderId -> time).
  final Map<int, DateTime> _cancelledAt = {};

  static bool _isCancelled(String status) {
    final s = status.toLowerCase();
    return s == 'canceled' || s == 'cancelled' || s == 'cancel';
  }

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _loadSingleOrder();
      _startPolling();
    } else {
      _loadOrders();
      _startPolling();
    }
    _startCancelledRemovalTimer();
  }

  @override
  void didUpdateWidget(covariant DeliveryTrackingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orderId != oldWidget.orderId) {
      _stopPolling();
      if (widget.orderId != null) {
        _singleOrder = null;
        _singleError = null;
        _singleLoading = true;
        _loadSingleOrder();
      } else {
        _loadOrders();
      }
      _startPolling();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _cancelledRemovalTimer?.cancel();
    _cancelledRemovalTimer = null;
    super.dispose();
  }

  void _startCancelledRemovalTimer() {
    _cancelledRemovalTimer?.cancel();
    _cancelledRemovalTimer = Timer.periodic(_cancelledRemovalCheckInterval, (_) {
      if (!mounted) return;
      _checkAndRemoveCancelledOrders();
    });
  }

  void _checkAndRemoveCancelledOrders() {
    final now = DateTime.now();
    if (widget.orderId != null) {
      // Detail view: if current order is cancelled and delay passed, pop and remove from list
      if (_singleOrder != null &&
          _isCancelled(_singleOrder!.status) &&
          _cancelledAt.containsKey(_singleOrder!.id)) {
        final at = _cancelledAt[_singleOrder!.id]!;
        if (now.difference(at) >= _cancelledRemovalDelay) {
          _cancelledAt.remove(_singleOrder!.id);
          _orders.removeWhere((o) => o.id == _singleOrder!.id);
          if (mounted) Navigator.of(context).pop();
          return;
        }
      }
    } else {
      // List view: remove any cancelled orders that have been shown long enough
      final toRemove = <int>[];
      for (final o in _orders) {
        if (_isCancelled(o.status) &&
            _cancelledAt.containsKey(o.id) &&
            now.difference(_cancelledAt[o.id]!) >= _cancelledRemovalDelay) {
          toRemove.add(o.id);
        }
      }
      if (toRemove.isNotEmpty) {
        for (final id in toRemove) {
          _cancelledAt.remove(id);
        }
        setState(() => _orders.removeWhere((o) => toRemove.contains(o.id)));
      }
    }
  }

  void _markCancelledIfNeeded(int orderId, String status) {
    if (_isCancelled(status)) {
      _cancelledAt.putIfAbsent(orderId, () => DateTime.now());
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      if (widget.orderId != null) {
        _refreshSingleOrder();
      } else {
        _refreshOrders();
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
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
        for (final o in list) {
          _markCancelledIfNeeded(o.id, o.status);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Silent refresh for polling – does not show loading.
  Future<void> _refreshOrders() async {
    try {
      final auth = AuthService();
      final list = await auth.getAllOrderHistory();
      if (!mounted) return;
      setState(() {
        _orders = list;
        for (final o in list) {
          _markCancelledIfNeeded(o.id, o.status);
        }
      });
    } catch (_) {
      // Keep previous data on poll error
    }
  }

  Future<void> _loadSingleOrder() async {
    if (widget.orderId == null) return;
    setState(() {
      _singleLoading = true;
      _singleError = null;
    });
    try {
      final auth = AuthService();
      final order = await auth.getSingleOrderHistory(widget.orderId!);
      if (!mounted) return;
      setState(() {
        _singleOrder = order;
        _singleLoading = false;
        _markCancelledIfNeeded(order.id, order.status);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _singleError = e.toString().replaceAll('Exception: ', '');
        _singleLoading = false;
      });
    }
  }

  /// Silent refresh for polling – does not show loading; timeline updates in real time.
  Future<void> _refreshSingleOrder() async {
    if (widget.orderId == null) return;
    try {
      final auth = AuthService();
      final order = await auth.getSingleOrderHistory(widget.orderId!);
      if (!mounted) return;
      setState(() {
        _singleOrder = order;
        _markCancelledIfNeeded(order.id, order.status);
      });
    } catch (_) {
      // Keep previous data on poll error
    }
  }

  /// Timeline: pending→0, confirmed→1, preparing→2, shipped/on_the_way→3, delivered/completed→5 (all five steps completed).
  static int _statusToStepIndex(String status) {
    final s = status.toLowerCase();
    if (s == 'pending') return 0;
    if (s == 'confirmed') return 1;
    if (s == 'processing' || s == 'preparing') return 2;
    if (s == 'shipped' || s == 'out_for_delivery' || s == 'on_the_way') return 3;
    if (s == 'delivered' || s == 'completed') return 5; // all five steps completed
    if (s == 'canceled' || s == 'cancelled' || s == 'cancel') return -1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final showingDetail = widget.orderId != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          showingDetail ? 'Order Status' : 'Delivery tracking',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: showingDetail
            ? [
                IconButton(
                  icon: Icon(Icons.info_outline, color: Colors.grey[700]),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.phone, color: Colors.grey[700]),
                  onPressed: () {},
                ),
              ]
            : null,
      ),
      body: showingDetail
          ? Stack(
              children: [
                if (_singleLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_singleError != null)
                  _buildSingleError()
                else if (_singleOrder != null)
                  _buildOrderTrackingView(_singleOrder!)
                else
                  const Center(child: Text('Order not found')),
                if (_cancelOrderLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Cancelling order...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : (_loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildListError()
                  : _orders.isEmpty
                      ? _buildEmptyState()
                      : _buildOrdersList(_orders)),
    );
  }

  Widget _buildListError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadOrders, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_singleError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadSingleOrder, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          const Text(
            "No active deliveries",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your orders will appear here",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<AllOrderHistoryModel> orders) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              "Your orders",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final order = orders[index];
                return _buildOrderCard(order);
              },
              childCount: orders.length,
            ),
          ),
        ),
      ],
    );
  }

  double _orderProgress(String status) {
    final idx = _statusToStepIndex(status);
    if (idx < 0) return 0;
    return (idx + 1) / 5;
  }

  Widget _buildOrderCard(AllOrderHistoryModel order) {
    final firstItemName = order.items.isNotEmpty ? order.items.first.name : 'Order #${order.id}';
    final statusColor = _getStatusColorString(order.status);
    final statusLabel = _getStatusChipTextString(order.status);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryTrackingPage(orderId: order.id.toString()),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.grey[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Order #${order.id}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 28, color: Colors.grey),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${order.items.length} item(s) · ₺${order.grandTotal.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _orderProgress(order.status),
                minHeight: 4,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _timelineSteps = [
    ('Pending', 'Your order has been placed and is waiting for confirmation'),
    ('Confirmed', 'Your order got confirmed'),
    ('Preparing', 'We started preparing your order'),
    ('Shipped', 'Our executive is delivering your order'),
    ('Delivered', 'Enjoy your meal. Don\'t forget to rate us!'),
  ];

  Widget _buildOrderTrackingView(SingleOrderHistoryModel order) {
    final currentStepIndex = _statusToStepIndex(order.status);
    final isCancelled = order.status.toLowerCase() == 'canceled' ||
        order.status.toLowerCase() == 'cancelled' ||
        order.status.toLowerCase() == 'cancel';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeaderCard(order, isCancelled),
          const SizedBox(height: 20),
          _buildTimelineCard(order, currentStepIndex, isCancelled),
          const SizedBox(height: 20),
          _buildOrderDetailsCard(order),
          if (order.deliveryTime != null && order.deliveryTime!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDeliveryTimeCard(order),
          ],
          const SizedBox(height: 20),
          _buildCancelOrderSection(order),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Cancel order: only enabled when status is pending; otherwise show explanation.
  Widget _buildCancelOrderSection(SingleOrderHistoryModel order) {
    final isPending = order.status.toLowerCase() == 'pending';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isPending) ...[
            Text(
              'You can only cancel an order with status Pending.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isPending ? () => _showCancelOrderConfirm(order) : null,
              icon: Icon(Icons.cancel_outlined, size: 20, color: isPending ? Colors.red : Colors.grey),
              label: Text(
                'Cancel order',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isPending ? Colors.red : Colors.grey,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: isPending ? Colors.red : Colors.grey),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelOrderConfirm(SingleOrderHistoryModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text(
          'Do you want to cancel order #${order.id}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    _cancelOrderWithLoading(order);
  }

  bool _cancelOrderLoading = false;

  Future<void> _cancelOrderWithLoading(SingleOrderHistoryModel order) async {
    setState(() => _cancelOrderLoading = true);
    try {
      final auth = AuthService();
      final response = await auth.cancelOrder(order.id.toString());
      if (!mounted) return;
      final orderData = response['order'];
      final newStatus = orderData is Map
          ? (orderData['status']?.toString().toLowerCase() ?? 'cancelled')
          : 'cancelled';
      setState(() {
        _cancelOrderLoading = false;
        if (_singleOrder != null && _singleOrder!.id == order.id) {
          _singleOrder = _singleOrder!.copyWith(status: newStatus);
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']?.toString() ?? 'Order cancelled'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelOrderLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildOrderHeaderCard(SingleOrderHistoryModel order, bool isCancelled) {
    final firstItemName = order.items.isNotEmpty ? order.items.first.name : 'Order #${order.id}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: order.items.isNotEmpty && order.items.first.image != null && order.items.first.image!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      order.items.first.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, size: 32),
                    ),
                  )
                : const Icon(Icons.shopping_bag_outlined, size: 32, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  firstItemName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "${order.items.length} item(s) · ₺${order.effectiveTotal.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCancelled
                  ? Colors.red.withOpacity(0.1)
                  : _getStatusColorString(order.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isCancelled ? 'Cancelled' : _getStatusChipTextString(order.status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCancelled ? Colors.red : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(SingleOrderHistoryModel order, int currentStepIndex, bool isCancelled) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order progress',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...List.generate(_timelineSteps.length, (index) {
            final step = _timelineSteps[index];
            final isReached = index <= currentStepIndex && !isCancelled;
            final isCurrent = index == currentStepIndex && !isCancelled;
            final isLast = index == _timelineSteps.length - 1;
            return _buildTimelineRow(
              title: step.$1,
              subtitle: step.$2,
              isCompleted: isReached && !isCurrent,
              isCurrent: isCurrent,
              isPending: !isReached || isCancelled,
              showLine: !isLast,
              deliveryTime: order.deliveryTime,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
    required bool isPending,
    required bool showLine,
    String? deliveryTime,
  }) {
    const green = Color(0xFF4CAF50);
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
                  color: isCompleted
                      ? green
                      : (isCurrent ? green.withOpacity(0.3) : grey[300]),
                ),
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: isCompleted
                      ? Colors.white
                      : (isPending ? grey[400] : green),
                ),
              ),
              if (showLine)
                Container(
                  width: 2,
                  height: 48,
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
              padding: const EdgeInsets.only(bottom: 28),
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
                    style: TextStyle(fontSize: 13, color: grey[600], height: 1.3),
                  ),
                  if (isCurrent && deliveryTime != null && deliveryTime.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Delivery time: $deliveryTime',
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

  Widget _buildOrderDetailsCard(SingleOrderHistoryModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order details',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text('${item.quantity}x', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.name, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    Text('₺${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const Divider(height: 24),
          if (order.deliveryFee != null && order.deliveryFee! > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery fee', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  Text('₺${order.deliveryFee!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('₺${order.effectiveTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeCard(SingleOrderHistoryModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.grey[600], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery time', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(order.deliveryTime!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColorString(String status) {
    final s = status.toLowerCase();
    if (s == 'delivered' || s == 'completed') return Colors.green[700]!;
    if (s == 'canceled' || s == 'cancelled' || s == 'cancel') return Colors.red;
    if (s == 'shipped' || s == 'out_for_delivery' || s == 'on_the_way') return const Color(0xFF4CAF50);
    if (s == 'confirmed') return Colors.blue;
    if (s == 'processing' || s == 'preparing') return Colors.amber[700]!;
    return Colors.orange;
  }

  String _getStatusChipTextString(String status) {
    final s = status.toLowerCase();
    if (s == 'delivered' || s == 'completed') return 'Delivered';
    if (s == 'canceled' || s == 'cancelled' || s == 'cancel') return 'Cancelled';
    if (s == 'shipped' || s == 'out_for_delivery' || s == 'on_the_way') return 'In transit';
    if (s == 'confirmed') return 'Confirmed';
    if (s == 'processing' || s == 'preparing') return 'Preparing';
    return 'Pending';
  }
}

