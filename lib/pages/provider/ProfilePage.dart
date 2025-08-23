// File: lib/pages/provider/ProfilePage.dart
// Enhanced Profile Page with Customer Account UI design pattern

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' as io;

import 'ShopDetailsSection.dart';
import 'package:eato/EatoComponents.dart';

class ProfilePage extends StatefulWidget {
  final CustomUser currentUser;

  const ProfilePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;
  bool _isEditingProfile = false;
  XFile? _pickedProfileImage;
  Uint8List? _webProfileImageData;

  // Password visibility toggles
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _editProfileFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    _nameController = TextEditingController(text: widget.currentUser.name);
    _emailController = TextEditingController(text: widget.currentUser.email);
    _phoneController =
        TextEditingController(text: widget.currentUser.phoneNumber ?? '');
    _locationController = TextEditingController(text: '');

    // Load user data only if not already cached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserDataIfNeeded();
    });
  }

  Future<void> _loadUserDataIfNeeded() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Only load if user data is not already cached
    if (userProvider.currentUser == null ||
        userProvider.currentUser!.id != widget.currentUser.id) {
      await _loadUserData();
    } else {
      // Use cached data
      final user = userProvider.currentUser!;
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
      _locationController.text = user.address ?? '';
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUser(widget.currentUser.id);

      if (mounted) {
        final user = userProvider.currentUser;
        setState(() {
          if (user != null) {
            _nameController.text = user.name;
            _emailController.text = user.email;
            _phoneController.text = user.phoneNumber ?? '';
            _locationController.text = user.address ?? '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to load user data: $e', EatoTheme.errorColor);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                backgroundColor == EatoTheme.errorColor
                    ? Icons.error
                    : Icons.check_circle,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onLoadingChanged(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  // Change profile picture
  Future<void> _changeProfilePicture(UserProvider userProvider) async {
    if (!mounted) return;

    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        io.File imageFile = io.File(image.path);
        String? newImageUrl = await userProvider.uploadProfilePicture(
            widget.currentUser.id, imageFile);

        if (mounted && newImageUrl != null) {
          await userProvider.fetchUser(widget.currentUser.id);
          _showSnackBar(
              'Profile picture updated successfully!', EatoTheme.successColor);
        } else {
          throw Exception('Failed to upload image');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(
              'Failed to update profile picture: $e', EatoTheme.errorColor);
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
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.lock_outline,
                      color: EatoTheme.primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text('Change Password', style: EatoTheme.headingSmall),
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
                          _showSnackBar('Password changed successfully',
                              EatoTheme.successColor);
                        }
                      } catch (e) {
                        if (mounted) {
                          _showSnackBar(
                              e.toString().replaceFirst('Exception: ', ''),
                              EatoTheme.errorColor);
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
      AuthCredential credential = EmailAuthProvider.credential(
        email: authUser.email!,
        password: currentPassword,
      );

      await authUser.reauthenticateWithCredential(credential);
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

  // Show edit profile dialog (Customer style)
  void _showEditProfileDialog(UserProvider userProvider) {
    final user = userProvider.currentUser ?? widget.currentUser;

    // Initialize controllers with current data
    _nameController.text = user.name;
    _phoneController.text = user.phoneNumber ?? '';
    _locationController.text = user.address ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _editProfileFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.edit,
                              color: EatoTheme.primaryColor, size: 24),
                          const SizedBox(width: 8),
                          Text('Edit Profile', style: EatoTheme.headingSmall),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Profile Picture Section
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor:
                                  EatoTheme.primaryColor.withOpacity(0.2),
                              child: user.profileImageUrl?.isNotEmpty == true
                                  ? ClipOval(
                                      child: Image.network(
                                        user.profileImageUrl!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            size: 40,
                                            color: EatoTheme.primaryColor,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 40,
                                      color: EatoTheme.primaryColor,
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await _changeProfilePicture(userProvider);
                                  _showEditProfileDialog(userProvider);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: EatoTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: EatoTheme.inputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field (Read-only)
                      TextFormField(
                        initialValue: user.email,
                        enabled: false,
                        decoration: EatoTheme.inputDecoration(
                          labelText: 'Email',
                          hintText: user.email,
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        decoration: EatoTheme.inputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: EatoTheme.outlinedButtonStyle,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _saveProfileChanges(userProvider),
                              style: EatoTheme.primaryButtonStyle,
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Save profile changes
  Future<void> _saveProfileChanges(UserProvider userProvider) async {
    if (!_editProfileFormKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Update user profile using UserProvider method
      final success = await userProvider.updateUserProfile(
        widget.currentUser.id,
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _locationController.text.trim(),
      );

      Navigator.of(context).pop(); // Close dialog

      if (success) {
        _showSnackBar('Profile updated successfully!', EatoTheme.successColor);
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      _showSnackBar('Failed to update profile: $e', EatoTheme.errorColor);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Logout Confirmation Dialog
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.logout, color: EatoTheme.errorColor, size: 24),
              const SizedBox(width: 8),
              const Text('Logout'),
            ],
          ),
          content:
              const Text('Are you sure you want to logout from your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
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
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      setState(() {
        _isLoading = true;
      });

      Provider.of<UserProvider>(context, listen: false).clearCurrentUser();
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Logout failed: ${e.toString()}', EatoTheme.errorColor);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: backgroundColor,
                radius: 22,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser ?? widget.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: EatoComponents.appBar(
        context: context,
        title: 'Profile',
        titleIcon: Icons.person,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: EatoTheme.primaryColor))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section with gradient background (like customer)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            EatoTheme.primaryColor.withOpacity(0.1),
                            EatoTheme.accentColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: EatoTheme.primaryColor.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor:
                                    EatoTheme.primaryColor.withOpacity(0.2),
                                child: user.profileImageUrl?.isNotEmpty == true
                                    ? ClipOval(
                                        child: Image.network(
                                          user.profileImageUrl!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                                strokeWidth: 2,
                                                color: EatoTheme.primaryColor,
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 50,
                                              color: EatoTheme.primaryColor,
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 50,
                                        color: EatoTheme.primaryColor,
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () =>
                                      _changeProfilePicture(userProvider),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: EatoTheme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (user.phoneNumber?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.phoneNumber!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          if (user.address?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.address!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 8),
                          // User Role Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  EatoTheme.primaryColor,
                                  EatoTheme.accentColor
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

                    const SizedBox(height: 24),

                    // Account Actions (Customer style)
                    Column(
                      children: [
                        // Edit Profile
                        _buildActionButton(
                          'Edit Profile',
                          'Update your personal information',
                          Icons.edit_outlined,
                          Colors.blue.shade100,
                          Colors.blue.shade700,
                          () => _showEditProfileDialog(userProvider),
                        ),

                        const SizedBox(height: 12),

                        // Change Password
                        _buildActionButton(
                          'Change Password',
                          'Update your account password',
                          Icons.lock_outline,
                          Colors.amber.shade100,
                          Colors.amber.shade700,
                          _showChangePasswordDialog,
                        ),

                        const SizedBox(height: 24),

                        // Store Details Section (for providers only)
                        if (user.userType
                            .toLowerCase()
                            .contains('provider')) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ShopDetailsSection(
                              currentUser: widget.currentUser,
                              onLoadingChanged: _onLoadingChanged,
                              onShowSnackBar: _showSnackBar,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Logout Button
                        _buildActionButton(
                          'Logout',
                          'Sign out from your account',
                          Icons.logout,
                          Colors.red.shade100,
                          Colors.red.shade700,
                          _showLogoutConfirmationDialog,
                        ),
                      ],
                    ),

                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
    );
  }
}
