import 'package:provider/provider.dart';
import '../Provider/FoodProvider.dart';
import '../Provider/StoreProvider.dart';
import '../Provider/userProvider.dart';
import '../Provider/OrderProvider.dart';
import '../Provider/CartProvider.dart';

class ProvidersSetup {
  // ✅ FIX: Clean provider setup with proper disposal
  static List<ChangeNotifierProvider> get providers => [
        // ✅ User Provider - Core authentication and user data
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
          lazy: false, // ✅ Load immediately to handle auth state
        ),

        // ✅ Store Provider - Shop/restaurant data
        ChangeNotifierProvider<StoreProvider>(
          create: (_) => StoreProvider(),
        ),

        // ✅ Food Provider - Menu items and food data
        ChangeNotifierProvider<FoodProvider>(
          create: (_) => FoodProvider(),
        ),

        // ✅ Order Provider - Order management and tracking
        ChangeNotifierProvider<OrderProvider>(
          create: (_) => OrderProvider(),
        ),

        // ✅ Cart Provider - Shopping cart functionality
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
      ];

  // ✅ FIX: Method to properly dispose all providers (if needed)
  static void disposeAll(List<ChangeNotifierProvider> providers) {
    for (var provider in providers) {
      try {
        // Providers will be automatically disposed by the framework
        // This is just for any manual cleanup if needed
      } catch (e) {
        print('Warning: Error disposing provider: $e');
      }
    }
  }
}
