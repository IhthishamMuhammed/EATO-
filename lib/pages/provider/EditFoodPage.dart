import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:eato/pages/theme/eato_theme.dart';
// Import the image compressor utility
import 'package:eato/utils/image_compressor.dart'; // Add this import

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
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  late String _selectedMealTime;
  late String _selectedFoodCategory;
  late String _selectedFoodType;
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  Uint8List? _webImageData;
  File? _compressedImageFile;
  Uint8List? _compressedWebData;
  String? _uploadedImageUrl;
  bool _imageChanged = false;
  bool _isLoading = false;
  bool _hasChanges = false;

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

    // Initialize controllers with existing food data
    _nameController = TextEditingController(text: widget.food.name);
    _priceController =
        TextEditingController(text: widget.food.price.toString());

    // Initialize drop-down values
    _selectedMealTime = widget.food.time;
    _selectedFoodType = widget.food.type;

    // Set food category if available, otherwise use first option
    _selectedFoodCategory = _foodCategories.contains(widget.food.category)
        ? widget.food.category
        : _foodCategories.first;

    // Pre-fetch image if available
    if (widget.food.imageUrl.isNotEmpty) {
      _uploadedImageUrl = widget.food.imageUrl;
    }

    // Add listeners to detect changes
    _nameController.addListener(_onFormChanged);
    _priceController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _pickImage() async {
    try {
      // Use Smart Compression - automatically tries different levels until it works
      final pickedFile = await ImageCompressor.pickSmartCompressedImage(
        source: ImageSource.gallery,
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
            _compressedWebData = webImageData; // Use directly
          });
        } else {
          // Use the already optimized file directly
          setState(() {
            _compressedImageFile = File(pickedFile.path);
          });
        }


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
        // Upload compressed data for web
        if (_compressedWebData != null) {
          await storageRef.putData(_compressedWebData!);
        } else {
          await storageRef.putData(_webImageData!);
        }
      } else {
        // Upload compressed file for mobile/desktop
        if (_compressedImageFile != null) {
          await storageRef.putFile(_compressedImageFile!);
        } else {
          await storageRef.putFile(io.File(_pickedImage!.path));
        }
      }

      _uploadedImageUrl = await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }

  Future<void> _updateFood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Only upload new image if changed
      if (_imageChanged) {
        await _uploadImage();
      }

      // Create updated food object
      final updatedFood = Food(
        id: widget.food.id,
        name: _nameController.text.trim(),
        type: _selectedFoodType,
        category: _selectedFoodCategory,
        price: double.tryParse(_priceController.text) ?? 0,
        time: _selectedMealTime,
        imageUrl: _uploadedImageUrl ?? widget.food.imageUrl,
      );

      // Update food via provider
      await Provider.of<FoodProvider>(context, listen: false)
          .updateFood(widget.storeId, updatedFood);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Food updated successfully'),
            backgroundColor: EatoTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(
            context, true); // Return true to indicate successful update
      }
    } catch (e) {
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

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
            Column(
              children: [
                // Meal time tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                      )
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
                            _hasChanges = true;
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
                                      : Colors.grey,
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

                // Form fields
                Expanded(
                  child: SingleChildScrollView(
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
                                        color: EatoTheme.primaryColor
                                            .withOpacity(0.5),
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
                                // Show compressed file size
                                if (_pickedImage != null)
                                  FutureBuilder<String>(
                                    future: _getCompressedSize(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            'Compressed size: ${snapshot.data}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green[600],
                                            ),
                                          ),
                                        );
                                      }
                                      return SizedBox.shrink();
                                    },
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),

                          // Food name
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

                          // Food price
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

                          // Food category
                          Text('Food Category *', style: EatoTheme.labelLarge),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value:
                                _foodCategories.contains(_selectedFoodCategory)
                                    ? _selectedFoodCategory
                                    : _foodCategories.first,
                            decoration: EatoTheme.inputDecoration(
                              hintText: 'Select food category',
                            ),
                            items: _foodCategories.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedFoodCategory = val;
                                  _hasChanges = true;
                                });
                              }
                            },
                            validator: (val) => val == null || val.isEmpty
                                ? 'Please select food category'
                                : null,
                          ),
                          SizedBox(height: 16),

                          // Food type
                          Text('Food Type *', style: EatoTheme.labelLarge),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _foodTypes.contains(_selectedFoodType)
                                ? _selectedFoodType
                                : _foodTypes.first,
                            decoration: EatoTheme.inputDecoration(
                              hintText: 'Select food type',
                            ),
                            items: _foodTypes.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option),
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
                            validator: (val) => val == null || val.isEmpty
                                ? 'Please select food type'
                                : null,
                          ),
                          SizedBox(height: 16),

                          // Description
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

                          // Update button
                          Center(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateFood,
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
                ),
              ],
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
                        Text(
                          'Updating food item...',
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
      // Show newly picked image
      if (kIsWeb) {
        final imageData = _compressedWebData ?? _webImageData;
        if (imageData != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              imageData,
              fit: BoxFit.cover,
              width: 150,
              height: 150,
            ),
          );
        }
      } else {
        final imageFile = _compressedImageFile ?? io.File(_pickedImage!.path);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            imageFile,
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
    }

    // Default fallback - Show add icon
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

  Future<String> _getCompressedSize() async {
    if (kIsWeb) {
      final imageData = _compressedWebData ?? _webImageData;
      if (imageData != null) {
        return ImageCompressor.getFileSize(imageData.length);
      }
    } else {
      final imageFile = _compressedImageFile ??
          (_pickedImage != null ? io.File(_pickedImage!.path) : null);
      if (imageFile != null) {
        final size = await imageFile.length();
        return ImageCompressor.getFileSize(size);
      }
    }
    return '';
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
            'Are you sure you want to delete "${widget.food.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
              style: EatoTheme.textButtonStyle,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteFood();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFood() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<FoodProvider>(context, listen: false)
          .deleteFood(widget.storeId, widget.food.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Food deleted successfully'),
            backgroundColor: EatoTheme.infoColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate change
      }
    } catch (e) {
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