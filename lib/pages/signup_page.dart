import 'package:clothing/pages/login.dart';
import 'package:clothing/services/database.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController namecontroller     = TextEditingController();
  final TextEditingController emailcontroller    = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();

  bool loading            = false;
  bool _isPasswordVisible = false;

  String _passwordStrength     = '';
  Color  _passwordStrengthColor = Colors.transparent;

  @override
  void dispose() {
    namecontroller.dispose();
    emailcontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email.trim());
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return "Password must be at least 8 characters.";
    }
    if (password.length > 32) {
      return "Password cannot exceed 32 characters.";
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Password must contain at least one number.";
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Password must contain at least one capital letter.";
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return "Password must contain at least one special character (!@#\$%).";
    }
    return null;
  }

  void _onPasswordChanged(String value) {
    int score = 0;
    if (value.length >= 8)                                    score++;
    if (value.contains(RegExp(r'[0-9]')))                    score++;
    if (value.contains(RegExp(r'[A-Z]')))                    score++;
    if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))  score++;

    setState(() {
      if (value.isEmpty) {
        _passwordStrength      = '';
        _passwordStrengthColor = Colors.transparent;
      } else if (score <= 1) {
        _passwordStrength      = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (score == 2 || score == 3) {
        _passwordStrength      = 'Medium';
        _passwordStrengthColor = Colors.orange;
      } else {
        _passwordStrength      = 'Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  void _showSnack(String msg, {Color bg = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          msg,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> registration() async {
    final name     = namecontroller.text.trim();
    final email    = emailcontroller.text.trim();
    final password = passwordcontroller.text;

    if (name.isEmpty) {
      _showSnack("Please enter your name.", bg: Colors.red);
      return;
    }
    if (name.length < 2) {
      _showSnack("Name must be at least 2 characters.", bg: Colors.red);
      return;
    }

    if (email.isEmpty) {
      _showSnack("Please enter your email.", bg: Colors.red);
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnack(
        "Invalid email. Please enter a valid email (e.g. user@example.com).",
        bg: Colors.red,
      );
      return;
    }

    // ✅ Password validation
    if (password.isEmpty) {
      _showSnack("Please enter a password.", bg: Colors.red);
      return;
    }
    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      _showSnack(passwordError, bg: Colors.red);
      return;
    }

    setState(() => loading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user!.sendEmailVerification();
      await userCredential.user!.updateDisplayName(name);

      final String uid = userCredential.user!.uid;

      final Map<String, dynamic> userInfoMap = {
        "Name"   : name,
        "Email"  : email,
        "Id"     : uid,
        "Wallet" : "0",
        "Role"   : "user",
      };

      await SharedPreferenceHelper().saveUserId(uid);
      await SharedPreferenceHelper().saveUserEmail(email);
      await SharedPreferenceHelper().saveUserName(name);
      await SharedPreferenceHelper().saveUserWallet("0");

      await DatabaseMethods().addUserInfo(userInfoMap, uid);

      await FirebaseAuth.instance.signOut();

      setState(() => loading = false);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Login()),
      );

      _showSnack("Verification email sent! Please verify before login.");

    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);
      switch (e.code) {
        case "weak-password":
          _showSnack("Password is too weak. Use at least 8 characters.", bg: Colors.red);
          break;
        case "email-already-in-use":
          _showSnack("Account already exists for this email.", bg: Colors.red);
          break;
        case "invalid-email":
          _showSnack("Invalid email address. Please check and try again.", bg: Colors.red);
          break;
        case "network-request-failed":
          _showSnack("No internet connection. Please try again.", bg: Colors.red);
          break;
        default:
          _showSnack("Something went wrong. Please try again.", bg: Colors.red);
      }
    } catch (e) {
      setState(() => loading = false);
      _showSnack("Unexpected error. Please try again.", bg: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xff6e5038),
                  borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Create Account",
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Join us and start shopping",
                      style: GoogleFonts.lato(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel("Full Name"),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: namecontroller,
                        hint: "Enter your name",
                        icon: Icons.person_outline,
                        maxLength: 20, 
                      ),

                      const SizedBox(height: 20),
                      _fieldLabel("Email"),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: emailcontroller,
                        hint: "Enter your email",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 50, 
                      ),

                      const SizedBox(height: 20),
                      _fieldLabel("Password"),
                      const SizedBox(height: 8),
                      _passwordField(),
                      if (_passwordStrength.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _passwordStrengthColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Password strength: $_passwordStrength",
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: _passwordStrengthColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 8),
                      Text(
                        "Min 8 chars • 1 capital • 1 number • 1 special character",
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading ? null : registration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff6e5038),
                            disabledBackgroundColor:
                                const Color(0xff6e5038).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  "Sign Up",
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Login()),
                    ),
                    child: Text(
                      "Login",
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff6e5038),
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0xff6e5038),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.lato(
        fontSize: 13,
        color: Colors.grey[600],
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.lato(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xff6e5038), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F3EF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: '', 
      ),
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: passwordcontroller,
      obscureText: !_isPasswordVisible,
      maxLength: 15, 
      onChanged: _onPasswordChanged, 
      style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: "Enter your password",
        hintStyle: GoogleFonts.lato(color: Colors.grey[400], fontSize: 14),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Color(0xff6e5038),
          size: 20,
        ),
        suffixIcon: GestureDetector(
          onTap: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
          child: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xff6e5038),
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F3EF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: '', 
      ),
    );
  }
}