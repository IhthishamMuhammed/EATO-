import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eato/Provider/userProvider.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/core/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isAuthChecking = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasNavigated = false; // ✅ FIX: Prevent multiple navigation

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthentication();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  // ✅ FIX: Simplified authentication check with proper error handling
  Future<void> _checkAuthentication() async {
    if (_hasNavigated) return; // ✅ Prevent multiple checks

    try {
      setState(() {
        _isAuthChecking = true;
        _hasError = false;
      });

      // ✅ FIX: Wait for animations to complete before checking auth
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted || _hasNavigated) return;

      final User? authUser = FirebaseAuth.instance.currentUser;
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (authUser != null) {
        print('🔐 Found authenticated user: ${authUser.uid}');

        // ✅ FIX: Only fetch user data if not already loaded
        if (userProvider.currentUser == null ||
            userProvider.currentUser!.id != authUser.uid) {
          print('📥 Loading user data...');
          await userProvider.fetchUser(authUser.uid);
        }

        if (!mounted || _hasNavigated) return;

        // ✅ FIX: Navigate based on user data
        if (userProvider.currentUser != null) {
          _navigateToHome();
        } else {
          _navigateToLogin();
        }
      } else {
        print('🚪 No authenticated user found');
        _navigateToLogin();
      }
    } catch (e) {
      print('❌ Authentication check failed: $e');
      if (mounted && !_hasNavigated) {
        setState(() {
          _isAuthChecking = false;
          _hasError = true;
          _errorMessage = 'Failed to check authentication. Please try again.';
        });
      }
    }
  }

  // ✅ FIX: Safe navigation methods with guards
  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    print('🏠 Navigating to home...');
    Navigator.of(context).pushReplacementNamed(AppRouter.home);
  }

  void _navigateToLogin() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    print('🔑 Navigating to role selection...');
    Navigator.of(context).pushReplacementNamed(AppRouter.roleSelection);
  }

  // ✅ FIX: Retry method for error state
  void _retryAuthentication() {
    if (_hasNavigated) return;

    setState(() {
      _hasNavigated = false;
      _hasError = false;
      _errorMessage = '';
    });
    _checkAuthentication();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  EatoTheme.primaryColor.withOpacity(0.05),
                  EatoTheme.primaryColor.withOpacity(0.1),
                ],
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo with animations
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: EatoTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: EatoTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.restaurant,
                        size: 60,
                        color: EatoTheme.primaryColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // App name
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Text(
                    'EATO',
                    style: EatoTheme.headingLarge.copyWith(
                      color: EatoTheme.primaryColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Tagline
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Text(
                    'Delicious food delivered',
                    style: EatoTheme.bodyMedium.copyWith(
                      color: EatoTheme.textSecondaryColor,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Loading indicator or error state
                if (_isAuthChecking && !_hasError)
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                EatoTheme.primaryColor),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: EatoTheme.bodySmall.copyWith(
                            color: EatoTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_hasError)
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: EatoTheme.errorColor,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _errorMessage,
                            style: EatoTheme.bodySmall.copyWith(
                              color: EatoTheme.errorColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _retryAuthentication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EatoTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
