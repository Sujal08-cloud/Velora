import 'dart:async';
import 'dart:io';
import 'package:clothing/pages/Edit_profile_page.dart';
import 'package:clothing/pages/address.dart';
import 'package:clothing/pages/help_support.dart';
import 'package:clothing/pages/login.dart';
import 'package:clothing/pages/my_order.dart';
import 'package:clothing/pages/order_history.dart';
import 'package:clothing/pages/setting.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? name, email;
  String _walletBalance = "0";
  StreamSubscription? _walletSub;
  File? _profileImage;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getontheload();
    _initWalletListener();
  }

  @override
  void dispose() {
    _walletSub?.cancel(); 
    super.dispose();
  }

  void _initWalletListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _walletSub = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists && mounted) {
            setState(() {
              _walletBalance = doc.data()?["Wallet"]?.toString() ?? "0";
            });
          }
        });
  }

  Future<void> getontheload() async {
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();

    if (name == null || name!.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      name = user?.displayName ?? user?.email?.split('@')[0];
      email ??= user?.email;
    }
    setState(() {});
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xfff5f5f5),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff6e5038), Color(0xff8d6748)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Color.fromARGB(255, 222, 216, 210),
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? Icon(
                              Icons.person,
                              size: 35,
                              color: Color(0xff6e5038),
                            )
                          : null,
                    ),
                    SizedBox(height: 10),
                    Text(
                      name ?? "User",
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      email ?? "",
                      style: GoogleFonts.lato(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              _drawerTile(Icons.person_outline, "Edit Profile", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => EditProfilePage()),
                );
              }),
              _drawerTile(Icons.receipt_long_outlined, "Order History", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => OrderHistoryPage()),
                );
              }),
              _drawerTile(Icons.location_on_outlined, "Shipping Address", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => ShippingAddressPage()),
                );
              }),
              _drawerTile(Icons.settings_outlined, "Settings", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => SettingsPage()),
                );
              }),
              _drawerTile(Icons.help_outline, "Help & Support", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => HelpSupportPage()),
                );
              }),
              Spacer(),
              Divider(),
              _drawerTile(Icons.logout, "Logout", () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (c) => Login()),
                );
              }, color: Colors.red),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff6e5038), Color(0xff8d6748)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 52),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 30),
                        Text(
                          "My Profile",
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: Color.fromARGB(255, 222, 216, 210),
                          ),
                          child: ClipOval(
                            child: _profileImage != null
                                ? Image.file(_profileImage!, fit: BoxFit.cover)
                                : Icon(
                                    Icons.person,
                                    size: 55,
                                    color: Color(0xff6e5038),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            height: 26,
                            width: 26,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xff6e5038),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 13,
                              color: Color(0xff6e5038),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    name ?? "User",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email ?? "",
                    style: GoogleFonts.lato(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 30),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Wallet Balance",
                          style: GoogleFonts.lato(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "₹$_walletBalance",
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Orders",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => MyOrdersPage()),
                    ),
                    child: Text(
                      "View All",
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: Color(0xff6e5038),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _orderStatusItem(
                    "Processing",
                    Icons.autorenew_outlined,
                    Colors.orange.shade50,
                    Colors.orange,
                  ),
                  _orderStatusItem(
                    "Delivered",
                    Icons.check_circle_outline,
                    Colors.green.shade50,
                    Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) =>
                            MyOrdersPage(initialCategory: "Delivered"),
                      ),
                    ),
                  ),
                  _orderStatusItem(
                    "Shipped",
                    Icons.local_shipping_outlined,
                    Colors.blue.shade50,
                    Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) =>
                            MyOrdersPage(initialCategory: "Shipped"),
                      ),
                    ),
                  ),
                  _orderStatusItem(
                    "Cancelled",
                    Icons.cancel_outlined,
                    Colors.red.shade50,
                    Colors.red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) =>
                            MyOrdersPage(initialCategory: "Cancelled"),
                      ),
                    ),
                  ),
                  _orderStatusItem(
                    "Support",
                    Icons.help_outline,
                    Colors.purple.shade50,
                    Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => HelpSupportPage()),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ACCOUNT",
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 10),
                  _profileOptionTile(
                    icon: Icons.person_outline,
                    title: "Edit Profile",
                    subtitle: "Update name, password & email",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => EditProfilePage()),
                    ),
                  ),
                  _profileOptionTile(
                    icon: Icons.location_on_outlined,
                    title: "Shipping Address",
                    subtitle: "Manage your delivery addresses",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => ShippingAddressPage()),
                    ),
                  ),
                  _profileOptionTile(
                    icon: Icons.receipt_long_outlined,
                    title: "Order History",
                    subtitle: "View all your past orders",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => OrderHistoryPage()),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "MORE",
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 10),
                  _profileOptionTile(
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    subtitle: "App preferences & more",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => SettingsPage()),
                    ),
                  ),
                  _profileOptionTile(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    subtitle: "FAQs, contact us",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => HelpSupportPage()),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (c) => Login()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Logout",
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
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _orderStatusItem(
    String label,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => MyOrdersPage()),
          ),
      child: Container(
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Color(0xff6e5038).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Color(0xff6e5038), size: 20),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
