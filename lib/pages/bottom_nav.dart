import 'package:clothing/pages/Cart.dart';
import 'package:clothing/pages/Shopping_page.dart';
import 'package:clothing/pages/home.dart';
import 'package:clothing/pages/profile.dart';
import 'package:clothing/pages/wallet.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentTabIndex = 0;

  final List<Widget> pages = [
    Home(),
    Shopping(),
    Cart(),
    Wallet(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentTabIndex],
      bottomNavigationBar: CurvedNavigationBar(
        height: 60,
        backgroundColor: Color(0xfff9f6f3),
        color: Color(0xff6e5038),
        animationDuration: Duration(milliseconds: 500),
        onTap: (int index) {
          setState(() {
            currentTabIndex = index;
          });
        },
        items: [
          Icon(Icons.home, color: Colors.white, size: 28),
          Icon(Icons.shopping_bag, color: Colors.white, size: 28),
          Icon(Icons.shopping_cart, color: Colors.white, size: 28),
          Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
          Icon(Icons.person, color: Colors.white, size: 28),
        ],
      ),
    );
  }
}