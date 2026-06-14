import 'dart:async';
import 'package:clothing/pages/all_transaction.dart';
import 'package:clothing/services/database.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:clothing/widgets/widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String _walletBalance = "0";         
  StreamSubscription? _walletSub;      
  String? id;
  String? formattedDate;
  final TextEditingController amountController = TextEditingController();
  late Razorpay _razorpay;
  int? selectedQuickAmount;
  Stream? transactionStream;

  @override
  void initState() {
    super.initState();
    getontheload();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    amountController.dispose();
    _walletSub?.cancel(); 
    _razorpay.clear();
    super.dispose();
  }

  Future<void> getontheload() async {
    id = await SharedPreferenceHelper().getUserId()
        ?? FirebaseAuth.instance.currentUser?.uid;

    if (id != null) {
      transactionStream = DatabaseMethods().getRecentTransactions(id!);
      _walletSub = FirebaseFirestore.instance
          .collection("users")
          .doc(id!)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          setState(() {
            _walletBalance = doc.data()?["Wallet"]?.toString() ?? "0";
          });
        }
      });
    }
    setState(() {});
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
  try {
    if (id == null) {
      id = FirebaseAuth.instance.currentUser?.uid;
    }
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text("Session expired. Please login again.",
            style: GoogleFonts.lato(color: Colors.white)),
      ));
      return;
    }
    final String txnDate = DateFormat("dd MMMM yyyy").format(DateTime.now());
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(id!)
        .get();
    int currentBalance =
        int.tryParse(userDoc.data()?["Wallet"]?.toString() ?? "0") ?? 0;

    int addAmount = int.tryParse(amountController.text) ?? 0;

    if (addAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text("Invalid amount!",
            style: GoogleFonts.lato(color: Colors.white)),
      ));
      return;
    }

    int updatedAmount = currentBalance + addAmount;
    await DatabaseMethods().updateWallet(id!, updatedAmount.toString());

    Map<String, dynamic> paymentInfoMap = {
      "Amount": addAmount.toString(),
      "Status": "CREDITED",
      "Date": txnDate,
    };
    await DatabaseMethods().addTransaction(paymentInfoMap, id!);
    await SharedPreferenceHelper().saveUserWallet(updatedAmount.toString());

    amountController.clear();
    if (mounted) setState(() => selectedQuickAmount = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          "₹$addAmount added to wallet! New balance: ₹$updatedAmount",
          style: GoogleFonts.lato(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ));
    }
  } catch (e) {
    print("Wallet update error: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text("Error updating wallet: $e",
            style: GoogleFonts.lato(color: Colors.white)),
      ));
    }
  }
}


  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "Payment Failed: ${response.message}",
          style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange,
        content: Text(
          "External Wallet: ${response.walletName}",
          style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void openCheckout(String amount) {
  int parsedAmount = int.tryParse(amount) ?? 0;
  
  print("Amount: $parsedAmount");
  print("Key: ${dotenv.env['RAZORPAY_KEY']}");
  
  if (parsedAmount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "Please enter a valid amount",
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    return;
  }

  var options = {
    'key': dotenv.env['RAZORPAY_KEY'] ?? '',
    'amount': parsedAmount * 100,
    'name': 'Clothing Store',
    'description': 'Wallet Recharge',
    'currency': 'INR',
    'prefill': {'contact': '9999999999', 'email': 'test@example.com'},
    'theme': {'color': '#6e5038'},
  };

  print("Options: $options");

  try {
    _razorpay.open(options);
    print("Razorpay opened!");
  } catch (e) {
    print("Razorpay Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "Error: $e",
          style: GoogleFonts.lato(color: Colors.white),
        ),
      ),
    );
  }
}



  Widget quickAddButton(String amount, Color bgColor, Color textColor) {
    int amountInt = int.parse(amount);
    bool isSelected = selectedQuickAmount == amountInt;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedQuickAmount = amountInt;
          amountController.text = amountInt.toString();
        });
      },
      child: Material(
        elevation: 2.0,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          height: 45,
          width: 95,
          decoration: BoxDecoration(
            color: isSelected ? bgColor : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: isSelected ? Border.all(color: textColor, width: 1.5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.attach_money, color: textColor, size: 16),
              ),
              SizedBox(width: 5),
              Text(
                "₹$amount",
                style: GoogleFonts.lato(
                  color: isSelected ? textColor : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    formattedDate = DateFormat("dd MMMM yyyy").format(DateTime.now());

    return Scaffold(
      backgroundColor:  Color(0xfff9f6f3),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 35),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Wallet",
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 25.0, fontWeight: FontWeight.bold)),
          
                ],
              ),
            ),
            SizedBox(height: 15.0),
            Container(
              margin: EdgeInsets.only(left: 20.0, right: 20.0),
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.all(16),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Color(0xff6e5038),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset("images/wallet.png",
                              height: 60, width: 60, fit: BoxFit.cover),
                          SizedBox(width: 12.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Balance",
                                  style: GoogleFonts.lato(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              SizedBox(height: 4),
                              Text(
                                "₹ $_walletBalance",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w500
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Quick Add",
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 16.0, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  quickAddButton("100", Colors.green.shade100, Colors.green),
                  quickAddButton("200", Colors.purple.shade100, Colors.purple),
                  quickAddButton("300", Colors.blue.shade100, Colors.blue),
                ],
              ),
            ),
            SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Or Enter Amount",
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 16.0, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.only(left: 18.0, right: 18.0),
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                color: Color.fromARGB(59, 158, 158, 158),
                borderRadius: BorderRadius.circular(58),
              ),
              child: TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    setState(() => selectedQuickAmount = null),
                style:
                    GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter amount (e.g. 500)",
                  hintStyle:
                      GoogleFonts.lato(fontSize: 15, color: Colors.grey),
                  prefixIcon: Icon(Icons.currency_rupee,
                      color: Color(0xff6e5038), size: 20),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            GestureDetector(
              onTap: () {
                if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.red,
                    content: Text("Please select or enter an amount first",
                        style: GoogleFonts.lato(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ));
                  return;
                }
                openCheckout(amountController.text);
              },
              child: Container(
                margin: EdgeInsets.only(left: 20.0, right: 20.0),
                child: Material(
                  elevation: 3.0,
                  borderRadius: BorderRadius.circular(15.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 71, 172, 90),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    height: 55,
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(width: 16),
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle),
                              child: Icon(Icons.add,
                                  color: Colors.green, size: 20),
                            ),
                            SizedBox(width: 12),
                            Text(
                              amountController.text.isEmpty
                                  ? "Add Money to Wallet"
                                  : "Add ₹${amountController.text} to Wallet",
                              style: GoogleFonts.lato(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Icon(Icons.arrow_forward_ios,
                              color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Transactions",
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 16.0, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AllTransactions())),
                    child: Text("View All >",
                        style: GoogleFonts.lato(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            StreamBuilder(
              stream: transactionStream,
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: Color(0xff6e5038)));
                }
                if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("No transactions yet",
                          style: GoogleFonts.lato(
                              color: Colors.grey, fontSize: 14)),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    var ds = snapshot.data.docs[index];
                    return transactionTile(
                      title: ds["Status"] == "CREDITED"
                          ? "Added to Wallet"
                          : "Payment",
                      date: ds["Date"] ?? "",
                      amount: ds["Amount"] ?? "0",
                      status: ds["Status"] ?? "CREDITED",
                    );
                  },
                );
              },
            ),
            SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}