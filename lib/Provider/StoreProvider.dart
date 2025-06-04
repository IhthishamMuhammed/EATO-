// SOLUTION: Replace your StoreProvider.dart (document 13) with this corrected version

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

      print('🔍 [StoreProvider] Fetching store for user: ${currentUser.id}');

      // FIXED: Query the top-level stores collection by ownerUid
      final storesSnapshot = await FirebaseFirestore.instance
          .collection('stores') // ✅ NEW TOP-LEVEL STRUCTURE
          .where('ownerUid', isEqualTo: currentUser.id)
          .limit(1)
          .get();

      if (storesSnapshot.docs.isNotEmpty) {
        // User has a store - use the ACTUAL document ID
        final storeDoc = storesSnapshot.docs.first;
        userStore = Store.fromFirestore(storeDoc);
        _store = userStore;

        print(
            '✅ [StoreProvider] Found store: ${storeDoc.id} (${userStore!.name})');
      } else {
        // Check if store exists in old location (for backward compatibility)
        print(
            'ℹ️ [StoreProvider] No store found in new structure, checking old location...');

        final oldStoreRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.id)
            .collection('stores')
            .doc(currentUser.id);

        final oldStoreSnapshot = await oldStoreRef.get();

        if (oldStoreSnapshot.exists) {
          print('📦 [StoreProvider] Found store in old location, migrating...');

          // Migrate the store to new location
          final data = oldStoreSnapshot.data() as Map<String, dynamic>;
          data['ownerUid'] = currentUser.id;
          data['isActive'] = data['isActive'] ?? true;
          data['createdAt'] = FieldValue.serverTimestamp();

          // Create store in new location
          final newStoreRef = await FirebaseFirestore.instance
              .collection('stores') // ✅ TOP-LEVEL COLLECTION
              .add(data);

          // Create Store object with new ID
          userStore = Store(
            id: newStoreRef.id, // ✅ ACTUAL FIRESTORE DOCUMENT ID
            name: data['name'] ?? '',
            contact: data['contact'] ?? '',
            isPickup: data['isPickup'] ?? true,
            imageUrl: data['imageUrl'] ?? '',
            foods: [],
            location: data['location'],
            ownerUid: currentUser.id,
            isActive: true,
            isAvailable: data['isAvailable'] ?? true,
            rating: data['rating']?.toDouble(),
          );

          _store = userStore;

          // Migrate foods to new location
          final foodsSnapshot = await oldStoreRef.collection('foods').get();
          if (foodsSnapshot.docs.isNotEmpty) {
            final batch = FirebaseFirestore.instance.batch();

            for (var foodDoc in foodsSnapshot.docs) {
              final foodRef = FirebaseFirestore.instance
                  .collection('stores')
                  .doc(newStoreRef.id) // ✅ NEW STRUCTURE
                  .collection('foods')
                  .doc(foodDoc.id);
              batch.set(foodRef, foodDoc.data());
            }

            await batch.commit();
            print(
                '✅ [StoreProvider] Migrated ${foodsSnapshot.docs.length} foods to new structure');
          }

          // Delete old store after successful migration
          await oldStoreRef.delete();
          print('🗑️ [StoreProvider] Deleted old store structure');
        } else {
          userStore = null;
          _store = null;
          print('ℹ️ [StoreProvider] No store found for user');
        }
      }
    } catch (e) {
      _errorMessage = 'Error fetching store data: $e';
      print('❌ [StoreProvider] $_errorMessage');
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
        'isPickup': store.isPickup,
        'imageUrl': store.imageUrl,
        'location': store.location,
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
