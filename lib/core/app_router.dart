import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/pages/customer/homepage/customer_home.dart';
import 'package:eato/pages/provider/ProviderMainNavigation.dart';
import 'package:eato/pages/customer/Orders_Page.dart';
import 'package:eato/pages/customer/activity_page.dart';
import 'package:eato/pages/customer/account_page.dart';
import 'package:eato/pages/customer/shops_page.dart';
import 'package:eato/pages/auth/login.dart';
import 'package:eato/pages/auth/signup.dart';
import 'package:eato/pages/onboarding/RoleSelectionPage.dart';
import 'package:eato/SplashScreen.dart';

class AppRouter {
  // Route names
  static const String splash = '/';
  static const String roleSelection = '/role_selection';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String shops = '/shops';
  static const String orders = '/orders';
  static const String activity = '/activity';
  static const String account = '/account';

  // Route generator with user type detection
  static Route<dynamic> generateRoute(RouteSettings settings) {
    print("Navigating to: ${settings.name}");

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case roleSelection:
        return MaterialPageRoute(
          builder: (_) => const RoleSelectionPage(),
          settings: settings,
        );

      case login:
        final String role =
            (settings.arguments as Map<String, dynamic>?)?['role'] ??
                'customer';
        return MaterialPageRoute(
          builder: (_) => LoginPage(role: role),
          settings: settings,
        );

      case signup:
        final String role =
            (settings.arguments as Map<String, dynamic>?)?['role'] ??
                'customer';
        return MaterialPageRoute(
          builder: (_) => SignUpPage(role: role),
          settings: settings,
        );

      case home:
        // Dynamic home page based on user type
        return MaterialPageRoute(
          builder: (context) => _buildHomePage(context),
          settings: settings,
        );

      case shops:
        return MaterialPageRoute(
          builder: (_) => const ShopsPage(),
          settings: settings,
        );

      case orders:
        return MaterialPageRoute(
          builder: (_) => const OrdersPage(),
          settings: settings,
        );

      case activity:
        return MaterialPageRoute(
          builder: (_) => const ActivityPage(),
          settings: settings,
        );

      case account:
        return MaterialPageRoute(
          builder: (_) => const AccountPage(),
          settings: settings,
        );

      default:
        print("Unknown route: ${settings.name}, redirecting to home");
        return MaterialPageRoute(
          builder: (context) => _buildHomePage(context),
          settings: RouteSettings(name: home),
        );
    }
  }

  // Dynamic home page builder based on user type
  static Widget _buildHomePage(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;

        if (user == null) {
          print("No user found, redirecting to role selection");
          // Navigate to role selection if no user
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, roleSelection);
          });
          return const Center(child: CircularProgressIndicator());
        }

        final userType = user.userType.toLowerCase().trim();
        print("User type detected: '$userType'");

        // FIXED: Proper user type routing to ProviderMainNavigation
        if (userType == 'mealprovider' ||
            userType == 'provider' ||
            userType == 'meal provider' ||
            userType == 'meal_provider') {
          print("Navigating to ProviderMainNavigation");
          return ProviderMainNavigation(
            currentUser: user,
            initialIndex: 0, // Start with Orders tab
          );
        } else {
          print("Navigating to CustomerHomePage");
          return const CustomerHomePage();
        }
      },
    );
  }

  // Helper method to navigate safely with arguments
  static Future<void> navigateTo(BuildContext context, String routeName,
      {Object? arguments}) async {
    try {
      if (Navigator.canPop(context)) {
        await Navigator.pushReplacementNamed(context, routeName,
            arguments: arguments);
      } else {
        await Navigator.pushNamedAndRemoveUntil(
          context,
          routeName,
          (route) => false,
          arguments: arguments,
        );
      }
    } catch (e) {
      print("Navigation error: $e");
      // Fallback navigation
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => _buildHomePage(context)),
        (route) => false,
      );
    }
  }

  // Helper methods for common navigations with role
  static Future<void> navigateToLogin(BuildContext context, String role) async {
    await navigateTo(context, login, arguments: {'role': role});
  }

  static Future<void> navigateToSignup(
      BuildContext context, String role) async {
    await navigateTo(context, signup, arguments: {'role': role});
  }
}
