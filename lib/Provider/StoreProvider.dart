// SOLUTION: Replace your StoreProvider.dart with this corrected version

import 'package:eato/Model/coustomUser.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/Model/Food&Store.dart';

class StoreProvider with ChangeNotifier {
  Store? _store;
  Store? userStore;
  bool isLoading = false;
  String? _errorMessage;

  Store? get store => _store;
  String? get errorMessage => _errorMessage;

  // Fetch the store for a specific user
  Future<void> fetchUserStore(CustomUser currentUser) async {
    try {
      isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // ✅ FIX: Query top-level stores collection
      final storesSnapshot = await FirebaseFirestore.instance
          .collection('stores') // Use top-level collection
          .where('ownerUid', isEqualTo: currentUser.id)
          .limit(1)
          .get();

      if (storesSnapshot.docs.isNotEmpty) {
        final storeDoc = storesSnapshot.docs.first;
        userStore = Store.fromFirestore(storeDoc);
        _store = userStore;
      } else {
        // ✅ ADD: Handle case where no store exists
        print('⚠️ No store found for user: ${currentUser.id}');
        userStore = null;
        _store = null;
      }
    } catch (e) {
      print('❌ StoreProvider fetchUserStore error: $e');
      _errorMessage = e.toString();
      userStore = null;
      _store = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Create a new store or update the existing one
  Future<void> createOrUpdateStore(Store store, String userId) async {
    try {
      isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (store.name.isEmpty || store.contact.isEmpty) {
        throw Exception("Store name and contact are required");
      }

      final Map<String, dynamic> storeData = {
        'name': store.name,
        'contact': store.contact,
        'deliveryMode':
            store.deliveryMode.value, // ✅ FIXED: Use deliveryMode.value
        'isPickup': store.isPickup, // Keep for backward compatibility
        'imageUrl': store.imageUrl,
        'location': store.location,
        'latitude': store.latitude,
        'longitude': store.longitude,
        'isAvailable': store.isAvailable ?? true,
        'rating': store.rating,
        'ownerUid': userId, // ✅ CRITICAL: Links store to user
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String storeId;

      if (store.id.isEmpty || store.id == userId) {
        // CREATE NEW STORE - Always use auto-generated ID
        storeData['createdAt'] = FieldValue.serverTimestamp();

        print('🔨 [StoreProvider] Creating new store...');

        final docRef = await FirebaseFirestore.instance
            .collection('stores') // ✅ TOP-LEVEL COLLECTION
            .add(storeData);

        storeId = docRef.id; // ✅ ACTUAL FIRESTORE DOCUMENT ID
        print('✅ [StoreProvider] Created store with ID: $storeId');
      } else {
        // UPDATE EXISTING STORE
        storeId = store.id;

        // Verify the store document actually exists
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .get();

        if (!storeDoc.exists) {
          throw Exception('Store with ID $storeId does not exist');
        }

        await FirebaseFirestore.instance
            .collection('stores') // ✅ TOP-LEVEL COLLECTION
            .doc(storeId)
            .update(storeData);

        print('✅ [StoreProvider] Updated existing store: $storeId');
      }

      // Update local store with the CORRECT ID
      userStore = store.copyWith(id: storeId, ownerUid: userId);
      _store = userStore;

      print('✅ [StoreProvider] Local store updated with correct ID: $storeId');
    } catch (e) {
      _errorMessage = "Error creating/updating store: $e";
      print('❌ [StoreProvider] $_errorMessage');
      throw Exception(_errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Delete store for the specific user
  Future<void> deleteStore(String userId) async {
    try {
      isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (_store != null && _store!.id.isNotEmpty) {
        // Delete from new structure
        final storeRef = FirebaseFirestore.instance
            .collection('stores') // ✅ TOP-LEVEL COLLECTION
            .doc(_store!.id);

        // Delete all foods first
        final foodsSnapshot = await storeRef.collection('foods').get();
        final batch = FirebaseFirestore.instance.batch();

        for (var doc in foodsSnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Delete the store document
        batch.delete(storeRef);
        await batch.commit();

        print('✅ [StoreProvider] Deleted store: ${_store!.id}');
      }

      // Remove store locally after deletion
      _store = null;
      userStore = null;
    } catch (e) {
      _errorMessage = "Error deleting store: $e";
      print('❌ [StoreProvider] $_errorMessage');
      throw Exception(_errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Method to set store directly if needed
  void setStore(Store store) {
    _store = store;
    userStore = store;
    notifyListeners();
  }
}
