import 'package:eato/pages/theme/eato_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'RoleSelectionPage.dart';
import 'onboarding2.dart'; // For RoleSelectionPage

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({Key? key}) : super(key: key);

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _imageScaleAnimation;

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

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _imageScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
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
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ScaleTransition(
                      scale: _imageScaleAnimation,
                      child: Container(
                        height: screenSize.height * 0.35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/get_started.jpeg',
                            fit: BoxFit.cover,
                          ),
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
                            shaderCallback: (bounds) => EatoTheme.primaryGradient.createShader(bounds),
                            child: Text(
                              "Get started on\nOrdering your Food",
                              style: EatoTheme.headingMedium.copyWith(
                                fontSize: isSmallScreen ? 20 : 24,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            "Create an account or sign in to browse delicious meals from your favorite restaurants!",
                            style: EatoTheme.bodyMedium.copyWith(
                              fontSize: isSmallScreen ? 13 : 14,
                              height: 1.5,
                            ),
                          ),

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
                                    EatoTheme.fadeTransition(page: const RoleSelectionPage()),
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
                                    EatoTheme.slideTransition(page: const RoleSelectionPage()),
                                  );
                                },
                                child: const Text("Continue"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          Center(child: EatoTheme.buildPageIndicators(4, 2)),
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
}