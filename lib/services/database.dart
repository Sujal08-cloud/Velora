import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseMethods {

  Future addUserInfo(Map<String, dynamic> userInfoMap, String id) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInfoMap);
  }

  Future addProducts(Map<String, dynamic> productInfoMap) {
    return FirebaseFirestore.instance
        .collection("Products")
        .add(productInfoMap);
  }

  Stream<QuerySnapshot> getallProducts() {
    return FirebaseFirestore.instance.collection("Products").snapshots();
  }

  Future addTransaction(Map<String, dynamic> transactionInfoMap, String id) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Transactions")  
        .add(transactionInfoMap);
  }

  Future updateWallet(String id, String amount) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .update({"Wallet": amount});
  }

  Future addOrder(Map<String, dynamic> orderInfoMap, String id) {
    orderInfoMap["Status"] = "Processing";
    return FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Orders")
        .add(orderInfoMap);
  }

  Future updateOrderStatus(String userId, String orderId, String status) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Orders")
        .doc(orderId)
        .update({"Status": status});
  }

  Stream getRecentTransactions(String id) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Transactions")   
        .orderBy("Date", descending: true)
        .limit(3)
        .snapshots();
  }

  Future updateUserName(String name, String id) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .update({"Name": name});
  }

  Stream getAllTransactions(String id) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Transactions")   
        .orderBy("Date", descending: true)
        .snapshots();
  }

  Future saveShippingAddress(
      Map<String, dynamic> addressMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("shippingAddress")
        .doc("default")
        .set(addressMap);
  }

  Future<Map<String, dynamic>?> getShippingAddress(String userId) async {
  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("shippingAddress")
        .doc("default")
        .get();

    if (doc.exists) return doc.data() as Map<String, dynamic>?;
    return null;
  } catch (e) {
    debugPrint("getShippingAddress error: $e");
    return null;
  }
}

  Future addFlashSaleProduct(Map<String, dynamic> productInfoMap) {
    return FirebaseFirestore.instance
        .collection("FlashSale")
        .add(productInfoMap);
  }

  Stream<QuerySnapshot> getFlashSaleProducts() {
    return FirebaseFirestore.instance
        .collection("FlashSale")
        .limit(4)
        .snapshots();
  }

  Stream getallOrder(String id) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Orders")
        .orderBy("Date", descending: true)
        .snapshots();
  }

  Future addToCart(Map<String, dynamic> cartInfoMap, String userId,
      String productName) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Cart")
        .doc(productName)
        .set(cartInfoMap);
  }

  Stream getCart(String userId) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Cart")
        .snapshots();
  }

  Future removeFromCart(String userId, String productName) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Cart")
        .doc(productName)
        .delete();
  }

  Future updateCartQuantity(
      String userId, String productName, int quantity, int totalPrice) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Cart")
        .doc(productName)
        .update({"Quantity": quantity, "Total": totalPrice});
  }

  Future updateCartItem(String userId, String productName, String size,
      int quantity, int total) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Cart")
        .doc(productName)
        .update({
      "Size": size,
      "Quantity": quantity,
      "Total": total,
    });
  }

  Stream<QuerySnapshot> getAllFlashSaleProducts() {
    return FirebaseFirestore.instance
        .collection("FlashSale")
        .snapshots();
  }
}
