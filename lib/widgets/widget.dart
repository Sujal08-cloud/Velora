import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppWidget{
  static TextStyle boldTextstyle(double size){
    return TextStyle(color:Colors.black, fontSize: size, fontWeight: FontWeight.bold, fontFamily: "Inter");
  }
  static TextStyle whiteTextstyle(double size){
    return  TextStyle(color: Colors.white, fontFamily: "Inter",fontSize: size);
   }
   static Widget nonSelected(String size){
    return  Container(
                    width: 37,
                    height:60,
                    decoration: BoxDecoration(border: Border.all(color: const Color.fromARGB(88, 0, 0, 0),), borderRadius: BorderRadius.circular(6.0) ), child: Center(child: Text(size, style: AppWidget.boldTextstyle(13.0),))
                    );
   }
   static Widget selected(String size){
    return  Container(
                    width: 37,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(0xff6e5038),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(size, style: AppWidget.whiteTextstyle(15.0)),
                    ),
                  );
   }
    static TextStyle greenTextstyle(double size){
    return  TextStyle(color: Color.fromARGB(255, 84, 95, 51), fontFamily: "Inter",fontSize: size);
   }
}

Widget transactionTile({
  required String title,
  required String date,
  required String amount,
  required String status,
}) {
  bool isCredited = status == "CREDITED";
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
                  title,
                  style: GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  date,
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
              isCredited ? "+₹$amount" : "-₹$amount",
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
                status,
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
}


Widget quickAddButton(String amount, Color bgColor, Color textColor) {
    return Material(
      elevation: 2.0,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        height: 45,
        width: 95,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
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
            Text(amount, style: GoogleFonts.lato(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
