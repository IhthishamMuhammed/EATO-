// File: lib/pages/provider/ProfilePage.dart
// Enhanced version with password change and logout confirmation - UPPER PART

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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' as io;

import '../../Model/Food&Store.dart';
import 'package:eato/pages/location/location_picker_page.dart';

// Main ProfilePage Class
class ProfilePage extends StatefulWidget {
  final CustomUser currentUser;

  const ProfilePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  bool _isEditingProfile = false;
  bool _isEditingShop = false;
  XFile? _pickedProfileImage;
  XFile? _pickedShopImage;
  Uint8List? _webProfileImageData;
  Uint8List? _webShopImageData;

  // Password visibility toggles
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserAndStoreData();
    });
  }

  Future<void> _loadUserAndStoreData() async {
    // ✅ FIX: Check if widget is still mounted before setState
    if (!mounted) return;

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

      // ✅ FIX: Check mounted before setState and batch updates
      if (mounted) {
        final user = userProvider.currentUser;
        final store = storeProvider.userStore;

        setState(() {
          // Update all controllers in a single setState
          if (user != null) {
            _nameController.text = user.name;
            _emailController.text = user.email;
            _phoneController.text = user.phoneNumber ?? '';
            _locationController.text = user.address ?? '';
          }

          if (store != null) {
            _shopNameController.text = store.name;
            _shopContactController.text = store.contact;
            _shopLocationController.text = store.location ?? '';
          }

          _isLoading = false; // Set loading to false in same setState
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user data: $e'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  // Password Change Dialog
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EatoTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      color: EatoTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Change Password',
                    style: EatoTheme.headingSmall,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Current Password
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: !_currentPasswordVisible,
                        decoration: EatoTheme.inputDecoration(
                          labelText: 'Current Password',
                          hintText: 'Enter your current password',
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_currentPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setDialogState(() {
                                _currentPasswordVisible =
                                    !_currentPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // New Password
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: !_newPasswordVisible,
                        decoration: EatoTheme.inputDecoration(
                          labelText: 'New Password',
                          hintText: 'Enter new password',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_newPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setDialogState(() {
                                _newPasswordVisible = !_newPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !_confirmPasswordVisible,
                        decoration: EatoTheme.inputDecoration(
                          labelText: 'Confirm Password',
                          hintText: 'Confirm new password',
                          prefixIcon: Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(_confirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setDialogState(() {
                                _confirmPasswordVisible =
                                    !_confirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: EatoTheme.textButtonStyle,
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        Navigator.of(dialogContext).pop();
                        setState(() {
                          _isLoading = true;
                        });

                        await _changePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Password changed successfully'),
                                ],
                              ),
                              backgroundColor: EatoTheme.successColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.error, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                      child: Text(e
                                          .toString()
                                          .replaceFirst('Exception: ', ''))),
                                ],
                              ),
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
                  },
                  style: EatoTheme.primaryButtonStyle,
                  child: Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Change password method
  Future<void> _changePassword(
      String currentPassword, String newPassword) async {
    final User? authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null || authUser.email == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Re-authenticate user with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: authUser.email!,
        password: currentPassword,
      );

      await authUser.reauthenticateWithCredential(credential);

      // Update password
      await authUser.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Current password is incorrect';
          break;
        case 'weak-password':
          errorMessage = 'New password is too weak';
          break;
        case 'requires-recent-login':
          errorMessage =
              'Please log out and log back in before changing password';
          break;
        default:
          errorMessage = 'Failed to change password: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Logout Confirmation Dialog
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EatoTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout,
                  color: EatoTheme.errorColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Confirm Logout',
                style: EatoTheme.headingSmall,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to logout?',
                style: EatoTheme.bodyMedium,
              ),
              SizedBox(height: 8),
              Text(
                'You will need to login again to access your account.',
                style: EatoTheme.bodySmall.copyWith(
                  color: EatoTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: EatoTheme.textButtonStyle,
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
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
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Profile updated successfully'),
            ],
          ),
          backgroundColor: EatoTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to update profile: $e'),
            ],
          ),
          backgroundColor: EatoTheme.errorColor,
          behavior: SnackBarBehavior.floating,
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

    // ✅ FIX: Check mounted before setState
    if (!mounted) return;

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

      if (currentStore != null) {
        // UPDATING EXISTING STORE
        final Store updatedStore = Store(
          id: currentStore.id,
          name: _shopNameController.text.trim(),
          contact: _shopContactController.text.trim(),
          deliveryMode: currentStore.deliveryMode,
          imageUrl: shopImageUrl ?? currentStore.imageUrl,
          foods: currentStore.foods,
          location: _shopLocationController.text.trim().isEmpty
              ? null
              : _shopLocationController.text.trim(),
          latitude: currentStore.latitude,
          longitude: currentStore.longitude,
          ownerUid: widget.currentUser.id,
          isActive: currentStore.isActive,
          isAvailable: currentStore.isAvailable,
          rating: currentStore.rating,
        );

        await storeProvider.createOrUpdateStore(
            updatedStore, widget.currentUser.id);
      } else {
        // CREATING NEW STORE
        final Store newStore = Store(
          id: '',
          name: _shopNameController.text.trim(),
          contact: _shopContactController.text.trim(),
          deliveryMode: DeliveryMode.pickup,
          imageUrl: shopImageUrl ?? '',
          foods: [],
          location: _shopLocationController.text.trim().isEmpty
              ? null
              : _shopLocationController.text.trim(),
          ownerUid: widget.currentUser.id,
          isActive: true,
          isAvailable: true,
          rating: null,
        );

        await storeProvider.createOrUpdateStore(
            newStore, widget.currentUser.id);
      }

      // ✅ FIX: Refresh data and update UI in sequence
      await storeProvider.fetchUserStore(widget.currentUser);

      // ✅ FIX: Check mounted before setState
      if (mounted) {
        setState(() {
          _isEditingShop = false;
          _isLoading = false; // Set both in same setState
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Shop details updated successfully'),
              ],
            ),
            backgroundColor: EatoTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error saving shop changes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to update shop details: $e'),
              ],
            ),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  // Delivery Mode Selector Widget
  Widget _buildDeliveryModeSelector(Store? store) {
    return Consumer<StoreProvider>(
      builder: (context, storeProvider, child) {
        final currentStore = storeProvider.userStore ?? store;
        final currentDeliveryMode =
            currentStore?.deliveryMode ?? DeliveryMode.pickup;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Options', style: EatoTheme.labelLarge),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  _buildDeliveryOption('Pickup', DeliveryMode.pickup,
                      currentDeliveryMode, currentStore, storeProvider),
                  _buildDeliveryOption('Delivery', DeliveryMode.delivery,
                      currentDeliveryMode, currentStore, storeProvider),
                  _buildDeliveryOption('Both', DeliveryMode.both,
                      currentDeliveryMode, currentStore, storeProvider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeliveryOption(
      String title,
      DeliveryMode mode,
      DeliveryMode currentMode,
      Store? currentStore,
      StoreProvider storeProvider) {
    final isSelected = currentMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (currentStore != null) {
            final updatedStore = currentStore.copyWith(deliveryMode: mode);
            storeProvider.setStore(updatedStore);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? EatoTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: mode == DeliveryMode.pickup
                  ? Radius.circular(11)
                  : Radius.zero,
              right:
                  mode == DeliveryMode.both ? Radius.circular(11) : Radius.zero,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Location Picker Widget using your LocationPickerPage
  Widget _buildLocationPicker(Store? store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shop Location',
          style: EatoTheme.labelLarge,
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            try {
              // Use your LocationPickerPage
              final result = await Navigator.push<LocationData>(
                context,
                MaterialPageRoute(
                  builder: (context) => LocationPickerPage(
                    initialLocation:
                        store?.latitude != null && store?.longitude != null
                            ? GeoPoint(store!.latitude!, store.longitude!)
                            : null,
                    initialAddress: store?.location,
                  ),
                ),
              );

              if (result != null) {
                // Update the store with new location
                setState(() {
                  _shopLocationController.text = result.formattedAddress;
                });

                // Update store in provider
                if (store != null) {
                  final updatedStore = store.copyWith(
                    location: result.formattedAddress,
                    latitude: result.geoPoint.latitude,
                    longitude: result.geoPoint.longitude,
                  );
                  Provider.of<StoreProvider>(context, listen: false)
                      .setStore(updatedStore);
                }
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error selecting location: $e'),
                  backgroundColor: EatoTheme.errorColor,
                ),
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: EatoTheme.primaryColor,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _shopLocationController.text.isEmpty
                        ? 'Tap to select location from map'
                        : _shopLocationController.text,
                    style: TextStyle(
                      color: _shopLocationController.text.isEmpty
                          ? Colors.grey
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            EatoTheme.primaryColor.withOpacity(0.1),
                            EatoTheme.accentColor.withOpacity(0.05),
                          ],
                        ),
                      ),
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: EatoTheme.primaryColor
                                            .withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: EatoTheme.primaryColor,
                                      width: 3,
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
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
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
                            style: EatoTheme.headingMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),

                          // User Role
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  EatoTheme.primaryColor,
                                  EatoTheme.accentColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      EatoTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              user.userType,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
                                style: EatoTheme.headingSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!_isEditingProfile && !_isEditingShop)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: EatoTheme.primaryColor
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isEditingProfile = true;
                                      });
                                    },
                                    icon: Icon(Icons.edit, size: 18),
                                    label: Text('Edit'),
                                    style: EatoTheme.textButtonStyle,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Personal Details Form or View
                          _isEditingProfile
                              ? _buildProfileEditForm(user)
                              : _buildProfileViewDetails(user),

                          // Password Change Section
                          if (!_isEditingProfile && !_isEditingShop) ...[
                            SizedBox(height: 24),
                            Divider(height: 32, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Security',
                                  style: EatoTheme.headingSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showChangePasswordDialog,
                                icon: Icon(Icons.lock_outline),
                                label: Text('Change Password'),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  side:
                                      BorderSide(color: EatoTheme.primaryColor),
                                  foregroundColor: EatoTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],

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
                                  style: EatoTheme.headingSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!_isEditingProfile && !_isEditingShop)
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: EatoTheme.primaryColor
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _isEditingShop = true;
                                        });
                                      },
                                      icon: Icon(Icons.edit, size: 18),
                                      label: Text('Edit'),
                                      style: EatoTheme.textButtonStyle,
                                    ),
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
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        EatoTheme.errorColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _showLogoutConfirmationDialog,
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
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              EatoTheme.primaryColor.withOpacity(0.1),
              EatoTheme.accentColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Icon(
          Icons.person,
          size: 60,
          color: EatoTheme.primaryColor,
        ),
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
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              EatoTheme.primaryColor.withOpacity(0.1),
              EatoTheme.accentColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Icon(
          Icons.store,
          size: 40,
          color: EatoTheme.primaryColor,
        ),
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

          // Location picker with your LocationPickerPage
          _buildLocationPicker(store),
          SizedBox(height: 16),

          // Delivery mode selector
          _buildDeliveryModeSelector(store),
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
          icon: _getDeliveryModeIcon(store.deliveryMode),
          title: 'Delivery Mode',
          value: store.deliveryMode.displayName,
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

  IconData _getDeliveryModeIcon(DeliveryMode mode) {
    switch (mode) {
      case DeliveryMode.pickup:
        return Icons.local_shipping_outlined;
      case DeliveryMode.delivery:
        return Icons.delivery_dining;
      case DeliveryMode.both:
        return Icons.compare_arrows;
    }
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
}
