import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String name;
  final String type;
  final String category;
  final double price;
  final String time;
  final String imageUrl;
  final bool isAvailable;
  final Map<String, dynamic>? additionalInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Food({
    required this.id,
    required this.name,
    required this.type,
    this.category = '',
    required this.price,
    required this.time,
    this.imageUrl = '',
    this.isAvailable = true,
    this.additionalInfo,
    this.createdAt,
    this.updatedAt,
  });

  // Create from Firestore document
  factory Food.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Food(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      time: data['time'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      additionalInfo: data['additionalInfo'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'category': category,
      'price': price,
      'time': time,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'additionalInfo': additionalInfo,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert to Map (for API calls, etc.)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'category': category,
      'price': price,
      'time': time,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Create a copy with updated fields
  Food copyWith({
    String? id,
    String? name,
    String? type,
    String? category,
    double? price,
    String? time,
    String? imageUrl,
    bool? isAvailable,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      price: price ?? this.price,
      time: time ?? this.time,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Override equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Food &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.category == category &&
        other.price == price &&
        other.time == time &&
        other.imageUrl == imageUrl &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    type.hashCode ^
    category.hashCode ^
    price.hashCode ^
    time.hashCode ^
    imageUrl.hashCode ^
    isAvailable.hashCode;
  }

  // Convert to string for debugging
  @override
  String toString() {
    return 'Food(id: $id, name: $name, type: $type, category: $category, price: $price, time: $time, isAvailable: $isAvailable)';
  }
}

class Store {
  final String id;
  final String name;
  final String contact;
  final bool isPickup;
  final String imageUrl;
  final List<Food> foods;
  final String? location;
  final GeoPoint? coordinates;
  final String? ownerUid;
  final bool isActive;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Store({
    required this.id,
    required this.name,
    required this.contact,
    required this.isPickup,
    this.imageUrl = '',
    required this.foods,
    this.location,
    this.coordinates,
    this.ownerUid,
    this.isActive = true,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  // Create from Firestore document
  factory Store.fromFirestore(DocumentSnapshot doc, String id, {List<Food>? foods}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Store(
      id: doc.id,
      name: data['name'] ?? '',
      contact: data['contact'] ?? '',
      isPickup: data['isPickup'] ?? true,
      imageUrl: data['imageUrl'] ?? '',
      foods: foods ?? [],
      location: data['location'],
      coordinates: data['coordinates'],
      ownerUid: data['ownerUid'],
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'contact': contact,
      'isPickup': isPickup,
      'imageUrl': imageUrl,
      'location': location,
      'coordinates': coordinates,
      'ownerUid': ownerUid,
      'isActive': isActive,
      'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert to Map (for API calls, etc.)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'isPickup': isPickup,
      'imageUrl': imageUrl,
      'foods': foods.map((food) => food.toMap()).toList(),
      'location': location,
      'coordinates': coordinates != null
          ? {'latitude': coordinates!.latitude, 'longitude': coordinates!.longitude}
          : null,
      'ownerUid': ownerUid,
      'isActive': isActive,
      'metadata': metadata,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Create a copy with updated fields
  Store copyWith({
    String? id,
    String? name,
    String? contact,
    bool? isPickup,
    String? imageUrl,
    List<Food>? foods,
    String? location,
    GeoPoint? coordinates,
    String? ownerUid,
    bool? isActive,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      isPickup: isPickup ?? this.isPickup,
      imageUrl: imageUrl ?? this.imageUrl,
      foods: foods ?? this.foods,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      ownerUid: ownerUid ?? this.ownerUid,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Override equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Store &&
        other.id == id &&
        other.name == name &&
        other.contact == contact &&
        other.isPickup == isPickup &&
        other.imageUrl == imageUrl &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    contact.hashCode ^
    isPickup.hashCode ^
    imageUrl.hashCode ^
    isActive.hashCode;
  }

  // Convert to string for debugging
  @override
  String toString() {
    return 'Store(id: $id, name: $name, contact: $contact, isPickup: $isPickup, foodCount: ${foods.length}, isActive: $isActive)';
  }
}

// Order related models
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  onTheWay,
  delivered,
  cancelled,
  rejected,
}

// Extension to convert enum to string and back
extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'on the way':
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
}

class OrderItem {
  final String foodId;
  final String foodName;
  final double price;
  final int quantity;
  final Map<String, dynamic>? extras;

  OrderItem({
    required this.foodId,
    required this.foodName,
    required this.price,
    required this.quantity,
    this.extras,
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      foodId: data['foodId'] ?? '',
      foodName: data['foodName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      extras: data['extras'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'price': price,
      'quantity': quantity,
      'extras': extras,
    };
  }

  OrderItem copyWith({
    String? foodId,
    String? foodName,
    double? price,
    int? quantity,
    Map<String, dynamic>? extras,
  }) {
    return OrderItem(
      foodId: foodId ?? this.foodId,
      foodName: foodName ?? this.foodName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      extras: extras ?? this.extras,
    );
  }
}

class Order {
  final String id;
  final String storeId;
  final String storeName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final OrderStatus status;
  final double totalAmount;
  final String deliveryLocation;
  final bool isPickup;
  final DateTime orderTime;
  final DateTime? deliveryTime;
  final String? notes;
  final Map<String, dynamic>? metadata;

  Order({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.status,
    required this.totalAmount,
    required this.deliveryLocation,
    required this.isPickup,
    required this.orderTime,
    this.deliveryTime,
    this.notes,
    this.metadata,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse order items
    List<OrderItem> orderItems = [];
    if (data['items'] != null && data['items'] is List) {
      orderItems = (data['items'] as List)
          .map((item) => OrderItem.fromMap(item))
          .toList();
    }

    return Order(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      items: orderItems,
      status: data['status'] != null
          ? OrderStatusExtension.fromString(data['status'])
          : OrderStatus.pending,
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      deliveryLocation: data['deliveryLocation'] ?? '',
      isPickup: data['isPickup'] ?? false,
      orderTime: data['orderTime'] != null
          ? (data['orderTime'] as Timestamp).toDate()
          : DateTime.now(),
      deliveryTime: data['deliveryTime'] != null
          ? (data['deliveryTime'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.name,
      'totalAmount': totalAmount,
      'deliveryLocation': deliveryLocation,
      'isPickup': isPickup,
      'orderTime': Timestamp.fromDate(orderTime),
      'deliveryTime': deliveryTime != null ? Timestamp.fromDate(deliveryTime!) : null,
      'notes': notes,
      'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Order copyWith({
    String? id,
    String? storeId,
    String? storeName,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<OrderItem>? items,
    OrderStatus? status,
    double? totalAmount,
    String? deliveryLocation,
    bool? isPickup,
    DateTime? orderTime,
    DateTime? deliveryTime,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return Order(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      isPickup: isPickup ?? this.isPickup,
      orderTime: orderTime ?? this.orderTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }
}