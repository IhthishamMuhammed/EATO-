import 'package:eato/Provider/FoodProvider.dart';
import 'package:eato/Provider/StoreProvider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e'); // Log Firebase errors
  }
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

        // Add placeholder routes for bottom navigation
        '/subscribed': (context) => const Scaffold(
              body: Center(child: Text('Subscribed Page Coming Soon')),
            ),
        '/orders': (context) => const Scaffold(
              body: Center(child: Text('Orders Page Coming Soon')),
            ),
        '/activity': (context) => const Scaffold(
              body: Center(child: Text('Activity Page Coming Soon')),
            ),
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
