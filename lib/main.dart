import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/Provider/OrderProvider.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:eato/services/notification_service.dart';

// Firebase configuration
import 'SplashScreen.dart';
import 'firebase_options.dart';

// Import user-related classes
import 'package:eato/pages/onboarding/onboarding1.dart'; // Welcome Page
import 'package:eato/pages/customer/homepage/customer_home.dart'; // Customer Home
import 'package:eato/pages/provider/shopdetails.dart'; // Meal Provider Home
import 'package:eato/pages/provider/OrderHomePage.dart';
import 'package:eato/pages/provider/RequestHome.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/pages/customer/account_page.dart'; // Account Page

// Import customer page files to register routing
import 'package:eato/pages/customer/homepage/meal_pages.dart';

// ✅ ADD THESE IMPORTS for the new order system
import 'package:eato/pages/customer/Orders_Page.dart'; // Updated Orders Page
import 'package:eato/pages/customer/Activity_Page.dart'; // Updated Activity Page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e'); // Log Firebase errors
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.initialize();

  await FirebaseAppCheck.instance.activate(
    // For Android, use AndroidProvider.playIntegrity
    // For iOS, use AppleProvider.appAttest
    androidProvider: AndroidProvider.playIntegrity,
  );

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    print("AUTH STATE CHANGED: ${user?.uid ?? 'No user'}");
  });

  runApp(
    DevicePreview(
      enabled: false, // Set to `true` for Device Preview during development
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => StoreProvider()),
          ChangeNotifierProvider(create: (_) => FoodProvider()),
          ChangeNotifierProvider(
              create: (_) => OrderProvider()), // ✅ ADD THIS LINE
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {
        // Define named routes for role selection
        '/role_selection': (context) => const WelcomePage(),

        // Define named routes for customer pages
        '/home': (context) => const CustomerHomePage(),
        '/breakfast': (context) => const MealPage(mealType: 'Breakfast'),
        '/lunch': (context) => const MealPage(mealType: 'Lunch'),
        '/dinner': (context) => const MealPage(mealType: 'Dinner'),
        '/account': (context) => const AccountPage(),

        // ✅ UPDATED: Real order system routes
        '/subscribed': (context) => const Scaffold(
              body: Center(child: Text('Subscribed Page Coming Soon')),
            ),
        '/orders': (context) =>
            const OrdersPage(showBottomNav: true), // ✅ UPDATED
        '/activity': (context) =>
            const ActivityPage(showBottomNav: true), // ✅ UPDATED

        // ✅ ADD: Provider routes for order management
        '/provider/orders': (context) {
          // Get current user from provider
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          final currentUser = userProvider.currentUser;

          if (currentUser != null) {
            return OrderHomePage(currentUser: currentUser);
          } else {
            return const Scaffold(
              body: Center(child: Text('Please login to access this page')),
            );
          }
        },
        '/provider/requests': (context) {
          // Get current user from provider
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          final currentUser = userProvider.currentUser;

          if (currentUser != null) {
            return RequestHome(currentUser: currentUser);
          } else {
            return const Scaffold(
              body: Center(child: Text('Please login to access this page')),
            );
          }
        },
      },
    );
  }
}

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  // Check if user is already logged in
  Future<CustomUser?> _checkUserState(UserProvider userProvider) async {
    try {
      // Get the current Firebase user
      final firebaseUser = FirebaseAuth.instance.currentUser;

      // If there's a logged in user, fetch their data
      if (firebaseUser != null) {
        await userProvider.fetchUser(firebaseUser.uid);
        return userProvider.currentUser;
      }
      return null;
    } catch (e) {
      print('Error checking user state: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return FutureBuilder<CustomUser?>(
      future: _checkUserState(userProvider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.purple),
            ),
          );
        }

        // User not logged in or error occurred
        if (!snapshot.hasData || snapshot.data == null) {
          return const WelcomePage();
        }

        // User is logged in, route based on user type
        final user = snapshot.data!;
        if (user.userType == 'customer') {
          return const CustomerHomePage();
        } else if (user.userType == 'provider') {
          // Check if the provider already has a store setup
          final storeProvider =
              Provider.of<StoreProvider>(context, listen: false);
          storeProvider.fetchUserStore(user);

          return ProviderHomePage(currentUser: user);
        } else {
          // Unknown user type
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Unknown user type: ${user.userType}'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WelcomePage()));
                    },
                    child: Text('Go Back to Welcome'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

// ✅ OPTIONAL: Enhanced App with Error Boundary
class EnhancedMyApp extends StatelessWidget {
  const EnhancedMyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        // Add error boundary wrapper
        return ErrorBoundary(
          child: DevicePreview.appBuilder(context, child),
        );
      },
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Enhanced theme for better UI
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      routes: {
        // Define named routes for role selection
        '/role_selection': (context) => const WelcomePage(),

        // Define named routes for customer pages
        '/home': (context) => const CustomerHomePage(),
        '/breakfast': (context) => const MealPage(mealType: 'Breakfast'),
        '/lunch': (context) => const MealPage(mealType: 'Lunch'),
        '/dinner': (context) => const MealPage(mealType: 'Dinner'),
        '/account': (context) => const AccountPage(),

        // Updated order system routes with proper error handling
        '/subscribed': (context) => const Scaffold(
              body: Center(child: Text('Subscribed Page Coming Soon')),
            ),
        '/orders': (context) => _buildProtectedRoute(
              child: const OrdersPage(showBottomNav: true),
              context: context,
            ),
        '/activity': (context) => _buildProtectedRoute(
              child: const ActivityPage(showBottomNav: true),
              context: context,
            ),

        // Provider routes for order management
        '/provider/orders': (context) => _buildProviderRoute(
              builder: (user) => OrderHomePage(currentUser: user),
              context: context,
            ),
        '/provider/requests': (context) => _buildProviderRoute(
              builder: (user) => RequestHome(currentUser: user),
              context: context,
            ),
      },
    );
  }

  // Helper method to build protected routes (requires authentication)
  Widget _buildProtectedRoute(
      {required Widget child, required BuildContext context}) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.currentUser == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Please login to access this page'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, '/role_selection'),
                    child: Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        }
        return child;
      },
    );
  }

  // Helper method to build provider-specific routes
  Widget _buildProviderRoute({
    required Widget Function(CustomUser) builder,
    required BuildContext context,
  }) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final currentUser = userProvider.currentUser;

        if (currentUser == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Please login to access this page'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, '/role_selection'),
                    child: Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        if (currentUser.userType != 'provider') {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.no_accounts, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('This page is only for meal providers'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    child: Text('Go to Home'),
                  ),
                ],
              ),
            ),
          );
        }

        return builder(currentUser);
      },
    );
  }
}

// ✅ Error Boundary Widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({Key? key, required this.child}) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Something went wrong'),
              SizedBox(height: 8),
              Text(errorMessage,
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    hasError = false;
                    errorMessage = '';
                  });
                },
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Catch errors in the widget tree
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        hasError = true;
        errorMessage = details.exception.toString();
      });
    };
  }
}
