import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/app_initializer.dart';
import 'core/providers_setup.dart';
import 'core/app_router.dart';
import 'core/theme_adapter.dart';
import 'SplashScreen.dart';
import 'services/notification_service.dart';
import 'Provider/userProvider.dart';
import 'Provider/OrderProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // ✅ FIX: Single Firebase initialization only
  await AppInitializer.initialize();

  runApp(const EatoApp());
}

class EatoApp extends StatefulWidget {
  const EatoApp({super.key});

  @override
  State<EatoApp> createState() => _EatoAppState();
}

class _EatoAppState extends State<EatoApp> {
  bool _isInitialized = false;
  bool _isSetupInProgress = false; // ✅ FIX: Prevent multiple setup calls

  @override
  void initState() {
    super.initState();
    // ✅ FIX: Setup auth listener only once in initState
    _setupAuthListener();
  }

  // ✅ FIX: Single auth listener setup - no more duplicates
  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      print("🔄 Auth state changed: ${user?.uid ?? 'No user'}");

      if (!mounted) return;

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);

        if (user != null) {
          // User logged in
          if (userProvider.currentUser == null ||
              userProvider.currentUser!.id != user.uid) {
            await userProvider.fetchUser(user.uid);
          }

          await NotificationService.saveUserToken(user.uid);
          print("✅ FCM token saved for user: ${user.uid}");

          if (userProvider.currentUser?.userType == 'customer') {
            orderProvider.listenToCustomerOrders(user.uid);
            print("✅ Started listening to customer orders");
          }
        } else {
          // User logged out
          userProvider.clearCurrentUser();
          orderProvider.stopListening();
          await NotificationService.removeUserToken();
          print("✅ User data cleared and FCM token removed");
        }
      } catch (e) {
        print("⚠️ Error in auth state change handler: $e");
      }
    });

    // ✅ FIX: Mark as initialized immediately after setting up listener
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: ProvidersSetup.providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Eato - Food Delivery',
        theme: ThemeAdapter.materialTheme,
        home: _isInitialized ? const SplashScreen() : const AppLoadingScreen(),
        onGenerateRoute: AppRouter.generateRoute,
        navigatorObservers: [
          NavigationObserver(),
        ],
      ),
    );
  }
}

// ✅ Custom Navigation Observer for debugging
class NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('🧭 Pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('🧭 Popped: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print(
        '🧭 Replaced: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}');
  }
}

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.restaurant,
                size: 40,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading Eato...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
