// FILE: lib/pages/customer/account_page.dart
// Corrected version - ONLY user account management, no order history

import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eato/pages/onboarding/RoleSelectionPage.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AccountPage extends StatefulWidget {
  final bool showBottomNav;

  const AccountPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final User? authUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    if (authUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<UserProvider>(context, listen: false)
            .fetchUser(authUser!.uid);
      });
    }
  }

  // Change password using Firebase Auth directly
  Future<void> _changePassword(
      String currentPassword, String newPassword) async {
    if (authUser == null || authUser!.email == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Re-authenticate user with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: authUser!.email!,
        password: currentPassword,
      );

      await authUser!.reauthenticateWithCredential(credential);

      // Update password
      await authUser!.updatePassword(newPassword);

      print('Password updated successfully');
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

  // Logout method
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Provider.of<UserProvider>(context, listen: false).clearCurrentUser();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Change profile picture
  Future<void> _changeProfilePicture(UserProvider userProvider) async {
    if (!mounted) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null && authUser != null && mounted) {
      setState(() {
        isLoading = true;
      });

      try {
        File imageFile = File(image.path);
        await userProvider.uploadProfilePicture(authUser!.uid, imageFile);

        if (mounted) {
          await userProvider.fetchUser(authUser!.uid);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile picture: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  // Show change password dialog
  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current Password
                  TextField(
                    controller: currentPasswordController,
                    obscureText: !_currentPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_currentPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setDialogState(() {
                            _currentPasswordVisible = !_currentPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // New Password
                  TextField(
                    controller: newPasswordController,
                    obscureText: !_newPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
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
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !_confirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_confirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setDialogState(() {
                            _confirmPasswordVisible = !_confirmPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('New passwords do not match'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (newPasswordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Password must be at least 6 characters'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await _changePassword(
                        currentPasswordController.text,
                        newPasswordController.text,
                      );

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password changed successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to change password: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.person, color: Colors.purple, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Account',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }

          if (userProvider.currentUser == null) {
            return const Center(
              child: Text('Please log in to view your account'),
            );
          }

          final user = userProvider.currentUser!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade100,
                        Colors.purple.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
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
                            backgroundColor: Colors.purple.shade200,
                            backgroundImage:
                                user.profileImageUrl?.isNotEmpty == true
                                    ? NetworkImage(user.profileImageUrl!)
                                    : null,
                            child: user.profileImageUrl?.isEmpty ?? true
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.purple.shade700,
                                  )
                                : null,
                          ),
                          if (isLoading)
                            const Positioned.fill(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.purple),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _changeProfilePicture(userProvider),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Account Actions - ✅ ONLY USER ACCOUNT RELATED OPTIONS
                Column(
                  children: [
                    // Edit Profile
                    _buildActionButton(
                      'Edit Profile',
                      'Update your personal information',
                      Icons.edit_outlined,
                      Colors.blue.shade100,
                      Colors.blue.shade700,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit Profile feature coming soon!'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
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

                    const SizedBox(height: 12),

                    // Notification Preferences
                    _buildActionButton(
                      'Notifications',
                      'Manage notification preferences',
                      Icons.notifications_outlined,
                      Colors.indigo.shade100,
                      Colors.indigo.shade700,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification settings coming soon!'),
                            backgroundColor: Colors.indigo,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Privacy & Security
                    _buildActionButton(
                      'Privacy & Security',
                      'Manage your privacy settings',
                      Icons.security,
                      Colors.teal.shade100,
                      Colors.teal.shade700,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy settings coming soon!'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Settings
                    _buildActionButton(
                      'Settings',
                      'App preferences and settings',
                      Icons.settings_outlined,
                      Colors.grey.shade100,
                      Colors.grey.shade700,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings feature coming soon!'),
                            backgroundColor: Colors.grey,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Help & Support
                    _buildActionButton(
                      'Help & Support',
                      'Get help and contact support',
                      Icons.help_outline,
                      Colors.orange.shade100,
                      Colors.orange.shade700,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Help & Support feature coming soon!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    _buildActionButton(
                      'Logout',
                      'Sign out from your account',
                      Icons.logout,
                      Colors.red.shade100,
                      Colors.red.shade700,
                      () => _logout(context),
                    ),
                  ],
                ),

                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
              currentIndex: 4, // Account tab
              onTap: _onBottomNavTap,
            )
          : null,
    );
  }

  // Handle bottom navigation taps
  void _onBottomNavTap(int index) {
    if (index == 4 || !mounted) return; // Already on Account tab

    if (widget.showBottomNav) {
      // Standalone mode: Use named routes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/shops');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/orders');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/activity');
              break;
          }
        }
      });
    } else {
      // ✅ ADD THIS: In embedded mode, don't navigate - let parent handle it
      print(
          "🔄 Account page embedded mode - ignoring navigation to index $index");
      // The CustomerHomePage will handle the tab switching via PageController
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
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
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
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
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
