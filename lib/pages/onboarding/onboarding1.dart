import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eato/pages/onboarding/onboarding2.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/pages/onboarding/GetStartedPage.dart'; // Import for GetStartedPage

import 'RoleSelectionPage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: EatoTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.06,
                vertical: screenSize.height * 0.02,
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 4,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 20,
                            child: Container(
                              width: screenSize.width * 0.7,
                              height: screenSize.width * 0.7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: EatoTheme.primaryColor.withOpacity(0.05),
                              ),
                            ),
                          ),
                          Hero(
                            tag: 'eato_logo',
                            child: Container(
                              height: screenSize.height * 0.3,
                              width: screenSize.width * 0.7,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: EatoTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                EatoTheme.primaryGradient.createShader(bounds),
                            child: Text(
                              "Welcome to EATO",
                              style: EatoTheme.headingMedium.copyWith(
                                fontSize: isSmallScreen ? 22 : 26,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Delicious food delivered to your doorstep",
                            style: EatoTheme.bodyMedium.copyWith(
                              fontSize: isSmallScreen ? 13 : 15,
                              fontWeight: FontWeight.w600,
                              color: EatoTheme.primaryColor.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Browse through restaurants and dishes. Add your favorite meals to your cart and checkout easily!",
                            style: EatoTheme.bodyMedium.copyWith(
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildFeatureItem(Icons.restaurant,
                              "Variety of restaurants", isSmallScreen),
                          _buildFeatureItem(Icons.delivery_dining,
                              "Fast and reliable delivery", isSmallScreen),
                          _buildFeatureItem(Icons.local_offer,
                              "Exclusive offers", isSmallScreen),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton(
                                style: EatoTheme.outlinedButtonStyle,
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    EatoTheme.fadeTransition(
                                        page: const RoleSelectionPage()),
                                  );
                                },
                                child: const Text("Skip"),
                              ),
                              ElevatedButton(
                                style: EatoTheme.primaryButtonStyle,
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.push(
                                    context,
                                    EatoTheme.slideTransition(
                                        page: const FreeMembershipPage()),
                                  );
                                },
                                child: const Text("Next"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: screenSize.height * 0.03),
                    child: EatoTheme.buildPageIndicators(4, 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: EatoTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: EatoTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: EatoTheme.bodyMedium.copyWith(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
