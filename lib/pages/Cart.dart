import 'package:clothing/pages/address.dart';
import 'package:clothing/services/database.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:clothing/pages/detail_page.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  String? id, wallet;
  Stream? cartStream;

  Future<void> getthesharedpref() async {
    id = await SharedPreferenceHelper().getUserId() ??
        FirebaseAuth.instance.currentUser?.uid;

    if (id != null) {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(id!)
          .get();
      wallet = doc.data()?["Wallet"]?.toString() ?? "0";
      await SharedPreferenceHelper().saveUserWallet(wallet!);
      cartStream = DatabaseMethods().getCart(id!);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getthesharedpref();
  }

  int calculateTotal(List<DocumentSnapshot> docs) {
    int total = 0;
    for (var doc in docs) {
      total += int.tryParse(doc["Total"].toString()) ?? 0;
    }
    return total;
  }

  Future<void> placeOrder(List<DocumentSnapshot> docs) async {
    if (id == null) {
      id = FirebaseAuth.instance.currentUser?.uid;
    }
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Session expired. Please login again.",
            style: GoogleFonts.lato(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    Map<String, dynamic>? shippingAddress =
        await DatabaseMethods().getShippingAddress(id!);

    if (shippingAddress == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Shipping Address is not added",
            style:
                GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Please add Shipping address before placing an order",
            style: GoogleFonts.lato(fontSize: 14, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Later",
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6e5038)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ShippingAddressPage()),
                );
              },
              child: Text("Add Address",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }


    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(id!)
          .get();
      wallet = doc.data()?["Wallet"]?.toString() ?? "0";
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Could not fetch wallet balance. Please try again.",
            style: GoogleFonts.lato(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    int totalAmount = calculateTotal(docs);
    int currentWallet = int.tryParse(wallet ?? "0") ?? 0;

    if (currentWallet < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Insufficient balance! Wallet: ₹$currentWallet, Required: ₹$totalAmount",
            style: GoogleFonts.lato(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    String formattedDate =
        DateFormat("dd MMMM yyyy").format(DateTime.now());

    try {
      for (var doc in docs) {
        Map<String, dynamic> orderMap = {
          "Name": doc["Name"],
          "Quantity": doc["Quantity"],
          "Total Price": doc["Total"].toString(),
          "Image": doc["Image"],
          "Size": doc["Size"],
          "Date": formattedDate,
          "Status": "Processing",
          "ShippingAddress": shippingAddress,
        };
        await DatabaseMethods().addOrder(orderMap, id!);
      }

      int updatedWallet = currentWallet - totalAmount;
      await DatabaseMethods().updateWallet(id!, updatedWallet.toString());
      await SharedPreferenceHelper()
          .saveUserWallet(updatedWallet.toString());

      Map<String, dynamic> transactionMap = {
        "Amount": totalAmount.toString(),
        "Status": "DEBITED",
        "Date": formattedDate,
      };
      await DatabaseMethods().addTransaction(transactionMap, id!);

      for (var doc in docs) {
        await DatabaseMethods().removeFromCart(id!, doc["Name"]);
      }

      wallet = updatedWallet.toString();
      if (mounted) setState(() {});

      if (mounted) {
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Order failed: ${e.toString()}",
              style: GoogleFonts.lato(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    }
  }

  void _showEditSheet(DocumentSnapshot ds) {
    String selectedSize = ds["Size"] ?? "S";
    int selectedQuantity =
        int.tryParse(ds["Quantity"].toString()) ?? 1;
    int unitPrice = int.tryParse(ds["Price"].toString()) ?? 0;

    final List<String> sizes = ["S", "M", "L", "XL", "XXL"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int totalPrice = unitPrice * selectedQuantity;

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
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          ds["Image"],
                          height: 55,
                          width: 55,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ds["Name"],
                              style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "₹$unitPrice per item",
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: Color(0xff6e5038),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Select Size",
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: sizes.map((size) {
                      bool isSelected = selectedSize == size;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedSize = size),
                        child: Container(
                          margin: EdgeInsets.only(right: 10),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xff6e5038)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Color(0xff6e5038)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            size,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Select Quantity",
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 38,
                        width: 130,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.black26, width: 1.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => setModalState(
                                  () => selectedQuantity++),
                              child: Container(
                                height: 38,
                                width: 38,
                                decoration: BoxDecoration(
                                  color: Color(0xff6e5038),
                                  borderRadius:
                                      BorderRadius.circular(50),
                                ),
                                child: Icon(Icons.add,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                            Text(
                              selectedQuantity.toString(),
                              style: GoogleFonts.lato(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () => setModalState(() {
                                if (selectedQuantity > 1)
                                  selectedQuantity--;
                              }),
                              child: Container(
                                height: 38,
                                width: 38,
                                decoration: BoxDecoration(
                                  color: Color(0xff6e5038),
                                  borderRadius:
                                      BorderRadius.circular(50),
                                ),
                                child: Icon(Icons.remove,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Total",
                              style: GoogleFonts.lato(
                                  fontSize: 12, color: Colors.grey)),
                          Text(
                            "₹$totalPrice",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff6e5038),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      await DatabaseMethods().updateCartItem(
                        id!,
                        ds["Name"],
                        selectedSize,
                        selectedQuantity,
                        unitPrice * selectedQuantity,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green,
                          content: Text(
                            "Cart updated!",
                            style: GoogleFonts.lato(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(0xff6e5038),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          "Save Changes",
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
                top: 50, left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: Color(0xff6e5038),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Text(
              "My Cart",
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: cartStream == null
                ? Center(
                    child: CircularProgressIndicator(
                        color: Color(0xff6e5038)))
                : StreamBuilder(
                    stream: cartStream,
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                              color: Color(0xff6e5038)),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Your cart is empty",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Add products to get started",
                                style: GoogleFonts.lato(
                                    fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      List<DocumentSnapshot> docs =
                          snapshot.data.docs;
                      int totalAmount = calculateTotal(docs);

                      return Column(
                        children: [
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${docs.length} item${docs.length > 1 ? 's' : ''} in cart",
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                DocumentSnapshot ds = docs[index];
                                return _cartItem(ds);
                              },
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Subtotal",
                                        style: GoogleFonts.lato(
                                            fontSize: 14,
                                            color: Colors.grey)),
                                    Text("₹$totalAmount",
                                        style: GoogleFonts.lato(
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Delivery",
                                        style: GoogleFonts.lato(
                                            fontSize: 14,
                                            color: Colors.grey)),
                                    Text(
                                      "FREE",
                                      style: GoogleFonts.lato(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                    height: 20,
                                    color: Colors.grey.shade200),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Total",
                                      style:
                                          GoogleFonts.playfairDisplay(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "₹$totalAmount",
                                      style:
                                          GoogleFonts.playfairDisplay(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff6e5038),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () => placeOrder(docs),
                                  child: Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Color(0xff6e5038),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Place Order  ₹$totalAmount",
                                        style: GoogleFonts.lato(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _cartItem(DocumentSnapshot ds) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(
              image: ds["Image"],
              name: ds["Name"],
              price: ds["Price"].toString(),
              detail: ds["Detail"] ?? "",
              fromCart: true,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ds["Image"],
                height: 80,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 80,
                  width: 80,
                  color: Colors.grey.shade100,
                  child: Icon(Icons.image_not_supported,
                      color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ds["Name"],
                    style: GoogleFonts.lato(
                        fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              Color(0xff6e5038).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Size: ${ds["Size"]}",
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: Color(0xff6e5038),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Qty: ${ds["Quantity"]}",
                        style: GoogleFonts.lato(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${ds["Total"]}",
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff6e5038),
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showEditSheet(ds),
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Color(0xff6e5038)
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.edit_outlined,
                                  color: Color(0xff6e5038),
                                  size: 18),
                            ),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              await DatabaseMethods()
                                  .removeFromCart(id!, ds["Name"]);
                            },
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.delete_outline,
                                  color: Colors.red, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}