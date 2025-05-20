import 'package:eato/Model/coustomUser.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/Model/Food&Store.dart';

class StoreProvider with ChangeNotifier {
  Store? _store; // Store for a specific user
  Store? userStore;
  bool isLoading = false;
  String? _errorMessage;

  Store? get store => _store;
  String? get errorMessage => _errorMessage;

  // Fetch the store for a specific user by their user ID
  Future<void> fetchUserStore(CustomUser currentUser) async {
    try {
      isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Access Firestore to retrieve the store from the user's 'stores' sub-collection
      final storeRef = FirebaseFirestore.instance
          .collection('users') // The 'users' collection
          .doc(currentUser.id) // The user document ID
          .collection('stores') // Sub-collection named 'stores'
          .doc(currentUser.id); // Using user ID as store ID for consistency

      // Fetch the store document
      final storeSnapshot = await storeRef.get();

      if (storeSnapshot.exists) {
        // Create Store object from document data
        final data = storeSnapshot.data() as Map<String, dynamic>;
        userStore = Store(
          id: currentUser.id,
          name: data['name'] ?? '',
          contact: data['contact'] ?? '',
          isPickup: data['isPickup'] ?? true,
          imageUrl: data['imageUrl'] ?? '',
          foods: [], // Foods are loaded separately
          location: data['location'],
          isAvailable: data['isAvailable'] ?? true,
          rating: data['rating']?.toDouble(),
        );

        _store = userStore; // Update local store reference too
      } else {
        userStore = null;
        _store = null;
      }

      print('Store data fetched successfully: ${userStore != null}');
    } catch (e) {
      _errorMessage = 'Error fetching store data: $e';
      print(_errorMessage);
      userStore = null;
      _store = null;
    } finally {
      isLoading = false;
      notifyListeners(); // Notify listeners to rebuild the UI with new data
    }
  }

  // Create a new store or update the existing one
  Future<void> createOrUpdateStore(Store store, String userId) async {
    try {
      isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Ensure we have valid data
      if (store.name.isEmpty || store.contact.isEmpty) {
        throw Exception("Store name and contact are required");
      }

      // Convert store to map for Firestore
      final Map<String, dynamic> storeData = {
        'name': store.name,
        'contact': store.contact,
        'isPickup': store.isPickup,
        'imageUrl': store.imageUrl,
        'location': store.location,
        'isAvailable': store.isAvailable ?? true,
        'rating': store.rating,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('Creating/updating store with data: $storeData');

      // Create or update store in Firestore
      await FirebaseFirestore.instance
          .collection('users') // Users collection
          .doc(userId) // Specific user document
          .collection('stores') // Store is a sub-collection
          .doc(userId) // Use userId as storeId for consistency
          .set(storeData, SetOptions(merge: true));

      // Update local store references
      userStore = store;
      _store = store; // Update local store reference

      print('Store created/updated successfully');
    } catch (e) {
      _errorMessage = "Error creating/updating store: $e";
      print(_errorMessage);
      throw Exception(_errorMessage);
    } finally {
      isLoading = false;
      notifyListeners(); // Notify listeners to update the UI
    }
  }

  // Delete store for the specific user
  Future<void> deleteStore(String userId) async {
    try {
      isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Delete the store document for this user
      await FirebaseFirestore.instance
          .collection('users') // Users collection
          .doc(userId) // Specific user document
          .collection('stores') // Store is a sub-collection
          .doc(userId) // Use user ID or unique store ID
          .delete();

      // Remove store locally after deletion
      _store = null;
      userStore = null;

      print('Store deleted successfully');
    } catch (e) {
      _errorMessage = "Error deleting store: $e";
      print(_errorMessage);
      throw Exception(_errorMessage);
    } finally {
      isLoading = false;
      notifyListeners(); // Notify listeners to update the UI
    }
  }

  // Method to set store directly if needed (e.g., for manual updates without Firestore)
  void setStore(Store store) {
    _store = store;
    userStore = store;
    notifyListeners(); // Notify listeners to trigger UI updates
  }
}
