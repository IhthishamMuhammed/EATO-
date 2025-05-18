import 'dart:async';
import 'package:eato/pages/onboarding/RoleSelectionPage.dart';
import 'package:eato/pages/onboarding/onboarding2.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/pages/customer/customer_home.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  // For gradient animation
  late Animation<Color?> _gradientStartColorAnimation;
  late Animation<Color?> _gradientEndColorAnimation;

  // For background decoration
  late Animation<double> _decorationOpacityAnimation;
  late Animation<double> _decorationScaleAnimation;

  bool _isAuthChecking = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Set up animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Logo animations
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Gradient animations
    _gradientStartColorAnimation = ColorTween(
      begin: EatoTheme.primaryLightColor.withOpacity(0.5),
      end: EatoTheme.primaryLightColor,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _gradientEndColorAnimation = ColorTween(
      begin: EatoTheme.primaryDarkColor.withOpacity(0.7),
      end: EatoTheme.primaryDarkColor,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Background decoration animations
    _decorationOpacityAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _decorationScaleAnimation = Tween<double>(begin: 0.6, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Start the animation
    _animationController.forward();

    // Check authentication after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      _checkAuthentication();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    try {
      setState(() {
        _isAuthChecking = true;
      });

      // Get current user
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // No user is signed in, navigate to role selection page
        _navigateToNextScreen(destination: 'role_selection');
        return;
      }

      // User is signed in, get user data from Firestore
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await userProvider.fetchUser(currentUser.uid);

      if (userProvider.currentUser == null) {
        // Could not find user data, sign out and go to role selection
        await FirebaseAuth.instance.signOut();
        _navigateToNextScreen(destination: 'role_selection');
        return;
      }

      // Determine next screen based on user type
      final userType = userProvider.currentUser!.userType.toLowerCase();

      if (userType.contains('customer') || userType.contains('user')) {
        _navigateToNextScreen(destination: 'customer_home');
      } else if (userType.contains('provider') || userType.contains('meal')) {
        _navigateToNextScreen(destination: 'provider_home');
      } else {
        // Unknown user type, go to role selection
        _navigateToNextScreen(destination: 'role_selection');
      }
    } catch (e) {
      print('Authentication check error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Something went wrong. Please try again.';
        _isAuthChecking = false;
      });
    }
  }

  void _navigateToNextScreen({required String destination}) {
    // Complete the animation first
    if (_animationController.status != AnimationStatus.completed) {
      // Wait for animation to complete
      _animationController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _performNavigation(destination);
        }
      });
    } else {
      // Animation already completed, navigate immediately
      _performNavigation(destination);
    }
  }

  void _performNavigation(String destination) {
    if (!mounted) return;

    // Reduced delay for better UX
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Navigate to appropriate screen
      Widget nextScreen;

      switch (destination) {
        case 'customer_home':
          nextScreen = CustomerHomePage();
          break;
        case 'provider_home':
          nextScreen = ProviderHomePage(
            currentUser:
                Provider.of<UserProvider>(context, listen: false).currentUser!,
          );
          break;
        case 'role_selection':
        default:
          nextScreen = const RoleSelectionPage();
          break;
      }

      // Replace the splash screen with the next screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var fadeAnimation = animation.drive(tween);

            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: EatoTheme.backgroundColor,
      body: Stack(
        children: [
          // Background circular decorations with animation
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.3,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _decorationOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _decorationScaleAnimation.value,
                    child: Container(
                      width: size.width * 0.8,
                      height: size.width * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EatoTheme.primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            left: -size.width * 0.2,
            bottom: -size.width * 0.2,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _decorationOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _decorationScaleAnimation.value,
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EatoTheme.primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content (centered logo and app name)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo with animations
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeInAnimation,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  _gradientStartColorAnimation.value!,
                                  _gradientEndColorAnimation.value!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      EatoTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // App name with gradient
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeInAnimation,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            _gradientStartColorAnimation.value!,
                            _gradientEndColorAnimation.value!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          "EATO",
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Tagline with fade in animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve:
                              const Interval(0.4, 1.0, curve: Curves.easeOut),
                        ),
                      ),
                      child: Text(
                        "Delicious meals, delivered.",
                        style: TextStyle(
                          fontSize: 16,
                          color: EatoTheme.textSecondaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 50),

                // Loading indicator or retry button
                if (_isAuthChecking)
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                      ),
                    ),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            EatoTheme.primaryColor),
                        strokeWidth: 3,
                      ),
                    ),
                  )
                else if (_hasError)
                  Column(
                    children: [
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          color: EatoTheme.errorColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkAuthentication,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: EatoTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
