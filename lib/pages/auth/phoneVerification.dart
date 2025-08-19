import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/Model/coustomUser.dart';
import 'package:eato/Provider/userProvider.dart';

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
  bool _debug = true; // Set to true for debugging

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
      _checkFirebaseConfig(); // Debug Firebase configuration
      _verifyPhoneNumber();
      _startResendTimer();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  void _setupFormControllers() {
    for (int i = 0; i < 6; i++) {
      _codeControllers[i].addListener(() {
        _updateCurrentCode();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _pasteController.dispose();
    super.dispose();
  }

  void _debugLog(String message) {
    if (_debug) {
      print('🔍 PhoneVerification: $message');
    }
  }

  // ✅ ENHANCED: Better phone verification with improved error handling
  Future<void> _verifyPhoneNumber() async {
    try {
      setState(() {
        _isVerifying = true;
        _errorMessage = '';
      });

      // ✅ IMPROVED: Better phone number formatting
      String phoneNumber = widget.phoneNumber.trim();

      // Remove any spaces, dashes, or parentheses
      phoneNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

      // Add country code if not present (assuming Sri Lanka +94)
      if (!phoneNumber.startsWith('+')) {
        if (phoneNumber.startsWith('0')) {
          phoneNumber =
              '+94${phoneNumber.substring(1)}'; // Remove leading 0 and add +94
        } else if (phoneNumber.startsWith('94')) {
          phoneNumber = '+$phoneNumber';
        } else {
          phoneNumber = '+94$phoneNumber';
        }
      }

      _debugLog("Formatted phone number: $phoneNumber");

      // ✅ ENHANCED: More detailed timeout and error handling
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 120),
        forceResendingToken: _forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _debugLog("✅ Auto verification completed");
          setState(() {
            _isAutoRetrievalInProgress = false;
            _isVerificationSuccessful = true;

            // Mark all fields as valid
            for (int i = 0; i < 6; i++) {
              _digitValidation[i] = true;
            }

            // Fill in the code fields with auto-retrieved code
            if (credential.smsCode != null) {
              String smsCode = credential.smsCode!;
              _debugLog("Auto-retrieved SMS code: $smsCode");

              for (int i = 0; i < smsCode.length && i < 6; i++) {
                _codeControllers[i].text = smsCode[i];
              }

              _currentCode = smsCode;
            }
          });

          // Sign in with auto-retrieved credential
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _debugLog("❌ Verification failed: ${e.code} - ${e.message}");
          setState(() {
            _isAutoRetrievalInProgress = false;
            _isVerifying = false;
          });

          // ✅ ENHANCED: More specific error messages
          _handleVerificationError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _debugLog("📱 SMS sent to $phoneNumber");
          setState(() {
            _verificationId = verificationId;
            _forceResendingToken = resendToken;
            _isCodeSent = true;
            _isVerifying = false;
            _isAutoRetrievalInProgress = false;
          });

          _showSuccessMessage("Verification code sent successfully!");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _debugLog("⏰ Auto retrieval timeout");
          setState(() {
            _verificationId = verificationId;
            _isAutoRetrievalInProgress = false;
          });
        },
      );
    } catch (e) {
      _debugLog("💥 Phone verification error: $e");
      setState(() {
        _isVerifying = false;
        _isAutoRetrievalInProgress = false;
      });

      // ✅ ENHANCED: Better error categorization
      if (e.toString().contains('operation-not-allowed')) {
        _showErrorMessage(
            "Phone authentication is not enabled. Please contact support.");
      } else if (e.toString().contains('quota-exceeded')) {
        _showErrorMessage("SMS quota exceeded. Please try again later.");
      } else if (e.toString().contains('invalid-phone-number')) {
        _showErrorMessage(
            "Invalid phone number format. Please check and try again.");
      } else {
        _showErrorMessage("Phone verification error: $e");
      }
    }
  }

  // ✅ ADD: Debug method to check Firebase configuration
  Future<void> _checkFirebaseConfig() async {
    try {
      _debugLog("🔍 Checking Firebase configuration...");

      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        _debugLog("❌ Firebase not initialized");
        return;
      }

      _debugLog("✅ Firebase initialized");
      _debugLog("📱 Project ID: ${Firebase.app().options.projectId}");
      _debugLog(
          "🔑 API Key: ${Firebase.app().options.apiKey?.substring(0, 10)}...");

      // Check auth configuration
      final authSettings = FirebaseAuth.instance.app.options;
      _debugLog("🔐 Auth domain: ${authSettings.authDomain}");
    } catch (e) {
      _debugLog("💥 Firebase config check failed: $e");
    }
  }

  void _updateCurrentCode() {
    // Get the current code from all controllers
    String newCode = _codeControllers.map((c) => c.text).join();

    setState(() {
      _currentCode = newCode;
    });

    // Only attempt verification if we have all 6 digits
    if (newCode.length == 6 && !_isAutoVerifying && _isCodeSent) {
      setState(() {
        _isAutoVerifying = true;
      });

      // Show verification attempt message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text("Verifying code..."),
            ],
          ),
          backgroundColor: EatoTheme.infoColor,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Attempt real-time verification
      _attemptRealTimeVerification(newCode);
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

  void _attemptRealTimeVerification(String code) async {
    try {
      _debugLog("Attempting real-time verification with code: $code");

      if (_verificationId.isEmpty) {
        _debugLog("No verification ID available yet");
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

      // If we reach here, the verification was successful
      setState(() {
        _isVerificationSuccessful = true;
        _isAutoVerifying = false;

        // Mark all digits as valid
        for (int i = 0; i < 6; i++) {
          _digitValidation[i] = true;
        }
      });

      _showSuccessMessage("Code verified successfully!");
    } catch (e) {
      _debugLog("Real-time verification failed: $e");

      // Check if this is a verification-specific error
      String errorMessage = e.toString();
      bool isCodeError = errorMessage.contains("invalid-verification-code") ||
          errorMessage.contains("invalid code") ||
          errorMessage.contains("verification code");

      setState(() {
        _isAutoVerifying = false;

        // If it's specifically about the code being wrong
        if (isCodeError) {
          // Mark all digits as invalid on verification failure
          for (int i = 0; i < 6; i++) {
            _digitValidation[i] = false;
          }
        } else {
          // For other errors, just show the message but don't mark fields
          _digitValidation = List.generate(6, (_) => null);
        }
      });

      if (isCodeError) {
        _showErrorMessage("Invalid verification code. Please try again.");
      }
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      setState(() {
        _isVerifying = true;
      });

      _debugLog("Starting authentication with credential");
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (widget.isSignUp) {
        // Signup flow - create new user
        await _handleSignup(credential, userProvider);
      } else {
        // Login flow - update phone number
        await _handleLogin(credential, userProvider);
      }
    } catch (e) {
      _debugLog("Authentication failed: $e");
      setState(() {
        _isVerifying = false;
        _isAutoVerifying = false;

        // Mark all fields as invalid on failure
        for (int i = 0; i < 6; i++) {
          _digitValidation[i] = false;
        }
      });

      // Check if the error is related to the verification code
      if (e.toString().contains("invalid-verification-code") ||
          e.toString().contains("invalid code") ||
          e.toString().contains("verification code")) {
        _showErrorMessage("Invalid verification code. Please try again.");
      } else {
        _showErrorMessage("Authentication failed: $e");
      }
    }
  }

  Future<void> _handleSignup(
      PhoneAuthCredential credential, UserProvider userProvider) async {
    _debugLog("Creating new user account");

    // Note: User was already created in signup.dart with email/password
    // We just need to update the phone number
    User? user = _auth.currentUser;

    if (user != null) {
      _debugLog("User already exists with ID: ${user.uid}");

      try {
        _debugLog("Updating phone number");
        await user.updatePhoneNumber(credential);
      } catch (e) {
        _debugLog("Error updating phone directly: $e");
        // If unable to update phone directly, try linking method
        try {
          _debugLog("Attempting to link credential instead");
          await user.linkWithCredential(credential);
        } catch (linkError) {
          _debugLog("Error linking credential: $linkError");
          // Continue anyway, as we'll update in Firestore
        }
      }

      // Update user document in Firestore
      _debugLog("Updating user document in Firestore");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'phoneNumber': widget.phoneNumber,
        'phoneVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get updated user data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Create and store user in provider
        final customUser = CustomUser(
          id: user.uid,
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          phoneNumber: widget.phoneNumber,
          userType: userData['userType'] ?? widget.userType,
          profileImageUrl: userData['profileImageUrl'] ?? '',
        );

        userProvider.setCurrentUser(customUser);
      }

      if (!mounted) return;

      _navigateToHome(userProvider.currentUser);
    }
  }

  Future<void> _handleLogin(
      PhoneAuthCredential credential, UserProvider userProvider) async {
    _debugLog("Login flow - updating phone number");
    final user = _auth.currentUser;
    if (user != null) {
      // Update the phone number in Firestore, and mark as verified
      _debugLog("Updating phone number in Firestore (verified)");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'phoneNumber': widget.phoneNumber,
        'phoneVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get user data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Update user in provider
        CustomUser updatedUser = CustomUser(
          id: user.uid,
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          phoneNumber: widget.phoneNumber,
          userType: userData['userType'] ?? widget.userType,
          profileImageUrl: userData['profileImageUrl'] ?? '',
        );

        userProvider.setCurrentUser(updatedUser);
      }

      if (!mounted) return;

      _navigateToHome(userProvider.currentUser);
    }
  }

  void _navigateToHome(CustomUser? user) {
    if (user == null) return;

    if (widget.userType.toLowerCase() == 'customer') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CustomerHomePage()),
        (route) => false, // Clear all previous routes
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => ProviderHomePage(
            currentUser: user,
          ),
        ),
        (route) => false, // Clear all previous routes
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
    if (!_canResend) {
      return;
    }

    // Reset all fields and validation
    for (var c in _codeControllers) {
      c.clear();
    }
    setState(() {
      _digitValidation = List.generate(6, (_) => null);
      _isVerificationSuccessful = false;
      _isAutoVerifying = false;
      _currentCode = '';
    });

    FocusScope.of(context).requestFocus(_focusNodes[0]);

    _debugLog("Requesting new verification code");
    _verifyPhoneNumber();
    _startResendTimer();
  }

  void _verifyManually() {
    final code = _codeControllers.map((c) => c.text).join();

    if (code.length != 6) {
      _showErrorMessage("Please enter the full 6-digit code");
      return;
    }

    _debugLog("Manually verifying 6-digit code: $code");

    // Create credential and verify
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: code,
    );

    _signInWithCredential(credential);
  }

  void _skipPhoneVerification() async {
    try {
      setState(() {
        _isVerifying = true;
      });

      _debugLog("Skipping phone verification");
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (widget.isSignUp) {
        // For sign up process - create new user without phone verification
        _debugLog("Creating new user account without phone verification");

        // User was already created in signup.dart, just update Firestore
        User? user = _auth.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'phoneNumber': widget.phoneNumber,
            'phoneVerified': false, // Flag to indicate phone is not verified
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Get user data and set in provider
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;

            final customUser = CustomUser(
              id: user.uid,
              name: userData['name'] ?? '',
              email: userData['email'] ?? '',
              phoneNumber: widget.phoneNumber,
              userType: userData['userType'] ?? widget.userType,
              profileImageUrl: userData['profileImageUrl'] ?? '',
            );

            userProvider.setCurrentUser(customUser);
          }

          if (!mounted) return;

          _navigateToHome(userProvider.currentUser);
        }
      } else {
        // For login process - simply proceed
        _debugLog("Login flow - proceeding without phone verification");
        final user = _auth.currentUser;
        if (user != null) {
          // Update the phone number in Firestore, but mark as unverified
          _debugLog("Updating phone number in Firestore (unverified)");
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'phoneNumber': widget.phoneNumber,
            'phoneVerified': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Get user data
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;

            // Update user in provider
            CustomUser updatedUser = CustomUser(
              id: user.uid,
              name: userData['name'] ?? '',
              email: userData['email'] ?? '',
              phoneNumber: widget.phoneNumber,
              userType: userData['userType'] ?? widget.userType,
              profileImageUrl: userData['profileImageUrl'] ?? '',
            );

            userProvider.setCurrentUser(updatedUser);
          }

          if (!mounted) return;

          _navigateToHome(userProvider.currentUser);
        }
      }
    } catch (e) {
      _debugLog("Error skipping phone verification: $e");
      setState(() {
        _isVerifying = false;
      });
      _showErrorMessage("Error: $e");
    }
  }

  // ✅ ENHANCED: Better error handling with specific solutions
  void _handleVerificationError(FirebaseAuthException e) {
    String errorMsg = "Verification failed";
    String solution = "";

    switch (e.code) {
      case 'invalid-phone-number':
        errorMsg = "Invalid phone number format";
        solution = "Please enter a valid Sri Lankan phone number (07XXXXXXXX)";
        break;

      case 'too-many-requests':
        errorMsg = "Too many verification attempts";
        solution = "Please wait 24 hours before trying again";
        break;

      case 'operation-not-allowed':
        errorMsg = "Phone verification not enabled";
        solution =
            "Contact support - Phone auth may not be configured properly";
        break;

      case 'quota-exceeded':
        errorMsg = "SMS quota exceeded";
        solution = "Daily SMS limit reached. Try again tomorrow";
        break;

      case 'missing-phone-number':
        errorMsg = "Phone number is required";
        solution = "Please provide a valid phone number";
        break;

      case 'app-not-authorized':
        errorMsg = "App not authorized for phone auth";
        solution = "Contact support - Firebase configuration issue";
        break;

      default:
        errorMsg = e.message ?? "Unknown verification error";
        solution =
            "Please try again or contact support if the problem persists";
    }

    _debugLog("Verification failed: $errorMsg (${e.code})");

    // Show detailed error dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Verification Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMsg, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(solution),
            SizedBox(height: 16),
            Text('Error Code: ${e.code}',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
          if (e.code != 'too-many-requests' && e.code != 'quota-exceeded')
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _verifyPhoneNumber(); // Retry
              },
              child: Text('Retry'),
            ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EatoTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: EatoTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Phone Verification',
          style: TextStyle(
            color: EatoTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Debug button (only show in debug mode)
          if (_debug)
            IconButton(
              icon: Icon(Icons.bug_report, color: EatoTheme.primaryColor),
              onPressed: _checkFirebaseConfig,
            ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          // Phone icon
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: EatoTheme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phone_android,
                                size: 40,
                                color: EatoTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Title and description
                          Text(
                            'Verify Phone Number',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: EatoTheme.textPrimaryColor,
                                ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            'We\'ve sent a 6-digit verification code to',
                            style: TextStyle(
                              color: EatoTheme.textSecondaryColor,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          Text(
                            '+94${widget.phoneNumber}',
                            style: TextStyle(
                              color: EatoTheme.textPrimaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Code input fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              return _buildCodeInputField(index);
                            }),
                          ),
                          const SizedBox(height: 32),

                          // Status messages
                          if (_isCodeSent && !_isVerificationSuccessful)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: EatoTheme.infoColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: EatoTheme.infoColor),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Enter the 6-digit code sent to your phone',
                                      style:
                                          TextStyle(color: EatoTheme.infoColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (_isVerificationSuccessful)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: EatoTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: EatoTheme.successColor),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Phone number verified successfully!',
                                      style: TextStyle(
                                          color: EatoTheme.successColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 32),

                          // Resend code section
                          if (_canResend)
                            TextButton(
                              onPressed: _requestNewCode,
                              child: Text(
                                'Resend Code',
                                style: TextStyle(
                                  color: EatoTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Text(
                              'Resend code in ${_remainingSeconds}s',
                              style: TextStyle(
                                  color: EatoTheme.textSecondaryColor),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Column(
                    children: [
                      // Verify button
                      if (_currentCode.length == 6 &&
                          !_isVerificationSuccessful)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isVerifying ? null : _verifyManually,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EatoTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isVerifying
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Verify Code',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Skip verification button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed:
                              _isVerifying ? null : _skipPhoneVerification,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side:
                                BorderSide(color: EatoTheme.textSecondaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Skip Verification',
                            style: TextStyle(
                              color: EatoTheme.textSecondaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInputField(int index) {
    return Container(
      width: 50, // Slightly wider
      height: 60, // Slightly taller
      decoration: BoxDecoration(
        border: Border.all(
          color: _digitValidation[index] == true
              ? EatoTheme.successColor
              : _digitValidation[index] == false
                  ? EatoTheme.errorColor
                  : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _digitValidation[index] == true
            ? EatoTheme.successColor.withOpacity(0.1)
            : _digitValidation[index] == false
                ? EatoTheme.errorColor.withOpacity(0.1)
                : Colors.white, // Change to white background
      ),
      child: TextField(
        // Change from TextFormField to TextField
        controller: _codeControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24, // Larger font
          fontWeight: FontWeight.bold,
          color: EatoTheme.textPrimaryColor,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero, // Remove padding
          isDense: true, // Make it dense
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1), // Ensure only 1 character
        ],
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Clear validation when typing
            setState(() {
              _digitValidation[index] = null;
            });

            // Move to next field
            if (index < 5) {
              FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
            } else {
              FocusScope.of(context).unfocus();
            }
          } else {
            // Move to previous field when deleting
            if (index > 0) {
              FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
            }
          }
        },
        onTap: () {
          // Clear the field when tapped
          _codeControllers[index].clear();
          setState(() {
            _digitValidation[index] = null;
          });
        },
      ),
    );
  }

// Also add this method to help with focus management
  void _focusOnFirstEmptyField() {
    for (int i = 0; i < 6; i++) {
      if (_codeControllers[i].text.isEmpty) {
        FocusScope.of(context).requestFocus(_focusNodes[i]);
        break;
      }
    }
  }
}
