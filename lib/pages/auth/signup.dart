import 'package:eato/pages/theme/eato_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'phoneVerification.dart';
import 'dart:async';

class SignUpPage extends StatefulWidget {
  final String role;

  const SignUpPage({required this.role, Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  // Current form step
  int _currentStep = 0;
  final int _totalSteps = 2;

  // Form keys and controllers
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Focus nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  // State variables
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  Timer? _debounceTimer;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupFocusListeners();
  }

  void _setupAnimations() {
    // Create animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Fade in animation
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
    ));

    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
    ));

    // Start the animation
    _animationController.forward();
  }

  void _setupFocusListeners() {
    // Add focus listeners for visual feedback
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));

    // Add listener to password field for strength indicator updates
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    // Debounce to avoid too many rebuilds during typing
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Clean up focus nodes
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();

    // Clean up animations and timers
    _animationController.dispose();
    _debounceTimer?.cancel();

    super.dispose();
  }

  // Validation methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    } else if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    } else if (!RegExp(r'^\d{9,10}$').hasMatch(value.trim())) {
      return 'Enter a valid phone number (9-10 digits)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    } else if (value.length < 6) {
      return 'Password must be at least 6 characters';
    } else if (!RegExp(r'(?=.*?[A-Z])').hasMatch(value)) {
      return 'Include at least one uppercase letter';
    } else if (!RegExp(r'(?=.*?[0-9])').hasMatch(value)) {
      return 'Include at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    } else if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Navigation methods
  void _goToNextStep() {
    // Validate current step
    if (_currentStep == 0) {
      if (!(_formKeyStep1.currentState?.validate() ?? false)) {
        return;
      }
    } else if (_currentStep == 1) {
      if (!(_formKeyStep2.currentState?.validate() ?? false)) {
        return;
      }
    }

    // If we're on the last step, proceed to phone verification
    if (_currentStep == _totalSteps - 1) {
      _proceedToPhoneVerification();
      return;
    }

    // Otherwise, go to the next step
    setState(() {
      _currentStep++;
    });
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _proceedToPhoneVerification() {
    setState(() {
      _isLoading = true;
    });

    // Add a slight delay to show loading state
    Future.delayed(const Duration(milliseconds: 500), () {
      // Prefix with country code (e.g., +94 for Sri Lanka)
      final String countryCode = '+94';
      final String fullPhoneNumber =
          '$countryCode${_phoneNumberController.text.trim()}';

      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PhoneVerificationPage(
                phoneNumber: fullPhoneNumber,
                userType: widget.role,
                isSignUp: true,
                userData: userData,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = const Offset(1.0, 0.0);
            var end = Offset.zero;
            var curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: EatoTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _currentStep == 0
                  ? Icons.arrow_back_ios_rounded
                  : Icons.arrow_back_ios_rounded,
              size: 16,
              color: EatoTheme.primaryColor,
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (_currentStep == 0) {
              Navigator.pop(context);
            } else {
              _goToPreviousStep();
            }
          },
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeInAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                ),
              );
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.06,
                  vertical: screenSize.height * 0.01,
                ),
                child: Column(
                  children: [
                    // Header with role badge
                    _buildSignupHeader(screenSize, isSmallScreen),

                    SizedBox(height: screenSize.height * 0.02),

                    // Form steps progress indicator
                    _buildStepIndicator(screenSize),

                    SizedBox(height: screenSize.height * 0.025),

                    // Current form step
                    _buildCurrentStep(screenSize, isSmallScreen),

                    SizedBox(height: screenSize.height * 0.025),

                    // Terms and conditions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "By signing up, you agree to our Terms of Service and Privacy Policy",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupHeader(Size screenSize, bool isSmallScreen) {
    final bool isCustomer = widget.role.toLowerCase() == 'customer';
    final String roleText = isCustomer ? 'Customer' : 'Food Provider';
    final Color roleColor = isCustomer
        ? EatoTheme.primaryColor
        : EatoTheme.accentColor;

    return Container(
      height: screenSize.height * 0.15,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decoration
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: screenSize.width * 0.3,
              height: screenSize.width * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EatoTheme.primaryColor.withOpacity(0.05),
              ),
            ),
          ),

          Row(
            children: [
              // Role image
              Hero(
                tag: 'role_image',
                child: Container(
                  width: screenSize.width * 0.18,
                  height: screenSize.width * 0.18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        roleColor.withOpacity(0.2),
                        roleColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: roleColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isCustomer ? Icons.person : Icons.restaurant,
                      size: screenSize.width * 0.08,
                      color: roleColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title and role badge
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          EatoTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        "EATO",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: roleColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "$roleText Signup",
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(Size screenSize) {
    return Column(
      children: [
        Row(
          children: List.generate(_totalSteps, (index) {
            final bool isActive = index <= _currentStep;
            final bool isCurrent = index == _currentStep;

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? EatoTheme.primaryColor
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: isCurrent ? _buildProgressAnimation() : null,
              ),
            );
          }),
        ),
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Step ${_currentStep + 1} of $_totalSteps",
                style: TextStyle(
                  color: EatoTheme.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _currentStep == 0 ? "Personal Info" : "Security",
                style: TextStyle(
                  color: EatoTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressAnimation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                EatoTheme.primaryColor.withOpacity(0.3),
                EatoTheme.primaryColor,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStep(Size screenSize, bool isSmallScreen) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(_currentStep == 0 ? -1.0 : 1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: _currentStep == 0
          ? _buildPersonalInfoStep(screenSize, isSmallScreen)
          : _buildSecurityStep(screenSize, isSmallScreen),
    );
  }

  Widget _buildPersonalInfoStep(Size screenSize, bool isSmallScreen) {
    return Container(
      key: ValueKey<String>('personal_info'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKeyStep1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step title
              ShaderMask(
                shaderCallback: (bounds) => EatoTheme.primaryGradient.createShader(bounds),
                child: Text(
                  "Create Your Account",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 22 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "First, let's get to know you",
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: EatoTheme.textSecondaryColor,
                ),
              ),
              SizedBox(height: 24),

              // Name field
              _buildInputField(
                label: "Full Name",
                hint: "Enter your full name",
                controller: _nameController,
                focusNode: _nameFocus,
                validator: _validateName,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                prefixIcon: Icons.person_outline,
                onFieldSubmitted: () => FocusScope.of(context).requestFocus(_emailFocus),
              ),
              SizedBox(height: 20),

              // Email field
              _buildInputField(
                label: "Email Address",
                hint: "Enter your email address",
                controller: _emailController,
                focusNode: _emailFocus,
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                onFieldSubmitted: () => FocusScope.of(context).requestFocus(_phoneFocus),
              ),
              SizedBox(height: 20),

              // Phone field
              _buildPhoneField(isSmallScreen),

              SizedBox(height: 32),

              // Next button
              _buildActionButton(
                text: "Continue",
                onPressed: _goToNextStep,
                showArrow: true,
              ),

              SizedBox(height: 20),

              // Login link
              _buildLoginLink(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityStep(Size screenSize, bool isSmallScreen) {
    return Container(
      key: ValueKey<String>('security'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKeyStep2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step title
              ShaderMask(
                shaderCallback: (bounds) => EatoTheme.primaryGradient.createShader(bounds),
                child: Text(
                  "Secure Your Account",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 22 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Create a strong password to protect your account",
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: EatoTheme.textSecondaryColor,
                ),
              ),
              SizedBox(height: 24),

              // Password field
              _buildPasswordField(isSmallScreen),
              SizedBox(height: 20),

              // Confirm password field
              _buildConfirmPasswordField(isSmallScreen),

              SizedBox(height: 20),

              // Password strength indicator
              _buildPasswordStrengthIndicator(),

              SizedBox(height: 32),

              // Row with Back and Sign Up buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _goToPreviousStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EatoTheme.primaryColor,
                        side: BorderSide(color: EatoTheme.primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "Back",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildActionButton(
                      text: "Sign Up",
                      onPressed: _goToNextStep,
                      isLoading: _isLoading,
                      showArrow: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? Function(String?) validator,
    required TextInputAction textInputAction,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Function()? onFieldSubmitted,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final bool hasFocus = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: hasFocus ? EatoTheme.primaryColor : EatoTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: hasFocus ? EatoTheme.primaryColor : Colors.grey.shade500,
              size: 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: EatoTheme.primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: EatoTheme.errorColor,
                width: 1.5,
              ),
            ),
          ),
          validator: validator,
          onFieldSubmitted: (_) => onFieldSubmitted?.call(),
        ),
      ],
    );
  }

  Widget _buildPhoneField(bool isSmallScreen) {
    final bool hasFocus = _phoneFocus.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phone Number",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: hasFocus ? EatoTheme.primaryColor : EatoTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _phoneNumberController,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          style: TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: "Enter your phone number",
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
            ),
            prefixIcon: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  "+94",
                  style: TextStyle(
                    color: EatoTheme.textPrimaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 60, minHeight: 0),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: EatoTheme.primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: EatoTheme.errorColor,
                width: 1.5,
              ),
            ),
          ),
          validator: _validatePhone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        SizedBox(height: 6),
        Text(
          "Enter numbers only, without country code",
          style: TextStyle(
            color: EatoTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isSmallScreen) {
    return _buildInputField(
      label: "Password",
      hint: "Create a strong password",
      controller: _passwordController,
      focusNode: _passwordFocus,
      validator: _validatePassword,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.lock_outline,
      obscureText: !_isPasswordVisible,
      suffixIcon: IconButton(
        icon: Icon(
          _isPasswordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: _passwordFocus.hasFocus
              ? EatoTheme.primaryColor
              : Colors.grey.shade500,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      ),
      onFieldSubmitted: () => FocusScope.of(context).requestFocus(_confirmPasswordFocus),
    );
  }

  Widget _buildConfirmPasswordField(bool isSmallScreen) {
    return _buildInputField(
      label: "Confirm Password",
      hint: "Confirm your password",
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocus,
      validator: _validateConfirmPassword,
      textInputAction: TextInputAction.done,
      prefixIcon: Icons.lock_clock_outlined,
      obscureText: !_isConfirmPasswordVisible,
      suffixIcon: IconButton(
        icon: Icon(
          _isConfirmPasswordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: _confirmPasswordFocus.hasFocus
              ? EatoTheme.primaryColor
              : Colors.grey.shade500,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
          });
        },
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    // Only show if there's some password text
    if (_passwordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate password strength
    int strength = 0;
    String strengthText = "Weak";
    Color strengthColor = EatoTheme.errorColor;

    if (_passwordController.text.length >= 6) strength++;
    if (_passwordController.text.length >= 8) strength++;
    if (RegExp(r'(?=.*?[A-Z])').hasMatch(_passwordController.text)) strength++;
    if (RegExp(r'(?=.*?[0-9])').hasMatch(_passwordController.text)) strength++;
    if (RegExp(r'(?=.*?[!@#$%^&*(),.?":{}|<>])')
        .hasMatch(_passwordController.text)) strength++;

    switch (strength) {
      case 0:
      case 1:
        strengthText = "Weak";
        strengthColor = EatoTheme.errorColor;
        break;
      case 2:
      case 3:
        strengthText = "Medium";
        strengthColor = EatoTheme.warningColor;
        break;
      case 4:
      case 5:
        strengthText = "Strong";
        strengthColor = EatoTheme.successColor;
        break;
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: strengthColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: strengthColor.withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                strength > 3
                    ? Icons.verified
                    : strength > 1
                    ? Icons.shield
                    : Icons.shield_outlined,
                color: strengthColor,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                "Password Strength: ",
                style: TextStyle(
                  fontSize: 14,
                  color: EatoTheme.textPrimaryColor,
                ),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength / 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              minHeight: 8,
            ),
          ),

          SizedBox(height: 12),

          // Requirements
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildPasswordRequirement(
                "6+ characters",
                _passwordController.text.length >= 6,
              ),
              _buildPasswordRequirement(
                "Uppercase",
                RegExp(r'(?=.*?[A-Z])').hasMatch(_passwordController.text),
              ),
              _buildPasswordRequirement(
                "Number",
                RegExp(r'(?=.*?[0-9])').hasMatch(_passwordController.text),
              ),
              _buildPasswordRequirement(
                "Special character",
                RegExp(r'(?=.*?[!@#$%^&*(),.?":{}|<>])')
                    .hasMatch(_passwordController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: 18,
          width: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMet ? EatoTheme.successColor : Colors.transparent,
            border: Border.all(
              color: isMet ? EatoTheme.successColor : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: isMet
              ? Icon(
            Icons.check,
            size: 12,
            color: Colors.white,
          )
              : null,
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isMet ? EatoTheme.successColor : Colors.grey.shade600,
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool showArrow = false,
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isLoading ? [] : [
          BoxShadow(
            color: EatoTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withOpacity(0.6),
          disabledBackgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isLoading
                ? LinearGradient(
              colors: [
                Colors.grey.shade400,
                Colors.grey.shade500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : EatoTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                if (showArrow) ...[
                  SizedBox(width: 10),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            color: EatoTheme.textSecondaryColor,
          ),
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: EatoTheme.primaryColor,
            padding: const EdgeInsets.only(left: 5),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            "Log In",
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}