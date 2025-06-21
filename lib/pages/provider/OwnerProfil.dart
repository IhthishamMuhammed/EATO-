import 'dart:io';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/pages/provider/AddFoodPage.dart';
import 'package:eato/pages/provider/ProfilePage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:eato/Model/Food&Store.dart';
import 'package:eato/Provider/StoreProvider.dart';
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
  DeliveryMode _selectedDeliveryMode =
      DeliveryMode.pickup; // Updated to use DeliveryMode
  XFile? _pickedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  int _currentIndex = 2; // Starting with menu tab active

  @override
  void initState() {
    super.initState();
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    storeProvider.fetchUserStore(widget.currentUser);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugStoreInfo();
    });
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
      // Profile
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(currentUser: widget.currentUser),
        ),
      );
    } else if (index == 2) {
      // Home (reload StoreDetailsPage) - current page
      // Already here
    }
  }

  // NEW: Delivery Mode Selector Widget
  Widget _buildDeliveryModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Delivery Options",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey),
          ),
          child: Row(
            children: [
              // Pickup Only
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDeliveryMode = DeliveryMode.pickup;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedDeliveryMode == DeliveryMode.pickup
                          ? Colors.purple
                          : Colors.transparent,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(30),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Pickup',
                        style: TextStyle(
                          color: _selectedDeliveryMode == DeliveryMode.pickup
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Delivery Only
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDeliveryMode = DeliveryMode.delivery;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedDeliveryMode == DeliveryMode.delivery
                          ? Colors.purple
                          : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        'Delivery',
                        style: TextStyle(
                          color: _selectedDeliveryMode == DeliveryMode.delivery
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Both Options
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDeliveryMode = DeliveryMode.both;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedDeliveryMode == DeliveryMode.both
                          ? Colors.purple
                          : Colors.transparent,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(30),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Both',
                        style: TextStyle(
                          color: _selectedDeliveryMode == DeliveryMode.both
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Location picker placeholder (same as ProfilePage)
  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Shop Location",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            // Temporary fallback - show dialog for manual entry
            _showLocationInputDialog();
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.purple,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _shopLocationController.text.isEmpty
                        ? 'Tap to select location'
                        : _shopLocationController.text,
                    style: TextStyle(
                      color: _shopLocationController.text.isEmpty
                          ? Colors.grey[600]
                          : Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Temporary location input dialog
  void _showLocationInputDialog() {
    final TextEditingController tempController = TextEditingController(
      text: _shopLocationController.text,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Shop Location'),
          content: TextField(
            controller: tempController,
            decoration: InputDecoration(
              hintText: 'Enter your shop address',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _shopLocationController.text = tempController.text;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

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
      body: storeProvider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            )
          : storeProvider.userStore == null
              ? _buildShopDetailsForm(storeProvider, currentUser!.id)
              : _buildFoodPage(storeProvider),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildShopDetailsForm(StoreProvider storeProvider, String userId) {
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

            // NEW: Location Picker
            _buildLocationPicker(),
            SizedBox(height: 20),

            // NEW: Updated Delivery Options (Three options)
            _buildDeliveryModeSelector(),
            SizedBox(height: 20),

            // Shop Image
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
                onPressed: () async {
                  if (_shopNameController.text.isEmpty ||
                      _shopContactController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Please fill all required fields')),
                    );
                    return;
                  }

                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // Upload image to Firebase Storage if selected
                    String imageUrl = '';
                    if (_pickedImage != null) {
                      final fileName =
                          DateTime.now().millisecondsSinceEpoch.toString();
                      final reference = FirebaseStorage.instance
                          .ref()
                          .child('store_images')
                          .child('$fileName.jpg');

                      await reference.putFile(File(_pickedImage!.path));
                      imageUrl = await reference.getDownloadURL();
                    }

                    // Create the store with new DeliveryMode structure
                    final store = Store(
                      id: '',
                      name: _shopNameController.text,
                      contact: _shopContactController.text,
                      deliveryMode:
                          _selectedDeliveryMode, // Updated to use DeliveryMode
                      imageUrl: imageUrl,
                      foods: [],
                      location: _shopLocationController.text.trim().isEmpty
                          ? null
                          : _shopLocationController.text.trim(),
                      ownerUid: userId,
                    );

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating shop: $e')),
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
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

  Widget _buildFoodPage(StoreProvider storeProvider) {
    final foodProvider = Provider.of<FoodProvider>(context);
    final storeId = storeProvider.userStore?.id ?? '';
    if (storeId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Store setup incomplete. Please complete store setup first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    print('🔍 Fetching foods for storeId: $storeId');

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

  void _debugStoreInfo() {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    print('=== STORE DEBUG INFO ===');
    print('User ID: ${widget.currentUser.id}');
    print('Store exists: ${storeProvider.userStore != null}');
    print('Store ID: ${storeProvider.userStore?.id ?? 'null'}');
    print('Store name: ${storeProvider.userStore?.name ?? 'null'}');
    print('========================');
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
