import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/pages/auth/login.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({Key? key}) : super(key: key);

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToLogin(String role) {
    setState(() => _selectedRole = role);
    HapticFeedback.mediumImpact();

    // Create a brief animation effect
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.push(
        context,
        EatoTheme.slideTransition(page: LoginPage(role: role)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: EatoTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: EatoTheme.textPrimaryColor, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background design elements
          Positioned(
            top: -screenSize.height * 0.1,
            right: -screenSize.width * 0.2,
            child: Container(
              height: screenSize.height * 0.4,
              width: screenSize.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    EatoTheme.primaryColor.withOpacity(0.1),
                    EatoTheme.primaryColor.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    EatoTheme.primaryColor.withOpacity(0.08),
                    EatoTheme.primaryColor.withOpacity(0.03),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenSize.height * 0.03),
                    // Logo or icon could go here
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: EatoTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: EatoTheme.primaryColor,
                        size: 40,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    ShaderMask(
                      shaderCallback: (bounds) => EatoTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        "Select your role",
                        style: EatoTheme.headingLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Choose how you want to use EATO",
                        style: EatoTheme.bodyMedium.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.06),

                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildRoleOption(
                            title: "Customer",
                            description: "Browse restaurants and order meals",
                            role: "customer",
                            icon: Icons.person,
                            iconBackground: Colors.blue.shade100,
                            iconColor: Colors.blue.shade700,
                          ),
                          const SizedBox(height: 24),
                          _buildRoleOption(
                            title: "Meal Provider",
                            description: "Manage your restaurant and receive orders",
                            role: "mealprovider",
                            icon: Icons.restaurant_menu,
                            iconBackground: Colors.orange.shade100,
                            iconColor: Colors.orange.shade700,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: EatoTheme.buildPageIndicators(4, 3),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String description,
    required String role,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
  }) {
    final isSelected = _selectedRole == role;
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => _navigateToLogin(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? EatoTheme.primaryColor : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? EatoTheme.primaryColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 5),
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EatoTheme.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: EatoTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: EatoTheme.bodySmall.copyWith(
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? EatoTheme.primaryColor : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.arrow_forward,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}