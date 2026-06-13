import 'package:clothing/services/database.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllTransactions extends StatefulWidget {
  const AllTransactions({super.key});

  @override
  State<AllTransactions> createState() => _AllTransactionsState();
}

class _AllTransactionsState extends State<AllTransactions> {
  Stream? transactionStream;
  String? id;

  Future<void> getontheload() async {
    id = await SharedPreferenceHelper().getUserId();
    if (id != null) {
      transactionStream = DatabaseMethods().getAllTransactions(id!);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xff6e5038),
        title: Text(
          "All Transactions",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: transactionStream == null
          ? Center(child: CircularProgressIndicator(color: Color(0xff6e5038)))
          : StreamBuilder(
              stream: transactionStream,
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Color(0xff6e5038)),
                  );
                }
                if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No transactions yet",
                      style: GoogleFonts.lato(color: Colors.grey, fontSize: 14),
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    var ds = snapshot.data.docs[index];
                    bool isCredited = ds["Status"] == "CREDITED";
                    return Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCredited ? Colors.green.shade50 : Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  isCredited ? "images/credited.png" : "images/debitted.png",
                                  height: 30,
                                  width: 30,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCredited ? "Added to Wallet" : "Payment",
                                    style: GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  Text(
                                    ds["Date"] ?? "",
                                    style: GoogleFonts.lato(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isCredited ? "+₹${ds["Amount"]}" : "-₹${ds["Amount"]}",
                                style: GoogleFonts.lato(
                                  color: isCredited ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCredited ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  ds["Status"],
                                  style: GoogleFonts.lato(
                                    color: isCredited ? Colors.green : Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}