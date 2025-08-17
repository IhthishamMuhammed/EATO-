// FILE: lib/Provider/user_provider_extensions.dart
// Extension methods for UserProvider to handle additional functionality

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eato/Provider/userProvider.dart';
import 'dart:io';

extension UserProviderExtensions on UserProvider {
  /// Change user password using Firebase Auth
  Future<void> changePassword(
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

  /// Update user profile picture (alias for existing method)
  Future<String?> updateUserProfilePicture(File imageFile) async {
    final User? authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) {
      throw Exception('User not authenticated');
    }

    return await uploadProfilePicture(authUser.uid, imageFile);
  }

  /// Get user profile image URL safely
  String? getUserProfileImageUrl() {
    return getProfilePictureUrl();
  }

  /// Update user email
  Future<void> updateUserEmail(String newEmail, String password) async {
    final User? authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null || authUser.email == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: authUser.email!,
        password: password,
      );

      await authUser.reauthenticateWithCredential(credential);

      // Update email
      await authUser.updateEmail(newEmail);

      // Update email in Firestore
      await updateUserFields(authUser.uid, {'email': newEmail});

      print('Email updated successfully');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Password is incorrect';
          break;
        case 'email-already-in-use':
          errorMessage = 'This email is already in use';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log out and log back in before changing email';
          break;
        default:
          errorMessage = 'Failed to update email: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  /// Delete user account
  Future<void> deleteUserAccount(String password) async {
    final User? authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null || authUser.email == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: authUser.email!,
        password: password,
      );

      await authUser.reauthenticateWithCredential(credential);

      // ✅ FIX: Delete user data from Firestore using the correct method
      await _deleteUserFromFirestore(authUser.uid);

      // Delete Firebase Auth account
      await authUser.delete();

      // Clear current user
      clearCurrentUser();

      print('Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Password is incorrect';
          break;
        case 'requires-recent-login':
          errorMessage =
              'Please log out and log back in before deleting account';
          break;
        default:
          errorMessage = 'Failed to delete account: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// ✅ FIX: Helper method to delete user from Firestore
  Future<void> _deleteUserFromFirestore(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Delete user document
      await firestore.collection('users').doc(userId).delete();
      print('User document deleted from Firestore');
    } catch (e) {
      print('Error deleting user from Firestore: $e');
      throw Exception('Failed to delete user data: $e');
    }
  }
}
