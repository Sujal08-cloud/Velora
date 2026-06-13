import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final List<Map<String, String>> faqs = [
    {"q": "How do I track my order?", "a": "Go to My Orders section in your profile to track all your orders."},
    {"q": "How do I add money to wallet?", "a": "Go to Wallet tab and use Quick Add or enter a custom amount to recharge."},
    {"q": "Can I cancel my order?", "a": "Currently orders cannot be cancelled once placed. Contact support for help."},
    {"q": "How do I change my delivery address?", "a": "Go to Profile → Shipping Address to update your delivery address."},
    {"q": "What payment methods are accepted?", "a": "We accept wallet payments via Razorpay including UPI, cards and net banking."},
    {"q": "How do I update my profile?", "a": "Go to Profile → Edit Profile to update your name and other details."},
  ];

  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 52, left: 20, right: 20, bottom: 24),
            decoration: BoxDecoration(
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
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  "Help & Support",
                  style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "How can we help you?",
                  style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _contactCard(
                    icon: Icons.email_outlined,
                    title: "Email Us",
                    subtitle: "support@clothing.com",
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _contactCard(
                    icon: Icons.phone_outlined,
                    title: "Call Us",
                    subtitle: "+91 9999999999",
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Frequently Asked Questions",
                style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                bool isExpanded = expandedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      expandedIndex = isExpanded ? null : index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  faqs[index]["q"]!,
                                  style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Color(0xff6e5038),
                              ),
                            ],
                          ),
                        ),
                        if (isExpanded)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                            child: Text(
                              faqs[index]["a"]!,
                              style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w700)),
                Text(subtitle, style: GoogleFonts.lato(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}