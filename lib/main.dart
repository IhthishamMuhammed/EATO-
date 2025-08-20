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
import 'EatoComponents.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize();
  runApp(const EatoApp());
}

class EatoApp extends StatelessWidget {
  const EatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: ProvidersSetup.providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Eato - Food Delivery',
        theme: ThemeAdapter.materialTheme,
        home: const AuthWrapper(), // ✅ New wrapper widget
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}

// ✅ NEW: Separate widget to handle auth logic
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (!mounted) return;

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);

        if (user != null) {
          if (userProvider.currentUser == null ||
              userProvider.currentUser!.id != user.uid) {
            await userProvider.fetchUser(user.uid);
          }
          await NotificationService.saveUserToken(user.uid);

          if (userProvider.currentUser?.userType == 'customer') {
            orderProvider.listenToCustomerOrders(user.uid);
          }
        } else {
          userProvider.clearCurrentUser();
          orderProvider.stopListening();
          await NotificationService.removeUserToken();
        }
      } catch (e) {
        print("Error in auth state change handler: $e");
      }
    });

    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? const SplashScreen()
        : EatoComponents.loadingScreen();
  }
}
