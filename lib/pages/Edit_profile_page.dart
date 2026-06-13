import 'package:clothing/services/database.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController newEmailController = TextEditingController();
  TextEditingController emailPasswordController = TextEditingController();

  bool loading = false;
  bool _showCurrentPass = false;
  bool _showNewPass = false;
  bool _showConfirmPass = false;

  String? currentName;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    currentName = await SharedPreferenceHelper().getUserName();
    nameController.text = currentName ?? "";
    setState(() {});
  }

  Future<void> updateName() async {
    if (nameController.text.trim().isEmpty) {
      _showSnack("Name cannot be empty", Colors.red);
      return;
    }
    if (nameController.text.trim() == currentName) {
      _showSnack("This is already your name", Colors.orange);
      return;
    }

    setState(() => loading = true);

    try {
      String? userId = await SharedPreferenceHelper().getUserId();
      await DatabaseMethods().updateUserName(
        nameController.text.trim(),
        userId!,
      );
      await SharedPreferenceHelper().saveUserName(nameController.text.trim());
      currentName = nameController.text.trim();
      _showSnack("Name updated successfully", Colors.green);
    } catch (e) {
      _showSnack("Failed to update name", Colors.red);
    }

    setState(() => loading = false);
  }

  Future<void> updatePassword() async {
    if (currentPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showSnack("Please fill all password fields", Colors.red);
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      _showSnack("New passwords do not match", Colors.red);
      return;
    }

    if (newPasswordController.text.length < 6) {
      _showSnack("Password must be at least 6 characters", Colors.red);
      return;
    }

    setState(() => loading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPasswordController.text.trim());

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      _showSnack("Password updated successfully", Colors.green);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showSnack("Current password is incorrect", Colors.red);
      } else {
        _showSnack("Failed to update password", Colors.red);
      }
    }

    setState(() => loading = false);
  }

  Future<void> updateEmail() async {
    if (newEmailController.text.trim().isEmpty) {
      _showSnack("Please enter new email", Colors.red);
      return;
    }
    if (emailPasswordController.text.trim().isEmpty) {
      _showSnack("Please enter current password", Colors.red);
      return;
    }

    setState(() => loading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: emailPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmailController.text.trim());

      newEmailController.clear();
      emailPasswordController.clear();

      _showSnack(
        "Verification sent to new email. Please verify to complete change.",
        Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showSnack("Current password is incorrect", Colors.red);
      } else if (e.code == 'email-already-in-use') {
        _showSnack("This email is already in use", Colors.red);
      } else {
        _showSnack("Failed to update email", Colors.red);
      }
    }

    setState(() => loading = false);
  }

  Future<void> sendForgotPassword() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      _showSnack("No email found", Colors.red);
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      _showSnack("Password reset email sent to ${user.email}", Colors.green);
    } catch (e) {
      _showSnack("Failed to send reset email", Colors.red);
    }

    setState(() => loading = false);
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(
          message,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Color(0xff6e5038),
        title: Text(
          "Edit Profile",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Update Name",
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff6e5038),
              ),
            ),
            SizedBox(height: 12),
            _buildTextField(
              controller: nameController,
              hint: "Enter new name",
              icon: Icons.person_outline,
            ),
            SizedBox(height: 12),
            _buildButton("Update Name", updateName),

            SizedBox(height: 35),
            Divider(color: Colors.grey.shade200, thickness: 1.5),
            SizedBox(height: 25),
            Text(
              "Change Password",
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff6e5038),
              ),
            ),

            SizedBox(height: 12),
            _buildTextField(
              controller: currentPasswordController,
              hint: "Current password",
              icon: Icons.lock_outline,
              isPassword: true,
              isVisible: _showCurrentPass,
              onToggle: () =>
                  setState(() => _showCurrentPass = !_showCurrentPass),
            ),
            SizedBox(height: 12),
            _buildTextField(
              controller: newPasswordController,
              hint: "New password",
              icon: Icons.lock_outline,
              isPassword: true,
              isVisible: _showNewPass,
              onToggle: () => setState(() => _showNewPass = !_showNewPass),
            ),
            SizedBox(height: 12),
            _buildTextField(
              controller: confirmPasswordController,
              hint: "Confirm new password",
              icon: Icons.lock_outline,
              isPassword: true,
              isVisible: _showConfirmPass,
              onToggle: () =>
                  setState(() => _showConfirmPass = !_showConfirmPass),
            ),
            SizedBox(height: 12),
            _buildButton("Update Password", updatePassword),

            SizedBox(height: 40),
            Divider(color: Colors.grey.shade200, thickness: 1.5),
            SizedBox(height: 25),
            Text(
              "Change Email",
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff6e5038),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "A verification link will be sent to your new email",
              style: GoogleFonts.lato(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 12),
            _buildTextField(
              controller: emailPasswordController,
              hint: "Current password",
              icon: Icons.lock_outline,
              isPassword: true,
              isVisible: _showCurrentPass,
              onToggle: () =>
                  setState(() => _showCurrentPass = !_showCurrentPass),
            ),
            SizedBox(height: 12),
            _buildTextField(
              controller: newEmailController,
              hint: "New email address",
              icon: Icons.email_outlined,
            ),
            SizedBox(height: 12),
            _buildButton("Update Email", updateEmail),

            SizedBox(height: 35),
            Divider(color: Colors.grey.shade200, thickness: 1.5),
            SizedBox(height: 25),

            Text(
              "Forgot Password?",
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff6e5038),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Reset link will be sent to your registered email",
              style: GoogleFonts.lato(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 12),
            _buildButton("Send Reset Email", sendForgotPassword),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !isVisible : false,
        style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.lato(color: Colors.grey, fontSize: 15),
          prefixIcon: Icon(icon, color: Color(0xff6e5038), size: 20),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: onToggle,
                  child: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: Color(0xff6e5038),
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Color(0xff6e5038),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: loading
              ? CircularProgressIndicator(color: Colors.white)
              : Text(
                  text,
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
