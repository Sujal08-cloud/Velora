import 'package:clothing/pages/login.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AddressModel {
  String id;
  String label;
  String fullName;
  String phone;
  String addressLine1;
  String addressLine2;
  String city;
  String state;
  String pincode;
  bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<AddressModel> _addresses = [];

  void _showAccountSettingsSheet() {
    _showSheet(
      title: "Account Settings",
      child: Column(
        children: [
          _sheetOptionTile(
            Icons.lock_outline,
            "Change Password",
            "Update your account password",
            () {
              Navigator.pop(context);
              _showChangePasswordSheet();
            },
          ),
          _sheetOptionTile(
            Icons.email_outlined,
            "Change Email",
            "Update your email address",
            () {
              Navigator.pop(context);
              _showChangeEmailSheet();
            },
          ),
          _sheetOptionTile(
            Icons.delete_outline,
            "Delete Account",
            "Permanently delete your account",
            () {
              Navigator.pop(context);
              _showDeleteAccountSheet();
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscureOld = true, obscureNew = true, obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 16),
                  Text(
                    "Change Password",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _passField(
                    "Current Password",
                    oldPassController,
                    obscureOld,
                    () => setModalState(() => obscureOld = !obscureOld),
                  ),
                  const SizedBox(height: 12),
                  _passField(
                    "New Password",
                    newPassController,
                    obscureNew,
                    () => setModalState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 12),
                  _passField(
                    "Confirm New Password",
                    confirmPassController,
                    obscureConfirm,
                    () => setModalState(() => obscureConfirm = !obscureConfirm),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      if (newPassController.text !=
                          confirmPassController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              "Passwords do not match",
                              style: GoogleFonts.lato(color: Colors.white),
                            ),
                          ),
                        );
                        return;
                      }
                      try {
                        User? user = FirebaseAuth.instance.currentUser;
                        await user?.updatePassword(newPassController.text);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Text(
                              "Password updated!",
                              style: GoogleFonts.lato(color: Colors.white),
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              "Error: ${e.toString()}",
                              style: GoogleFonts.lato(color: Colors.white),
                            ),
                          ),
                        );
                      }
                    },
                    child: _actionButton(
                      "Update Password",
                      const Color(0xff6e5038),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChangeEmailSheet() {
    final emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Text(
                "Change Email",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _inputField(
                "New Email Address",
                emailController,
                TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  try {
                    User? user = FirebaseAuth.instance.currentUser;
                    await user?.verifyBeforeUpdateEmail(
                      emailController.text.trim(),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green,
                        content: Text(
                          "Verification sent! Please verify to complete change.",
                          style: GoogleFonts.lato(color: Colors.white),
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text(
                          "Error: ${e.toString()}",
                          style: GoogleFonts.lato(color: Colors.white),
                        ),
                      ),
                    );
                  }
                },
                child: _actionButton(
                  "Send Verification",
                  const Color(0xff6e5038),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountSheet() {
    final rootCtx = context;

    showModalBottomSheet(
      context: rootCtx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 50),
              const SizedBox(height: 12),
              Text(
                "Delete Account",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This action is permanent and cannot be undone. All your data will be lost.",
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(sheetCtx),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text("Cancel",
                              style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _showConfirmPasswordSheet(rootCtx);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "Delete",
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmPasswordSheet(BuildContext rootCtx) {
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: rootCtx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (confirmCtx) {
        return StatefulBuilder(
          builder: (confirmCtx, setS) {
            bool obscure = true;
            bool isDeleting = false;

            return StatefulBuilder(
              builder: (confirmCtx, setInner) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(confirmCtx).viewInsets.bottom,
                    left: 20,
                    right: 20,
                    top: 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _sheetHandle()),
                        const SizedBox(height: 16),
                        const Icon(Icons.lock_outline,
                            color: Color(0xff6e5038), size: 36),
                        const SizedBox(height: 12),
                        Text(
                          "Confirm Your Identity",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Enter your password to permanently delete your account.",
                          style: GoogleFonts.lato(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        _passField(
                          "Current Password",
                          passwordController,
                          obscure,
                          () => setInner(() => obscure = !obscure),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: isDeleting
                              ? null
                              : () async {
                                  final password = passwordController.text.trim();

                                  if (password.isEmpty) {
                                    ScaffoldMessenger.of(rootCtx).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text("Password cannot be empty",
                                            style: GoogleFonts.lato(color: Colors.white)),
                                      ),
                                    );
                                    return;
                                  }

                                  setInner(() => isDeleting = true);

                                  try {
                                    final user = FirebaseAuth.instance.currentUser;
                                    final uid = user?.uid;
                                    final email = user?.email;

                                    if (user == null || email == null) {
                                      setInner(() => isDeleting = false);
                                      ScaffoldMessenger.of(rootCtx).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text("No user session found. Please login again.",
                                              style: GoogleFonts.lato(color: Colors.white)),
                                        ),
                                      );
                                      return;
                                    }

                                    final credential = EmailAuthProvider.credential(
                                      email: email,
                                      password: password,
                                    );
                                    await user.reauthenticateWithCredential(credential);

                                    if (uid != null) {
                                      final userRef = FirebaseFirestore.instance
                                          .collection("users")
                                          .doc(uid);

                                      for (final sub in [
                                        "Cart",
                                        "Orders",
                                        "Transactions",
                                        "shippingAddress",
                                      ]) {
                                        final snap = await userRef.collection(sub).get();
                                        for (final doc in snap.docs) {
                                          await doc.reference.delete();
                                        }
                                      }

                                      await userRef.delete();
                                    }

                                    await SharedPreferenceHelper().saveUserId("");
                                    await SharedPreferenceHelper().saveUserName("");
                                    await SharedPreferenceHelper().saveUserEmail("");
                                    await SharedPreferenceHelper().saveUserWallet("0");

                                    await user.delete();

                                    if (rootCtx.mounted) {
                                      Navigator.of(rootCtx).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const Login()),
                                        (route) => false,
                                      );
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    setInner(() => isDeleting = false);
                                    String msg;
                                    switch (e.code) {
                                      case 'wrong-password':
                                      case 'invalid-credential':
                                        msg = "Incorrect password. Please try again.";
                                        break;
                                      case 'too-many-requests':
                                        msg = "Too many attempts. Try again later.";
                                        break;
                                      case 'requires-recent-login':
                                        msg = "Session expired. Please logout and login again.";
                                        break;
                                      case 'network-request-failed':
                                        msg = "No internet connection. Try again.";
                                        break;
                                      default:
                                        msg = e.message ?? "Something went wrong.";
                                    }
                                    ScaffoldMessenger.of(rootCtx).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text(msg,
                                            style: GoogleFonts.lato(color: Colors.white)),
                                      ),
                                    );
                                  } catch (e) {
                                    setInner(() => isDeleting = false);
                                    ScaffoldMessenger.of(rootCtx).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text("Error: ${e.toString()}",
                                            style: GoogleFonts.lato(color: Colors.white)),
                                      ),
                                    );
                                  }
                                },
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDeleting ? Colors.red.shade300 : Colors.red,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: isDeleting
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      "Delete My Account",
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => Navigator.pop(confirmCtx),
                          child: _actionButton("Cancel", Colors.grey.shade400),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  void _showAddressBookSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xfff5f5f5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Center(child: _sheetHandle()),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Address Book",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final result = await _openAddressForm(
                                context,
                                null,
                              );
                              if (result != null) {
                                setState(() {
                                  if (_addresses.isEmpty) {
                                    result.isDefault = true;
                                  }
                                  _addresses.add(result);
                                });
                                setModalState(() {});
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff6e5038),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Add",
                                    style: GoogleFonts.lato(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _addresses.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_off_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "No addresses saved",
                                      style: GoogleFonts.lato(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _addresses.length,
                                itemBuilder: (context, index) {
                                  final addr = _addresses[index];
                                  return _addressCard(
                                    addr,
                                    onEdit: () async {
                                      final result = await _openAddressForm(
                                        context,
                                        addr,
                                      );
                                      if (result != null) {
                                        setState(
                                          () => _addresses[index] = result,
                                        );
                                        setModalState(() {});
                                      }
                                    },
                                    onDelete: () {
                                      setState(
                                        () => _addresses.removeAt(index),
                                      );
                                      setModalState(() {});
                                    },
                                    onSetDefault: () {
                                      setState(() {
                                        for (var a in _addresses) {
                                          a.isDefault = false;
                                        }
                                        _addresses[index].isDefault = true;
                                      });
                                      setModalState(() {});
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _addressCard(
    AddressModel addr, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onSetDefault,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: addr.isDefault ? const Color(0xff6e5038) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _labelChip(addr.label),
              const SizedBox(width: 8),
              if (addr.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff6e5038).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Default",
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      color: const Color(0xff6e5038),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Color(0xff6e5038),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            addr.fullName,
            style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            addr.phone,
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            [
              addr.addressLine1,
              addr.addressLine2,
              addr.city,
              addr.state,
              addr.pincode,
            ].where((s) => s.isNotEmpty).join(', '),
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey),
          ),
          if (!addr.isDefault) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onSetDefault,
              child: Text(
                "Set as Default",
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: const Color(0xff6e5038),
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _labelChip(String label) {
    final Map<String, IconData> icons = {
      "Home": Icons.home_outlined,
      "Work": Icons.work_outline,
      "Other": Icons.location_on_outlined,
    };
    return Row(
      children: [
        Icon(
          icons[label] ?? Icons.location_on_outlined,
          size: 14,
          color: const Color(0xff6e5038),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xff6e5038),
          ),
        ),
      ],
    );
  }

  Future<AddressModel?> _openAddressForm(
    BuildContext context,
    AddressModel? existing,
  ) async {
    final nameController = TextEditingController(
      text: existing?.fullName ?? '',
    );
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final line1Controller = TextEditingController(
      text: existing?.addressLine1 ?? '',
    );
    final line2Controller = TextEditingController(
      text: existing?.addressLine2 ?? '',
    );
    final cityController = TextEditingController(text: existing?.city ?? '');
    final stateController = TextEditingController(text: existing?.state ?? '');
    final pincodeController = TextEditingController(
      text: existing?.pincode ?? '',
    );
    String selectedLabel = existing?.label ?? 'Home';

    return showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xfff5f5f5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setS) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _sheetHandle()),
                    const SizedBox(height: 16),
                    Text(
                      existing == null ? "Add New Address" : "Edit Address",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Address Type",
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ["Home", "Work", "Other"].map((label) {
                        final isSelected = selectedLabel == label;
                        return GestureDetector(
                          onTap: () => setS(() => selectedLabel = label),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xff6e5038)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              label,
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _formField("Full Name", nameController, TextInputType.name),
                    const SizedBox(height: 12),
                    _formField(
                      "Phone Number",
                      phoneController,
                      TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _formField(
                      "Address Line 1",
                      line1Controller,
                      TextInputType.streetAddress,
                    ),
                    const SizedBox(height: 12),
                    _formField(
                      "Address Line 2 (Optional)",
                      line2Controller,
                      TextInputType.streetAddress,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _formField(
                            "City",
                            cityController,
                            TextInputType.text,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _formField(
                            "State",
                            stateController,
                            TextInputType.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _formField(
                      "Pincode",
                      pincodeController,
                      TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        if (nameController.text.trim().isEmpty ||
                            phoneController.text.trim().isEmpty ||
                            line1Controller.text.trim().isEmpty ||
                            cityController.text.trim().isEmpty ||
                            stateController.text.trim().isEmpty ||
                            pincodeController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                "Please fill all required fields",
                                style: GoogleFonts.lato(color: Colors.white),
                              ),
                            ),
                          );
                          return;
                        }
                        final addr = AddressModel(
                          id:
                              existing?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          label: selectedLabel,
                          fullName: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                          addressLine1: line1Controller.text.trim(),
                          addressLine2: line2Controller.text.trim(),
                          city: cityController.text.trim(),
                          state: stateController.text.trim(),
                          pincode: pincodeController.text.trim(),
                          isDefault: existing?.isDefault ?? false,
                        );
                        Navigator.pop(ctx, addr);
                      },
                      child: _actionButton(
                        existing == null ? "Save Address" : "Update Address",
                        const Color(0xff6e5038),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  void _showPrivacyPolicySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xfff5f5f5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(child: _sheetHandle()),
                  const SizedBox(height: 16),
                  Text(
                    "Privacy Policy",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _policySection(
                    "1. Data Collection",
                    "We collect information you provide directly to us, such as your name, email address, and payment information when you create an account or make a purchase.",
                  ),
                  _policySection(
                    "2. Data Usage",
                    "We use your information to process orders, send order confirmations, and improve our services. We do not sell your personal information to third parties.",
                  ),
                  _policySection(
                    "3. Data Security",
                    "We implement appropriate security measures to protect your personal information from unauthorized access or disclosure.",
                  ),
                  _policySection(
                    "4. Cookies",
                    "We use cookies to enhance your browsing experience and analyze site traffic. You can control cookie settings through your browser.",
                  ),
                  _policySection(
                    "5. Third-Party Services",
                    "We use trusted third-party services like Firebase and Razorpay. These services have their own privacy policies.",
                  ),
                  _policySection(
                    "6. Contact Us",
                    "If you have questions about this policy, contact us at support@clothing.com",
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTermsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xfff5f5f5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(child: _sheetHandle()),
                  const SizedBox(height: 16),
                  Text(
                    "Terms & Conditions",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _policySection(
                    "1. Acceptance",
                    "By using our app, you agree to these terms and conditions. If you do not agree, please do not use our services.",
                  ),
                  _policySection(
                    "2. Account",
                    "You are responsible for maintaining the confidentiality of your account credentials and all activities that occur under your account.",
                  ),
                  _policySection(
                    "3. Orders & Payments",
                    "All orders are subject to availability. Payments are processed securely through Razorpay. We reserve the right to cancel orders.",
                  ),
                  _policySection(
                    "4. Returns & Refunds",
                    "Please contact our support team within 7 days of delivery for any return or refund requests.",
                  ),
                  _policySection(
                    "5. Prohibited Use",
                    "You may not use our service for any unlawful purpose or in any way that could damage or impair our services.",
                  ),
                  _policySection(
                    "6. Changes",
                    "We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of updated terms.",
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSheet({required String title, required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              child,
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    final sectionLabelColor = Colors.grey.shade500;
    const bgColor = Color(0xfff5f5f5);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 52,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff6e5038), Color(0xff8d6748)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  "Settings",
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel("ACCOUNT", sectionLabelColor),
                  _settingsCard(cardColor, [
                    _settingsTile(
                      title: "Account Settings",
                      onTap: _showAccountSettingsSheet,
                    ),
                    _divider(),
                    _settingsTile(
                      title: "Address Book",
                      onTap: _showAddressBookSheet,
                    ),
                  ]),

                  const SizedBox(height: 16),
                  _sectionLabel("LEGAL", sectionLabelColor),
                  _settingsCard(cardColor, [
                    _settingsTile(
                      title: "Privacy Policy",
                      onTap: _showPrivacyPolicySheet,
                    ),
                    _divider(),
                    _settingsTile(
                      title: "Terms & Conditions",
                      onTap: _showTermsSheet,
                    ),
                  ]),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (c) => Login()),
                        );
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Log Out",
                              style: GoogleFonts.lato(
                                color: Colors.red,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _settingsCard(Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _sheetOptionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color color = const Color(0xff6e5038),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _passField(
    String hint,
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.lato(fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.lato(color: Colors.grey),
          suffixIcon: GestureDetector(
            onTap: toggle,
            child: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller,
    TextInputType type,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: GoogleFonts.lato(fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.lato(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _formField(
    String hint,
    TextEditingController controller,
    TextInputType type,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: GoogleFonts.lato(fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.lato(
            color: Colors.grey.shade500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String text, Color color) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _policySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.lato(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }
}