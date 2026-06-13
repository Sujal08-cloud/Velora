import 'package:clothing/services/database.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String? id;
  Stream? orderStream;

  Future<void> getontheload() async {
    id = await SharedPreferenceHelper().getUserId();
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
                  "Order History",
                  style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "All your past orders",
                  style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          Expanded(
            child: orderStream == null
                ? Center(child: CircularProgressIndicator(color: Color(0xff6e5038)))
                : StreamBuilder(
                    stream: orderStream,
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: Color(0xff6e5038)));
                      }

                      if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey.shade300),
                              SizedBox(height: 16),
                              Text("No orders yet", style: GoogleFonts.playfairDisplay(fontSize: 18, color: Colors.grey)),
                              SizedBox(height: 8),
                              Text("Your order history will appear here", style: GoogleFonts.lato(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: snapshot.data.docs.length,
                        itemBuilder: (context, index) {
                          var ds = snapshot.data.docs[index];
                          String status = ds["Status"] ?? "Processing";
                          Color statusColor = status == "Delivered"
                              ? Colors.green
                              : status == "Cancelled"
                                  ? Colors.red
                                  : Color(0xff6e5038);

                          return Container(
                            padding: EdgeInsets.all(14),
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    ds["Image"] ?? "",
                                    height: 65,
                                    width: 65,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      height: 65,
                                      width: 65,
                                      color: Colors.grey.shade100,
                                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ds["Name"] ?? "",
                                        style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text("Qty: ${ds["Quantity"] ?? "1"}", style: GoogleFonts.lato(fontSize: 12, color: Colors.grey)),
                                          SizedBox(width: 10),
                                          if (ds["Size"] != null)
                                            Text("Size: ${ds["Size"]}", style: GoogleFonts.lato(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text("₹${ds["Total Price"] ?? "0"}", style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xff6e5038))),
                                      SizedBox(height: 4),
                                      Text(ds["Date"] ?? "", style: GoogleFonts.lato(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                                  ),
                                ),
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