import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/Model/Food&Store.dart';

import 'dart:io' as io; // Required for mobile/desktop File

class AddFoodPage extends StatefulWidget {
  final String storeId;

  const AddFoodPage({Key? key, required this.storeId}) : super(key: key);

  @override
  _AddFoodPageState createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedMealTime = 'Breakfast';
  String _selectedFoodCategory = 'Rice and Curry';
  String _selectedFoodType = 'Non-Vegetarian';
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  Uint8List? _webImageData;
  String? _uploadedImageUrl;
  bool _isLoading = false;

  final List<String> _mealTimes = ['Breakfast', 'Lunch', 'Dinner'];
  final List<String> _foodCategories = [
    'Rice and Curry',
    'String Hoppers',
    'Roti',
    'Egg Roti',
    'Short Eats',
    'Hoppers',
    'Other'
  ];
  final List<String> _foodTypes = [
    'Vegetarian',
    'Non-Vegetarian',
    'Vegan',
    'Dessert'
  ];

  @override
  void initState() {
    super.initState();
    // Validate storeId on init
    if (widget.storeId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please set up your store first.'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate back after showing error
        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        // Upload data for web
        await storageRef.putData(_webImageData!);
      } else {
        // Upload file for mobile/desktop
        await storageRef.putFile(io.File(_pickedImage!.path));
      }

      _uploadedImageUrl = await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _saveFood() async {
    // Check if storeId is valid
    if (widget.storeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' Please set up your store first.'),
          backgroundColor: EatoTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if image is selected
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image
      await _uploadImage();

      // Generate a unique id for the food
      final foodId = 'food_${DateTime.now().millisecondsSinceEpoch}';

      // Create food object
      final food = Food(
        id: foodId,
        name: _nameController.text.trim(),
        type: _selectedFoodType,
        category: _selectedFoodCategory,
        price: double.tryParse(_priceController.text) ?? 0,
        time: _selectedMealTime,
        imageUrl: _uploadedImageUrl ?? '',
        description: _descriptionController.text.trim(),
      );

      // Add food to database
      await Provider.of<FoodProvider>(context, listen: false)
          .addFood(widget.storeId, food);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Food added successfully'),
            backgroundColor: EatoTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back after success
        Navigator.pop(context, true);
      }
    } catch (e) {
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
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: EatoTheme.appBar(
        context: context,
        title: 'Add New Food',
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Meal time tabs
            Column(
              children: [
                // Meal time selector
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _mealTimes.map((mealTime) {
                      bool isActive = mealTime == _selectedMealTime;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMealTime = mealTime;
                          });
                        },
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                mealTime,
                                style: TextStyle(
                                  color: isActive
                                      ? EatoTheme.primaryColor
                                      : Colors.grey, // Fixed color visibility
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Container(
                              height: 2,
                              width: screenSize.width / _mealTimes.length - 24,
                              color: isActive
                                  ? EatoTheme.primaryColor
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Form section
                Expanded(
                  child: SingleChildScrollView(
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
                                Text(
                                  'Food Image',
                                  style: EatoTheme.labelLarge,
                                ),
                                SizedBox(height: 12),
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: EatoTheme.primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                                255, 255, 255, 255)
                                            .withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: _getImageWidget(),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to select image',
                                  style: EatoTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // REORDERED FIELDS as requested:
                          // 1. Food category
                          Text('Food Category *', style: EatoTheme.labelLarge),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: EatoTheme.inputDecoration(
                              hintText: 'Select food category',
                            ),
                            value: _selectedFoodCategory,
                            items: _foodCategories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedFoodCategory = value;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          // 2. Food type
                          Text('Food Type *', style: EatoTheme.labelLarge),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: EatoTheme.inputDecoration(
                              hintText: 'Select food type',
                            ),
                            value: _selectedFoodType,
                            items: _foodTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedFoodType = value;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a food type';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          // 3. Food name
                          Text('Food Name *', style: EatoTheme.labelLarge),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: EatoTheme.inputDecoration(
                              hintText: 'Enter food name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter food name';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          // 4. Food price
                          Text('Price (Rs) *', style: EatoTheme.labelLarge),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _priceController,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            decoration: EatoTheme.inputDecoration(
                              hintText: 'Enter price in rupees',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter price';
                              }

                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }

                              if (double.parse(value) <= 0) {
                                return 'Price must be greater than zero';
                              }

                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          // 5. Description
                          Text('Description (Optional)',
                              style: EatoTheme.labelLarge),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
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
                ),
              ],
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
                        Text(
                          'Saving food item...',
                          style: EatoTheme.bodyMedium,
                        ),
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
      // Show selected image
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
      // Show placeholder
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
