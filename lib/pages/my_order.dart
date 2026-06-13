import 'package:clothing/services/database.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyOrdersPage extends StatefulWidget {
  final String initialCategory;
  const MyOrdersPage({super.key, this.initialCategory = "Processing"});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late String selectedCategory;
  String? id;
  Stream? orderStream;
  final List<String> categories = [
    "Processing",
    "Confirmed",
    "Shipped",
    "Delivered",
    "Cancelled",
  ];

  Future<void> getontheload() async {
    id = await SharedPreferenceHelper().getUserId();
    if (id != null) orderStream = DatabaseMethods().getallOrder(id!);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    getontheload();
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Confirmed": return Colors.blue;
      case "Shipped":   return Colors.purple;
      case "Delivered": return Colors.green;
      case "Cancelled": return Colors.red;
      default:          return Colors.orange; // Processing
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "Confirmed": return Icons.check_circle_outline;
      case "Shipped":   return Icons.local_shipping_outlined;
      case "Delivered": return Icons.done_all;
      case "Cancelled": return Icons.cancel_outlined;
      default:          return Icons.autorenew; // Processing
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back, color: Colors.black),
                ),
                Icon(Icons.search, color: Colors.black),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text("My Orders",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 26, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 16),
            child: Row(
              children: categories.map((category) {
                bool isSelected = selectedCategory == category;
                Color catColor = _statusColor(category);
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = category),
                  child: Container(
                    margin: EdgeInsets.only(right: 10),
                    padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? catColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? catColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _statusIcon(category),
                          size: 14,
                          color: isSelected ? Colors.white : catColor,
                        ),
                        SizedBox(width: 5),
                        Text(
                          category,
                          style: GoogleFonts.lato(
                            color:
                                isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 16),

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
                        return _emptyState();
                      }
                      var filteredDocs =
                          snapshot.data.docs.where((doc) {
                        String status =
                            doc["Status"] ?? "Processing";
                        return status == selectedCategory;
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return _emptyState();
                      }
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) =>
                            _orderCard(filteredDocs[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 60, color: Colors.grey.shade300),
          SizedBox(height: 12),
          Text("No $selectedCategory orders",
              style: GoogleFonts.lato(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _orderCard(var ds) {
    String status = ds["Status"] ?? "Processing";
    Color statusColor = _statusColor(status);
    IconData statusIcon = _statusIcon(status);

    return Container(
      padding: EdgeInsets.all(14),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Order: ${ds["Name"] ?? ""}",
                  style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(ds["Date"] ?? "",
                  style: GoogleFonts.lato(
                      color: Colors.grey, fontSize: 12)),
            ],
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Qty: ${ds["Quantity"] ?? "1"}",
                  style: GoogleFonts.lato(
                      color: Colors.grey, fontSize: 12)),
              Text("₹${ds["Total Price"] ?? "0"}",
                  style: GoogleFonts.lato(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 10),
          _statusProgressBar(status),

          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    SizedBox(width: 4),
                    Text(status,
                        style: GoogleFonts.lato(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _statusProgressBar(String status) {
    final steps = ["Processing", "Confirmed", "Shipped", "Delivered"];
    if (status == "Cancelled") {
      return Row(
        children: [
          Icon(Icons.cancel, size: 14, color: Colors.red),
          SizedBox(width: 6),
          Text("Order Cancelled",
              style: GoogleFonts.lato(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      );
    }

    int currentStep = steps.indexOf(status);

    return Row(
      children: List.generate(steps.length, (i) {
        bool done    = i <= currentStep;
        bool current = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? Color(0xff6e5038) : Colors.grey.shade300,
                  border: current
                      ? Border.all(color: Color(0xff6e5038), width: 2)
                      : null,
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < currentStep
                        ? Color(0xff6e5038)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}