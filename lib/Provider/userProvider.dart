import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';

class UserProvider with ChangeNotifier {
  CustomUser? _currentUser;
  bool _isLoading = false;

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

  // Fetch user from Firestore
  Future<void> fetchUser(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _currentUser = CustomUser.fromMap(userData);
      }
    } catch (e) {
      print('Error fetching user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user data
  Future<void> updateUser(CustomUser updatedUser) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedUser.id)
          .update(updatedUser.toMap());

      _currentUser = updatedUser;
    } catch (e) {
      print('Error updating user: $e');
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