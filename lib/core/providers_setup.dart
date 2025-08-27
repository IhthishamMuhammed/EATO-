import 'package:provider/provider.dart';
import '../Provider/FoodProvider.dart';
import '../Provider/StoreProvider.dart';
import '../Provider/userProvider.dart';
import '../Provider/OrderProvider.dart';
import '../Provider/CartProvider.dart';
import 'package:eato/Provider/RatingProvider.dart';

class ProvidersSetup {
  static List<ChangeNotifierProvider> get providers => [
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider<StoreProvider>(
          create: (_) => StoreProvider(),
        ),
        ChangeNotifierProvider<FoodProvider>(
          create: (_) => FoodProvider(),
        ),
        ChangeNotifierProvider<OrderProvider>(
          create: (_) => OrderProvider(),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider<RatingProvider>(
          create: (_) => RatingProvider(),
        ),
      ];
}
