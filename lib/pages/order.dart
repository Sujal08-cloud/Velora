import 'package:clothing/services/database.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  Stream? orderStream;
  String? id;

  Future<void> getontheload() async {
    id = await SharedPreferenceHelper().getUserId() ?? FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      orderStream = DatabaseMethods().getallOrder(id!);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getontheload();
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Confirmed": return Colors.blue;
      case "Shipped":   return Colors.purple;
      case "Delivered": return Colors.green;
      case "Cancelled": return Colors.red;
      default:          return Colors.orange; 
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "Confirmed": return Icons.check_circle_outline;
      case "Shipped":   return Icons.local_shipping_outlined;
      case "Delivered": return Icons.done_all;
      case "Cancelled": return Icons.cancel_outlined;
      default:          return Icons.autorenew;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "My Orders",
              style: GoogleFonts.playfairDisplay(
                  fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: orderStream == null
                ? Center(
                    child: CircularProgressIndicator(
                        color: Color(0xff6e5038)))
                : StreamBuilder(
                    stream: orderStream,
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                            child: CircularProgressIndicator(
                                color: Color(0xff6e5038)));
                      }
                      if (!snapshot.hasData ||
                          snapshot.data.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300),
                              SizedBox(height: 12),
                              Text("No orders yet",
                                  style: GoogleFonts.lato(
                                      color: Colors.grey,
                                      fontSize: 14)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: snapshot.data.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot ds =
                              snapshot.data.docs[index];
                          String status =
                              ds["Status"] ?? "Processing";
                          Color statusColor = _statusColor(status);
                          IconData statusIcon = _statusIcon(status);

                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    ds["Image"],
                                    height: 110,
                                    width: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        Container(
                                      height: 110,
                                      width: 110,
                                      color: Color(0xFFF7F3EF),
                                      child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ds["Name"] ?? "",
                                          style: GoogleFonts.playfairDisplay(
                                              fontSize: 15,
                                              fontWeight:
                                                  FontWeight.bold),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                                Icons
                                                    .production_quantity_limits,
                                                color:
                                                    Color(0xff6e5038),
                                                size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              "Qty: ${ds["Quantity"]}",
                                              style: GoogleFonts.lato(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.currency_rupee,
                                                color:
                                                    Color(0xff6e5038),
                                                size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              "₹${ds["Total Price"]}",
                                              style: GoogleFonts.lato(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    20),
                                            border: Border.all(
                                                color: statusColor
                                                    .withOpacity(0.4)),
                                          ),
                                          child: Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              Icon(statusIcon,
                                                  size: 12,
                                                  color: statusColor),
                                              SizedBox(width: 4),
                                              Text(
                                                status,
                                                style: GoogleFonts.lato(
                                                  color: statusColor,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}