import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' as io;

import '../../Model/Food&Store.dart';
import 'OrderHomePage.dart';
import 'RequestHome.dart';
import 'ProviderHomePage.dart';

class ProfilePage extends StatefulWidget {
  final CustomUser currentUser;

  const ProfilePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 3; // Profile tab is selected by default
  bool _isLoading = false;
  bool _isEditingProfile = false;
  bool _isEditingShop = false;
  XFile? _pickedProfileImage;
  XFile? _pickedShopImage;
  Uint8List? _webProfileImageData;
  Uint8List? _webShopImageData;

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  // Store controllers
  late TextEditingController _shopNameController;
  late TextEditingController _shopContactController;
  late TextEditingController _shopLocationController;

  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _shopFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    _nameController = TextEditingController(text: widget.currentUser.name);
    _emailController = TextEditingController(text: widget.currentUser.email);
    _phoneController =
        TextEditingController(text: widget.currentUser.phoneNumber ?? '');
    _locationController = TextEditingController(text: '');

    // Initialize store controllers
    _shopNameController = TextEditingController();
    _shopContactController = TextEditingController();
    _shopLocationController = TextEditingController();

    // Load user and store data
    _loadUserAndStoreData();
  }

  Future<void> _loadUserAndStoreData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch user data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUser(widget.currentUser.id);

      // Fetch store data
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      await storeProvider.fetchUserStore(widget.currentUser);

      // Update controllers with fetched data
      final user = userProvider.currentUser;
      final store = storeProvider.userStore;

      if (user != null) {
        setState(() {
          _nameController.text = user.name;
          _emailController.text = user.email;
          _phoneController.text = user.phoneNumber ?? '';
          _locationController.text = user.address ?? '';
        });
      }

      if (store != null) {
        setState(() {
          _shopNameController.text = store.name;
          _shopContactController.text = store.contact;
          _shopLocationController.text = store.location ?? '';
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user data: $e'),
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _shopNameController.dispose();
    _shopContactController.dispose();
    _shopLocationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Orders
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderHomePage(currentUser: widget.currentUser),
          ),
        );
        break;
      case 1: // Requests
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RequestHome(currentUser: widget.currentUser),
          ),
        );
        break;
      case 2: // Menu
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProviderHomePage(currentUser: widget.currentUser),
          ),
        );
        break;
      case 3: // Profile - current page
        // Already on this page
        break;
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _pickedProfileImage = image;
        });

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webProfileImageData = bytes;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: EatoTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _pickShopImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _pickedShopImage = image;
        });

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webShopImageData = bytes;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: EatoTheme.errorColor,
        ),
      );
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_pickedProfileImage == null) return null;

    try {
      final fileName =
          'profile_${widget.currentUser.id}_${DateTime.now().millisecondsSinceEpoch}';
      final ref =
          FirebaseStorage.instance.ref().child('profile_images/$fileName');

      if (kIsWeb) {
        await ref.putData(_webProfileImageData!);
      } else {
        await ref.putFile(io.File(_pickedProfileImage!.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<String?> _uploadShopImage() async {
    if (_pickedShopImage == null) return null;

    try {
      final fileName =
          'shop_${widget.currentUser.id}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = FirebaseStorage.instance.ref().child('shop_images/$fileName');

      if (kIsWeb) {
        await ref.putData(_webShopImageData!);
      } else {
        await ref.putFile(io.File(_pickedShopImage!.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading shop image: $e');
      return null;
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser ?? widget.currentUser;

      // Upload profile image if changed
      String? profileImageUrl;
      if (_pickedProfileImage != null) {
        profileImageUrl = await _uploadProfileImage();
      }

      // Create updated user data map
      final Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _locationController.text.trim(),
      };

      // Only update image URL if a new one was uploaded
      if (profileImageUrl != null) {
        userData['profileImageUrl'] = profileImageUrl;
      }

      // Update specific fields in Firestore
      await userProvider.updateUserFields(currentUser.id, userData);

      // Refresh user data
      await userProvider.fetchUser(currentUser.id);

      setState(() {
        _isEditingProfile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: EatoTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: EatoTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveShopChanges() async {
    if (!_shopFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final currentStore = storeProvider.userStore;

      // Upload shop image if changed
      String? shopImageUrl;
      if (_pickedShopImage != null) {
        shopImageUrl = await _uploadShopImage();
      }

      // Determine if we're creating a new store or updating existing
      if (currentStore != null) {
        // Create updated store data
        final Store updatedStore = Store(
          id: currentStore.id,
          name: _shopNameController.text.trim(),
          contact: _shopContactController.text.trim(),
          isPickup: currentStore.isPickup,
          imageUrl: shopImageUrl ?? currentStore.imageUrl,
          foods: currentStore.foods,
          location: _shopLocationController.text.trim(),
        );

        // Update store in Firebase
        await storeProvider.createOrUpdateStore(
            updatedStore, widget.currentUser.id);
      } else {
        // Create new store data
        final Store newStore = Store(
          id: widget.currentUser.id, // Use user ID as store ID for consistency
          name: _shopNameController.text.trim(),
          contact: _shopContactController.text.trim(),
          isPickup: true, // Default value
          imageUrl: shopImageUrl ?? '',
          foods: [],
          location: _shopLocationController.text.trim(),
        );

        // Create store in Firebase
        await storeProvider.createOrUpdateStore(
            newStore, widget.currentUser.id);
      }

      // Refresh store data after update
      await storeProvider.fetchUserStore(widget.currentUser);

      setState(() {
        _isEditingShop = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shop details updated successfully'),
          backgroundColor: EatoTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update shop details: $e'),
          backgroundColor: EatoTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Clear provider data
      Provider.of<UserProvider>(context, listen: false).clearCurrentUser();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: EatoTheme.errorColor,
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
    final userProvider = Provider.of<UserProvider>(context);
    final storeProvider = Provider.of<StoreProvider>(context);

    // Use updated currentUser if available from provider
    final user = userProvider.currentUser ?? widget.currentUser;
    final store = storeProvider.userStore;

    return Scaffold(
      appBar: EatoTheme.appBar(
        context: context,
        title: 'Profile',
        actions: [
          if (_isEditingProfile || _isEditingShop)
            IconButton(
              icon: Icon(Icons.check, color: EatoTheme.primaryColor),
              onPressed: () {
                if (_isEditingProfile) {
                  _saveProfileChanges();
                } else if (_isEditingShop) {
                  _saveShopChanges();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: EatoTheme.primaryColor))
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header with Image
                    Container(
                      color: EatoTheme.primaryColor.withOpacity(0.05),
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Profile Image
                          GestureDetector(
                            onTap: _isEditingProfile ? _pickProfileImage : null,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        EatoTheme.primaryColor.withOpacity(0.2),
                                    border: Border.all(
                                      color: EatoTheme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _buildProfileImage(user),
                                  ),
                                ),
                                if (_isEditingProfile)
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: EatoTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),

                          // User Name
                          Text(
                            user.name,
                            style: EatoTheme.headingMedium,
                          ),
                          SizedBox(height: 4),

                          // User Role
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: EatoTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.userType,
                              style: TextStyle(
                                color: EatoTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Section Divider
                    SizedBox(height: 8),

                    // Personal Details Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Personal Details',
                                style: EatoTheme.headingSmall,
                              ),
                              if (!_isEditingProfile && !_isEditingShop)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isEditingProfile = true;
                                    });
                                  },
                                  icon: Icon(Icons.edit, size: 18),
                                  label: Text('Edit'),
                                  style: EatoTheme.textButtonStyle,
                                ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Personal Details Form or View
                          _isEditingProfile
                              ? _buildProfileEditForm(user)
                              : _buildProfileViewDetails(user),

                          SizedBox(height: 24),

                          // Store Details Section (for providers only)
                          if (user.userType
                              .toLowerCase()
                              .contains('provider')) ...[
                            Divider(height: 32, thickness: 1),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Shop Details',
                                  style: EatoTheme.headingSmall,
                                ),
                                if (!_isEditingProfile && !_isEditingShop)
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isEditingShop = true;
                                      });
                                    },
                                    icon: Icon(Icons.edit, size: 18),
                                    label: Text('Edit'),
                                    style: EatoTheme.textButtonStyle,
                                  ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Store Details Form or View
                            _isEditingShop
                                ? _buildShopEditForm(store)
                                : _buildShopViewDetails(store),
                          ],

                          SizedBox(height: 32),

                          // Logout Button
                          if (!_isEditingProfile && !_isEditingShop)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _handleLogout,
                                icon: Icon(Icons.logout),
                                label: Text('Logout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EatoTheme.errorColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),

                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProfileImage(CustomUser user) {
    if (_pickedProfileImage != null) {
      // Show newly picked image
      if (kIsWeb) {
        return Image.memory(
          _webProfileImageData!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        );
      } else {
        return Image.file(
          io.File(_pickedProfileImage!.path),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        );
      }
    } else if (user.profileImageUrl != null &&
        user.profileImageUrl!.isNotEmpty) {
      // Show existing profile image
      return Image.network(
        user.profileImageUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
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
            Icons.person,
            size: 60,
            color: EatoTheme.primaryColor,
          );
        },
      );
    } else {
      // Show placeholder
      return Icon(
        Icons.person,
        size: 60,
        color: EatoTheme.primaryColor,
      );
    }
  }

  Widget _buildShopImage(Store? store) {
    if (_pickedShopImage != null) {
      // Show newly picked image
      if (kIsWeb) {
        return Image.memory(
          _webShopImageData!,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        );
      } else {
        return Image.file(
          io.File(_pickedShopImage!.path),
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        );
      }
    } else if (store != null && store.imageUrl.isNotEmpty) {
      // Show existing shop image
      return Image.network(
        store.imageUrl,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
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
            Icons.store,
            size: 40,
            color: EatoTheme.primaryColor,
          );
        },
      );
    } else {
      // Show placeholder
      return Icon(
        Icons.store,
        size: 40,
        color: EatoTheme.primaryColor,
      );
    }
  }

  Widget _buildProfileEditForm(CustomUser user) {
    return Form(
      key: _profileFormKey,
      child: Column(
        children: [
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: EatoTheme.inputDecoration(
              hintText: 'Enter your name',
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Email field (disabled - should be changed through auth)
          TextFormField(
            controller: _emailController,
            enabled: false,
            decoration: EatoTheme.inputDecoration(
              hintText: 'Enter your email',
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          SizedBox(height: 16),

          // Phone field
          TextFormField(
            controller: _phoneController,
            decoration: EatoTheme.inputDecoration(
              hintText: 'Enter your phone number',
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16),

          // Location field
          TextFormField(
            controller: _locationController,
            decoration: EatoTheme.inputDecoration(
              hintText: 'Enter your location',
              labelText: 'Location',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingProfile = false;

                      // Reset controllers to original values
                      _nameController.text = user.name;
                      _phoneController.text = user.phoneNumber ?? '';
                      _locationController.text = user.address ?? '';

                      // Clear picked image
                      _pickedProfileImage = null;
                      _webProfileImageData = null;
                    });
                  },
                  style: EatoTheme.outlinedButtonStyle,
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveProfileChanges,
                  style: EatoTheme.primaryButtonStyle,
                  child: Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopEditForm(Store? store) {
    return Form(
      key: _shopFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop image
          Center(
            child: Column(
              children: [
                Text(
                  'Shop Image',
                  style: EatoTheme.labelLarge,
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickShopImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: EatoTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: EatoTheme.primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildShopImage(store),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap to change image',
                  style: EatoTheme.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Shop name field
          TextFormField(
            controller: _shopNameController,
            decoration: EatoTheme.inputDecoration(
              hintText: 'Enter shop name',
              labelText: 'Shop Name',
              prefixIcon: Icon(Icons.store_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter shop name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Shop contact field
          TextFormField(
            controller: _shopContactController,
            decoration: EatoTheme.inputDecoration(
              hintText: 'Enter shop contact number',
              labelText: 'Contact Number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter contact number';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Shop location field
          TextFormField(
            controller: _shopLocationController,
            decoration: EatoTheme.inputDecoration(
              hintText: 'Enter shop location',
              labelText: 'Location',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          SizedBox(height: 16),

          // Delivery options
          Text(
            'Delivery Options',
            style: EatoTheme.labelLarge,
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (store != null) {
                        final updatedStore = store.copyWith(
                          isPickup: true,
                        );
                        Provider.of<StoreProvider>(context, listen: false)
                            .setStore(updatedStore);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: store?.isPickup ?? true
                            ? EatoTheme.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(11),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Pickup',
                          style: TextStyle(
                            color: store?.isPickup ?? true
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (store != null) {
                        final updatedStore = store.copyWith(
                          isPickup: false,
                        );
                        Provider.of<StoreProvider>(context, listen: false)
                            .setStore(updatedStore);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !(store?.isPickup ?? true)
                            ? EatoTheme.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(11),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Delivery',
                          style: TextStyle(
                            color: !(store?.isPickup ?? true)
                                ? Colors.white
                                : Colors.black,
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
          SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingShop = false;

                      // Reset controllers to original values
                      if (store != null) {
                        _shopNameController.text = store.name;
                        _shopContactController.text = store.contact;
                        _shopLocationController.text = store.location ?? '';
                      }

                      // Clear picked image
                      _pickedShopImage = null;
                      _webShopImageData = null;
                    });
                  },
                  style: EatoTheme.outlinedButtonStyle,
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveShopChanges,
                  style: EatoTheme.primaryButtonStyle,
                  child: Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileViewDetails(CustomUser user) {
    return Column(
      children: [
        _buildInfoTile(
          icon: Icons.email_outlined,
          title: 'Email',
          value: user.email,
        ),
        SizedBox(height: 8),
        _buildInfoTile(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: user.phoneNumber ?? 'Not set',
        ),
        SizedBox(height: 8),
        if (user.address != null && user.address!.isNotEmpty) ...[
          _buildInfoTile(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: user.address!,
          ),
          SizedBox(height: 8),
        ],
        _buildInfoTile(
          icon: Icons.verified_user_outlined,
          title: 'Account Type',
          value: user.userType,
        ),
      ],
    );
  }

  Widget _buildShopViewDetails(Store? store) {
    if (store == null) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.store_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No shop details available',
              style: EatoTheme.bodyMedium.copyWith(
                color: EatoTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditingShop = true;
                  // Initialize shop controllers with default values
                  _shopNameController.text = '';
                  _shopContactController.text = '';
                  _shopLocationController.text = '';
                });
              },
              style: EatoTheme.primaryButtonStyle,
              child: Text('Add Shop Details'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Shop image
        if (store.imageUrl.isNotEmpty)
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: EatoTheme.primaryColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  store.imageUrl,
                  fit: BoxFit.cover,
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.store,
                      size: 40,
                      color: EatoTheme.primaryColor,
                    );
                  },
                ),
              ),
            ),
          ),
        if (store.imageUrl.isNotEmpty) SizedBox(height: 16),

        _buildInfoTile(
          icon: Icons.store_outlined,
          title: 'Shop Name',
          value: store.name,
        ),
        SizedBox(height: 8),
        _buildInfoTile(
          icon: Icons.phone_outlined,
          title: 'Contact',
          value: store.contact,
        ),
        SizedBox(height: 8),
        _buildInfoTile(
          icon: store.isPickup
              ? Icons.local_shipping_outlined
              : Icons.delivery_dining,
          title: 'Delivery Mode',
          value: store.isPickup ? 'Pickup' : 'Delivery',
        ),
        if (store.location != null && store.location!.isNotEmpty) ...[
          SizedBox(height: 8),
          _buildInfoTile(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: store.location!,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: EatoTheme.primaryColor,
            size: 24,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: EatoTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: EatoTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      selectedItemColor: EatoTheme.primaryColor,
      unselectedItemColor: EatoTheme.textLightColor,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_outlined),
          activeIcon: Icon(Icons.receipt),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          activeIcon: Icon(Icons.notifications),
          label: 'Requests',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu_outlined),
          activeIcon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
