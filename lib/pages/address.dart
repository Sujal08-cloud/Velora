import 'package:clothing/services/database.dart';
import 'package:clothing/services/shared_prefrence.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShippingAddressPage extends StatefulWidget {
  const ShippingAddressPage({super.key});

  @override
  State<ShippingAddressPage> createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController pincodeController = TextEditingController();

  bool loading = false;
  bool dataLoaded = false;

  @override
  void initState() {
    super.initState();
    loadAddress();
  }

  Future<void> loadAddress() async {
  try {
    String? userId = await SharedPreferenceHelper().getUserId();
    if (userId == null) return;

    Map<String, dynamic>? data = await DatabaseMethods().getShippingAddress(userId);

    if (data != null) {
      fullNameController.text = data['fullName'] ?? '';
      phoneController.text = data['phone'] ?? '';
      addressController.text = data['address'] ?? '';
      cityController.text = data['city'] ?? '';
      stateController.text = data['state'] ?? '';
      pincodeController.text = data['pincode'] ?? '';
    }
  } catch (e) {
    debugPrint("loadAddress error: $e");
  } finally {
    setState(() => dataLoaded = true); // ✅ ALWAYS runs
  }
}

  Future<void> saveAddress() async {
    if (fullNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        stateController.text.trim().isEmpty ||
        pincodeController.text.trim().isEmpty) {
      _showSnack("Please fill all fields", Colors.red);
      return;
    }

    if (phoneController.text.trim().length != 10) {
      _showSnack("Enter valid 10 digit phone number", Colors.red);
      return;
    }

    if (pincodeController.text.trim().length != 6) {
      _showSnack("Enter valid 6 digit pincode", Colors.red);
      return;
    }

    setState(() => loading = true);

    try {
      String? userId = await SharedPreferenceHelper().getUserId();

      Map<String, dynamic> addressMap = {
        "fullName": fullNameController.text.trim(),
        "phone": phoneController.text.trim(),
        "address": addressController.text.trim(),
        "city": cityController.text.trim(),
        "state": stateController.text.trim(),
        "pincode": pincodeController.text.trim(),
      };

      await DatabaseMethods().saveShippingAddress(addressMap, userId!);
      _showSnack("Address saved successfully", Colors.green);
    } catch (e) {
      _showSnack("Failed to save address", Colors.red);
    }

    setState(() => loading = false);
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(
          message,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xff6e5038),
        title: Text(
          "Shipping Address",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: dataLoaded
          ? SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xff6e5038).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xff6e5038).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Color(0xff6e5038),
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Your default delivery address",
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              color: Color(0xff6e5038),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 25),

                  _buildLabel("Full Name"),
                  _buildTextField(
                    controller: fullNameController,
                    hint: "Enter full name",
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                  ),

                  SizedBox(height: 16),

                  _buildLabel("Phone Number"),
                  _buildTextField(
                    controller: phoneController,
                    hint: "10 digit phone number",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                  ),

                  SizedBox(height: 16),

                  _buildLabel("Address"),
                  _buildTextField(
                    controller: addressController,
                    hint: "House no, Street, Area",
                    icon: Icons.home_outlined,
                    maxLines: 2,
                  ),

                  SizedBox(height: 16),

                  _buildLabel("City"),
                  _buildTextField(
                    controller: cityController,
                    hint: "Enter city",
                    icon: Icons.location_city_outlined,
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("State"),
                            _buildTextField(
                              controller: stateController,
                              hint: "Enter state",
                              icon: Icons.map_outlined,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Pincode"),
                            _buildTextField(
                              controller: pincodeController,
                              hint: "6 digit pincode",
                              icon: Icons.pin_outlined,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  GestureDetector(
                    onTap: loading ? null : saveAddress,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Color(0xff6e5038),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: loading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.save_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Save Address",
                                    style: GoogleFonts.lato(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            )
          : Center(
              child: CircularProgressIndicator(color: Color(0xff6e5038)),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.lato(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.lato(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: Color(0xff6e5038), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          counterText: "",
        ),
      ),
    );
  }
}