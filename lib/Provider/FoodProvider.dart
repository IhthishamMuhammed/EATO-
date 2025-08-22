import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:eato/Model/Food&Store.dart';

class FoodProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Food> _foods = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterMealTime = '';
  String _filterCategory = '';
  String _filterType = '';

  // Getters
  List<Food> get foods => _getFilteredFoods();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered getters
  List<Food> get breakfastFoods =>
      _foods.where((food) => food.time.toLowerCase() == 'breakfast').toList();
  List<Food> get lunchFoods =>
      _foods.where((food) => food.time.toLowerCase() == 'lunch').toList();
  List<Food> get dinnerFoods =>
      _foods.where((food) => food.time.toLowerCase() == 'dinner').toList();

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterMealTime(String mealTime) {
    _filterMealTime = mealTime;
    notifyListeners();
  }

  void setFilterCategory(String category) {
    _filterCategory = category;
    notifyListeners();
  }

  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  String getFilterType() {
    return _filterType;
  }

  String getFilterCategory() {
    return _filterCategory;
  }

  void clearFilters() {
    _searchQuery = '';
    _filterMealTime = '';
    _filterCategory = '';
    _filterType = '';
    notifyListeners();
  }

  List<Food> _getFilteredFoods() {
    List<Food> filteredList = List.from(_foods);

    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where((food) =>
              food.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              food.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (food.description
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    // Apply meal time filter
    if (_filterMealTime.isNotEmpty) {
      filteredList = filteredList
          .where((food) =>
              food.time.toLowerCase() == _filterMealTime.toLowerCase())
          .toList();
    }

    // Apply category filter
    if (_filterCategory.isNotEmpty) {
      filteredList = filteredList
          .where((food) =>
              food.category.toLowerCase() == _filterCategory.toLowerCase())
          .toList();
    }

    // Apply type filter
    if (_filterType.isNotEmpty) {
      filteredList = filteredList
          .where((food) => food.type.toLowerCase() == _filterType.toLowerCase())
          .toList();
    }

    return filteredList;
  }

  // Fetch all foods for a store
  Future<void> fetchFoods(String storeId) async {
    if (storeId.isEmpty) {
      _error = "Store ID is required";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final foodsRef =
          _firestore.collection('stores').doc(storeId).collection('foods');
      final snapshot = await foodsRef.get();

      _foods = snapshot.docs.map((doc) {
        return Food.fromFirestore(doc);
      }).toList();

      // Sort foods by name for consistency
      _foods.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _error = e.toString();
      print("Error fetching foods: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new food
  Future<void> addFood(String storeId, Food food) async {
    if (storeId.isEmpty) {
      throw Exception("Store ID is required");
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate food data
      if (food.name.isEmpty || food.price <= 0) {
        throw Exception("Food name and valid price are required");
      }

      // Validate portion prices
      if (food.portionPrices.isNotEmpty) {
        for (var entry in food.portionPrices.entries) {
          if (entry.value <= 0) {
            throw Exception("All portion prices must be greater than zero");
          }
        }
      }

      // Create food document
      final foodRef = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('foods')
          .doc();

      await foodRef.set({
        'name': food.name,
        'type': food.type,
        'category': food.category,
        'price': food.price,
        'portionPrices': food.portionPrices, // NEW: Store portion prices
        'time': food.time,
        'imageUrl': food.imageUrl,
        'isAvailable': food.isAvailable,
        'description': food.description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create food object with generated ID
      final newFood = food.copyWith(id: foodRef.id);

      // Add to local list
      _foods.add(newFood);

      // Sort foods by name
      _foods.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _error = e.toString();
      print("Error adding food: $_error");
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getShopsForMealWithDetails(
      String mealTitle, String category) async {
    try {
      _isLoading = true;
      notifyListeners();

      print(
          '🔍 [FoodProvider] Getting shops with details for meal: $mealTitle in category: $category');

      // First, get all stores
      final storesSnapshot = await _firestore.collection('stores').get();
      List<Map<String, dynamic>> detailedShops = [];

      // For each store, check if they have the specified food
      for (var storeDoc in storesSnapshot.docs) {
        try {
          Store store = Store.fromFirestore(storeDoc);

          // Skip inactive stores
          if (!store.isActive || !(store.isAvailable ?? true)) {
            continue;
          }

          // Get foods from this store that match the meal title and category
          final foodsSnapshot = await _firestore
              .collection('stores')
              .doc(storeDoc.id)
              .collection('foods')
              .where('name', isEqualTo: mealTitle)
              .where('category', isEqualTo: category)
              .where('isAvailable', isEqualTo: true)
              .get();

          // If this store offers the meal, add it to the result with details
          for (var foodDoc in foodsSnapshot.docs) {
            Food food = Food.fromFirestore(foodDoc);

            // Calculate estimated delivery time (you can customize this logic)
            int estimatedDeliveryTime = _calculateDeliveryTime(store);

            // Get store rating (with fallback)
            double storeRating = store.rating ?? 4.0;

            // Check if store offers delivery/pickup
            bool hasDelivery = store.isDelivery ?? true;
            bool hasPickup = store.isPickup ?? true;

            detailedShops.add({
              'store': store,
              'food': food,
              'storeId': store.id,
              'storeName': store.name,
              'storeRating': storeRating,
              'storeImageUrl': store.imageUrl ?? '',
              'storeLocation': store.location ?? 'Location not specified',
              'storeContact': store.contact ?? '',
              'hasDelivery': hasDelivery,
              'hasPickup': hasPickup,
              'estimatedDeliveryTime': estimatedDeliveryTime,
              'distance': _calculateDistance(store), // You can implement this
              'foodPrice': food.price,
              'foodPortionPrices':
                  food.portionPrices, // Use existing portionPrices structure
              'foodImageUrl': food.imageUrl ?? '',
              'foodDescription': food.description ?? '',
              'isSubscribed': false, // You can implement subscription check
            });
          }
        } catch (e) {
          print('⚠️ [FoodProvider] Error processing store ${storeDoc.id}: $e');
          continue;
        }
      }

      // Sort by rating and delivery time
      detailedShops.sort((a, b) {
        // Primary sort by rating (highest first)
        int ratingComparison =
            (b['storeRating'] as double).compareTo(a['storeRating'] as double);
        if (ratingComparison != 0) return ratingComparison;

        // Secondary sort by delivery time (fastest first)
        return (a['estimatedDeliveryTime'] as int)
            .compareTo(b['estimatedDeliveryTime'] as int);
      });

      _isLoading = false;
      notifyListeners();

      print(
          '✅ [FoodProvider] Found ${detailedShops.length} shops offering $mealTitle');
      return detailedShops;
    } catch (e) {
      _error = e.toString();
      print('❌ [FoodProvider] Error getting shops with details: $_error');
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<void> debugCustomerFoodVisibility() async {
    try {
      print('=== DEBUGGING CUSTOMER FOOD VISIBILITY ===');

      // 1. Check all stores and their status
      final storesSnapshot = await _firestore.collection('stores').get();
      print('Total stores found: ${storesSnapshot.docs.length}');

      for (var storeDoc in storesSnapshot.docs) {
        final storeData = storeDoc.data();
        print('\n--- Store: ${storeDoc.id} ---');
        print('Store name: ${storeData['name']}');
        print('Store isActive: ${storeData['isActive']}');
        print('Store isAvailable: ${storeData['isAvailable']}');

        // Check if this store will be included in customer queries
        bool isActive = storeData['isActive'] ?? true;
        bool isAvailable = storeData['isAvailable'] ?? true;
        bool willShowToCustomers = isActive && isAvailable;
        print('Will show to customers: $willShowToCustomers');

        // Check foods in this store
        final foodsSnapshot = await _firestore
            .collection('stores')
            .doc(storeDoc.id)
            .collection('foods')
            .get();

        print('Total foods in store: ${foodsSnapshot.docs.length}');

        for (var foodDoc in foodsSnapshot.docs) {
          final foodData = foodDoc.data();
          print('  Food: ${foodData['name']}');
          print('    Category: ${foodData['category']}');
          print('    Time: ${foodData['time']}');
          print('    Available: ${foodData['isAvailable']}');
          print('    Price: ${foodData['price']}');

          // Check if this food will be visible to customers
          bool foodAvailable = foodData['isAvailable'] ?? true;
          bool visibleToCustomers = willShowToCustomers && foodAvailable;
          print('    Visible to customers: $visibleToCustomers');
        }
      }

      // 2. Test the actual customer method
      print('\n=== TESTING CUSTOMER METHODS ===');

      // Test getMealsByCategory for 'breakfast'
      print('\nTesting getMealsByCategory("breakfast"):');
      final breakfastMeals = await getMealsByCategory('breakfast');
      print('Found ${breakfastMeals.length} breakfast meals:');
      for (var meal in breakfastMeals) {
        print('  - ${meal.name} (${meal.category})');
      }

      // Test getAllCategories
      print('\nTesting getAllCategories():');
      final categories = await getAllCategories();
      print('Found categories: $categories');

      // Test each category
      for (String category in categories) {
        print('\nTesting category: $category');
        final meals = await getMealsByCategory(category);
        print('  Found ${meals.length} meals');
        for (var meal in meals) {
          print('    - ${meal.name}');
        }
      }
    } catch (e) {
      print('Error in debugCustomerFoodVisibility: $e');
    }
  }

// Method to fix common visibility issues
  Future<void> fixFoodVisibility(String storeId) async {
    try {
      print('=== FIXING FOOD VISIBILITY FOR STORE: $storeId ===');

      // 1. Ensure store is active and available
      await _firestore.collection('stores').doc(storeId).update({
        'isActive': true,
        'isAvailable': true,
      });
      print('✅ Store marked as active and available');

      // 2. Ensure all foods are available
      final foodsSnapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('foods')
          .get();

      for (var foodDoc in foodsSnapshot.docs) {
        await foodDoc.reference.update({
          'isAvailable': true,
        });
      }
      print('✅ All foods marked as available');

      // 3. Verify the fix
      await debugCustomerFoodVisibility();
    } catch (e) {
      print('Error fixing food visibility: $e');
    }
  }

// Method to manually test customer food retrieval
  Future<void> testCustomerFoodRetrieval() async {
    try {
      print('=== TESTING CUSTOMER FOOD RETRIEVAL ===');

      // Test the exact query that customers use
      final storesSnapshot = await _firestore.collection('stores').get();
      Set<String> uniqueMealNames = {};
      List<Food> uniqueMeals = [];

      for (var storeDoc in storesSnapshot.docs) {
        final storeData = storeDoc.data();
        bool isActive = storeData['isActive'] ?? true;
        bool isAvailable = storeData['isAvailable'] ?? true;

        print('Store ${storeDoc.id}: active=$isActive, available=$isAvailable');

        if (isActive && isAvailable) {
          final foodsSnapshot = await _firestore
              .collection('stores')
              .doc(storeDoc.id)
              .collection('foods')
              .where('category', isEqualTo: 'breakfast')
              .where('isAvailable', isEqualTo: true)
              .get();

          print('  Foods found: ${foodsSnapshot.docs.length}');

          for (var foodDoc in foodsSnapshot.docs) {
            Food food = Food.fromFirestore(foodDoc);
            print('    - ${food.name}');

            if (!uniqueMealNames.contains(food.name)) {
              uniqueMealNames.add(food.name);
              uniqueMeals.add(food);
            }
          }
        }
      }

      print('\nFinal result for customers:');
      print('Unique breakfast meals: ${uniqueMeals.length}');
      for (var meal in uniqueMeals) {
        print('  - ${meal.name}');
      }
    } catch (e) {
      print('Error testing customer food retrieval: $e');
    }
  }

// Helper method to calculate estimated delivery time
  int _calculateDeliveryTime(Store store) {
    // You can customize this logic based on:
    // - Store location vs customer location
    // - Current order volume
    // - Time of day
    // - Store's average preparation time

    // For now, return a random time between 20-45 minutes
    return 20 +
        (store.name.length % 25); // Simple pseudo-random based on store name
  }

// Helper method to calculate distance (placeholder)
  double _calculateDistance(Store store) {
    // You can implement actual distance calculation here using:
    // - Customer's current location
    // - Store's location (store.location)
    // - Google Maps API or similar

    // For now, return a placeholder distance
    return 1.5 + (store.name.length % 30) / 10; // Simple pseudo-distance
  }

  // Update an existing food
  Future<void> updateFood(String storeId, Food updatedFood) async {
    if (storeId.isEmpty || updatedFood.id.isEmpty) {
      throw Exception("Store ID and Food ID are required");
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate food data
      if (updatedFood.name.isEmpty || updatedFood.price <= 0) {
        throw Exception("Food name and valid price are required");
      }

      // Validate portion prices
      if (updatedFood.portionPrices.isNotEmpty) {
        for (var entry in updatedFood.portionPrices.entries) {
          if (entry.value <= 0) {
            throw Exception("All portion prices must be greater than zero");
          }
        }
      }

      // Update food document
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('foods')
          .doc(updatedFood.id)
          .update({
        'name': updatedFood.name,
        'type': updatedFood.type,
        'category': updatedFood.category,
        'price': updatedFood.price,
        'portionPrices':
            updatedFood.portionPrices, // NEW: Update portion prices
        'time': updatedFood.time,
        'imageUrl': updatedFood.imageUrl,
        'isAvailable': updatedFood.isAvailable,
        'description': updatedFood.description,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      final index = _foods.indexWhere((food) => food.id == updatedFood.id);
      if (index != -1) {
        _foods[index] = updatedFood;
      }

      // Sort foods by name
      _foods.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _error = e.toString();
      print("Error updating food: $_error");
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a food
  Future<void> deleteFood(String storeId, String foodId) async {
    if (storeId.isEmpty || foodId.isEmpty) {
      throw Exception("Store ID and Food ID are required");
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Delete from Firestore
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('foods')
          .doc(foodId)
          .delete();

      // Remove from local list
      _foods.removeWhere((food) => food.id == foodId);
    } catch (e) {
      _error = e.toString();
      print("Error deleting food: $_error");
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a single food by ID
  Food? getFoodById(String foodId) {
    try {
      return _foods.firstWhere((food) => food.id == foodId);
    } catch (e) {
      return null;
    }
  }

  // Get foods by meal time
  List<Food> getFoodsByMealTime(String mealTime) {
    return _foods
        .where((food) => food.time.toLowerCase() == mealTime.toLowerCase())
        .toList();
  }

  // Get foods by category
  List<Food> getFoodsByCategory(String category) {
    return _foods
        .where((food) => food.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  // Get foods by type
  List<Food> getFoodsByType(String type) {
    return _foods
        .where((food) => food.type.toLowerCase() == type.toLowerCase())
        .toList();
  }
// Add this method to your FoodProvider.dart

  Future<void> fixTimeValuesInDatabase() async {
    try {
      print('Starting database time values fix...');

      // Get all stores
      final storesSnapshot = await _firestore.collection('stores').get();

      int totalUpdated = 0;

      for (var storeDoc in storesSnapshot.docs) {
        print('Checking store: ${storeDoc.id}');

        // Get all foods in this store
        final foodsSnapshot = await _firestore
            .collection('stores')
            .doc(storeDoc.id)
            .collection('foods')
            .get();

        for (var foodDoc in foodsSnapshot.docs) {
          final data = foodDoc.data();
          final currentTime = data['time'] as String?;

          if (currentTime != null) {
            String? newTime;

            // Check if needs fixing
            switch (currentTime) {
              case 'Breakfast':
                newTime = 'breakfast';
                break;
              case 'Lunch':
                newTime = 'lunch';
                break;
              case 'Dinner':
                newTime = 'dinner';
                break;
            }

            // Update if needed
            if (newTime != null && newTime != currentTime) {
              await foodDoc.reference.update({'time': newTime});
              print('Updated ${data['name']}: "$currentTime" → "$newTime"');
              totalUpdated++;
            }
          }
        }
      }

      print('Database fix completed. Updated $totalUpdated items.');
    } catch (e) {
      print('Error fixing database: $e');
    }
  }

// Call this method once from your app to fix the data
// You can add a button in your admin panel or call it once in development
  Future<List<Food>> getMealsByCategoryAndTime(
      String category, String? mealTime) async {
    try {
      final mealTimeQuery = mealTime?.toLowerCase();
      final storesSnapshot = await _firestore.collection('stores').get();
      Set<String> uniqueMealNames = {};
      List<Food> uniqueMeals = [];

      for (var storeDoc in storesSnapshot.docs) {
        final storeData = storeDoc.data();
        final isActive = storeData['isActive'] ?? true;
        final isAvailable = storeData['isAvailable'] ?? true;

        if (!isActive || !isAvailable) continue;

        var query = _firestore
            .collection('stores')
            .doc(storeDoc.id)
            .collection('foods')
            .where('category', isEqualTo: category)
            .where('isAvailable', isEqualTo: true);

        if (mealTime != null && mealTime.isNotEmpty) {
          query = query.where('time', isEqualTo: mealTimeQuery);
        }

        final foodsSnapshot = await query.get();

        for (var foodDoc in foodsSnapshot.docs) {
          Food food = Food.fromFirestore(foodDoc);
          if (!uniqueMealNames.contains(food.name)) {
            uniqueMealNames.add(food.name);
            uniqueMeals.add(food);
          }
        }
      }

      return uniqueMeals;
    } catch (e) {
      print('Error getting meals by category and time: $e');
      return [];
    }
  }

  // Helper methods for batch operations
  Future<void> deleteManyFoods(String storeId, List<String> foodIds) async {
    if (storeId.isEmpty || foodIds.isEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();

      for (var foodId in foodIds) {
        final foodRef = _firestore
            .collection('stores')
            .doc(storeId)
            .collection('foods')
            .doc(foodId);
        batch.delete(foodRef);
      }

      await batch.commit();

      // Update local list
      _foods.removeWhere((food) => foodIds.contains(food.id));
    } catch (e) {
      _error = e.toString();
      print("Error in batch delete: $_error");
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update many foods at once (for bulk operations)
  Future<void> updateManyFoods(
      String storeId, Map<String, Map<String, dynamic>> foodUpdates) async {
    if (storeId.isEmpty || foodUpdates.isEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final batch = _firestore.batch();

      foodUpdates.forEach((foodId, data) {
        final foodRef = _firestore
            .collection('stores')
            .doc(storeId)
            .collection('foods')
            .doc(foodId);

        data['updatedAt'] = FieldValue.serverTimestamp();
        batch.update(foodRef, data);
      });

      await batch.commit();

      // Update local list
      foodUpdates.forEach((foodId, data) {
        final index = _foods.indexWhere((food) => food.id == foodId);
        if (index != -1) {
          // Update only fields in the data
          Food oldFood = _foods[index];

          // Handle portionPrices update
          Map<String, double> updatedPortionPrices =
              Map.from(oldFood.portionPrices);
          if (data['portionPrices'] != null) {
            updatedPortionPrices =
                Map<String, double>.from(data['portionPrices']);
          }

          Food updatedFood = oldFood.copyWith(
            name: data['name'],
            type: data['type'],
            category: data['category'],
            price: data['price']?.toDouble(),
            portionPrices: updatedPortionPrices, // NEW: Update portion prices
            time: data['time'],
            imageUrl: data['imageUrl'],
            description: data['description'],
            isAvailable: data['isAvailable'],
          );
          _foods[index] = updatedFood;
        }
      });

      // Sort foods by name
      _foods.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _error = e.toString();
      print("Error in batch update: $_error");
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW METHODS FOR CUSTOMER SIDE

  // Get all meal types for a specific category
  Future<List<Food>> getMealsByCategory(String category) async {
    try {
      _isLoading = true;
      notifyListeners();

      // First, get all stores
      final storesSnapshot = await _firestore.collection('stores').get();
      Set<String> uniqueMealNames = {}; // To track unique meal names
      List<Food> uniqueMeals = [];

      // For each store, check their foods
      for (var storeDoc in storesSnapshot.docs) {
        final foodsSnapshot = await _firestore
            .collection('stores')
            .doc(storeDoc.id)
            .collection('foods')
            .where('category', isEqualTo: category)
            .where('isAvailable', isEqualTo: true)
            .get();

        for (var foodDoc in foodsSnapshot.docs) {
          Food food = Food.fromFirestore(foodDoc);
          // Only add if we haven't seen this meal name before
          if (!uniqueMealNames.contains(food.name)) {
            uniqueMealNames.add(food.name);
            uniqueMeals.add(food);
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return uniqueMeals;
    } catch (e) {
      _error = e.toString();
      print('Error getting meals by category: $_error');
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Add this debug method to your FoodProvider.dart
  Future<void> debugFoodData() async {
    try {
      print('=== DEBUGGING FOOD DATA ===');

      // 1. Check if any stores exist
      final storesSnapshot = await _firestore.collection('stores').get();
      print('Total stores found: ${storesSnapshot.docs.length}');

      if (storesSnapshot.docs.isEmpty) {
        print('❌ NO STORES FOUND - Providers need to create stores first');
        return;
      }

      // 2. Check each store for foods
      for (var storeDoc in storesSnapshot.docs) {
        final storeData = storeDoc.data();
        print('\n--- Store: ${storeDoc.id} ---');
        print('Store name: ${storeData['name']}');
        print('Store active: ${storeData['isActive']}');
        print('Store available: ${storeData['isAvailable']}');

        // Check foods in this store
        final foodsSnapshot = await _firestore
            .collection('stores')
            .doc(storeDoc.id)
            .collection('foods')
            .get();

        print('Foods in store: ${foodsSnapshot.docs.length}');

        for (var foodDoc in foodsSnapshot.docs) {
          final foodData = foodDoc.data();
          print(
              '  - Food: ${foodData['name']} | Category: ${foodData['category']} | Available: ${foodData['isAvailable']}');
        }
      }

      // 3. Test the getAllCategories method
      print('\n=== TESTING getAllCategories ===');
      final categories = await getAllCategories();
      print('Categories found: $categories');

      // 4. Test getMealsByCategory for each category
      for (String category in categories) {
        print('\n=== TESTING getMealsByCategory for: $category ===');
        final meals = await getMealsByCategory(category);
        print('Meals in $category: ${meals.length}');
        for (var meal in meals) {
          print('  - ${meal.name} (${meal.time})');
        }
      }
    } catch (e) {
      print('❌ Error in debugFoodData: $e');
    }
  }

  // Get shops that offer a specific meal
  Future<List<Map<String, dynamic>>> getShopsForMeal(
      String mealTitle, String category) async {
    try {
      _isLoading = true;
      notifyListeners();

      // First, get all stores
      final storesSnapshot = await _firestore.collection('stores').get();
      List<Map<String, dynamic>> shopItems = [];

      // For each store, check if they have the specified food
      for (var storeDoc in storesSnapshot.docs) {
        Store store = Store.fromFirestore(storeDoc);

        // Skip inactive stores
        if (!store.isActive || !(store.isAvailable ?? true)) {
          continue;
        }

        // Get foods from this store that match the meal title and category
        final foodsSnapshot = await _firestore
            .collection('stores')
            .doc(storeDoc.id)
            .collection('foods')
            .where('name', isEqualTo: mealTitle)
            .where('category', isEqualTo: category)
            .where('isAvailable', isEqualTo: true)
            .get();

        // If this store offers the meal, add it to the result
        for (var foodDoc in foodsSnapshot.docs) {
          Food food = Food.fromFirestore(foodDoc);
          shopItems.add({
            'store': store,
            'food': food,
          });
        }
      }

      _isLoading = false;
      notifyListeners();
      return shopItems;
    } catch (e) {
      _error = e.toString();
      print('Error getting shops for meal: $_error');
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

// Enhanced method to get categories available for a specific meal time
  Future<List<String>> getCategoriesForMealTime(String mealTime) async {
    try {
      print('🔍 [FoodProvider] Getting categories for meal time: $mealTime');

      final mealTimeQuery = mealTime.toLowerCase();
      final storesSnapshot = await _firestore.collection('stores').get();
      Set<String> uniqueCategories = {};

      for (var storeDoc in storesSnapshot.docs) {
        final storeData = storeDoc.data();
        final isActive = storeData['isActive'] ?? true;
        final isAvailable = storeData['isAvailable'] ?? true;

        if (!isActive || !isAvailable) continue;

        final foodsSnapshot = await _firestore
            .collection('stores')
            .doc(storeDoc.id)
            .collection('foods')
            .where('time', isEqualTo: mealTimeQuery)
            .where('isAvailable', isEqualTo: true)
            .get();

        for (var foodDoc in foodsSnapshot.docs) {
          final category = foodDoc.data()['category'] as String?;
          if (category != null && category.isNotEmpty) {
            uniqueCategories.add(category);
          }
        }
      }

      final categoriesList = uniqueCategories.toList();
      print(
          '✅ [FoodProvider] Found ${categoriesList.length} categories for $mealTime: $categoriesList');
      return categoriesList;
    } catch (e) {
      print('❌ [FoodProvider] Error getting categories for meal time: $e');
      return [];
    }
  }
// Add this debug method to your FoodProvider and call it from MealCategoryPage

  Future<void> debugMealCategoryIssue(String? mealTime) async {
    try {
      print('\n=== DEBUGGING MEAL CATEGORY ISSUE ===');
      print('Input mealTime: "$mealTime"');
      print('Converted to lowercase: "${mealTime?.toLowerCase()}"');

      // 1. Check all stores first
      final storesSnapshot = await _firestore.collection('stores').get();
      print('Total stores: ${storesSnapshot.docs.length}');

      for (var storeDoc in storesSnapshot.docs) {
        final storeData = storeDoc.data();
        final storeName = storeData['name'] ?? 'Unknown';
        final isActive = storeData['isActive'] ?? true;
        final isAvailable = storeData['isAvailable'] ?? true;

        print('\nStore: $storeName');
        print('  Active: $isActive, Available: $isAvailable');

        if (!isActive || !isAvailable) {
          print('  SKIPPED - Store not active/available');
          continue;
        }

        // Get all foods from this store
        final allFoodsSnapshot = await _firestore
            .collection('stores')
            .doc(storeDoc.id)
            .collection('foods')
            .get();

        print('  Total foods: ${allFoodsSnapshot.docs.length}');

        // Check each food
        for (var foodDoc in allFoodsSnapshot.docs) {
          final foodData = foodDoc.data();
          final foodName = foodData['name'] ?? 'Unknown';
          final category = foodData['category'] ?? '';
          final time = foodData['time'] ?? '';
          final isAvailable = foodData['isAvailable'] ?? true;

          print('    Food: $foodName');
          print('      Category: "$category"');
          print('      Time: "$time"');
          print('      Available: $isAvailable');

          // Check if this food matches our criteria
          if (mealTime != null) {
            final mealTimeQuery = mealTime.toLowerCase();
            final timeMatches = time == mealTimeQuery;
            print('      Time matches "$mealTimeQuery": $timeMatches');
          }
        }

        // Now test the actual query for this store
        if (mealTime != null) {
          final mealTimeQuery = mealTime.toLowerCase();

          // Get categories for this meal time
          final mealTimeFoodsSnapshot = await _firestore
              .collection('stores')
              .doc(storeDoc.id)
              .collection('foods')
              .where('time', isEqualTo: mealTimeQuery)
              .where('isAvailable', isEqualTo: true)
              .get();

          print(
              '  Foods matching time "$mealTimeQuery": ${mealTimeFoodsSnapshot.docs.length}');

          Set<String> categories = {};
          for (var foodDoc in mealTimeFoodsSnapshot.docs) {
            final category = foodDoc.data()['category'] as String?;
            if (category != null && category.isNotEmpty) {
              categories.add(category);
            }
          }
          print('  Categories found: ${categories.toList()}');
        }
      }

      // 2. Test the actual methods
      print('\n=== TESTING ACTUAL METHODS ===');

      if (mealTime != null) {
        print('Testing getCategoriesForMealTime("$mealTime"):');
        final categories = await getCategoriesForMealTime(mealTime);
        print('Result: $categories');

        // Test each category
        for (String category in categories) {
          print(
              '\nTesting getMealsByCategoryAndTime("$category", "$mealTime"):');
          final meals = await getMealsByCategoryAndTime(category, mealTime);
          print('Found ${meals.length} meals:');
          for (var meal in meals) {
            print('  - ${meal.name} (${meal.category}, ${meal.time})');
          }
        }
      }
    } catch (e) {
      print('ERROR in debugMealCategoryIssue: $e');
    }
  }
// Enhanced method to get shops with better sorting options

// Helper methods for enhanced shop details
  double _calculateMockDistance(dynamic coordinates) {
    // Mock distance calculation - replace with actual geolocation logic
    if (coordinates == null) return 2.5;

    // Simple mock based on some coordinate math
    if (coordinates is Map) {
      final lat = coordinates['latitude'] ?? 6.9271;
      final lng = coordinates['longitude'] ?? 79.8612;
      return ((lat.abs() + lng.abs()) % 5.0) + 0.5;
    }

    return 2.5;
  }

  double _calculateAvailabilityScore(Store store, Food food) {
    // Calculate a score based on various factors
    double score = 0.0;

    // Rating contributes 40%
    score += (store.rating ?? 3.0) * 0.4;

    // Price contributes 30% (lower price = higher score)
    score += (100 - food.price.clamp(0, 100)) / 100 * 0.3;

    // Pickup vs delivery contributes 20%
    score += store.isPickup ? 0.2 : 0.15;

    // Random factor for variety 10%
    score += (food.name.hashCode % 10) / 100.0;

    return score.clamp(0.0, 5.0);
  }

// Enhanced sorting method with more options
  void sortShopsBy(List<Map<String, dynamic>> shops, String sortBy) {
    switch (sortBy.toLowerCase()) {
      case 'price_low_high':
        shops.sort(
            (a, b) => (a['price'] as double).compareTo(b['price'] as double));
        break;

      case 'price_high_low':
        shops.sort(
            (a, b) => (b['price'] as double).compareTo(a['price'] as double));
        break;

      case 'rating':
        shops.sort((a, b) =>
            (b['shopRating'] as double).compareTo(a['shopRating'] as double));
        break;

      case 'distance':
        shops.sort((a, b) =>
            (a['distance'] as double).compareTo(b['distance'] as double));
        break;

      case 'delivery_time':
        shops.sort((a, b) =>
            (a['deliveryTime'] as int).compareTo(b['deliveryTime'] as int));
        break;

      case 'popularity':
        shops.sort((a, b) => (b['availabilityScore'] as double)
            .compareTo(a['availabilityScore'] as double));
        break;

      case 'alphabetical':
        shops.sort((a, b) =>
            (a['shopName'] as String).compareTo(b['shopName'] as String));
        break;

      case 'best_match':
      default:
        // Multi-factor scoring algorithm
        shops.sort((a, b) {
          double aScore = (a['shopRating'] as double) * 0.3 +
              (5.0 - (a['distance'] as double).clamp(0, 5)) * 0.25 +
              (100 - (a['price'] as double).clamp(0, 100)) / 100 * 0.2 +
              (a['availabilityScore'] as double) * 0.25;

          double bScore = (b['shopRating'] as double) * 0.3 +
              (5.0 - (b['distance'] as double).clamp(0, 5)) * 0.25 +
              (100 - (b['price'] as double).clamp(0, 100)) / 100 * 0.2 +
              (b['availabilityScore'] as double) * 0.25;

          return bScore.compareTo(aScore);
        });
        break;
    }

    print('🔄 [FoodProvider] Sorted ${shops.length} shops by: $sortBy');
  }

  // Get all available categories
  Future<List<String>> getAllCategories() async {
    try {
      // Use collectionGroup for all foods
      final foodsSnapshot = await _firestore
          .collectionGroup('foods')
          .where('isAvailable', isEqualTo: true)
          .get();

      Set<String> uniqueCategories = {};

      for (var foodDoc in foodsSnapshot.docs) {
        final foodData = foodDoc.data();
        final category = foodData['category'] as String?;
        if (category != null && category.isNotEmpty) {
          uniqueCategories.add(category);
        }
      }

      return uniqueCategories.toList();
    } catch (e) {
      print('Error getting all categories: $e');
      return [];
    }
  }
}
