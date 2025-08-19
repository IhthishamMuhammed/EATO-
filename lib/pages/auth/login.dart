import 'package:eato/Provider/userProvider.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADD: Import Firestore
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import 'package:eato/Model/coustomUser.dart';
import 'signup.dart';
import 'phoneVerification.dart';
import 'package:eato/pages/customer/homepage/customer_home.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';

class LoginPage extends StatefulWidget {
  final String role;

  const LoginPage({required this.role, Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // Form controllers and focus nodes
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // Authentication state
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _emailHasError = false;
  bool _passwordHasError = false;
  String? _emailErrorText;
  String? _passwordErrorText;

  // Biometric authentication
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _hasBiometrics = false;

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
    _checkBiometrics();
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
    _emailFocus.addListener(_onEmailFocusChange);
    _passwordFocus.addListener(_onPasswordFocusChange);
  }

  Future<void> _checkBiometrics() async {
    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      _hasBiometrics = availableBiometrics.isNotEmpty;
      setState(() {});
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailFocusChange() {
    // Clear error when field gets focus
    if (_emailFocus.hasFocus && _emailHasError) {
      setState(() {
        _emailHasError = false;
        _emailErrorText = null;
      });
    }
  }

  void _onPasswordFocusChange() {
    // Clear error when field gets focus
    if (_passwordFocus.hasFocus && _passwordHasError) {
      setState(() {
        _passwordHasError = false;
        _passwordErrorText = null;
      });
    }
  }

  // Form validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    } else if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // ✅ ENHANCED: Authentication methods with email verification
  Future<void> _loginWithCredentials(BuildContext context) async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Login using Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // ✅ CHECK EMAIL VERIFICATION
        await user.reload(); // Refresh user data
        user = FirebaseAuth.instance.currentUser; // Get updated user

        if (!user!.emailVerified) {
          // Show email verification dialog
          setState(() {
            _isLoading = false;
          });
          await _showEmailNotVerifiedDialog(user);
          return;
        }

        // Email is verified, proceed with normal flow
        await userProvider.fetchUser(user.uid);

        // Verify role matches
        if (!_verifyRoleMatches(
            userProvider.currentUser?.userType, widget.role)) {
          throw Exception(
              "This account doesn't match your selected role. Please use a ${widget.role} account.");
        }

        // Navigate to appropriate screen
        _handleSuccessfulLogin(userProvider.currentUser, context);
      }
    } catch (e) {
      _handleLoginError(e, context);
    }
  }

  // ✅ NEW: Show email not verified dialog
  Future<void> _showEmailNotVerifiedDialog(User user) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.email_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Email Not Verified'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your email address has not been verified. Please check your inbox for a verification email.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EatoTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.email ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: EatoTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _resendVerificationEmail(user);
            },
            child: Text('Resend Email'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _checkEmailAndProceed(user);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.primaryColor),
            child:
                Text('I\'ve Verified', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Resend verification email
  Future<void> _resendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Verification email sent!'),
            ],
          ),
          backgroundColor: EatoTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending email: $e'),
          backgroundColor: EatoTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ NEW: Check email verification and proceed
  Future<void> _checkEmailAndProceed(User user) async {
    try {
      await user.reload();
      user = FirebaseAuth.instance.currentUser!;

      if (user.emailVerified) {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'emailVerified': true,
        });

        Navigator.of(context).pop(); // Close dialog

        // Continue with login
        setState(() {
          _isLoading = true;
        });

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.fetchUser(user.uid);

        if (_verifyRoleMatches(
            userProvider.currentUser?.userType, widget.role)) {
          _handleSuccessfulLogin(userProvider.currentUser, context);
        } else {
          throw Exception("This account doesn't match your selected role.");
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email not yet verified. Please check your inbox.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: EatoTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to log in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // Handle last logged in user authentication or show email field
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication successful'),
            backgroundColor: EatoTheme.successColor,
          ),
        );

        // In a real app, you might retrieve saved credentials here
        // For demo purposes, we'll just prompt the user to enter credentials
        setState(() {
          _emailController.text = 'demo@example.com'; // Example only
        });
      }
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
    }
  }

  bool _verifyRoleMatches(String? userRole, String expectedRole) {
    if (userRole == null) return false;

    final dbRole = userRole.toLowerCase().trim();
    final expectedRoleLower = expectedRole.toLowerCase().trim();

    print(
        '🔍 Role Debug: DB="$dbRole", Expected="$expectedRoleLower"'); // Debug

    // Direct match
    if (dbRole == expectedRoleLower) {
      return true;
    }

    // Enhanced meal provider variations
    if (expectedRoleLower == 'mealprovider' ||
        expectedRoleLower == 'meal provider') {
      return dbRole == 'mealprovider' ||
          dbRole == 'meal provider' ||
          dbRole == 'provider' ||
          dbRole == 'meal_provider';
    }

    // Enhanced customer variations
    if (expectedRoleLower == 'customer') {
      return dbRole == 'customer' || dbRole == 'user' || dbRole == 'client';
    }

    return false;
  }

  void _handleSuccessfulLogin(CustomUser? user, BuildContext context) {
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
      // Navigate to phone verification if needed
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneVerificationPage(
            phoneNumber: '',
            userType: widget.role,
            isSignUp: false,
            userData: null,
          ),
        ),
      );
    } else {
      // Navigate to appropriate home page
      if (!mounted) return;

      if (widget.role.toLowerCase() == 'customer') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => CustomerHomePage()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderHomePage(currentUser: user),
          ),
          (route) => false,
        );
      }
    }
  }

  void _handleLoginError(dynamic error, BuildContext context) {
    String errorMessage = "Login failed. Please try again.";

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          setState(() {
            _emailHasError = true;
            _emailErrorText = 'No account found with this email';
          });
          errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
          setState(() {
            _passwordHasError = true;
            _passwordErrorText = 'Incorrect password';
          });
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          setState(() {
            _emailHasError = true;
            _emailErrorText = 'Invalid email format';
          });
          errorMessage = 'Invalid email format';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later';
          break;
        case 'invalid-credential':
          setState(() {
            _emailHasError = true;
            _passwordHasError = true;
            _emailErrorText = 'Invalid credentials';
            _passwordErrorText = 'Invalid credentials';
          });
          errorMessage = 'Invalid email or password';
          break;
        default:
          errorMessage = error.message ?? errorMessage;
      }
    } else {
      errorMessage = error.toString().contains('account doesn\'t match')
          ? error.toString().replaceAll('Exception: ', '')
          : errorMessage;
    }

    // Show error message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: EatoTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToSignup(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignUpPage(role: widget.role)),
    );
  }

  void _handleForgotPassword() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your email address first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show a password reset confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Password'),
        content: Text(
            'We will send a password reset link to ${_emailController.text}. Would you like to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendPasswordResetEmail();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EatoTheme.primaryColor,
            ),
            child: Text('Send Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent!'),
            backgroundColor: EatoTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: ${e.toString()}'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: EatoTheme.primaryColor,
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
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
                  vertical: screenSize.height * 0.02,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Login header with role-specific image
                      _buildLoginHeader(screenSize, isSmallScreen),

                      // Title and welcome message
                      _buildWelcomeSection(isSmallScreen),

                      SizedBox(height: screenSize.height * 0.03),

                      // Login form
                      _buildLoginForm(screenSize, isSmallScreen),

                      SizedBox(height: screenSize.height * 0.04),

                      // Login button
                      _buildLoginButton(isSmallScreen),

                      SizedBox(height: screenSize.height * 0.02),

                      // Biometric login
                      if (_hasBiometrics) _buildBiometricLogin(),

                      SizedBox(height: screenSize.height * 0.03),

                      // Sign up option
                      _buildSignupOption(isSmallScreen),

                      SizedBox(height: screenSize.height * 0.04),

                      // Footer text
                      _buildFooterText(isSmallScreen),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginHeader(Size screenSize, bool isSmallScreen) {
    final bool isCustomer = widget.role.toLowerCase() == 'customer';
    final String roleName = isCustomer ? 'Customer' : 'Food Provider';
    final Color roleColor =
        isCustomer ? EatoTheme.primaryColor : EatoTheme.accentColor;

    return Center(
      child: Column(
        children: [
          // Role indicator badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: roleColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCustomer ? Icons.person : Icons.restaurant,
                  color: roleColor,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  '$roleName Login',
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: screenSize.height * 0.03),

          // Logo or illustration
          Hero(
            tag: 'role_image',
            child: Container(
              width: screenSize.width * 0.35,
              height: screenSize.width * 0.35,
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
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: roleColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  isCustomer ? Icons.food_bank_outlined : Icons.store_outlined,
                  size: screenSize.width * 0.15,
                  color: roleColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        ShaderMask(
          shaderCallback: (bounds) =>
              EatoTheme.primaryGradient.createShader(bounds),
          child: Text(
            "Welcome Back!",
            style: TextStyle(
              fontSize: isSmallScreen ? 26 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Please log in to continue your ${widget.role} experience",
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: EatoTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(Size screenSize, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email field
          _buildEmailField(isSmallScreen),
          SizedBox(height: 20),

          // Password field
          _buildPasswordField(isSmallScreen),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handleForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: EatoTheme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email Address",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 14 : 15,
            color: EatoTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            fontSize: isSmallScreen ? 15 : 16,
          ),
          decoration: InputDecoration(
            hintText: "Enter your email",
            errorText: _emailHasError ? _emailErrorText : null,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: _emailFocus.hasFocus
                  ? EatoTheme.primaryColor
                  : Colors.grey.shade600,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
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
            contentPadding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          validator: _validateEmail,
          onChanged: (value) {
            if (_emailHasError) {
              setState(() {
                _emailHasError = false;
                _emailErrorText = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Password",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 14 : 15,
            color: EatoTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          style: TextStyle(
            fontSize: isSmallScreen ? 15 : 16,
          ),
          decoration: InputDecoration(
            hintText: "Enter your password",
            errorText: _passwordHasError ? _passwordErrorText : null,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: _passwordFocus.hasFocus
                  ? EatoTheme.primaryColor
                  : Colors.grey.shade600,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _passwordFocus.hasFocus
                    ? EatoTheme.primaryColor
                    : Colors.grey.shade600,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
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
            contentPadding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          validator: _validatePassword,
          onChanged: (value) {
            if (_passwordHasError) {
              setState(() {
                _passwordHasError = false;
                _passwordErrorText = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: EatoTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _loginWithCredentials(context),
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
            gradient: _isLoading
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
            child: _isLoading
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
                        "Sign In",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
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
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricLogin() {
    return Center(
      child: Column(
        children: [
          TextButton.icon(
            onPressed: _isLoading ? null : _authenticateWithBiometrics,
            icon: Icon(
              Icons.fingerprint,
              color: EatoTheme.primaryColor,
              size: 22,
            ),
            label: Text(
              "Use Fingerprint",
              style: TextStyle(
                color: EatoTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: EatoTheme.primaryColor,
              backgroundColor: EatoTheme.primaryColor.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupOption(bool isSmallScreen) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 1,
              color: Colors.grey.shade300,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "New to Eato?",
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: EatoTheme.textSecondaryColor,
                ),
              ),
            ),
            Container(
              width: 60,
              height: 1,
              color: Colors.grey.shade300,
            ),
          ],
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => _navigateToSignup(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: EatoTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              "Create an Account",
              style: TextStyle(
                color: EatoTheme.primaryColor,
                fontSize: isSmallScreen ? 15 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterText(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          "By continuing, you agree to our Terms of Service and Privacy Policy",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: EatoTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}
