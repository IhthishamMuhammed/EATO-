// FILE: lib/core/route_guards.dart
// Enhanced with automatic user data loading

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Provider/userProvider.dart';
import '../Model/coustomUser.dart';

class RouteGuards {
  // ✅ Enhanced protected route with auto user loading
  static Widget buildProtectedRoute({required Widget child}) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return FutureBuilder<bool>(
          future: _ensureUserIsLoaded(userProvider),
          builder: (context, snapshot) {
            // Show loading while checking/loading user
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            // Check if user is authenticated and loaded
            if (userProvider.currentUser == null) {
              return const _LoginRequiredScreen();
            }

            return child;
          },
        );
      },
    );
  }

  // ✅ Enhanced provider route with auto user loading
  static Widget buildProviderRoute({
    required Widget Function(CustomUser) builder,
  }) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return FutureBuilder<bool>(
          future: _ensureUserIsLoaded(userProvider),
          builder: (context, snapshot) {
            // Show loading while checking/loading user
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            final user = userProvider.currentUser;

            if (user == null) {
              return const _LoginRequiredScreen();
            }

            if (user.userType.toLowerCase() != 'provider') {
              return const _AccessDeniedScreen();
            }

            return builder(user);
          },
        );
      },
    );
  }

  // ✅ Helper method to ensure user data is loaded
  static Future<bool> _ensureUserIsLoaded(UserProvider userProvider) async {
    try {
      // If user data is already loaded, return true
      if (userProvider.currentUser != null) {
        return true;
      }

      // Check if there's an authenticated Firebase user
      final User? authUser = FirebaseAuth.instance.currentUser;

      if (authUser == null) {
        print("🚫 No authenticated Firebase user found");
        return false;
      }

      print("🔄 Loading user data for authenticated user: ${authUser.uid}");

      // Fetch user data from Firestore
      await userProvider.fetchUser(authUser.uid);

      // Check if data was successfully loaded
      final bool success = userProvider.currentUser != null;

      if (success) {
        print(
            "✅ User data loaded successfully: ${userProvider.currentUser?.name}");
      } else {
        print("❌ Failed to load user data");
      }

      return success;
    } catch (e) {
      print("⚠️ Error ensuring user is loaded: $e");
      return false;
    }
  }
}

// ✅ Enhanced loading screen
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 30,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your account...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginRequiredScreen extends StatelessWidget {
  const _LoginRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Login Required',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Please login to access this page',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/role_selection',
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'This page is only available for food providers',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/home',
                ),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
