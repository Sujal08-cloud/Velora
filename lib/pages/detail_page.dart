import 'package:clothing/services/database.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:clothing/widgets/widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


class DetailPage extends StatefulWidget {
  final String image, name, price, detail;
  final String? originalPrice;
  final bool fromCart;

  const DetailPage({
    super.key,
    required this.image,
    required this.name,
    required this.price,
    required this.detail,
    this.originalPrice,
    this.fromCart = false,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int quantity = 1;
  int totalprice = 0;
  String? wallet, id;
  bool small = true, medium = false, large = false, xl = false, xxl = false;
  bool addingToCart = false;
  bool placingOrder = false;

  String get selectedSize {
    if (small) return "S";
    if (medium) return "M";
    if (large) return "L";
    if (xl) return "XL";
    if (xxl) return "XXL";
    return "S";
  }

  Future<void> getthesharedpref() async {
  id = await SharedPreferenceHelper().getUserId()
      ?? FirebaseAuth.instance.currentUser?.uid;

  if (id != null) {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(id!)
        .get();
    wallet = doc.data()?["Wallet"]?.toString() ?? "0";
    await SharedPreferenceHelper().saveUserWallet(wallet!);
  }
  setState(() {});
}


  @override
  void initState() {
    super.initState();
    getthesharedpref();
    totalprice = int.tryParse(widget.price) ?? 0; 
  }

  int get discountAmount {
    if (widget.originalPrice == null || widget.originalPrice!.isEmpty) return 0;
    int original = int.tryParse(widget.originalPrice!) ?? 0;
    int sale = int.tryParse(widget.price) ?? 0;
    return original - sale;
  }

  int get discountPercent {
    if (widget.originalPrice == null || widget.originalPrice!.isEmpty) return 0;
    int original = int.tryParse(widget.originalPrice!) ?? 0;
    int sale = int.tryParse(widget.price) ?? 0;
    if (original == 0) return 0;
    return (((original - sale) / original) * 100).round();
  }
  Future<void> addToCart() async {
  if (id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange,
        content: Text(
          "Please wait and try again!",
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    return;
  }

  setState(() => addingToCart = true);
  try {
    Map<String, dynamic> cartMap = {
      "Name": widget.name,
      "Price": widget.price,
      "Image": widget.image,
      "Detail": widget.detail,
      "Quantity": quantity,
      "Size": selectedSize,
      "Total": totalprice,
    };
    await DatabaseMethods().addToCart(cartMap, id!, widget.name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              "Added to Cart!",
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    print("CART ERROR: $e"); // ← debug ke liye
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "Error: $e", // ← exact error dikhega
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  setState(() => addingToCart = false);
}


  Future<void> placeOrder() async {
    if (wallet == null || id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "Please wait and try again!",
            style: GoogleFonts.lato(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => placingOrder = true);

    try {
      int currentWallet = int.tryParse(wallet!) ?? 0;

      if (currentWallet >= totalprice) {
        int updatedAmount = currentWallet - totalprice;
        String formattedDate =
            DateFormat("dd MMMM yyyy").format(DateTime.now());

        Map<String, dynamic> addOrder = {
          "Name": widget.name,
          "Quantity": quantity.toString(),
          "Total Price": totalprice.toString(),
          "Image": widget.image,
          "Date": formattedDate,
          "Status": "Processing",
          "Size": selectedSize,
        };

        Map<String, dynamic> paymentInfoMap = {
          "Amount": totalprice.toString(),
          "Status": "DEBITED",
          "Date": formattedDate,
        };

        await SharedPreferenceHelper().saveUserWallet(updatedAmount.toString());
        await DatabaseMethods().updateWallet(id!, updatedAmount.toString());
        await DatabaseMethods().addTransaction(paymentInfoMap, id!);
        await DatabaseMethods().addOrder(addOrder, id!);

        setState(() {
          wallet = updatedAmount.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Order Placed Successfully!",
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Insufficient wallet balance! Add money first.",
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Order failed. Try again!",
            style: GoogleFonts.lato(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    setState(() => placingOrder = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  widget.image,
                  height: MediaQuery.of(context).size.height / 2.2,
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                  errorBuilder: (c, e, s) => Container(
                    height: MediaQuery.of(context).size.height / 2.2,
                    color: Colors.grey.shade100,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Positioned(
                  top: 33,
                  left: 18,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xff6e5038),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
                if (discountPercent > 0)
                  Positioned(
                    top: 33,
                    right: 18,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$discountPercent% OFF",
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 14),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          if (widget.originalPrice != null &&
                              widget.originalPrice!.isNotEmpty)
                            Text(
                              "₹${widget.originalPrice}  ",
                              style: GoogleFonts.lato(
                                color: Colors.grey,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey,
                              ),
                            ),
                          Text(
                            "₹${widget.price}",
                            style: GoogleFonts.lato(
                              color: Color(0xff6e5038),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (discountAmount > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            "Save ₹$discountAmount",
                            style: GoogleFonts.lato(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 15),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Product Details",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.detail,
                style: GoogleFonts.lato(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                "Select Size",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Container(
              margin: EdgeInsets.only(left: 15),
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  small
                      ? AppWidget.selected("S")
                      : GestureDetector(
                          onTap: () => setState(() {
                            small = true;
                            medium = false;
                            large = false;
                            xl = false;
                            xxl = false;
                          }),
                          child: AppWidget.nonSelected("S"),
                        ),
                  SizedBox(width: 20),
                  medium
                      ? AppWidget.selected("M")
                      : GestureDetector(
                          onTap: () => setState(() {
                            small = false;
                            medium = true;
                            large = false;
                            xl = false;
                            xxl = false;
                          }),
                          child: AppWidget.nonSelected("M"),
                        ),
                  SizedBox(width: 20),
                  large
                      ? AppWidget.selected("L")
                      : GestureDetector(
                          onTap: () => setState(() {
                            small = false;
                            medium = false;
                            large = true;
                            xl = false;
                            xxl = false;
                          }),
                          child: AppWidget.nonSelected("L"),
                        ),
                  SizedBox(width: 20),
                  xl
                      ? AppWidget.selected("XL")
                      : GestureDetector(
                          onTap: () => setState(() {
                            small = false;
                            medium = false;
                            large = false;
                            xl = true;
                            xxl = false;
                          }),
                          child: AppWidget.nonSelected("XL"),
                        ),
                  SizedBox(width: 20),
                  xxl
                      ? AppWidget.selected("XXL")
                      : GestureDetector(
                          onTap: () => setState(() {
                            small = false;
                            medium = false;
                            large = false;
                            xl = false;
                            xxl = true;
                          }),
                          child: AppWidget.nonSelected("XXL"),
                        ),
                ],
              ),
            ),

            SizedBox(height: 20),

            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                "Select Quantity",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 12),
            Container(
              margin: EdgeInsets.only(left: 20),
              height: 35,
              width: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26, width: 1.5),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      quantity++;
                      totalprice = quantity * (int.tryParse(widget.price) ?? 0);
                      setState(() {});
                    },
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: Color(0xff6e5038),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                  Text(
                    quantity.toString(),
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (quantity > 1) {
                        quantity--;
                        totalprice =
                            quantity * (int.tryParse(widget.price) ?? 0);
                        setState(() {});
                      }
                    },
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: Color(0xff6e5038),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(Icons.remove, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Price",
                            style: GoogleFonts.lato(
                              color: Colors.black45,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "₹$totalprice",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff6e5038),
                            ),
                          ),
                        ],
                      ),
                      if (discountAmount > 0)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            "Save ₹${discountAmount * quantity}",
                            style: GoogleFonts.lato(
                              color: Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 14),
                  id == null
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Color(0xff6e5038),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          children: [
                            if (!widget.fromCart) ...[
                              Expanded(
                                child: GestureDetector(
                                  onTap: addingToCart ? null : addToCart,
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Color(0xff6e5038),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: addingToCart
                                          ? CircularProgressIndicator(
                                              color: Color(0xff6e5038),
                                              strokeWidth: 2,
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.shopping_cart_outlined,
                                                  color: Color(0xff6e5038),
                                                  size: 20,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  "Add to Cart",
                                                  style: GoogleFonts.lato(
                                                    color: Color(0xff6e5038),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                            ],

                            Expanded(
                              child: GestureDetector(
                                onTap: placingOrder ? null : placeOrder,
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(0xff6e5038),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: placingOrder
                                        ? CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          )
                                        : Text(
                                            "Place Order",
                                            style: GoogleFonts.lato(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}