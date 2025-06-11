import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/userProvider.dart';

// Import home pages directly
import 'package:eato/pages/customer/homepage/customer_home.dart';
import 'package:eato/pages/provider/ProviderHomePage.dart';
import '../theme/eato_theme.dart';

class PhoneVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String userType;
  final bool isSignUp;
  final Map<String, String>? userData;

  const PhoneVerificationPage({
    Key? key,
    required this.phoneNumber,
    required this.userType,
    required this.isSignUp,
    this.userData,
  }) : super(key: key);

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage>
    with SingleTickerProviderStateMixin {
  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Verification state
  String _verificationId = '';
  bool _isCodeSent = false;
  bool _isVerifying = false;
  bool _isAutoVerifying = false;
  String _errorMessage = '';
  int? _forceResendingToken;

  // Resend timer
  int _remainingSeconds = 120;
  bool _canResend = false;

  // Verification status
  bool _isVerificationSuccessful = false;
  String _currentCode = '';
  List<bool?> _digitValidation = List.generate(6, (_) => null);
  bool _isAutoRetrievalInProgress = false;

  // Debug mode
  bool _debug = true; // Enable debug for troubleshooting

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Form controllers
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController _pasteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupFormControllers();

    // Start verification process in the background
    Future.microtask(() {
      _verifyPhoneNumber();
      _startResendTimer();
    });
  }

  void _setupAnimations() {
    // Main animation controller
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

  void _setupFormControllers() {
    // Add listeners to code input fields
    for (int i = 0; i < 6; i++) {
      _codeControllers[i].addListener(() {
        _updateCurrentCode();
      });
    }

    // Add listener to paste controller
    _pasteController.addListener(() {
      final text = _pasteController.text;
      if (text.length == 6 && RegExp(r'^\d{6}$').hasMatch(text)) {
        // Valid 6-digit code, fill the input fields
        for (int i = 0; i < 6; i++) {
          _codeControllers[i].text = text[i];
        }

        // Clear the paste field
        _pasteController.clear();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();

    // Dispose all controllers
    for (var controller in _codeControllers) {
      controller.dispose();
    }

    for (var focus in _focusNodes) {
      focus.dispose();
    }

    _pasteController.dispose();
    super.dispose();
  }

  // VERIFICATION PROCESS LOGIC

  Future<void> _verifyPhoneNumber() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = '';
      _isAutoRetrievalInProgress = true;
    });

    try {
      // Ensure proper phone number format
      String phoneNumber = widget.phoneNumber.trim();

      // Remove any spaces and ensure it starts with +
      phoneNumber = phoneNumber.replaceAll(' ', '');
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }

      _debugLog("Attempting to verify phone number: $phoneNumber");

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 120),
        forceResendingToken: _forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _debugLog("Auto verification completed with credential");

          setState(() {
            _isAutoRetrievalInProgress = false;
            _isVerificationSuccessful = true;

            // Fill in the code fields if SMS code is available
            if (credential.smsCode != null) {
              String smsCode = credential.smsCode!;
              _debugLog("Auto-retrieved SMS code: $smsCode");

              for (int i = 0; i < smsCode.length && i < 6; i++) {
                _codeControllers[i].text = smsCode[i];
                _digitValidation[i] = true;
              }
              _currentCode = smsCode;
            }
          });

          // Proceed with sign-in
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _debugLog("Verification failed: ${e.code} - ${e.message}");
          setState(() {
            _isAutoRetrievalInProgress = false;
            _isVerifying = false;
          });
          _handleVerificationError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _debugLog("Verification code sent successfully");
          setState(() {
            _verificationId = verificationId;
            _forceResendingToken = resendToken;
            _isCodeSent = true;
            _isVerifying = false;
            _isAutoRetrievalInProgress = false;
          });

          _showSuccessMessage("Verification code sent to your phone");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _debugLog("Auto retrieval timeout, manual input required");
          setState(() {
            _verificationId = verificationId;
            _isAutoRetrievalInProgress = false;
          });
        },
      );
    } catch (e) {
      _debugLog("Error in phone verification: $e");
      setState(() {
        _isVerifying = false;
        _isAutoRetrievalInProgress = false;
      });
      _showErrorMessage("Phone verification error: ${e.toString()}");
    }
  }

  void _updateCurrentCode() {
    // Get the current code from all controllers
    String newCode = _codeControllers.map((c) => c.text).join();

    setState(() {
      _currentCode = newCode;
    });

    // Only attempt verification if we have all 6 digits and code was sent
    if (newCode.length == 6 &&
        !_isAutoVerifying &&
        _isCodeSent &&
        _verificationId.isNotEmpty) {
      _debugLog("6-digit code entered, attempting verification: $newCode");

      setState(() {
        _isAutoVerifying = true;
      });

      // Attempt real-time verification with a small delay to avoid rapid calls
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _currentCode == newCode) {
          _attemptRealTimeVerification(newCode);
        }
      });
    } else if (newCode.length < 6) {
      // Reset validation when code is incomplete
      setState(() {
        _isVerificationSuccessful = false;
        _isAutoVerifying = false;

        // Reset validation for cleared fields
        for (int i = 0; i < 6; i++) {
          if (_codeControllers[i].text.isEmpty) {
            _digitValidation[i] = null;
          }
        }
      });
    }
  }

  Future<void> _attemptRealTimeVerification(String code) async {
    try {
      _debugLog("Attempting real-time verification with code: $code");

      if (_verificationId.isEmpty) {
        _debugLog("No verification ID available");
        setState(() {
          _isAutoVerifying = false;
        });
        return;
      }

      // Create credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );

      // Try to sign in with the credential
      await _signInWithCredential(credential);

      // If successful, update UI
      setState(() {
        _isVerificationSuccessful = true;
        _isAutoVerifying = false;

        // Mark all digits as valid
        for (int i = 0; i < 6; i++) {
          _digitValidation[i] = true;
        }
      });

      _showSuccessMessage("Phone number verified successfully!");
    } catch (e) {
      _debugLog("Real-time verification failed: $e");

      setState(() {
        _isAutoVerifying = false;
        _isVerificationSuccessful = false;

        // Mark digits as invalid for wrong code
        if (e.toString().contains("invalid-verification-code") ||
            e.toString().contains("invalid code")) {
          for (int i = 0; i < 6; i++) {
            _digitValidation[i] = false;
          }
          _showErrorMessage(
              "Invalid verification code. Please check and try again.");
        } else {
          // For other errors, reset validation state
          for (int i = 0; i < 6; i++) {
            _digitValidation[i] = null;
          }
          _showErrorMessage("Verification failed: ${e.toString()}");
        }
      });
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      setState(() {
        _isVerifying = true;
      });

      _debugLog("Starting authentication with phone credential");
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (widget.isSignUp) {
        // Signup flow - create new user account
        await _handleSignup(credential, userProvider);
      } else {
        // Login flow - update existing user's phone number
        await _handleLogin(credential, userProvider);
      }
    } catch (e) {
      _debugLog("Authentication failed: $e");
      setState(() {
        _isVerifying = false;
        _isAutoVerifying = false;
      });

      // Show appropriate error message
      String errorMessage = "Authentication failed";
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = "Invalid verification code";
            break;
          case 'credential-already-in-use':
            errorMessage = "This phone number is already registered";
            break;
          case 'email-already-in-use':
            errorMessage = "Email address is already registered";
            break;
          default:
            errorMessage = e.message ?? "Authentication failed";
        }
      } else {
        errorMessage = e.toString();
      }

      _showErrorMessage(errorMessage);
    }
  }

  Future<void> _handleSignup(
      PhoneAuthCredential credential, UserProvider userProvider) async {
    try {
      _debugLog("Creating new user account");

      // First create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: widget.userData!['email']!,
        password: widget.userData!['password']!,
      );

      User user = userCredential.user!;
      _debugLog("User created with ID: ${user.uid}");

      // Link phone credential to the user
      try {
        await user.linkWithCredential(credential);
        _debugLog("Phone credential linked successfully");
      } catch (linkError) {
        _debugLog("Error linking phone credential: $linkError");
        // Continue anyway, we'll save the phone number in Firestore
      }

      // Create user document in Firestore
      _debugLog("Creating user document in Firestore");
      final userMap = {
        'name': widget.userData!['name']!,
        'email': widget.userData!['email']!,
        'phoneNumber': widget.phoneNumber,
        'userType': widget.userType,
        'profileImageUrl': '',
        'phoneVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userMap);

      // Create CustomUser and set in provider
      final customUser = CustomUser(
        id: user.uid,
        name: widget.userData!['name']!,
        email: widget.userData!['email']!,
        phoneNumber: widget.phoneNumber,
        userType: widget.userType,
        profileImageUrl: '',
      );

      userProvider.setCurrentUser(customUser);
      _debugLog("User created and set in provider successfully");

      if (!mounted) return;
      _navigateToHome(customUser);
    } catch (e) {
      _debugLog("Error in signup process: $e");
      throw e;
    }
  }

  Future<void> _handleLogin(
      PhoneAuthCredential credential, UserProvider userProvider) async {
    try {
      _debugLog("Login flow - updating phone number");
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception("No user is currently logged in");
      }

      _debugLog("Current user ID: ${user.uid}");

      // Try to link/update phone credential
      try {
        await user.linkWithCredential(credential);
        _debugLog("Phone credential linked successfully");
      } catch (linkError) {
        _debugLog("Error linking credential: $linkError");
        // Continue anyway, we'll update Firestore
      }

      // Update phone number in Firestore
      _debugLog("Updating phone number in Firestore");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'phoneNumber': widget.phoneNumber,
        'phoneVerified': true,
      });

      // Fetch updated user data
      await userProvider.fetchUser(user.uid);
      _debugLog("User data updated in provider");

      if (!mounted) return;
      _navigateToHome(userProvider.currentUser);
    } catch (e) {
      _debugLog("Error in login process: $e");
      throw e;
    }
  }

  void _navigateToHome(CustomUser? user) {
    if (user == null) {
      _showErrorMessage("User data not available");
      return;
    }

    _debugLog("Navigating to home screen for user type: ${widget.userType}");

    if (widget.userType.toLowerCase() == 'customer') {
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

  // HELPER METHODS

  void _startResendTimer() {
    setState(() {
      _remainingSeconds = 120;
      _canResend = false;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds > 0) {
        _startResendTimer();
      } else {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  void _requestNewCode() {
    if (!_canResend) return;

    _debugLog("Requesting new verification code");

    // Reset all fields and validation
    for (var c in _codeControllers) {
      c.clear();
    }

    setState(() {
      _digitValidation = List.generate(6, (_) => null);
      _isVerificationSuccessful = false;
      _isAutoVerifying = false;
      _currentCode = '';
      _isCodeSent = false;
      _verificationId = '';
    });

    // Focus first input field
    FocusScope.of(context).requestFocus(_focusNodes[0]);

    // Request new verification
    _verifyPhoneNumber();
    _startResendTimer();
  }

  void _verifyManually() {
    final code = _codeControllers.map((c) => c.text).join();

    if (code.length != 6) {
      _showErrorMessage("Please enter the complete 6-digit code");
      return;
    }

    if (_verificationId.isEmpty) {
      _showErrorMessage(
          "Verification session expired. Please request a new code.");
      return;
    }

    _debugLog("Manually verifying 6-digit code: $code");
    _attemptRealTimeVerification(code);
  }

  void _skipPhoneVerification() async {
    if (!widget.isSignUp) {
      _showErrorMessage("Phone verification is required for login");
      return;
    }

    try {
      setState(() {
        _isVerifying = true;
      });

      _debugLog("Skipping phone verification for signup");
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Create user account without phone verification
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: widget.userData!['email']!,
        password: widget.userData!['password']!,
      );

      // Create user document in Firestore with unverified phone
      final userMap = {
        'name': widget.userData!['name']!,
        'email': widget.userData!['email']!,
        'phoneNumber': widget.phoneNumber,
        'phoneVerified': false,
        'userType': widget.userType,
        'profileImageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userMap);

      // Create and set user in provider
      final customUser = CustomUser(
        id: userCredential.user!.uid,
        name: widget.userData!['name']!,
        email: widget.userData!['email']!,
        phoneNumber: widget.phoneNumber,
        userType: widget.userType,
        profileImageUrl: '',
      );

      userProvider.setCurrentUser(customUser);

      if (!mounted) return;
      _navigateToHome(customUser);
    } catch (e) {
      _debugLog("Error skipping phone verification: $e");
      setState(() {
        _isVerifying = false;
      });
      _showErrorMessage("Error creating account: ${e.toString()}");
    }
  }

  void _handleVerificationError(FirebaseAuthException e) {
    String errorMsg = "Verification failed";

    switch (e.code) {
      case 'invalid-phone-number':
        errorMsg = "The phone number format is invalid";
        break;
      case 'too-many-requests':
        errorMsg = "Too many requests. Please try again later";
        break;
      case 'operation-not-allowed':
        errorMsg = "Phone authentication is not enabled";
        break;
      case 'quota-exceeded':
        errorMsg = "SMS quota exceeded. Please try again later";
        break;
      case 'missing-phone-number':
        errorMsg = "Phone number is required";
        break;
      default:
        errorMsg = e.message ?? "Verification failed";
    }

    _debugLog("Verification error: $errorMsg (code: ${e.code})");
    _showErrorMessage(errorMsg);
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: EatoTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: EatoTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _debugLog(String message) {
    if (_debug) {
      print("PHONE VERIFICATION: $message");
    }
  }

  // UI BUILDING METHODS - keeping the existing UI code but with some fixes

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: EatoTheme.backgroundColor,
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
                child: Column(
                  children: [
                    // Verification header
                    _buildVerificationHeader(screenSize, isSmallScreen),

                    SizedBox(height: screenSize.height * 0.03),

                    // Main verification form
                    _buildVerificationForm(screenSize, isSmallScreen),

                    SizedBox(height: screenSize.height * 0.03),

                    // Alternative options
                    _buildAlternativeOptions(isSmallScreen),

                    // Debug information if enabled
                    if (_debug && _errorMessage.isNotEmpty) _buildDebugInfo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // [Rest of the UI building methods remain the same as in your original code]
  // I'm keeping the existing UI methods to maintain the design consistency

  Widget _buildVerificationHeader(Size screenSize, bool isSmallScreen) {
    return Column(
      children: [
        Container(
          width: screenSize.width * 0.5,
          height: screenSize.width * 0.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isVerificationSuccessful
                ? Colors.green.withOpacity(0.1)
                : _isAutoRetrievalInProgress
                    ? Colors.blue.withOpacity(0.1)
                    : EatoTheme.primaryColor.withOpacity(0.1),
          ),
          child: Center(
            child: _isVerificationSuccessful
                ? Icon(
                    Icons.check_circle_rounded,
                    size: screenSize.width * 0.25,
                    color: Colors.green.withOpacity(0.7),
                  )
                : _isAutoRetrievalInProgress
                    ? SizedBox(
                        width: screenSize.width * 0.12,
                        height: screenSize.width * 0.12,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.withOpacity(0.7),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.smartphone_rounded,
                        size: screenSize.width * 0.25,
                        color: EatoTheme.primaryColor.withOpacity(0.7),
                      ),
          ),
        ),
        SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) =>
              EatoTheme.primaryGradient.createShader(bounds),
          child: Text(
            _isVerificationSuccessful
                ? "Verification Successful"
                : "Verify Your Phone",
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          _isCodeSent
              ? "Enter the 6-digit code sent to your phone"
              : "We're sending a verification code to your phone",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: EatoTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationForm(Size screenSize, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(24),
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
        children: [
          _buildPhoneDisplay(isSmallScreen),
          SizedBox(height: 24),
          _buildStatusIndicator(isSmallScreen),
          SizedBox(height: 24),
          _buildCodeInput(isSmallScreen),
          SizedBox(height: 16),
          _buildResendOption(isSmallScreen),
          SizedBox(height: 24),
          _buildVerifyButton(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildPhoneDisplay(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: EatoTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EatoTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.phone_android_rounded,
                size: 20,
                color: EatoTheme.primaryColor,
              ),
              SizedBox(width: 12),
              Text(
                widget.phoneNumber.startsWith('+')
                    ? widget.phoneNumber
                    : '+${widget.phoneNumber}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 16,
                  fontWeight: FontWeight.w500,
                  color: EatoTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Row(
                children: [
                  Text(
                    "Change",
                    style: TextStyle(
                      fontSize: 13,
                      color: EatoTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: EatoTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool isSmallScreen) {
    if (_isAutoRetrievalInProgress) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.2),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Auto-Verifying",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                      fontSize: isSmallScreen ? 14 : 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Waiting for SMS to arrive automatically...",
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_isVerificationSuccessful) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.2),
              ),
              child: Icon(
                Icons.check,
                color: Colors.green,
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Verification Successful",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                      fontSize: isSmallScreen ? 14 : 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Your phone number has been verified!",
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_isCodeSent) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: EatoTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EatoTheme.primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.sms_rounded,
                color: EatoTheme.primaryColor,
                size: 14,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Code Sent",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: EatoTheme.primaryColor,
                      fontSize: isSmallScreen ? 14 : 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Enter the 6-digit code from your SMS",
                    style: TextStyle(
                      color: EatoTheme.textSecondaryColor,
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.2),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Sending verification code...",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCodeInput(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Verification Code",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 15 : 16,
            color: EatoTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (index) => AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: isSmallScreen ? 38 : 44,
                height: isSmallScreen ? 50 : 56,
                decoration: BoxDecoration(
                  color: _getDigitFieldColor(index),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getDigitBorderColor(index),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _digitValidation[index] == true
                          ? Colors.green.withOpacity(0.1)
                          : _digitValidation[index] == false
                              ? Colors.red.withOpacity(0.1)
                              : Colors.transparent,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: TextField(
                    controller: _codeControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    showCursor: false,
                    readOnly: _isVerificationSuccessful || _isAutoVerifying,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getDigitColor(index),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        if (index < 5) {
                          FocusScope.of(context)
                              .requestFocus(_focusNodes[index + 1]);
                        } else {
                          FocusScope.of(context).unfocus();
                        }
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context)
                            .requestFocus(_focusNodes[index - 1]);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getDigitColor(int index) {
    if (_codeControllers[index].text.isEmpty) {
      return EatoTheme.textPrimaryColor;
    } else if (_digitValidation[index] == null) {
      return EatoTheme.primaryColor;
    } else if (_digitValidation[index]!) {
      return Colors.green.shade700;
    } else {
      return Colors.red.shade700;
    }
  }

  Color _getDigitFieldColor(int index) {
    if (_codeControllers[index].text.isEmpty) {
      return Colors.white;
    } else if (_digitValidation[index] == null) {
      return EatoTheme.primaryColor.withOpacity(0.05);
    } else if (_digitValidation[index]!) {
      return Colors.green.withOpacity(0.05);
    } else {
      return Colors.red.withOpacity(0.05);
    }
  }

  Color _getDigitBorderColor(int index) {
    if (_focusNodes[index].hasFocus) {
      return EatoTheme.primaryColor;
    } else if (_codeControllers[index].text.isEmpty) {
      return Colors.grey.shade300;
    } else if (_digitValidation[index] == null) {
      return EatoTheme.primaryColor.withOpacity(0.5);
    } else if (_digitValidation[index]!) {
      return Colors.green.withOpacity(0.5);
    } else {
      return Colors.red.withOpacity(0.5);
    }
  }

  Widget _buildResendOption(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ",
          style: TextStyle(
            color: EatoTheme.textSecondaryColor,
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
        TextButton(
          onPressed: _canResend ? _requestNewCode : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _canResend ? "Resend Code" : "Resend in $_remainingSeconds s",
            style: TextStyle(
              color: _canResend ? EatoTheme.primaryColor : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton(bool isSmallScreen) {
    bool isDisabled = _isVerifying ||
        _isAutoVerifying ||
        !_isCodeSent ||
        _currentCode.length != 6 ||
        _verificationId.isEmpty;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isDisabled
            ? null
            : _isVerificationSuccessful
                ? () => _navigateToHome(
                    Provider.of<UserProvider>(context, listen: false)
                        .currentUser)
                : _verifyManually,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white60,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _isVerificationSuccessful
                ? LinearGradient(
                    colors: [Colors.green.shade500, Colors.green.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : isDisabled
                    ? LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : EatoTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: _isVerificationSuccessful
                          ? Colors.green.withOpacity(0.3)
                          : EatoTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Container(
            height: 55,
            alignment: Alignment.center,
            child: _isVerifying
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
                        _isVerificationSuccessful ? "Continue" : "Verify Code",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        _isVerificationSuccessful
                            ? Icons.check_circle
                            : Icons.lock_open,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativeOptions(bool isSmallScreen) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "OR",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        SizedBox(height: 20),
        if (widget.isSignUp) // Only show skip option for signup
          OutlinedButton.icon(
            onPressed: _isVerifying ? null : _skipPhoneVerification,
            icon: Icon(Icons.skip_next_rounded),
            label: Text("Continue without verification"),
            style: OutlinedButton.styleFrom(
              foregroundColor: EatoTheme.primaryColor,
              side: BorderSide(color: EatoTheme.primaryColor.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.amber.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.amber.shade800,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Why verify your phone?",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                        fontSize: isSmallScreen ? 14 : 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Verified phone numbers help protect your account and enable important notifications.",
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: isSmallScreen ? 12 : 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.grey.shade700, size: 16),
              SizedBox(width: 8),
              Text(
                "Debug Information",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Phone: ${widget.phoneNumber}\n"
            "Code Sent: $_isCodeSent\n"
            "Verification ID: ${_verificationId.isEmpty ? 'Empty' : 'Available'}\n"
            "Current Code: $_currentCode\n"
            "Auto Verifying: $_isAutoVerifying\n"
            "Error: $_errorMessage",
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
