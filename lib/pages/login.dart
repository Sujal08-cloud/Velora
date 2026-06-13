import 'package:clothing/pages/bottom_nav.dart';
import 'package:clothing/pages/signup_page.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailcontroller    = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();

  bool _isPasswordVisible = false;
  bool _loading           = false;

  @override
  void dispose() {
    emailcontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email.trim());
  }

  void _showSnack(String msg, {Color bg = Colors.red}) {
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

  Future<void> userLogin() async {
    final email    = emailcontroller.text.trim();
    final password = passwordcontroller.text.trim();

    if (email.isEmpty) {
      _showSnack("Please enter your email.");
      return;
    }
    if (password.isEmpty) {
      _showSnack("Please enter your password.");
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnack("Invalid email. Please enter a valid email (e.g. user@example.com).");
      return;
    }

    setState(() => _loading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.reload();
      final User? freshUser = FirebaseAuth.instance.currentUser;

      if (freshUser == null) {
        setState(() => _loading = false);
        _showSnack("Login failed. Please try again.");
        return;
      }

      if (!freshUser.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() => _loading = false);
        _showSnack(
          "Email not verified. Please check your inbox and verify first.",
          bg: Colors.orange,
        );
        return;
      }
      await SharedPreferenceHelper().saveUserId(freshUser.uid);
      await SharedPreferenceHelper().saveUserEmail(freshUser.email ?? email);

      String userName = freshUser.displayName ?? '';
      if (userName.isEmpty) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection("users")
              .doc(freshUser.uid)
              .get();
          userName = doc.data()?["Name"] ?? email.split('@')[0];
        } catch (_) {
          userName = email.split('@')[0];
        }
      }
      await SharedPreferenceHelper().saveUserName(userName);

      try {
        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(freshUser.uid)
            .get();
        final wallet = doc.data()?["Wallet"]?.toString() ?? "0";
        await SharedPreferenceHelper().saveUserWallet(wallet);
      } catch (_) {}

      setState(() => _loading = false);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNav()),
      );

    } on FirebaseAuthException catch (e) {
      setState(() => _loading = false);
      final String message;
      switch (e.code) {
        case "invalid-credential":
        case "INVALID_LOGIN_CREDENTIALS":
        case "wrong-password":
        case "invalid-email":
          message = "Invalid email or password.";
          break;
        case "user-not-found":
          message = "No account found with this email.";
          break;
        case "user-disabled":
          message = "This account has been disabled.";
          break;
        case "too-many-requests":
          message = "Too many attempts. Please try again later.";
          break;
        case "network-request-failed":
          message = "No internet connection. Please try again.";
          break;
        default:
          message = e.message ?? "Login failed. Please try again.";
      }
      _showSnack(message);
    } catch (e) {
      setState(() => _loading = false);
      _showSnack("Something went wrong. Please try again.");
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailcontroller.text.trim();

    if (email.isEmpty) {
      _showSnack("Please enter your email address first.");
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnack("Please enter a valid email address.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnack("Password reset email sent! Check your inbox.", bg: Colors.green);
    } on FirebaseAuthException catch (e) {
      final String message;
      switch (e.code) {
        case "user-not-found":
          message = "No account found with this email.";
          break;
        case "invalid-email":
          message = "Invalid email address.";
          break;
        default:
          message = "Could not send reset email. Try again.";
      }
      _showSnack(message);
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
                        Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Welcome Back",
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Sign in to continue shopping",
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
                      _fieldLabel("Email"),
                      const SizedBox(height: 8),
                      _inputField(
                        controller: emailcontroller,
                        hint: "Enter your email",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 20),
                      _fieldLabel("Password"),
                      const SizedBox(height: 8),
                      _passwordField(),

                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _forgotPassword,
                          child: Text(
                            "Forgot Password?",
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff6e5038),
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xff6e5038),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : userLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff6e5038),
                            disabledBackgroundColor:
                                const Color(0xff6e5038).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  "Sign In",
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
                    "Don't have an account? ",
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    ),
                    child: Text(
                      "Sign Up",
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
      ),
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: passwordcontroller,
      obscureText: !_isPasswordVisible,
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
      ),
    );
  }
}
