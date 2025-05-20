import 'package:eato/pages/onboarding/onboarding1.dart'; // Import for WelcomePage
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'GetStartedPage.dart';
import 'RoleSelectionPage.dart';

class FreeMembershipPage extends StatefulWidget {
  const FreeMembershipPage({Key? key}) : super(key: key);

  @override
  State<FreeMembershipPage> createState() => _FreeMembershipPageState();
}

class _FreeMembershipPageState extends State<FreeMembershipPage>
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
      duration: const Duration(milliseconds: 600),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
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

    return Scaffold(
      backgroundColor: EatoTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EatoTheme.textPrimaryColor),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              EatoTheme.fadeTransition(page: const WelcomePage()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        height: screenSize.height * 0.25,
                        margin: EdgeInsets.only(top: screenSize.height * 0.02),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/flogo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.03),
                  Expanded(
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
                              "Free Membership!",
                              style: EatoTheme.headingMedium.copyWith(
                                fontSize: isSmallScreen ? 20 : 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Any student from Faculty of Engineering, University of Ruhuna, can open an account!",
                            style: EatoTheme.bodyMedium.copyWith(
                              fontSize: isSmallScreen ? 13 : 14,
                              height: 1.5,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: EatoTheme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: EatoTheme.primaryColor
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.school_rounded,
                                        color: EatoTheme.primaryColor,
                                        size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      "Verify your student email to unlock discounts!",
                                      style: EatoTheme.bodySmall.copyWith(
                                        fontSize: isSmallScreen ? 13 : 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildBenefitItem(Icons.local_offer_rounded,
                              "Exclusive discounts", isSmallScreen),
                          _buildBenefitItem(Icons.delivery_dining_rounded,
                              "Free delivery on 3 orders", isSmallScreen),
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
                                        page: const GetStartedPage()),
                                  );
                                },
                                child: const Text("Next"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(child: EatoTheme.buildPageIndicators(4, 1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: EatoTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: EatoTheme.successColor, size: 18),
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
