import 'package:flutter/material.dart';
import 'package:eato/widgets/bottom_nav_bar.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart,
                size: 80,
                color: Colors.purple.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              const Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Your orders will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index != 2) {
            Navigator.pushReplacementNamed(
              context,
              _getRouteNameForIndex(index),
            );
          }
        },
      ),
    );
  }

  String _getRouteNameForIndex(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/subscribed';
      case 2:
        return '/orders';
      case 3:
        return '/activity';
      case 4:
        return '/account';
      default:
        return '/home';
    }
  }
}
