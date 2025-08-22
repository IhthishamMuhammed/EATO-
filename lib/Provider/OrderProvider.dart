// FILE: lib/Provider/OrderProvider.dart
// Complete OrderProvider with notification integration (keeping all your existing methods)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/services/order_notification_service.dart'; // ✅ ADD THIS
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
      .where((order) => order.status == OrderStatus.confirmed)
      .toList();

  List<CustomerOrder> get activeOrders => _providerOrders
      .where((order) =>
          order.status == OrderStatus.preparing ||
          order.status == OrderStatus.ready ||
          (order.status == OrderStatus.onTheWay &&
              order.deliveryOption == 'Delivery'))
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

  /// Listen to customer orders in real-time
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

  /// Place multiple orders from cart (one per store) - EXISTING METHOD
  Future<List<String>> placeOrdersFromCart(
    CustomUser customer,
    List<Map<String, dynamic>> cartItems, {
    required String deliveryOption,
    required String deliveryAddress,
    required String paymentMethod,
    String? specialInstructions,
    DateTime? scheduledTime,
    GeoPoint? deliveryLocation,
    String? locationDisplayText,
  }) async {
    _setLoading(true);
    List<String> orderIds = [];

    try {
      // Group cart items by store
      Map<String, List<Map<String, dynamic>>> itemsByStore = {};
      Map<String, String> storeNames = {};
      Map<String, String> providerIds = {};

      for (var item in cartItems) {
        final storeId = item['shopId'] ?? item['storeId'] ?? '';
        final storeName =
            item['shopName'] ?? item['storeName'] ?? 'Unknown Store';
        final providerId = item['providerId'] ?? '';

        if (storeId.isNotEmpty) {
          itemsByStore.putIfAbsent(storeId, () => []);
          itemsByStore[storeId]!.add(item);
          storeNames[storeId] = storeName;
          providerIds[storeId] = providerId;
        }
      }

      print(
          '📦 [OrderProvider] Creating orders for ${itemsByStore.length} stores');

      // Create separate order for each store
      for (var entry in itemsByStore.entries) {
        final storeId = entry.key;
        final storeItems = entry.value;
        final storeName = storeNames[storeId] ?? 'Unknown Store';
        final providerId = providerIds[storeId] ?? '';

        // Calculate total for this store
        double storeTotal = 0.0;
        List<Map<String, dynamic>> orderItems = [];

        for (var item in storeItems) {
          final totalPrice = (item['totalPrice'] ?? 0.0) as double;
          storeTotal += totalPrice;

          orderItems.add({
            'foodId': item['foodId'] ?? '',
            'foodName': item['foodName'] ?? item['name'] ?? '',
            'foodImage': item['foodImage'] ?? item['imageUrl'] ?? '',
            'price': (item['price'] ?? 0.0) as double,
            'quantity': item['quantity'] ?? 1,
            'totalPrice': totalPrice,
            'variation': item['variation'],
            'specialInstructions': item['specialInstructions'],
          });
        }

        // Create order document
        final orderRef = _firestore.collection('orders').doc();
        final orderId = orderRef.id;

        final orderData = {
          'orderId': orderId,
          'customerId': customer.id,
          'customerName': customer.name,
          'customerPhone': customer.phoneNumber,
          'storeId': storeId,
          'storeName': storeName,
          'providerId': providerId,
          'items': orderItems,
          'subtotal': storeTotal,
          'deliveryFee': deliveryOption == 'Delivery' ? 50.0 : 0.0,
          'serviceFee': storeTotal * 0.05, // 5% service fee
          'totalAmount': storeTotal +
              (deliveryOption == 'Delivery' ? 50.0 : 0.0) +
              (storeTotal * 0.05),
          'deliveryOption': deliveryOption,
          'deliveryAddress': deliveryAddress,
          'deliveryLocation': deliveryLocation != null
              ? {
                  'geoPoint': deliveryLocation,
                  'formattedAddress': locationDisplayText ?? deliveryAddress,
                }
              : null,
          'paymentMethod': paymentMethod,
          'specialInstructions': specialInstructions,
          'scheduledTime': scheduledTime?.toIso8601String(),
          'status': OrderStatus.pending.toString().split('.').last,
          'orderTime': DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Save order to Firestore
        await orderRef.set(orderData);
        orderIds.add(orderId);

        print(
            '✅ [OrderProvider] Order created: $orderId for store: $storeName');
      }

      print('🎉 [OrderProvider] All orders placed successfully: $orderIds');
      return orderIds;
    } catch (e) {
      _setError('Error placing orders: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ NEW: Enhanced place orders with notifications
  Future<List<String>> placeOrdersWithNotifications({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> cartItems,
    required String deliveryOption,
    required String deliveryAddress,
    GeoPoint? deliveryLocation,
    String? locationDisplayText,
    required String paymentMethod,
    String? specialInstructions,
    DateTime? scheduledTime,
  }) async {
    // Use existing place order logic
    final customer = CustomUser(
      id: customerId,
      name: customerName,
      email: '',
      phoneNumber: customerPhone,
      userType: 'customer',
      profileImageUrl: '',
      address: deliveryAddress,
    );

    final orderIds = await placeOrdersFromCart(
      customer,
      cartItems,
      deliveryOption: deliveryOption,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      specialInstructions: specialInstructions,
      scheduledTime: scheduledTime,
      deliveryLocation: deliveryLocation,
      locationDisplayText: locationDisplayText,
    );

    // ✅ ADD: Create order requests AND send notifications
    try {
      for (String orderId in orderIds) {
        final orderDoc =
            await _firestore.collection('orders').doc(orderId).get();
        if (orderDoc.exists) {
          final orderData = orderDoc.data() as Map<String, dynamic>;
          final storeId = orderData['storeId'] ?? '';
          final storeName = orderData['storeName'] ?? '';
          final totalAmount = (orderData['totalAmount'] ?? 0.0) as double;
          final items = orderData['items'] as List<dynamic>? ?? [];

          // ✅ GET PROVIDER ID FROM STORE DOCUMENT
          String providerId = orderData['providerId'] ?? '';
          if (providerId.isEmpty && storeId.isNotEmpty) {
            providerId = await _getProviderIdFromStore(storeId);
          }

          // ✅ CREATE ORDER REQUEST FOR THE REQUESTS TAB
          await _createOrderRequest(
            orderId: orderId,
            customerId: customerId,
            customerName: customerName,
            storeId: storeId,
            storeName: storeName,
          );

          // ✅ SEND NOTIFICATIONS
          if (providerId.isNotEmpty) {
            await OrderNotificationService.sendOrderPlacedNotification(
              orderId: orderId,
              customerId: customerId,
              providerId: providerId,
              customerName: customerName,
              storeName: storeName,
              totalAmount: totalAmount,
              items: items.cast<Map<String, dynamic>>(),
            );
            print(
                '✅ Notification sent for order $orderId to provider $providerId');
          } else {
            print('⚠️ No provider ID found for store $storeId');
          }
        }
      }
    } catch (e) {
      print('❌ Error creating requests/notifications: $e');
    }

    return orderIds;
  }

  Future<void> _createOrderRequest({
    required String orderId,
    required String customerId,
    required String customerName,
    required String storeId,
    required String storeName,
  }) async {
    try {
      final request = OrderRequest(
        id: '',
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        storeId: storeId,
        storeName: storeName,
        status: OrderRequestStatus.pending,
        requestTime: DateTime.now(),
      );

      await _firestore.collection('order_requests').add(request.toMap());
      print('📋 [OrderProvider] Order request created for order $orderId');
    } catch (e) {
      print('❌ [OrderProvider] Error creating order request: $e');
      throw Exception('Failed to create order request');
    }
  }

  /// Get provider ID from store document

  Future<String> _getProviderIdFromStore(String storeId) async {
    try {
      final storeDoc = await _firestore.collection('stores').doc(storeId).get();
      if (storeDoc.exists) {
        final storeData = storeDoc.data() as Map<String, dynamic>;
        return storeData['ownerUid'] ??
            storeData['ownerId'] ??
            storeData['providerId'] ??
            ''; // ✅ CORRECT FIELDS
      }
      return '';
    } catch (e) {
      print('❌ Error getting provider ID: $e');
      return '';
    }
  }

  /// Cancel order
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

  /// Listen to provider orders in real-time
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

  /// Listen to store order requests in real-time
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

      // ✅ ADD: Send notification for confirmed status
      try {
        final orderDoc =
            await _firestore.collection('orders').doc(orderId).get();
        if (orderDoc.exists) {
          final orderData = orderDoc.data() as Map<String, dynamic>;
          final customerId = orderData['customerId'] as String;
          final storeName = orderData['storeName'] as String;

          await OrderNotificationService.sendOrderStatusUpdate(
            orderId: orderId,
            customerId: customerId,
            newStatus: 'confirmed',
            storeName: storeName,
            estimatedTime: '20-30 mins', // Standard prep time
          );

          print(
              '✅ [OrderProvider] Confirmation notification sent for order $orderId');
        }
      } catch (e) {
        print('❌ Error sending confirmation notification: $e');
      }

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

      // ✅ ADD: Send notification for rejected status
      try {
        final orderDoc =
            await _firestore.collection('orders').doc(orderId).get();
        if (orderDoc.exists) {
          final orderData = orderDoc.data() as Map<String, dynamic>;
          final customerId = orderData['customerId'] as String;
          final storeName = orderData['storeName'] as String;

          // Send rejection notification with reason
          await OrderNotificationService.sendOrderStatusUpdate(
            orderId: orderId,
            customerId: customerId,
            newStatus: 'rejected',
            storeName: storeName,
            // Include rejection reason in the notification
          );

          print(
              '✅ [OrderProvider] Rejection notification sent for order $orderId');
        }
      } catch (e) {
        print('❌ Error sending rejection notification: $e');
      }

      print('✅ [OrderProvider] Order request $requestId rejected');
    } catch (e) {
      _setError('Error rejecting order request: $e');
      throw Exception(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Update order status (provider side) - EXISTING METHOD
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

  /// ✅ NEW: Enhanced update order status with notifications
  Future<void> updateOrderStatusWithNotifications({
    required String orderId,
    required OrderStatus newStatus,
    String? estimatedTime,
  }) async {
    // Use existing update logic first
    await updateOrderStatus(orderId, newStatus);

    // Add notification
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final customerId = orderData['customerId'] as String;
        final storeName = orderData['storeName'] as String;

        await OrderNotificationService.sendOrderStatusUpdate(
          orderId: orderId,
          customerId: customerId,
          newStatus: newStatus.toString().split('.').last,
          storeName: storeName,
          estimatedTime: estimatedTime,
        );
      }
    } catch (e) {
      print('❌ Error sending status notification: $e');
    }
  }

  // ====================
  // NOTIFICATION METHODS (NEW)
  // ====================

  /// ✅ NEW: Send payment confirmation notification
  Future<void> sendPaymentConfirmation({
    required String orderId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final customerId = orderData['customerId'] as String;
        final storeName = orderData['storeName'] as String;

        await OrderNotificationService.sendPaymentConfirmation(
          orderId: orderId,
          customerId: customerId,
          amount: amount,
          paymentMethod: paymentMethod,
          storeName: storeName,
        );
      }
    } catch (e) {
      print('❌ Error sending payment notification: $e');
    }
  }

  /// ✅ NEW: Send promotional notifications
  Future<void> sendPromotionToCustomers({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'customer')
          .get();

      final List<String> customerIds =
          usersQuery.docs.map((doc) => doc.id).toList();

      await OrderNotificationService.sendPromotionalNotification(
        userIds: customerIds,
        title: title,
        body: body,
        imageUrl: imageUrl,
      );
    } catch (e) {
      print('❌ Error sending promotional notification: $e');
    }
  }

  /// ✅ NEW: Send new restaurant notification
  Future<void> notifyAboutNewRestaurant({
    required String restaurantName,
    required String description,
    String? imageUrl,
  }) async {
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'customer')
          .get();

      final List<String> customerIds =
          usersQuery.docs.map((doc) => doc.id).toList();

      await OrderNotificationService.sendNewRestaurantNotification(
        userIds: customerIds,
        restaurantName: restaurantName,
        description: description,
        imageUrl: imageUrl,
      );
    } catch (e) {
      print('❌ Error sending new restaurant notification: $e');
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

  /// Fix all store documents that are missing ownerUid
  Future<void> fixAllStoresOwnerUid() async {
    try {
      print('🔧 Starting to fix all store documents...');

      // Get all stores
      final storesSnapshot = await _firestore.collection('stores').get();

      // Get all provider users
      final providersSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'provider')
          .get();

      print('📦 Found ${storesSnapshot.docs.length} stores');
      print('👥 Found ${providersSnapshot.docs.length} providers');

      int fixedCount = 0;

      for (var storeDoc in storesSnapshot.docs) {
        final storeData = storeDoc.data();
        final storeId = storeDoc.id;
        final storeName = storeData['name'] ?? 'Unknown Store';

        // Check if ownerUid is missing
        if (storeData['ownerUid'] == null || storeData['ownerUid'] == '') {
          print('⚠️ Store $storeName ($storeId) missing ownerUid');

          // Try to find owner by store name or other criteria
          String? foundOwnerId;

          // Method 1: If there's only one provider, assign to them
          if (providersSnapshot.docs.length == 1) {
            foundOwnerId = providersSnapshot.docs.first.id;
            print('📍 Only one provider found, assigning to: $foundOwnerId');
          }
          // Method 2: Try to match by checking if provider has foods in this store
          else {
            for (var providerDoc in providersSnapshot.docs) {
              // Check if this provider has foods in this store
              final foodsSnapshot = await _firestore
                  .collection('stores')
                  .doc(storeId)
                  .collection('foods')
                  .limit(1)
                  .get();

              if (foodsSnapshot.docs.isNotEmpty) {
                // Assume first provider with foods is the owner
                foundOwnerId = providerDoc.id;
                print('📍 Found foods in store, assigning to: $foundOwnerId');
                break;
              }
            }
          }

          // Method 3: Fallback - assign to first provider
          if (foundOwnerId == null && providersSnapshot.docs.isNotEmpty) {
            foundOwnerId = providersSnapshot.docs.first.id;
            print(
                '📍 Using fallback, assigning to first provider: $foundOwnerId');
          }

          // Update the store document
          if (foundOwnerId != null) {
            await _firestore.collection('stores').doc(storeId).update({
              'ownerUid': foundOwnerId,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            print('✅ Fixed store $storeName -> Owner: $foundOwnerId');
            fixedCount++;
          } else {
            print('❌ Could not find owner for store $storeName');
          }
        } else {
          print(
              '✅ Store $storeName already has ownerUid: ${storeData['ownerUid']}');
        }
      }

      print('🎉 Fixed $fixedCount stores successfully!');
    } catch (e) {
      print('❌ Error fixing stores: $e');
    }
  }

  /// Get store statistics
  Future<Map<String, dynamic>> getStoreStats(String storeId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      final monthAgo = DateTime(now.year, now.month - 1, now.day);

      // Get orders for different time periods
      final todaySnapshot = await _firestore
          .collection('orders')
          .where('storeId', isEqualTo: storeId)
          .where('orderTime', isGreaterThanOrEqualTo: today.toIso8601String())
          .get();

      final weekSnapshot = await _firestore
          .collection('orders')
          .where('storeId', isEqualTo: storeId)
          .where('orderTime', isGreaterThanOrEqualTo: weekAgo.toIso8601String())
          .get();

      final monthSnapshot = await _firestore
          .collection('orders')
          .where('storeId', isEqualTo: storeId)
          .where('orderTime',
              isGreaterThanOrEqualTo: monthAgo.toIso8601String())
          .get();

      // Calculate revenue
      double todayRevenue = 0, weekRevenue = 0, monthRevenue = 0;

      for (var doc in todaySnapshot.docs) {
        final order = CustomerOrder.fromFirestore(doc);
        todayRevenue += order.totalAmount;
      }

      for (var doc in weekSnapshot.docs) {
        final order = CustomerOrder.fromFirestore(doc);
        weekRevenue += order.totalAmount;
      }

      for (var doc in monthSnapshot.docs) {
        final order = CustomerOrder.fromFirestore(doc);
        monthRevenue += order.totalAmount;
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
