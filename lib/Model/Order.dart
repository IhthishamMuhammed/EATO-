// File: lib/Model/Order.dart (Enhanced with location support)

import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  onTheWay,
  delivered,
  cancelled,
  rejected
}

enum OrderRequestStatus { pending, accepted, rejected }

class OrderLocation {
  final GeoPoint geoPoint;
  final String formattedAddress;
  final String? streetName;
  final String? city;
  final String? postalCode;

  OrderLocation({
    required this.geoPoint,
    required this.formattedAddress,
    this.streetName,
    this.city,
    this.postalCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'geoPoint': geoPoint,
      'formattedAddress': formattedAddress,
      'streetName': streetName,
      'city': city,
      'postalCode': postalCode,
    };
  }

  factory OrderLocation.fromMap(Map<String, dynamic> map) {
    return OrderLocation(
      geoPoint: map['geoPoint'] as GeoPoint,
      formattedAddress: map['formattedAddress'] ?? '',
      streetName: map['streetName'],
      city: map['city'],
      postalCode: map['postalCode'],
    );
  }
}

class OrderItem {
  final String foodId;
  final String foodName;
  final String foodImage;
  final double price;
  final int quantity;
  final double totalPrice;
  final String? specialInstructions;
  final String? variation;

  OrderItem({
    required this.foodId,
    required this.foodName,
    required this.foodImage,
    required this.price,
    required this.quantity,
    required this.totalPrice,
    this.specialInstructions,
    this.variation,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'foodImage': foodImage,
      'price': price.toDouble(),
      'quantity': quantity.toInt(),
      'totalPrice': totalPrice.toDouble(),
      'specialInstructions': specialInstructions,
      'variation': variation,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      foodId: map['foodId'] ?? '',
      foodName: map['foodName'] ?? '',
      foodImage: map['foodImage'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      specialInstructions: map['specialInstructions'],
      variation: map['variation'],
    );
  }
}

class CustomerOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String storeId;
  final String storeName;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double totalAmount;
  final OrderStatus status;
  final String deliveryOption; // 'Delivery' or 'Pickup'

  // Enhanced location support
  final String deliveryAddress; // Keep for backward compatibility
  final OrderLocation? deliveryLocation; // New location object

  final String paymentMethod;
  final String? specialInstructions;
  final DateTime? scheduledTime;
  final DateTime orderTime;
  final DateTime? confirmedTime;
  final DateTime? readyTime;
  final DateTime? deliveredTime;
  final String? rejectionReason;

  CustomerOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.storeId,
    required this.storeName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.totalAmount,
    required this.status,
    required this.deliveryOption,
    required this.deliveryAddress,
    this.deliveryLocation,
    required this.paymentMethod,
    this.specialInstructions,
    this.scheduledTime,
    required this.orderTime,
    this.confirmedTime,
    this.readyTime,
    this.deliveredTime,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'storeId': storeId,
      'storeName': storeName,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'deliveryOption': deliveryOption,
      'deliveryAddress': deliveryAddress,
      'deliveryLocation': deliveryLocation?.toMap(),
      'paymentMethod': paymentMethod,
      'specialInstructions': specialInstructions,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'orderTime': orderTime.toIso8601String(),
      'confirmedTime': confirmedTime?.toIso8601String(),
      'readyTime': readyTime?.toIso8601String(),
      'deliveredTime': deliveredTime?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory CustomerOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CustomerOrder(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      serviceFee: (data['serviceFee'] ?? 0.0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: _parseOrderStatus(data['status']),
      deliveryOption: data['deliveryOption'] ?? 'Pickup',
      deliveryAddress: data['deliveryAddress'] ?? '',
      deliveryLocation: data['deliveryLocation'] != null
          ? OrderLocation.fromMap(
              data['deliveryLocation'] as Map<String, dynamic>)
          : null,
      paymentMethod: data['paymentMethod'] ?? 'Cash on Delivery',
      specialInstructions: data['specialInstructions'],
      scheduledTime: data['scheduledTime'] != null
          ? DateTime.parse(data['scheduledTime'])
          : null,
      orderTime: DateTime.parse(data['orderTime']),
      confirmedTime: data['confirmedTime'] != null
          ? DateTime.parse(data['confirmedTime'])
          : null,
      readyTime:
          data['readyTime'] != null ? DateTime.parse(data['readyTime']) : null,
      deliveredTime: data['deliveredTime'] != null
          ? DateTime.parse(data['deliveredTime'])
          : null,
      rejectionReason: data['rejectionReason'],
    );
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'onTheWay':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'rejected':
        return OrderStatus.rejected;
      default:
        return OrderStatus.pending;
    }
  }

  // Helper methods for location
  String get displayAddress {
    if (deliveryLocation != null) {
      return deliveryLocation!.formattedAddress;
    }
    return deliveryAddress;
  }

  GeoPoint? get locationCoordinates {
    return deliveryLocation?.geoPoint;
  }

  CustomerOrder copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? storeId,
    String? storeName,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? serviceFee,
    double? totalAmount,
    OrderStatus? status,
    String? deliveryOption,
    String? deliveryAddress,
    OrderLocation? deliveryLocation,
    String? paymentMethod,
    String? specialInstructions,
    DateTime? scheduledTime,
    DateTime? orderTime,
    DateTime? confirmedTime,
    DateTime? readyTime,
    DateTime? deliveredTime,
    String? rejectionReason,
  }) {
    return CustomerOrder(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryOption: deliveryOption ?? this.deliveryOption,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      orderTime: orderTime ?? this.orderTime,
      confirmedTime: confirmedTime ?? this.confirmedTime,
      readyTime: readyTime ?? this.readyTime,
      deliveredTime: deliveredTime ?? this.deliveredTime,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class OrderRequest {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String storeId;
  final String storeName;
  final OrderRequestStatus status;
  final DateTime requestTime;
  final DateTime? responseTime;
  final String? rejectionReason;

  OrderRequest({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.storeId,
    required this.storeName,
    required this.status,
    required this.requestTime,
    this.responseTime,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'storeId': storeId,
      'storeName': storeName,
      'status': status.toString().split('.').last,
      'requestTime': requestTime.toIso8601String(),
      'responseTime': responseTime?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory OrderRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OrderRequest(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      status: _parseRequestStatus(data['status']),
      requestTime: DateTime.parse(data['requestTime']),
      responseTime: data['responseTime'] != null
          ? DateTime.parse(data['responseTime'])
          : null,
      rejectionReason: data['rejectionReason'],
    );
  }

  static OrderRequestStatus _parseRequestStatus(String? status) {
    switch (status) {
      case 'pending':
        return OrderRequestStatus.pending;
      case 'accepted':
        return OrderRequestStatus.accepted;
      case 'rejected':
        return OrderRequestStatus.rejected;
      default:
        return OrderRequestStatus.pending;
    }
  }
}
