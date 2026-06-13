import 'package:clothing/pages/detail_page.dart';
import 'package:clothing/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlashSaleAllPage extends StatefulWidget {
  const FlashSaleAllPage({super.key});

  @override
  State<FlashSaleAllPage> createState() => _FlashSaleAllPageState();
}

class _FlashSaleAllPageState extends State<FlashSaleAllPage> {
  Stream<QuerySnapshot>? flashStream;

  @override
  void initState() {
    super.initState();
    loadFlashSale();
  }

  Future<void> loadFlashSale() async {
    flashStream = await DatabaseMethods().getAllFlashSaleProducts();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: Color(0xff6e5038),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                SizedBox(width: 14),
                Icon(Icons.flash_on, color: Colors.yellow, size: 22),
                SizedBox(width: 6),
                Text(
                  "Flash Sale",
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          Expanded(
            child: flashStream == null
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xff6e5038)),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: flashStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: Color(0xff6e5038)),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flash_off,
                                  size: 60, color: Colors.grey.shade300),
                              SizedBox(height: 12),
                              Text(
                                "No flash sale products",
                                style: GoogleFonts.lato(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      List<DocumentSnapshot> docs = snapshot.data!.docs;

                      return GridView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> data =
                              docs[index].data() as Map<String, dynamic>;
                          return _flashCard(data);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _flashCard(Map<String, dynamic> data) {
    int originalPrice = int.tryParse(data['OriginalPrice']?.toString() ?? '0') ?? 0;
    int salePrice = int.tryParse(data['Price']?.toString() ?? '0') ?? 0;
    int discountPercent = originalPrice > 0
        ? (((originalPrice - salePrice) / originalPrice) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(
              image: data['Image'] ?? '',
              name: data['Name'] ?? '',
              price: data['Price'] ?? '',
              detail: data['Detail'] ?? '',
              originalPrice: data['OriginalPrice'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: data['Image'] != null && data['Image'].toString().isNotEmpty
                        ? Image.network(
                            data['Image'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.grey.shade100,
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.grey, size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: Icon(Icons.image, color: Colors.grey, size: 40),
                          ),
                  ),

                  if (discountPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "$discountPercent% OFF",
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['Name'] ?? '',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (originalPrice > 0)
                    Text(
                      "₹${data['OriginalPrice']}",
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${data['Price']}",
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff6e5038),
                        ),
                      ),
                      if (originalPrice > salePrice)
                        Text(
                          "Save ₹${originalPrice - salePrice}",
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
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