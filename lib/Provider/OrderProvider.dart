// File: lib/Provider/OrderProvider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/Model/coustomUser.dart';
import 'dart:async';

class OrderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Order lists
  List<CustomerOrder> _customerOrders = [];
  List<CustomerOrder> _providerOrders = [];
  List<OrderRequest> _orderRequests = [];

  // Loading states
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions for real-time updates
  StreamSubscription<QuerySnapshot>? _customerOrdersSubscription;
  StreamSubscription<QuerySnapshot>? _providerOrdersSubscription;
  StreamSubscription<QuerySnapshot>? _orderRequestsSubscription;

  // Getters
  List<CustomerOrder> get customerOrders => _customerOrders;
  List<CustomerOrder> get providerOrders => _providerOrders;
  List<OrderRequest> get orderRequests => _orderRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered getters for provider
  List<CustomerOrder> get pendingOrders => _providerOrders
      .where((order) =>
          order.status == OrderStatus.pending ||
          order.status == OrderStatus.confirmed)
      .toList();

  List<CustomerOrder> get activeOrders => _providerOrders
      .where((order) =>
          order.status == OrderStatus.preparing ||
          order.status == OrderStatus.ready ||
          order.status == OrderStatus.onTheWay)
      .toList();

  List<CustomerOrder> get completedOrders => _providerOrders
      .where((order) =>
          order.status == OrderStatus.delivered ||
          order.status == OrderStatus.cancelled ||
          order.status == OrderStatus.rejected)
      .toList();

  // ====================
  // CUSTOMER METHODS
  // ====================

  /// Place multiple orders from cart (one per store)
  Future<List<String>> placeOrdersFromCart(
    CustomUser customer,
    List<Map<String, dynamic>> cartItems, {
    required String deliveryOption,
    required String deliveryAddress,
    required String paymentMethod,
    String? specialInstructions,
    DateTime? scheduledTime,
  }) async {
    _setLoading(true);

    try {
      // Group cart items by store
      Map<String, List<Map<String, dynamic>>> itemsByStore = {};

      for (var item in cartItems) {
        final storeId = item['shopId'] as String;
        if (!itemsByStore.containsKey(storeId)) {
          itemsByStore[storeId] = [];
        }
        itemsByStore[storeId]!.add(item);
      }

      List<String> orderIds = [];

      // Create one order per store
      for (var entry in itemsByStore.entries) {
        final storeId = entry.key;
        final storeItems = entry.value;

        // Calculate totals for this store
        double subtotal = storeItems.fold(
            0.0, (sum, item) => sum + (item['totalPrice'] as double));
        double deliveryFee = deliveryOption == 'Delivery' ? 100.0 : 0.0;
        double serviceFee = subtotal * 0.00;
        double totalAmount = subtotal + deliveryFee + serviceFee;

        // Convert cart items to order items
        List<OrderItem> orderItems = storeItems
            .map((item) => OrderItem(
                  foodId: item['foodId'] ?? '',
                  foodName: item['foodName'] ?? '',
                  foodImage: item['foodImage'] ?? '',
                  price: (item['price'] as num).toDouble(),
                  quantity: item['quantity'] as int,
                  totalPrice: (item['totalPrice'] as num).toDouble(),
                  specialInstructions: item['specialInstructions'],
                  variation: item['variation'],
                ))
            .toList();

        // Create order
        final order = CustomerOrder(
          id: '', // Will be set by Firestore
          customerId: customer.id,
          customerName: customer.name,
          customerPhone: customer.phoneNumber ?? '',
          storeId: storeId,
          storeName: storeItems.first['shopName'] ?? '',
          items: orderItems,
          subtotal: subtotal,
          deliveryFee: deliveryFee,
          serviceFee: serviceFee,
          totalAmount: totalAmount,
          status: OrderStatus.pending,
          deliveryOption: deliveryOption,
          deliveryAddress: deliveryAddress,
          paymentMethod: paymentMethod,
          specialInstructions: specialInstructions,
          scheduledTime: scheduledTime,
          orderTime: DateTime.now(),
        );

        // Save to Firestore
        final docRef = await _firestore.collection('orders').add(order.toMap());
        orderIds.add(docRef.id);

        // Create order request for the store
        await _createOrderRequest(docRef.id, order);
      }

      print('✅ [OrderProvider] Created ${orderIds.length} orders');
      return orderIds;
    } catch (e) {
      _setError('Error placing orders: $e');
      throw Exception(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Create order request for store owner
  Future<void> _createOrderRequest(String orderId, CustomerOrder order) async {
    final request = OrderRequest(
      id: '',
      orderId: orderId,
      customerId: order.customerId,
      customerName: order.customerName,
      storeId: order.storeId,
      storeName: order.storeName,
      status: OrderRequestStatus.pending,
      requestTime: DateTime.now(),
    );

    await _firestore.collection('order_requests').add(request.toMap());
  }

  /// Listen to customer's orders in real-time
  void listenToCustomerOrders(String customerId) {
    _customerOrdersSubscription?.cancel();

    _customerOrdersSubscription = _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('orderTime', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _customerOrders = snapshot.docs
            .map((doc) => CustomerOrder.fromFirestore(doc))
            .toList();
        notifyListeners();
      },
      onError: (e) {
        _setError('Error listening to customer orders: $e');
      },
    );
  }

  /// Cancel an order (customer side)
  Future<void> cancelOrder(String orderId, String reason) async {
    _setLoading(true);

    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.toString().split('.').last,
        'rejectionReason': reason,
        'deliveredTime': DateTime.now().toIso8601String(),
      });

      print('✅ [OrderProvider] Order $orderId cancelled');
    } catch (e) {
      _setError('Error cancelling order: $e');
      throw Exception(_error);
    } finally {
      _setLoading(false);
    }
  }

  // ====================
  // PROVIDER METHODS
  // ====================

  /// Listen to store's orders in real-time
  void listenToStoreOrders(String storeId) {
    _providerOrdersSubscription?.cancel();

    _providerOrdersSubscription = _firestore
        .collection('orders')
        .where('storeId', isEqualTo: storeId)
        .orderBy('orderTime', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _providerOrders = snapshot.docs
            .map((doc) => CustomerOrder.fromFirestore(doc))
            .toList();
        notifyListeners();
      },
      onError: (e) {
        _setError('Error listening to store orders: $e');
      },
    );
  }

  /// Listen to store's order requests in real-time
  void listenToStoreOrderRequests(String storeId) {
    _orderRequestsSubscription?.cancel();

    _orderRequestsSubscription = _firestore
        .collection('order_requests')
        .where('storeId', isEqualTo: storeId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestTime', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _orderRequests = snapshot.docs
            .map((doc) => OrderRequest.fromFirestore(doc))
            .toList();
        notifyListeners();
      },
      onError: (e) {
        _setError('Error listening to order requests: $e');
      },
    );
  }

  /// Accept an order request
  Future<void> acceptOrderRequest(String requestId, String orderId) async {
    _setLoading(true);

    try {
      final batch = _firestore.batch();

      // Update order request
      batch.update(_firestore.collection('order_requests').doc(requestId), {
        'status': OrderRequestStatus.accepted.toString().split('.').last,
        'responseTime': DateTime.now().toIso8601String(),
      });

      // Update order status
      batch.update(_firestore.collection('orders').doc(orderId), {
        'status': OrderStatus.confirmed.toString().split('.').last,
        'confirmedTime': DateTime.now().toIso8601String(),
      });

      await batch.commit();
      print('✅ [OrderProvider] Order request $requestId accepted');
    } catch (e) {
      _setError('Error accepting order request: $e');
      throw Exception(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Reject an order request
  Future<void> rejectOrderRequest(
      String requestId, String orderId, String reason) async {
    _setLoading(true);

    try {
      final batch = _firestore.batch();

      // Update order request
      batch.update(_firestore.collection('order_requests').doc(requestId), {
        'status': OrderRequestStatus.rejected.toString().split('.').last,
        'responseTime': DateTime.now().toIso8601String(),
        'rejectionReason': reason,
      });

      // Update order status
      batch.update(_firestore.collection('orders').doc(orderId), {
        'status': OrderStatus.rejected.toString().split('.').last,
        'rejectionReason': reason,
        'deliveredTime': DateTime.now().toIso8601String(),
      });

      await batch.commit();
      print('✅ [OrderProvider] Order request $requestId rejected');
    } catch (e) {
      _setError('Error rejecting order request: $e');
      throw Exception(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Update order status (provider side)
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    _setLoading(true);

    try {
      Map<String, dynamic> updateData = {
        'status': newStatus.toString().split('.').last,
      };

      // Add timestamp based on status
      switch (newStatus) {
        case OrderStatus.confirmed:
          updateData['confirmedTime'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.ready:
          updateData['readyTime'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.delivered:
        case OrderStatus.cancelled:
          updateData['deliveredTime'] = DateTime.now().toIso8601String();
          break;
        default:
          break;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);
      print('✅ [OrderProvider] Order $orderId status updated to $newStatus');
    } catch (e) {
      _setError('Error updating order status: $e');
      throw Exception(_error);
    } finally {
      _setLoading(false);
    }
  }

  // ====================
  // UTILITY METHODS
  // ====================

  /// Get order by ID
  Future<CustomerOrder?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return CustomerOrder.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _setError('Error getting order: $e');
      return null;
    }
  }

  /// Get customer's order history
  Future<List<CustomerOrder>> getCustomerOrderHistory(String customerId,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .orderBy('orderTime', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CustomerOrder.fromFirestore(doc))
          .toList();
    } catch (e) {
      _setError('Error getting order history: $e');
      return [];
    }
  }

  /// Get store's order statistics
  Future<Map<String, dynamic>> getStoreOrderStats(String storeId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Today's orders
      final todaySnapshot = await _firestore
          .collection('orders')
          .where('storeId', isEqualTo: storeId)
          .where('orderTime',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .get();

      // This week's orders
      final weekSnapshot = await _firestore
          .collection('orders')
          .where('storeId', isEqualTo: storeId)
          .where('orderTime',
              isGreaterThanOrEqualTo: startOfWeek.toIso8601String())
          .get();

      // This month's orders
      final monthSnapshot = await _firestore
          .collection('orders')
          .where('storeId', isEqualTo: storeId)
          .where('orderTime',
              isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .get();

      double todayRevenue = 0;
      double weekRevenue = 0;
      double monthRevenue = 0;

      for (var doc in todaySnapshot.docs) {
        final order = CustomerOrder.fromFirestore(doc);
        if (order.status == OrderStatus.delivered) {
          todayRevenue += order.totalAmount;
        }
      }

      for (var doc in weekSnapshot.docs) {
        final order = CustomerOrder.fromFirestore(doc);
        if (order.status == OrderStatus.delivered) {
          weekRevenue += order.totalAmount;
        }
      }

      for (var doc in monthSnapshot.docs) {
        final order = CustomerOrder.fromFirestore(doc);
        if (order.status == OrderStatus.delivered) {
          monthRevenue += order.totalAmount;
        }
      }

      return {
        'todayOrders': todaySnapshot.docs.length,
        'weekOrders': weekSnapshot.docs.length,
        'monthOrders': monthSnapshot.docs.length,
        'todayRevenue': todayRevenue,
        'weekRevenue': weekRevenue,
        'monthRevenue': monthRevenue,
      };
    } catch (e) {
      _setError('Error getting store stats: $e');
      return {};
    }
  }

  /// Search orders
  List<CustomerOrder> searchOrders(List<CustomerOrder> orders, String query) {
    if (query.isEmpty) return orders;

    return orders.where((order) {
      return order.customerName.toLowerCase().contains(query.toLowerCase()) ||
          order.id.toLowerCase().contains(query.toLowerCase()) ||
          order.items.any((item) =>
              item.foodName.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  // ====================
  // PRIVATE METHODS
  // ====================

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    print('❌ [OrderProvider] $_error');
    notifyListeners();
  }

  // ====================
  // CLEANUP
  // ====================

  @override
  void dispose() {
    _customerOrdersSubscription?.cancel();
    _providerOrdersSubscription?.cancel();
    _orderRequestsSubscription?.cancel();
    super.dispose();
  }

  /// Stop all listeners
  void stopListening() {
    _customerOrdersSubscription?.cancel();
    _providerOrdersSubscription?.cancel();
    _orderRequestsSubscription?.cancel();
  }

  /// Clear all data
  void clearData() {
    _customerOrders.clear();
    _providerOrders.clear();
    _orderRequests.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
