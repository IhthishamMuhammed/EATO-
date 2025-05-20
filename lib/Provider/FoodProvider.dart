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
          Food updatedFood = oldFood.copyWith(
            name: data['name'],
            type: data['type'],
            category: data['category'],
            price: data['price']?.toDouble(),
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

  // Get all available categories
  Future<List<String>> getAllCategories() async {
    try {
      _isLoading = true;
      notifyListeners();

      // First, get all stores
      final storesSnapshot = await _firestore.collection('stores').get();
      Set<String> uniqueCategories = {};

      // For each store, get all their foods
      for (var storeDoc in storesSnapshot.docs) {
        // Only check active stores
        final storeData = storeDoc.data();
        final isActive = storeData['isActive'] ?? true;
        final isAvailable = storeData['isAvailable'] ?? true;

        if (!isActive || !isAvailable) {
          continue;
        }

        final foodsSnapshot = await _firestore
            .collection('stores')
            .doc(storeDoc.id)
            .collection('foods')
            .where('isAvailable', isEqualTo: true)
            .get();

        // Extract unique categories
        for (var foodDoc in foodsSnapshot.docs) {
          final foodData = foodDoc.data();
          final category = foodData['category'] as String?;
          if (category != null && category.isNotEmpty) {
            uniqueCategories.add(category);
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return uniqueCategories.toList();
    } catch (e) {
      _error = e.toString();
      print('Error getting all categories: $_error');
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }
}
