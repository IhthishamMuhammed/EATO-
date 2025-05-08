import 'package:eato/Model/coustomUser.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/Model/Food&Store.dart';

class StoreProvider with ChangeNotifier {
  Store? _store; // Store for a specific user
  Store? userStore;
  bool isLoading = false;
  Store? get store => _store;

  // Fetch the store for a specific user by their user ID
  Future<void> fetchUserStore(CustomUser currentUser) async {
    try {
      isLoading = true;
      notifyListeners();

      // Access Firestore to retrieve the store from the user's 'stores' sub-collection
      final storeRef = FirebaseFirestore.instance
          .collection('users') // The 'users' collection
          .doc(currentUser.id) // The user document ID
          .collection('stores') // Sub-collection named 'stores'
          .doc(currentUser
              .id); // Assuming the store ID is the same as the user ID

      // Fetch the store document
      final storeSnapshot = await storeRef.get();

      if (storeSnapshot.exists) {
        // Convert the Firestore document to a Store object
        userStore = Store.fromFirestore(storeSnapshot.data()! as DocumentSnapshot<Object?>, currentUser.id);
      } else {
        userStore = null;
      }
    } catch (e) {
      print('Error fetching store data: $e');
      userStore = null;
    } finally {
      isLoading = false;
      notifyListeners(); // Notify listeners to rebuild the UI with new data
    }
  }

  // Create a new store or update the existing one
  Future<void> createOrUpdateStore(Store store, String userId) async {
    try {
      // Create or update store in Firestore
      await FirebaseFirestore.instance
          .collection('users') // Collection for users
          .doc(userId) // User document ID
          .collection('stores') // Sub-collection for stores
          .doc(
              userId) // Document ID for the store (same as user ID or a unique ID)
          .set(store.toMap()); // Store converted to a Map

      _store = store; // Update local store reference
      notifyListeners(); // Notify listeners for UI update
    } catch (e) {
      print("Error creating/updating store: $e"); // Handle errors
    }
  }

  // Delete store for the specific user
  Future<void> deleteStore(String userId) async {
    try {
      // Delete the store document for this user
      await FirebaseFirestore.instance
          .collection('users') // Users collection
          .doc(userId) // Specific user document
          .collection('stores') // Store is a sub-collection
          .doc(userId) // Use user ID or unique store ID
          .delete();

      _store = null; // Remove store locally after deletion
      notifyListeners(); // Notify listeners to update the UI
    } catch (e) {
      print("Error deleting store: $e"); // Handle deletion errors
    }
  }

  // Method to set store directly if needed (e.g., for manual updates without Firestore)
  void setStore(Store store) {
    _store = store;
    notifyListeners(); // Notify listeners to trigger UI updates
  }
}
