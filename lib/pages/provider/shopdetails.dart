import 'dart:io';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/pages/provider/AddFoodPage.dart';
import 'package:eato/pages/provider/ProfilePage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:eato/Provider/StoreProvider.dart' as store_provider;
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/FoodProvider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StoreDetailsPage extends StatefulWidget {
  final CustomUser currentUser;

  const StoreDetailsPage({Key? key, required this.currentUser})
      : super(key: key);

  @override
  _StoreDetailsPageState createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopContactController = TextEditingController();
  final TextEditingController _shopLocationController = TextEditingController();
  bool isPickup = true;
  XFile? _pickedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  int _currentIndex = 3; // Starting with profile tab active
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final storeProvider =
        Provider.of<store_provider.StoreProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await storeProvider.fetchUserStore(widget.currentUser);

      // If store exists, pre-fill the form
      if (storeProvider.userStore != null) {
        setState(() {
          _shopNameController.text = storeProvider.userStore!.name;
          _shopContactController.text = storeProvider.userStore!.contact;
          _shopLocationController.text =
              storeProvider.userStore!.location ?? '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading store data: $e";
      });
      print(_errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedImage =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _pickedImage = pickedImage;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 3) {
      // Add Food
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddFoodPage(
            storeId: Provider.of<store_provider.StoreProvider>(context,
                        listen: false)
                    .userStore
                    ?.id ??
                widget.currentUser.id,
          ),
        ),
      );
    } else if (index == 4) {
      // Profile
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(currentUser: widget.currentUser),
        ),
      );
    } else if (index == 2) {
      // Home (reload StoreDetailsPage)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              StoreDetailsPage(currentUser: widget.currentUser),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<store_provider.StoreProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser ?? widget.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Welcome!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading || storeProvider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            )
          : storeProvider.userStore == null
              ? _buildShopDetailsForm(storeProvider, currentUser.id)
              : _buildFoodPage(storeProvider),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildShopDetailsForm(
      store_provider.StoreProvider storeProvider, String userId) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Enter your shop details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Shop Name Field
            Text(
              "Shop Name",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _shopNameController,
                decoration: InputDecoration(
                  hintText: "Enter your shop name",
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Shop Contact Number Field
            Text(
              "Shop Contact Number",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _shopContactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Enter your shop contact number",
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Shop Location Field (new)
            Text(
              "Shop Location (Optional)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _shopLocationController,
                decoration: InputDecoration(
                  hintText: "Enter your shop location",
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Delivery Options
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  // Pickup button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPickup = true;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isPickup ? Colors.purple : Colors.transparent,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Pickup',
                            style: TextStyle(
                              color: isPickup ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Delivery button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPickup = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isPickup ? Colors.purple : Colors.transparent,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Delivery',
                            style: TextStyle(
                              color: !isPickup ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Profile Picture
            Center(
              child: Column(
                children: [
                  Text(
                    "Shop Image",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: _pickedImage == null
                          ? Center(
                              child: Icon(
                                Icons.add,
                                size: 40,
                                color: Colors.purple,
                              ),
                            )
                          : ClipOval(
                              child: Image.file(
                                File(_pickedImage!.path),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // Next Button
            Center(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _saveShopDetails(storeProvider, userId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: Size(120, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveShopDetails(
      store_provider.StoreProvider storeProvider, String userId) async {
    if (_shopNameController.text.isEmpty ||
        _shopContactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Upload image to Firebase Storage if selected
      String imageUrl = '';
      if (_pickedImage != null) {
        final fileName =
            'shop_${userId}_${DateTime.now().millisecondsSinceEpoch}';
        final reference = FirebaseStorage.instance
            .ref()
            .child('store_images')
            .child('$fileName.jpg');

        await reference.putFile(File(_pickedImage!.path));
        imageUrl = await reference.getDownloadURL();
        print('Image uploaded successfully. URL: $imageUrl');
      }

      // Create the store - using userId as storeId for consistency
      final store = Store(
        id: userId, // Use userId instead of timestamp for consistency
        name: _shopNameController.text,
        contact: _shopContactController.text,
        isPickup: isPickup,
        imageUrl: imageUrl,
        location: _shopLocationController.text.trim(),
        foods: [],
      );

      print('Creating store with data: ${store.toMap()}');
      await storeProvider.createOrUpdateStore(store, userId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shop created successfully')),
      );

      // Refresh page to show the food page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              StoreDetailsPage(currentUser: widget.currentUser),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating shop: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );

      print(_errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildFoodPage(store_provider.StoreProvider storeProvider) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final storeId = storeProvider.userStore!.id;

    // Fetch foods for this store
    foodProvider.fetchFoods(storeId);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Tab selector for meal types
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMealTypeTab('Breakfast', true),
                _buildMealTypeTab('Lunch', false),
                _buildMealTypeTab('Dinner', false),
              ],
            ),
          ),

          // Add New Food button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddFoodPage(storeId: storeId),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.0),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add New Food',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Food items list
          foodProvider.foods.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No food items added yet. Add your first food item!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: foodProvider.foods.length,
                  itemBuilder: (context, index) {
                    final food = foodProvider.foods[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              // Food image
                              food.imageUrl.isNotEmpty
                                  ? Image.network(
                                      food.imageUrl,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 120,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.fastfood,
                                          size: 40, color: Colors.grey[600]),
                                    ),

                              // Delete button overlay
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () async {
                                    await foodProvider.deleteFood(
                                        storeId, food.id);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.delete,
                                        color: Colors.red, size: 20),
                                  ),
                                ),
                              ),

                              // Edit button overlay
                              Positioned(
                                top: 8,
                                right: 40,
                                child: GestureDetector(
                                  onTap: () {
                                    // Handle edit functionality
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.edit,
                                        color: Colors.purple, size: 20),
                                  ),
                                ),
                              ),

                              // Food info overlay
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  color: Colors.white,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        food.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Rs.${food.price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMealTypeTab(String title, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? Colors.purple : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.purple : Colors.grey,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      selectedItemColor: Colors.purple,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.article_outlined),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none),
          label: 'Requests',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Add Food',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
