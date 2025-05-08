import 'package:flutter/material.dart';
import 'phoneVerification.dart';

class PhoneInputPage extends StatefulWidget {
  final String role;
  final bool isSignUp;
  final Map<String, String>? userData;

  const PhoneInputPage({
    Key? key,
    required this.role,
    required this.isSignUp,
    this.userData,
  }) : super(key: key);

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  String _selectedCountryCode = '+1'; // Default to US

  // List of country codes for dropdown
  final List<String> _countryCodes = [
    '+1',    // US/Canada
    '+44',   // UK
    '+91',   // India
    '+61',   // Australia
    '+86',   // China
    '+33',   // France
    '+49',   // Germany
    '+81',   // Japan
    '+52',   // Mexico
    '+55',   // Brazil
    '+94',   // Sri Lanka
    '+27',   // South Africa
    '+65',   // Singapore
    '+971',  // UAE
    '+966',  // Saudi Arabia
    '+7',    // Russia
  ];

  bool validatePhoneNumber() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    return true;
  }

  void proceedToVerification() {
    if (!validatePhoneNumber()) return;

    setState(() {
      _isLoading = true;
    });

    final fullPhoneNumber = '$_selectedCountryCode${phoneController.text.trim()}';
    print("Proceeding with phone number: $fullPhoneNumber");

    // Navigate to phone verification page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneVerificationPage(
          phoneNumber: fullPhoneNumber,
          userType: widget.role,
          isSignUp: widget.isSignUp,
          userData: widget.userData,
        ),
      ),
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 30.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text("Back"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Enter Phone Number",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                "Please enter your phone number to verify your account",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country code dropdown
                  Container(
                    height: 60,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        items: _countryCodes.map((String code) {
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text(code),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCountryCode = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  // Phone number field
                  Expanded(
                    child: TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        hintText: "Enter phone number",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        
                        // Basic phone number validation (digits only)
                        final phoneRegex = RegExp(r'^\d+$');
                        if (!phoneRegex.hasMatch(value)) {
                          return 'Please enter numbers only';
                        }
                        
                        // Length validation
                        if (value.length < 9 || value.length > 15) {
                          return 'Phone number should be 9-15 digits';
                        }
                        
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "We'll send a verification code to this number",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : proceedToVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Continue",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}