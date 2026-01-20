import 'dart:convert';
import 'package:chicken_dilivery/pages/Auth/signIn.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  // Controllers for the input fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> registerUser() async {
    // Validate input fields
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your username")),
      );
      return;
    }
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your first name")),
      );
      return;
    }
    if (_lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your last name")),
      );
      return;
    }
    if (_shopNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter shop name")));
      return;
    }
    if (_phoneNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter phone number")),
      );
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter password")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final registerUrl = dotenv.env['registerUrl'];
      if (registerUrl == null || registerUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration URL not configured.")),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
      final url = Uri.parse(registerUrl);

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "register",
          "userName": _usernameController.text.trim(),
          "firstName": _firstNameController.text.trim(),
          "lastName": _lastNameController.text.trim(),
          "shopName": _shopNameController.text.trim(),
          "phoneNumber": _phoneNumberController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      setState(() {
        isLoading = false;
      });

      // Google Apps Script typically returns 200 or 302 for successful requests
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 302) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == 'success' ||
              responseData['result'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Registered Successfully!"),
                backgroundColor: Colors.green,
              ),
            );
            // Clear the form
            _usernameController.clear();
            _firstNameController.clear();
            _lastNameController.clear();
            _shopNameController.clear();
            _phoneNumberController.clear();
            _passwordController.clear();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? "Registration Failed"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          // If response is not JSON, treat as success based on status code
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registered Successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          // Clear the form
          _usernameController.clear();
          _firstNameController.clear();
          _lastNameController.clear();
          _shopNameController.clear();
          _phoneNumberController.clear();
          _passwordController.clear();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Registration Failed (Status: ${response.statusCode})",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isPasswordVisible = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _shopNameController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width < 360 ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1a1a1a),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width < 360 ? 15 : 16,
            color: const Color(0xFF1a1a1a),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF9CA3AF),
              fontSize: MediaQuery.of(context).size.width < 360 ? 14 : 15,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00bf63), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: MediaQuery.of(context).size.width < 360 ? 14 : 16,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1a1a1a)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06, // 6% of screen width
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.02), // 2% of screen height
              // Logo section - improved design
              Center(
                child: Container(
                  width: 200,
                  height: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'images/pos_billing_logo1.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01), // 4% of screen height
              // Improved header text
              Text(
                'Create your account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth < 360 ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1a1a1a),
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              Text(
                'Please fill in the information below\nකරුණාකර පහත තොරතුරු පුරවන්න',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              // Form fields with responsive spacing
              _buildTextField(
                label: 'Username/පරිශීලක නාමය/பயனர் பெயர்',
                hint: 'Enter your username',
                controller: _usernameController,
              ),

              SizedBox(height: screenHeight * 0.025),

              // Responsive row for name fields
              screenWidth < 400
                  ? Column(
                      children: [
                        _buildTextField(
                          label: 'First Name/මුල් නම/முதல் பெயர்',
                          hint: 'Enter your first name',
                          controller: _firstNameController,
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        _buildTextField(
                          label: 'Last Name/අවසන් නම/கடைசி பெயர்',
                          hint: 'Enter your last name',
                          controller: _lastNameController,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'First Name/මුල් නම/முதல் பெயர்',
                            hint: 'First name',
                            controller: _firstNameController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'Last Name/අවසන් නම/கடைசி பெயர்',
                            hint: 'Last name',
                            controller: _lastNameController,
                          ),
                        ),
                      ],
                    ),

              SizedBox(height: screenHeight * 0.025),

              _buildTextField(
                label: 'Shop Name/වෙළඳසැල් නාමය/கடை பெயர்',
                hint: 'Enter your shop name',
                controller: _shopNameController,
              ),

              SizedBox(height: screenHeight * 0.025),

              _buildTextField(
                label: 'Phone Number/දුරකථන අංකය/தொலைபேசி எண்',
                hint: '+94 70 123 4567',
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
              ),

              SizedBox(height: screenHeight * 0.025),

              _buildTextField(
                label: 'Password/මුරපදය/கடவுச்சொல்',
                hint: 'Create a strong password',
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Sign up button - responsive sizing
              Container(
                height: screenHeight * 0.065, // 6.5% of screen height
                constraints: const BoxConstraints(minHeight: 48, maxHeight: 56),
                child: ElevatedButton(
                  onPressed: isLoading ? null : registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00bf63),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF00bf63),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              // Sign in link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontSize: isSmallScreen ? 14 : 15,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SigninPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: const Color(0xFF00bf63),
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}
