import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserProvider with ChangeNotifier {
  CustomUser? _currentUser;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool get isLoading => _isLoading;
  CustomUser? get currentUser => _currentUser;

  // Setter method for current user
  set currentUser(CustomUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  // Method to set current user (for backward compatibility)
  void setCurrentUser(CustomUser user) {
    _currentUser = user;
    notifyListeners();
  }

  // Get user's profile picture URL
  String? getProfilePictureUrl() {
    if (_currentUser == null) return null;

    // Try to get the profile picture URL from the user data
    try {
      final userData = _currentUser!.toMap();
      return userData.containsKey('profilePictureUrl')
          ? userData['profilePictureUrl']
          : null;
    } catch (e) {
      print('Error getting profile picture URL: $e');
      return null;
    }
  }

  // Get user's address
  String? getAddress() {
    if (_currentUser == null) return null;

    // Try to get the address from the user data
    try {
      final userData = _currentUser!.toMap();
      final address = userData.containsKey('address')
          ? userData['address'] as String?
          : null;
      print('Getting address from user data: $address');
      return address;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  // Fetch user from Firestore
  Future<void> fetchUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('Fetched user data: $userData');
        _currentUser = CustomUser.fromMap(userData);
      }
    } catch (e) {
      print('Error fetching user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user data (directly update the CustomUser object)
  Future<void> updateUser(CustomUser updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> userData = updatedUser.toMap();
      await _firestore.collection('users').doc(updatedUser.id).update(userData);

      _currentUser = updatedUser;
    } catch (e) {
      print('Error updating user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create or update a user's custom field in Firestore
  Future<void> updateUserField(
      String userId, String field, dynamic value) async {
    if (userId.isEmpty) return;

    try {
      // First check if the user document exists
      final docRef = _firestore.collection('users').doc(userId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Update the field
        await docRef.update({field: value});

        // Update local user object if it exists
        if (_currentUser != null && _currentUser!.id == userId) {
          final updatedMap = _currentUser!.toMap();
          updatedMap[field] = value;
          _currentUser = CustomUser.fromMap(updatedMap);
        }
      } else {
        // Document doesn't exist, can't update
        print('User document does not exist');
      }

      // Notify listeners after updating
      notifyListeners();
    } catch (e) {
      print('Error updating $field: $e');
    }
  }

  // Update specific user fields
  Future<void> updateUserFields(
      String userId, Map<String, dynamic> fields) async {
    if (userId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Update Firestore
      await _firestore.collection('users').doc(userId).update(fields);

      print('Updated fields in Firestore: $fields');

      // Update the local user object if it exists
      if (_currentUser != null && _currentUser!.id == userId) {
        // Create updated user with new fields
        Map<String, dynamic> currentUserMap = _currentUser!.toMap();
        fields.forEach((key, value) {
          currentUserMap[key] = value;
          print('Setting local user field $key to $value');
        });

        _currentUser = CustomUser.fromMap(currentUserMap);
        print('Updated local user: ${_currentUser!.toMap()}');
      }
    } catch (e) {
      print('Error updating user fields: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload profile picture and update user
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    if (userId.isEmpty) return null;

    _isLoading = true;
    notifyListeners();

    try {
      // Create file name
      String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = _storage.ref().child('profile_images/$fileName');

      // Upload file
      await ref.putFile(imageFile);
      String downloadUrl = await ref.getDownloadURL();

      // Update user profile picture URL
      await updateUserField(userId, 'profilePictureUrl', downloadUrl);

      // Refresh user data
      await fetchUser(userId);

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile (name, phone, address)
  Future<bool> updateUserProfile(
      String userId, String name, String phoneNumber, String address) async {
    if (userId.isEmpty) return false;

    try {
      print(
          'Updating profile with: Name=$name, Phone=$phoneNumber, Address=$address');

      // Direct update to Firestore
      final userDocRef = _firestore.collection('users').doc(userId);
      await userDocRef.update(
          {'name': name, 'phoneNumber': phoneNumber, 'address': address});

      print('Firestore update completed');

      // Refresh user data from Firestore
      await fetchUser(userId);

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Method to clear current user (for logout)
  void clearCurrentUser() {
    _currentUser = null;
    notifyListeners();
  }
}
