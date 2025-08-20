// File: lib/pages/provider/ProviderMainNavigation.dart
// Complete navigation solution with fixed bottom bar for provider pages

import 'package:flutter/material.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/pages/provider/OrderHomePage.dart';
import 'package:eato/pages/provider/RequestHome.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import 'package:eato/pages/provider/ProfilePage.dart';
import 'package:eato/pages/theme/eato_theme.dart';

class ProviderMainNavigation extends StatefulWidget {
  final CustomUser currentUser;
  final int initialIndex;

  const ProviderMainNavigation({
    Key? key,
    required this.currentUser,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _ProviderMainNavigationState createState() => _ProviderMainNavigationState();
}

class _ProviderMainNavigationState extends State<ProviderMainNavigation> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Smooth page transition
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: NeverScrollableScrollPhysics(), // Disable swipe navigation
        children: [
          // Orders Page (Index 0)
          _buildOrdersPage(),

          // Requests Page (Index 1)
          _buildRequestsPage(),

          // Menu/Provider Home Page (Index 2)
          _buildMenuPage(),

          // Profile Page (Index 3)
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildOrdersPage() {
    return OrderHomePage(currentUser: widget.currentUser);
  }

  Widget _buildRequestsPage() {
    return RequestHome(currentUser: widget.currentUser);
  }

  Widget _buildMenuPage() {
    return ProviderHomePage(currentUser: widget.currentUser);
  }

  Widget _buildProfilePage() {
    return ProfilePage(currentUser: widget.currentUser);
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: EatoTheme.primaryColor,
        unselectedItemColor: EatoTheme.textLightColor,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 24,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            activeIcon: Icon(Icons.receipt),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
