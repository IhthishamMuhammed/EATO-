// File: lib/pages/AddFoodPage.dart (Fixed with multi-select meal times)

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/Model/Food&Store.dart';
import 'dart:io' as io;

class AddFoodPage extends StatefulWidget {
  final String storeId;
  final String? preSelectedMealTime;

  const AddFoodPage({
    Key? key,
    required this.storeId,
    this.preSelectedMealTime,
  }) : super(key: key);

  @override
  _AddFoodPageState createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

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
  bool _isLoading = false;

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

    // ✅ UPDATED: Initialize with pre-selected meal time if provided
    if (widget.preSelectedMealTime != null) {
      final preSelected = widget.preSelectedMealTime!.toLowerCase();
      if (_selectedMealTimes.containsKey(preSelected)) {
        _selectedMealTimes[preSelected] = true;
      }
    }

    if (widget.storeId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please set up your store first.'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _portionControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
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
    });
  }

  String _generateFoodName() {
    if (_selectedMainCategory == null || _selectedFoodType == null) {
      return '';
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
    if (portions.isEmpty) return 0;

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
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
        });

        if (kIsWeb) {
          final webImageData = await pickedFile.readAsBytes();
          setState(() {
            _webImageData = webImageData;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected successfully'),
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
    if (_pickedImage == null) return;

    try {
      final fileName = 'food_${DateTime.now().millisecondsSinceEpoch}';
      final storageRef =
          FirebaseStorage.instance.ref().child('food_images/$fileName');

      if (kIsWeb) {
        await storageRef.putData(_webImageData!);
      } else {
        await storageRef.putFile(io.File(_pickedImage!.path));
      }

      _uploadedImageUrl = await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // ✅ UPDATED: Save food for multiple meal times
  Future<void> _saveFood() async {
    if (widget.storeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please set up your store first.'),
          backgroundColor: EatoTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedMainCategory == null || _selectedMainCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a main category'),
          backgroundColor: EatoTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
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

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a food image'),
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
      await _uploadImage();

      final selectedMealTimes = _getSelectedMealTimesList();
      final foodName = _generateFoodName();

      print(
          '🍽️ [AddFoodPage] Creating food for meal times: $selectedMealTimes');
      print('📝 [AddFoodPage] Food name: $foodName');

      // ✅ NEW: Create separate food entries for each selected meal time
      for (String mealTime in selectedMealTimes) {
        final foodId =
            'food_${mealTime}_${DateTime.now().millisecondsSinceEpoch}';

        final food = Food(
          id: foodId,
          name: foodName,
          type: _selectedFoodType ?? '',
          category: _selectedMainCategory ?? '',
          price: _getMainPrice(),
          portionPrices: selectedPortions,
          time: mealTime, // Each entry gets specific meal time
          imageUrl: _uploadedImageUrl ?? '',
          description: _descriptionController.text.trim(),
        );

        await Provider.of<FoodProvider>(context, listen: false)
            .addFood(widget.storeId, food);

        print('✅ [AddFoodPage] Food added for $mealTime: $foodId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Food added successfully for ${selectedMealTimes.length} meal time(s)'),
            backgroundColor: EatoTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ [AddFoodPage] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add food: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EatoTheme.appBar(
        context: context,
        title: 'Add New Food',
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food Image Selection
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
                          Text('Tap to select image',
                              style: EatoTheme.bodySmall),
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
                      decoration: EatoTheme.inputDecoration(
                        hintText: 'Select main category',
                      ),
                      value: _selectedMainCategory,
                      items: _getMainCategories().map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: _onMainCategoryChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a main category';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Food Type
                    if (_getFoodTypes().isNotEmpty) ...[
                      Text('Food Type *', style: EatoTheme.labelLarge),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: EatoTheme.inputDecoration(
                          hintText: 'Select food type',
                        ),
                        value: _selectedFoodType,
                        items: _getFoodTypes().map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFoodType = value;
                          });
                        },
                        validator: (value) {
                          if (_getFoodTypes().isNotEmpty &&
                              (value == null || value.isEmpty)) {
                            return 'Please select a food type';
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

                    // Submit button
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveFood,
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
                                    'Save Food',
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

            // Loading overlay
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
                        Text('Saving food item...',
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
    } else {
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
}
