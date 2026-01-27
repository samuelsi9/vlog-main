import 'package:flutter/material.dart';
import '../Models/order_model.dart';
import '../Models/restaurant_model.dart';

class OrderService extends ChangeNotifier {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final List<Order> _orders = [];
  Order? _currentOrder;

  List<Order> get orders => List.unmodifiable(_orders);
  Order? get currentOrder => _currentOrder;
  List<Order> get activeOrders =>
      _orders.where((o) => o.status != OrderStatus.delivered && 
                         o.status != OrderStatus.cancelled).toList();

  Future<void> placeOrder({
    required String userId,
    required Restaurant restaurant,
    required List<OrderItem> items,
    required DeliveryAddress deliveryAddress,
    required PaymentMethod paymentMethod,
  }) async {
    final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final tax = subtotal * 0.10; // 10% de taxe
    final total = subtotal + restaurant.deliveryFee + tax;

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      storeId: restaurant.id,
      storeName: restaurant.name,
      storeImage: restaurant.image,
      items: items,
      subtotal: subtotal,
      shippingFee: restaurant.deliveryFee,
      tax: tax,
      total: total,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      estimatedDelivery: DateTime.now().add(Duration(
        minutes: restaurant.deliveryTime.toInt(),
      )),
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      trackingId: 'TRK${DateTime.now().millisecondsSinceEpoch}',
    );

    _orders.insert(0, order);
    _currentOrder = order;
    notifyListeners();

    // Simuler la progression de la commande
    _simulateOrderProgress(order);
  }

  void _simulateOrderProgress(Order order) async {
    await Future.delayed(Duration(seconds: 5));
    _updateOrderStatus(order.id, OrderStatus.confirmed);
    notifyListeners();

    await Future.delayed(Duration(seconds: 10));
    _updateOrderStatus(order.id, OrderStatus.processing);
    notifyListeners();

    await Future.delayed(Duration(seconds: 15));
    _updateOrderStatus(order.id, OrderStatus.shipped);
    notifyListeners();

    await Future.delayed(Duration(seconds: 5));
    _updateOrderStatus(order.id, OrderStatus.outForDelivery);
    notifyListeners();

    await Future.delayed(Duration(seconds: 20));
    _updateOrderStatus(order.id, OrderStatus.delivered);
    notifyListeners();
  }

  void _updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      _orders[index] = Order(
        id: order.id,
        userId: order.userId,
        storeId: order.storeId,
        storeName: order.storeName,
        storeImage: order.storeImage,
        items: order.items,
        subtotal: order.subtotal,
        shippingFee: order.shippingFee,
        tax: order.tax,
        total: order.total,
        status: status,
        createdAt: order.createdAt,
        estimatedDelivery: order.estimatedDelivery,
        deliveryAddress: order.deliveryAddress,
        paymentMethod: order.paymentMethod,
        trackingId: order.trackingId,
      );
      if (_currentOrder?.id == orderId) {
        _currentOrder = _orders[index];
      }
    }
  }

  void cancelOrder(String orderId) {
    _updateOrderStatus(orderId, OrderStatus.cancelled);
    notifyListeners();
  }

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (e) {
      return null;
    }
  }
}

