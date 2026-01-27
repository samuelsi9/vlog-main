import 'package:flutter/material.dart';

enum DeliveryStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

class DeliveryOrder {
  final String id;
  final String orderNumber;
  final String itemName;
  final String itemImage;
  final int quantity;
  final double totalPrice;
  final String deliveryAddress;
  final DeliveryStatus status;
  final DateTime orderDate;
  final DateTime? estimatedDelivery;
  final String? trackingNumber;
  final String? deliveryPersonName;
  final String? deliveryPersonPhone;

  DeliveryOrder({
    required this.id,
    required this.orderNumber,
    required this.itemName,
    required this.itemImage,
    required this.quantity,
    required this.totalPrice,
    required this.deliveryAddress,
    required this.status,
    required this.orderDate,
    this.estimatedDelivery,
    this.trackingNumber,
    this.deliveryPersonName,
    this.deliveryPersonPhone,
  });

  String get statusText {
    switch (status) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.confirmed:
        return 'Confirmée';
      case DeliveryStatus.preparing:
        return 'En préparation';
      case DeliveryStatus.ready:
        return 'Prête';
      case DeliveryStatus.outForDelivery:
        return 'En livraison';
      case DeliveryStatus.delivered:
        return 'Livrée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }

  double get progressPercentage {
    switch (status) {
      case DeliveryStatus.pending:
        return 0.0;
      case DeliveryStatus.confirmed:
        return 0.2;
      case DeliveryStatus.preparing:
        return 0.4;
      case DeliveryStatus.ready:
        return 0.6;
      case DeliveryStatus.outForDelivery:
        return 0.8;
      case DeliveryStatus.delivered:
        return 1.0;
      case DeliveryStatus.cancelled:
        return 0.0;
    }
  }
}

class DeliveryTrackingService extends ChangeNotifier {
  static final DeliveryTrackingService _instance = DeliveryTrackingService._internal();
  factory DeliveryTrackingService() => _instance;
  DeliveryTrackingService._internal();

  final List<DeliveryOrder> _orders = [];

  List<DeliveryOrder> get orders => List.unmodifiable(_orders);
  List<DeliveryOrder> get activeOrders => _orders
      .where((order) =>
          order.status != DeliveryStatus.delivered &&
          order.status != DeliveryStatus.cancelled)
      .toList();

  // Simuler des données de démonstration
  void initializeDemoData() {
    if (_orders.isEmpty) {
      _orders.addAll([
        DeliveryOrder(
          id: '1',
          orderNumber: 'ORD-2024-001',
          itemName: 'Nescafe Classic',
          itemImage: 'assets/cafe.png',
          quantity: 2,
          totalPrice: 290.0,
          deliveryAddress: '123 Rue de la Paix, Paris 75001',
          status: DeliveryStatus.outForDelivery,
          orderDate: DateTime.now().subtract(const Duration(hours: 2)),
          estimatedDelivery: DateTime.now().add(const Duration(minutes: 30)),
          trackingNumber: 'TRK-123456',
          deliveryPersonName: 'Jean Dupont',
          deliveryPersonPhone: '+33 6 12 34 56 78',
        ),
        DeliveryOrder(
          id: '2',
          orderNumber: 'ORD-2024-002',
          itemName: 'Tat Tomate',
          itemImage: 'assets/tomate.png',
          quantity: 5,
          totalPrice: 150.0,
          deliveryAddress: '45 Avenue des Champs, Paris 75008',
          status: DeliveryStatus.preparing,
          orderDate: DateTime.now().subtract(const Duration(minutes: 30)),
          estimatedDelivery: DateTime.now().add(const Duration(hours: 1)),
          trackingNumber: 'TRK-123457',
        ),
        DeliveryOrder(
          id: '3',
          orderNumber: 'ORD-2024-003',
          itemName: 'Lays',
          itemImage: 'assets/lays.png',
          quantity: 3,
          totalPrice: 1035.0,
          deliveryAddress: '78 Boulevard Saint-Germain, Paris 75005',
          status: DeliveryStatus.delivered,
          orderDate: DateTime.now().subtract(const Duration(days: 1)),
          estimatedDelivery: DateTime.now().subtract(const Duration(hours: 22)),
          trackingNumber: 'TRK-123455',
        ),
      ]);
      notifyListeners();
    }
  }

  void addOrder(DeliveryOrder order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  DeliveryOrder? getOrderById(String id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  DeliveryOrder? getOrderByTrackingNumber(String trackingNumber) {
    try {
      return _orders.firstWhere(
          (order) => order.trackingNumber == trackingNumber);
    } catch (e) {
      return null;
    }
  }

  void updateOrderStatus(String orderId, DeliveryStatus status) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      final order = _orders[index];
      _orders[index] = DeliveryOrder(
        id: order.id,
        orderNumber: order.orderNumber,
        itemName: order.itemName,
        itemImage: order.itemImage,
        quantity: order.quantity,
        totalPrice: order.totalPrice,
        deliveryAddress: order.deliveryAddress,
        status: status,
        orderDate: order.orderDate,
        estimatedDelivery: order.estimatedDelivery,
        trackingNumber: order.trackingNumber,
        deliveryPersonName: order.deliveryPersonName,
        deliveryPersonPhone: order.deliveryPersonPhone,
      );
      notifyListeners();
    }
  }

  void cancelOrder(String orderId) {
    updateOrderStatus(orderId, DeliveryStatus.cancelled);
  }

  // Simuler la progression automatique d'une commande
  void startTracking(String orderId) {
    final order = getOrderById(orderId);
    if (order == null || order.status == DeliveryStatus.delivered) return;

    // Simuler la progression toutes les 10 secondes
    Future.delayed(const Duration(seconds: 10), () {
      if (order.status == DeliveryStatus.pending) {
        updateOrderStatus(orderId, DeliveryStatus.confirmed);
        startTracking(orderId);
      } else if (order.status == DeliveryStatus.confirmed) {
        updateOrderStatus(orderId, DeliveryStatus.preparing);
        startTracking(orderId);
      } else if (order.status == DeliveryStatus.preparing) {
        updateOrderStatus(orderId, DeliveryStatus.ready);
        startTracking(orderId);
      } else if (order.status == DeliveryStatus.ready) {
        updateOrderStatus(orderId, DeliveryStatus.outForDelivery);
        startTracking(orderId);
      } else if (order.status == DeliveryStatus.outForDelivery) {
        updateOrderStatus(orderId, DeliveryStatus.delivered);
      }
    });
  }
}







