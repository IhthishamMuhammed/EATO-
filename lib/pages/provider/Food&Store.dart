import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String name;
  final String type;
  final String category;
  final double price;
  final String time;
  final String imageUrl;
  final String? description;

  Food({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.price,
    required this.time,
    required this.imageUrl,
    this.description,
  });

  // Create a Food from a Firestore document
  factory Food.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Food(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      time: data['time'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'],
    );
  }

  // Convert Food to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'category': category,
      'price': price,
      'time': time,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  // Copy with method for creating updated copies
  Food copyWith({
    String? id,
    String? name,
    String? type,
    String? category,
    double? price,
    String? time,
    String? imageUrl,
    String? description,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      price: price ?? this.price,
      time: time ?? this.time,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
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
  final bool? isAvailable;
  final double? rating;

  Store({
    required this.id,
    required this.name,
    required this.contact,
    required this.isPickup,
    required this.imageUrl,
    required this.foods,
    this.location,
    this.isAvailable,
    this.rating,
  });

  // Create a Store from a Firestore document and populate with user ID
  factory Store.fromFirestore(DocumentSnapshot snapshot, String userId) {
    final data = snapshot.data() as Map<String, dynamic>;

    return Store(
      id: userId, // Use the user ID as the store ID
      name: data['name'] ?? '',
      contact: data['contact'] ?? '',
      isPickup: data['isPickup'] ?? true,
      imageUrl: data['imageUrl'] ?? '',
      foods: [], // Foods are loaded separately
      location: data['location'],
      isAvailable: data['isAvailable'] ?? true,
      rating: data['rating']?.toDouble(),
    );
  }

  // Convert Store to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contact': contact,
      'isPickup': isPickup,
      'imageUrl': imageUrl,
      'location': location,
      'isAvailable': isAvailable ?? true,
      'rating': rating,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with method for creating updated copies
  Store copyWith({
    String? id,
    String? name,
    String? contact,
    bool? isPickup,
    String? imageUrl,
    List<Food>? foods,
    String? location,
    bool? isAvailable,
    double? rating,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      isPickup: isPickup ?? this.isPickup,
      imageUrl: imageUrl ?? this.imageUrl,
      foods: foods ?? this.foods,
      location: location ?? this.location,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
    );
  }
}
