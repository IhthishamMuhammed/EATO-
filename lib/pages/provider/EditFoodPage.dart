// File: lib/pages/EditFoodPage.dart (Updated with multi-select meal times)

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' as io;

class EditFoodPage extends StatefulWidget {
  final String storeId;
  final Food food;

  const EditFoodPage({
    Key? key,
    required this.storeId,
    required this.food,
  }) : super(key: key);

  @override
  _EditFoodPageState createState() => _EditFoodPageState();
}

class _EditFoodPageState extends State<EditFoodPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;

  // ✅ NEW: Multi-select meal times
  final Map<String, bool> _selectedMealTimes = {
    'breakfast': false,
    'lunch': false,
    'dinner': false,
  };

  String? _selectedMainCategory;
  String? _selectedFoodType;

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _webImageData;
  String? _uploadedImageUrl;
  bool _imageChanged = false;
  bool _isLoading = false;
  bool _hasChanges = false;

  // Portion pricing
  final Map<String, TextEditingController> _portionControllers = {
    'Full': TextEditingController(),
    'Half': TextEditingController(),
    'Mini': TextEditingController(),
  };
  final Map<String, bool> _selectedPortions = {
    'Full': false,
    'Half': false,
    'Mini': false,
  };

  // ✅ UPDATED: Combined food hierarchy for all meal times
  final Map<String, List<String>> _foodHierarchy = {
    'Rice and Curry': [
      'Vegetarian',
      'Egg',
      'Omelette',
      'Fish',
      'Chicken',
      'Sausage',
      'Beef',
      'Mutton'
    ],
    'Noodles': ['Chicken', 'Egg', 'Sausage', 'Veg'],
    'Hoppers': ['Plain', 'Egg', 'With Curry'],
    'String Hoppers': [
      'Plain',
      'With Dhal Curry',
      'With Chicken Curry',
      'With Coconut Sambol'
    ],
    'Parata': ['Plain', 'Egg', 'With Curry'],
    'Egg Rotti': ['Plain', 'Egg', 'With Curry'],
    'Roti': ['Plain'],
    'Sandwiches': ['Regular'],
    'Short Eats': [
      'Veg Roll',
      'Egg Roll',
      'Chicken Roll',
      'Fish Bun',
      'Sausage Bun'
    ],
    'Milk Rice (Kiribath)': ['Plain'],
    'Bread and Omelette': ['Regular'],
    'Toast and Jam': ['Regular'],
    'Porridge (Kenda)': ['Regular'],
    'Chapati': ['Plain', 'With Egg', 'With Curry'],
    'Biriyani': ['Chicken', 'Mutton', 'Egg'],
    'Fried Rice': ['Chicken', 'Seafood', 'Egg', 'Veg'],
    'Nasi Goreng': ['Chicken', 'Egg', 'Veg'],
    'Vegetable Rice': ['Regular'],
    'Kottu': ['Veg', 'Egg', 'Chicken'],
    'Dosa': ['Plain', 'With Masala'],
    'Pittu': [
      'With Coconut Sambol',
      'With Dhal',
      'With Chicken Curry',
      'With Fish'
    ],
    'Macaroni': ['Chicken', 'Egg', 'Sausage', 'Veg'],
    'Roti Meals': ['Various']
  };

  @override
  void initState() {
    super.initState();
    _validateStoreId();

    // Initialize controllers with existing food data
    _descriptionController =
        TextEditingController(text: widget.food.description ?? '');

    // ✅ NEW: Initialize meal time - only the current meal time is selected
    _selectedMealTimes[widget.food.time] = true;

    // Parse existing category and type from food name
    _parseExistingFoodData();

    // Initialize portion pricing
    _initializePortionPricing();

    // Pre-fetch image if available
    if (widget.food.imageUrl.isNotEmpty) {
      _uploadedImageUrl = widget.food.imageUrl;
    }

    // Add listener to detect changes
    _descriptionController.addListener(_onFormChanged);

    // ✅ NEW: Check if there are other meal time versions of this food
    _checkForOtherMealTimeVersions();
  }

  // ✅ NEW: Check if this food exists in other meal times
  Future<void> _checkForOtherMealTimeVersions() async {
    try {
      final foodsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('foods')
          .where('name', isEqualTo: widget.food.name)
          .get();

      // Check which meal times already have this food
      for (var doc in foodsSnapshot.docs) {
        final data = doc.data();
        final mealTime = data['time'] as String?;
        if (mealTime != null && _selectedMealTimes.containsKey(mealTime)) {
          _selectedMealTimes[mealTime] = true;
        }
      }

      if (mounted) {
        setState(() {});
      }

      print(
          '🔍 [EditFoodPage] Found ${widget.food.name} in meal times: ${_getSelectedMealTimesList()}');
    } catch (e) {
      print('❌ [EditFoodPage] Error checking meal time versions: $e');
    }
  }

  void _parseExistingFoodData() {
    // Parse food name like "Rice and Curry - Chicken"
    final nameParts = widget.food.name.split(' - ');

    if (nameParts.length == 2) {
      _selectedMainCategory = nameParts[0];
      _selectedFoodType = nameParts[1];
    } else {
      // Fallback to using category and type fields
      _selectedMainCategory =
          widget.food.category.isNotEmpty ? widget.food.category : null;
      _selectedFoodType = widget.food.type.isNotEmpty ? widget.food.type : null;
    }
  }

  void _initializePortionPricing() {
    // Initialize from existing portion prices if available
    if (widget.food.portionPrices.isNotEmpty) {
      widget.food.portionPrices.forEach((portion, price) {
        if (_portionControllers.containsKey(portion)) {
          _selectedPortions[portion] = true;
          _portionControllers[portion]!.text = price.toStringAsFixed(2);
        }
      });
    } else {
      // If no portion prices exist (old food), default to Full portion with existing price
      _selectedPortions['Full'] = true;
      _portionControllers['Full']!.text = widget.food.price.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _portionControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _onFormChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  // ✅ NEW: Multi-select meal times widget
  Widget _buildMealTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Meal Times *', style: EatoTheme.labelLarge),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select when this food item will be available:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              ...['breakfast', 'lunch', 'dinner'].map((mealTime) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selectedMealTimes[mealTime],
                        onChanged: (bool? value) {
                          setState(() {
                            _selectedMealTimes[mealTime] = value ?? false;
                            _hasChanges = true;
                          });
                        },
                        activeColor: EatoTheme.primaryColor,
                      ),
                      SizedBox(width: 8),
                      Icon(
                        _getMealTimeIcon(mealTime),
                        size: 20,
                        color: _selectedMealTimes[mealTime]!
                            ? EatoTheme.primaryColor
                            : Colors.grey,
                      ),
                      SizedBox(width: 8),
                      Text(
                        mealTime.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _selectedMealTimes[mealTime]!
                              ? EatoTheme.primaryColor
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (_getSelectedMealTimesCount() > 0) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: EatoTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Available during: ${_getSelectedMealTimesText()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: EatoTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  IconData _getMealTimeIcon(String mealTime) {
    switch (mealTime) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  int _getSelectedMealTimesCount() {
    return _selectedMealTimes.values.where((selected) => selected).length;
  }

  String _getSelectedMealTimesText() {
    final selected = _selectedMealTimes.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key.toUpperCase())
        .toList();

    if (selected.length == 1) {
      return selected.first;
    } else if (selected.length == 2) {
      return '${selected[0]} & ${selected[1]}';
    } else if (selected.length == 3) {
      return 'ALL MEALS';
    }
    return '';
  }

  List<String> _getSelectedMealTimesList() {
    return _selectedMealTimes.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  List<String> _getMainCategories() {
    return _foodHierarchy.keys.toList();
  }

  List<String> _getFoodTypes() {
    if (_selectedMainCategory == null) return [];
    return _foodHierarchy[_selectedMainCategory!] ?? [];
  }

  void _onMainCategoryChanged(String? value) {
    setState(() {
      _selectedMainCategory = value;
      _selectedFoodType = null;
      _hasChanges = true;
    });
  }

  String _generateFoodName() {
    if (_selectedMainCategory == null || _selectedFoodType == null) {
      return widget.food.name; // Return original name if incomplete
    }
    return '$_selectedMainCategory - $_selectedFoodType';
  }

  Map<String, double> _getSelectedPortionPrices() {
    Map<String, double> prices = {};
    _selectedPortions.forEach((portion, isSelected) {
      if (isSelected) {
        final price = double.tryParse(_portionControllers[portion]!.text);
        if (price != null && price > 0) {
          prices[portion] = price;
        }
      }
    });
    return prices;
  }

  double _getMainPrice() {
    final portions = _getSelectedPortionPrices();
    if (portions.isEmpty) return widget.food.price;

    // Return Full portion price if available, otherwise the first available price
    if (portions.containsKey('Full')) {
      return portions['Full']!;
    }
    return portions.values.first;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
          _imageChanged = true;
          _hasChanges = true;
        });

        if (kIsWeb) {
          final webImageData = await pickedFile.readAsBytes();
          setState(() {
            _webImageData = webImageData;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New image selected'),
            backgroundColor: EatoTheme.infoColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: EatoTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_pickedImage == null || !_imageChanged) return;

    try {
      final fileName = 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child('food_images/$fileName');

      if (kIsWeb) {
        await storageRef.putData(_webImageData!);
      } else {
        await storageRef.putFile(io.File(_pickedImage!.path));
      }

      _uploadedImageUrl = await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }

  // ✅ UPDATED: Update food for multiple meal times
  Future<void> _updateFood() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.storeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid store ID. Cannot update food.'),
          backgroundColor: EatoTheme.errorColor,
        ),
      );
      return;
    }

    // Validate meal times selection
    if (_getSelectedMealTimesCount() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one meal time'),
          backgroundColor: EatoTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedPortions = _getSelectedPortionPrices();
    if (selectedPortions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one portion size with price'),
          backgroundColor: EatoTheme.warningColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 [EditFoodPage] Updating food: ${widget.food.name}');
      print('📍 [EditFoodPage] Store ID: ${widget.storeId}');

      // Only upload new image if changed
      if (_imageChanged) {
        print('📸 [EditFoodPage] Uploading new image...');
        await _uploadImage();
        print('✅ [EditFoodPage] Image uploaded: $_uploadedImageUrl');
      }

      final selectedMealTimes = _getSelectedMealTimesList();
      final currentMealTime = widget.food.time;
      final foodName = _generateFoodName();

      print('🍽️ [EditFoodPage] Updating for meal times: $selectedMealTimes');
      print('🍽️ [EditFoodPage] Current meal time: $currentMealTime');

      // ✅ NEW: Handle meal time changes

      // Step 1: Delete food from meal times that are no longer selected
      await _deleteFromUnselectedMealTimes(currentMealTime, selectedMealTimes);

      // Step 2: Update or create food for selected meal times
      for (String mealTime in selectedMealTimes) {
        final updatedFood = Food(
          id: mealTime == currentMealTime
              ? widget.food.id
              : 'food_${mealTime}_${DateTime.now().millisecondsSinceEpoch}',
          name: foodName,
          type: _selectedFoodType ?? widget.food.type,
          category: _selectedMainCategory ?? widget.food.category,
          price: _getMainPrice(),
          portionPrices: selectedPortions,
          time: mealTime,
          imageUrl: _uploadedImageUrl ?? widget.food.imageUrl,
          description: _descriptionController.text.trim(),
          isAvailable: widget.food.isAvailable,
          createdAt: widget.food.createdAt,
        );

        if (mealTime == currentMealTime) {
          // Update existing food
          await Provider.of<FoodProvider>(context, listen: false)
              .updateFood(widget.storeId, updatedFood);
          print('✅ [EditFoodPage] Updated existing food for $mealTime');
        } else {
          // Create new food for other meal times
          await Provider.of<FoodProvider>(context, listen: false)
              .addFood(widget.storeId, updatedFood);
          print('✅ [EditFoodPage] Created new food for $mealTime');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Food updated successfully for ${selectedMealTimes.length} meal time(s)'),
            backgroundColor: EatoTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ [EditFoodPage] Update failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update food: $e'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _updateFood,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ NEW: Delete food from unselected meal times
  Future<void> _deleteFromUnselectedMealTimes(
      String currentMealTime, List<String> selectedMealTimes) async {
    try {
      // Find all versions of this food
      final foodsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('foods')
          .where('name', isEqualTo: widget.food.name)
          .get();

      for (var doc in foodsSnapshot.docs) {
        final data = doc.data();
        final mealTime = data['time'] as String?;

        // Delete if this meal time is no longer selected
        if (mealTime != null && !selectedMealTimes.contains(mealTime)) {
          await doc.reference.delete();
          print('🗑️ [EditFoodPage] Deleted food from $mealTime');
        }
      }
    } catch (e) {
      print('❌ [EditFoodPage] Error deleting from unselected meal times: $e');
    }
  }

  Future<void> _validateStoreId() async {
    try {
      print('🔍 [EditFoodPage] Validating storeId: ${widget.storeId}');
      print(
          '🍽️ [EditFoodPage] Editing food: ${widget.food.name} (${widget.food.id})');

      if (widget.storeId.isEmpty) {
        throw Exception('Store ID is empty');
      }

      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .get();

      if (!storeDoc.exists) {
        throw Exception('Store does not exist: ${widget.storeId}');
      }

      final storeData = storeDoc.data()!;
      print(
          '✅ [EditFoodPage] Store verified: ${storeData['name']} (${widget.storeId})');

      final foodDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('foods')
          .doc(widget.food.id)
          .get();

      if (!foodDoc.exists) {
        throw Exception('Food item does not exist in this store');
      }

      print('✅ [EditFoodPage] Food verified in store: ${widget.food.name}');
    } catch (e) {
      print('❌ [EditFoodPage] Validation failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Invalid store or food item. Returning to previous page.'),
            backgroundColor: EatoTheme.errorColor,
          ),
        );

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes?'),
        content: Text(
            'You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
            style: EatoTheme.textButtonStyle,
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: EatoTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Edit Food',
            style: TextStyle(
              color: EatoTheme.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: EatoTheme.textPrimaryColor),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.delete, color: EatoTheme.errorColor),
              onPressed: () => _showDeleteConfirmationDialog(),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                onChanged: () {
                  setState(() {
                    _hasChanges = true;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food image
                    Center(
                      child: Column(
                        children: [
                          Text('Food Image', style: EatoTheme.labelLarge),
                          SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: EatoTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      EatoTheme.primaryColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: _getImageWidget(),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to change image',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // ✅ NEW: Meal Time Multi-Selector
                    _buildMealTimeSelector(),

                    // Main Category
                    Text('Food Category *', style: EatoTheme.labelLarge),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value:
                          _getMainCategories().contains(_selectedMainCategory)
                              ? _selectedMainCategory
                              : null,
                      decoration: EatoTheme.inputDecoration(
                        hintText: 'Select main category',
                      ),
                      items: _getMainCategories().map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: _onMainCategoryChanged,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please select main category'
                          : null,
                    ),
                    SizedBox(height: 16),

                    // Food Type
                    if (_getFoodTypes().isNotEmpty) ...[
                      Text('Food Type *', style: EatoTheme.labelLarge),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _getFoodTypes().contains(_selectedFoodType)
                            ? _selectedFoodType
                            : null,
                        decoration: EatoTheme.inputDecoration(
                          hintText: 'Select food type',
                        ),
                        items: _getFoodTypes().map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedFoodType = val;
                              _hasChanges = true;
                            });
                          }
                        },
                        validator: (val) {
                          if (_getFoodTypes().isNotEmpty &&
                              (val == null || val.isEmpty)) {
                            return 'Please select food type';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                    ],

                    // Auto-generated Food Name Display
                    if (_selectedMainCategory != null &&
                        _selectedFoodType != null) ...[
                      Text('Food Name (Auto-generated)',
                          style: EatoTheme.labelLarge),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: EatoTheme.primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: EatoTheme.primaryColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          _generateFoodName(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: EatoTheme.primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Portion Sizes and Pricing
                    Text('Available Portion Sizes & Pricing *',
                        style: EatoTheme.labelLarge),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: _portionControllers.keys.map((portion) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedPortions[portion]!
                                  ? EatoTheme.primaryColor.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedPortions[portion]!
                                    ? EatoTheme.primaryColor.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Checkbox
                                Checkbox(
                                  value: _selectedPortions[portion],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _selectedPortions[portion] =
                                          value ?? false;
                                      if (!_selectedPortions[portion]!) {
                                        _portionControllers[portion]!.clear();
                                      }
                                      _hasChanges = true;
                                    });
                                  },
                                  activeColor: EatoTheme.primaryColor,
                                ),

                                // Portion name
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    portion,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: _selectedPortions[portion]!
                                          ? EatoTheme.primaryColor
                                          : Colors.grey,
                                    ),
                                  ),
                                ),

                                SizedBox(width: 12),

                                // Price input
                                Expanded(
                                  child: TextFormField(
                                    controller: _portionControllers[portion],
                                    enabled: _selectedPortions[portion],
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                      hintText: 'Enter price (Rs.)',
                                      prefixText: 'Rs. ',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      filled: true,
                                      fillColor: _selectedPortions[portion]!
                                          ? Colors.white
                                          : Colors.grey.withOpacity(0.1),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _hasChanges = true;
                                      });
                                    },
                                    validator: (value) {
                                      if (_selectedPortions[portion]!) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Enter price for $portion';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Invalid price';
                                        }
                                        if (double.parse(value) <= 0) {
                                          return 'Price must be > 0';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Description
                    Text('Description (Optional)', style: EatoTheme.labelLarge),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: EatoTheme.inputDecoration(
                        hintText: 'Enter food description',
                      ),
                    ),
                    SizedBox(height: 32),

                    // Update button
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateFood,
                          style: EatoTheme.primaryButtonStyle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Update Food',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Full-screen loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            color: EatoTheme.primaryColor),
                        SizedBox(height: 16),
                        Text('Updating food item...',
                            style: EatoTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getImageWidget() {
    if (_pickedImage != null) {
      // Show newly picked image
      if (kIsWeb) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            _webImageData!,
            fit: BoxFit.cover,
            width: 150,
            height: 150,
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            io.File(_pickedImage!.path),
            fit: BoxFit.cover,
            width: 150,
            height: 150,
          ),
        );
      }
    } else if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
      // Show existing image
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _uploadedImageUrl!,
          fit: BoxFit.cover,
          width: 150,
          height: 150,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: EatoTheme.primaryColor,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image_not_supported_outlined,
              color: EatoTheme.primaryColor,
              size: 40,
            );
          },
        ),
      );
    } else {
      // Show add icon
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            color: EatoTheme.primaryColor,
            size: 40,
          ),
          SizedBox(height: 8),
          Text(
            'Add Photo',
            style: TextStyle(
              color: EatoTheme.primaryColor,
              fontSize: 12,
            ),
          ),
        ],
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Delete Food Item?'),
          content: Text(
            'Are you sure you want to delete "${widget.food.name}"? This will remove it from ALL meal times. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
              style: EatoTheme.textButtonStyle,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteFood();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  // ✅ UPDATED: Delete food from all meal times
  Future<void> _deleteFood() async {
    if (widget.storeId.isEmpty || widget.food.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid store or food ID. Cannot delete.'),
          backgroundColor: EatoTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print(
          '🗑️ [EditFoodPage] Deleting all versions of food: ${widget.food.name}');
      print('📍 [EditFoodPage] From store: ${widget.storeId}');

      // ✅ NEW: Delete all versions of this food across all meal times
      final foodsSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('foods')
          .where('name', isEqualTo: widget.food.name)
          .get();

      for (var doc in foodsSnapshot.docs) {
        await doc.reference.delete();
        print(
            '🗑️ [EditFoodPage] Deleted ${doc.id} from ${doc.data()['time']}');
      }

      print('✅ [EditFoodPage] All versions of food deleted successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Food deleted from all meal times'),
            backgroundColor: EatoTheme.infoColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ [EditFoodPage] Delete failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete food: $e'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
