class CustomUser {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String userType; // Main field used for role identification
  final String? profileImageUrl;
  final String? address; // Added address property to match ProfilePage usage

  CustomUser({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.userType,
    this.profileImageUrl,
    this.address, // Added to constructor
  });

  // Convert a CustomUser instance to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'profileImageUrl': profileImageUrl,
      'address': address, // Added to map
    };
  }

  // Create a new CustomUser instance with updated fields
  CustomUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? userType,
    String? profileImageUrl,
    String? address, // Added to copyWith
  }) {
    return CustomUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address, // Added to copyWith
    );
  }

  // Create a CustomUser instance from Firestore data
  factory CustomUser.fromMap(Map<String, dynamic> map) {
    return CustomUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      userType: map['userType'] ?? '', // Primary field for role
      profileImageUrl: map['profileImageUrl'],
      address: map['address'], // Extract address from map
    );
  }

  // Added for role check compatibility
  String get role => userType; // Alias for userType
}
