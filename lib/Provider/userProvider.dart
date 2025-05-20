import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserProvider with ChangeNotifier {
  CustomUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool get isLoading => _isLoading;
  CustomUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

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
      return userData.containsKey('profileImageUrl')
          ? userData['profileImageUrl']
          : null;
    } catch (e) {
      print('Error getting profile picture URL: $e');
      return null;
    }
  }

  // Get user's address (this method is safe even if address doesn't exist in the model)
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
    _errorMessage = null;
    notifyListeners();

    try {
      if (userId.isEmpty) {
        throw Exception("User ID is required");
      }

      print('Fetching user data for ID: $userId');

      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('Fetched user data: $userData');

        // Ensure id is included in the data for creating CustomUser
        userData['id'] = userId;

        _currentUser = CustomUser.fromMap(userData);
      } else {
        print('User document not found for ID: $userId');
        _errorMessage = 'User not found';
      }
    } catch (e) {
      _errorMessage = 'Error fetching user: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user data (directly update the CustomUser object)
  Future<void> updateUser(CustomUser updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (updatedUser.id.isEmpty) {
        throw Exception("User ID is required");
      }

      final Map<String, dynamic> userData = updatedUser.toMap();

      print('Updating user with data: $userData');

      // Remove empty fields to avoid overwriting with empty values
      userData.removeWhere(
          (key, value) => value == null || (value is String && value.isEmpty));

      await _firestore.collection('users').doc(updatedUser.id).update(userData);

      print('User updated successfully');
      _currentUser = updatedUser;
    } catch (e) {
      _errorMessage = 'Error updating user: $e';
      print(_errorMessage);
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create or update a user's custom field in Firestore
  Future<void> updateUserField(
      String userId, String field, dynamic value) async {
    if (userId.isEmpty) {
      _errorMessage = 'User ID is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Updating user field $field for user ID: $userId');

      // First check if the user document exists
      final docRef = _firestore.collection('users').doc(userId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Update the field
        await docRef.update({field: value});
        print('Field $field updated successfully to $value');

        // Update local user object if it exists
        if (_currentUser != null && _currentUser!.id == userId) {
          final updatedMap = _currentUser!.toMap();
          updatedMap[field] = value;
          // Make sure the ID is preserved in the map
          updatedMap['id'] = userId;
          _currentUser = CustomUser.fromMap(updatedMap);
        }
      } else {
        // Document doesn't exist, can't update
        _errorMessage = 'User document does not exist';
        print('User document does not exist for ID: $userId');
      }
    } catch (e) {
      _errorMessage = 'Error updating $field: $e';
      print(_errorMessage);
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update specific user fields
  Future<void> updateUserFields(
      String userId, Map<String, dynamic> fields) async {
    if (userId.isEmpty) {
      _errorMessage = 'User ID is required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Updating multiple fields for user ID: $userId with data: $fields');

      // Remove empty fields to avoid overwriting with empty values
      fields.removeWhere(
          (key, value) => value == null || (value is String && value.isEmpty));

      if (fields.isEmpty) {
        print('No valid fields to update');
        return;
      }

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

        // Make sure the ID is preserved in the map
        currentUserMap['id'] = userId;

        _currentUser = CustomUser.fromMap(currentUserMap);
        print('Updated local user: ${_currentUser!.toMap()}');
      }
    } catch (e) {
      _errorMessage = 'Error updating user fields: $e';
      print(_errorMessage);
      throw Exception(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload profile picture and update user
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    if (userId.isEmpty) {
      _errorMessage = 'User ID is required';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Uploading profile picture for user ID: $userId');

      // Create file name with timestamp to avoid collisions
      String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = _storage.ref().child('profile_images/$fileName');

      // Upload file
      await ref.putFile(imageFile);
      String downloadUrl = await ref.getDownloadURL();
      print('Image uploaded successfully. URL: $downloadUrl');

      // Update user profile picture URL
      await updateUserField(userId, 'profileImageUrl', downloadUrl);

      // Refresh user data
      await fetchUser(userId);

      return downloadUrl;
    } catch (e) {
      _errorMessage = 'Error uploading profile picture: $e';
      print(_errorMessage);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile (name, phone, address)
  Future<bool> updateUserProfile(
      String userId, String name, String phoneNumber, String address) async {
    if (userId.isEmpty) {
      _errorMessage = 'User ID is required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print(
          'Updating profile with: Name=$name, Phone=$phoneNumber, Address=$address');

      // Create update data map
      final Map<String, dynamic> updateData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'address': address,
      };

      // Remove empty fields
      updateData.removeWhere((key, value) => value.isEmpty);

      if (updateData.isEmpty) {
        print('No valid fields to update');
        return false;
      }

      // Direct update to Firestore
      final userDocRef = _firestore.collection('users').doc(userId);
      await userDocRef.update(updateData);

      print('Firestore update completed');

      // Refresh user data from Firestore
      await fetchUser(userId);

      return true;
    } catch (e) {
      _errorMessage = 'Error updating user profile: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to clear current user (for logout)
  void clearCurrentUser() {
    _currentUser = null;
    notifyListeners();
  }
}
