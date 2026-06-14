import 'package:clothing/pages/Shopping_page.dart';
import 'package:clothing/pages/detail_page.dart';
import 'package:clothing/pages/flashSaleproduct_page.dart';
import 'package:clothing/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Stream? productStream;
  String address = "Getting your location...";
  final GlobalKey _searchKey = GlobalKey();
double _searchBarBottom = 130;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  bool isSearching = false;
  bool isLoadingSearch = false;
  List<DocumentSnapshot> searchResults = [];

  @override
  void initState() {
    super.initState();
    getontheload();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
  final box = _searchKey.currentContext?.findRenderObject() as RenderBox?;
  if (box != null) {
    final position = box.localToGlobal(Offset.zero);
    setState(() {
      _searchBarBottom = position.dy + box.size.height + 4;
    });
  }
});
  }

  Future<void> getontheload() async {
    productStream = DatabaseMethods().getFlashSaleProducts();
    setState(() {});
  }
  Future<void> _onSearchChanged(String query) async {
    setState(() => searchQuery = query);

    if (query.trim().isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
        isLoadingSearch = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
      isLoadingSearch = true;
    });

    try {
      final productsSnap =
          await FirebaseFirestore.instance.collection("Products").get();
      final flashSnap =
          await FirebaseFirestore.instance.collection("FlashSale").get();

      final lowerQuery = query.toLowerCase();

      final matchedFlash = flashSnap.docs.where((doc) {
        final data = doc.data();
        final name = (data['Name'] ?? '').toString().toLowerCase();
        final category = (data['Category'] ?? '').toString().toLowerCase();
        return name.contains(lowerQuery) || category.contains(lowerQuery);
      }).toList();

      final matchedProducts = productsSnap.docs.where((doc) {
        final data = doc.data();
        final name = (data['Name'] ?? '').toString().toLowerCase();
        final category = (data['Category'] ?? '').toString().toLowerCase();
        return name.contains(lowerQuery) || category.contains(lowerQuery);
      }).toList();

      setState(() {
        searchResults = [...matchedFlash, ...matchedProducts];
        isLoadingSearch = false;
      });
    } catch (e) {
      setState(() => isLoadingSearch = false);
    }
  }

  void _clearSearch() {
    searchController.clear();
    setState(() {
      searchQuery = "";
      isSearching = false;
      searchResults = [];
    });
  }

  bool _isFlashDoc(DocumentSnapshot doc) =>
      doc.reference.parent.id == "FlashSale";

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => address = "Location services are disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => address = "Location permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => address = "Location permanently denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks.first;
      setState(() {
        address =
            "${place.locality ?? place.subLocality ?? place.administrativeArea}, ${place.country}";
      });
    } catch (e) {
      setState(() => address = "Error getting location");
    }
  }

  Widget allProduct() {
    return StreamBuilder(
      stream: productStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 165 / 180,
                ),
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            image: ds["Image"],
                            name: ds["Name"],
                            price: ds["Price"],
                            detail: ds["Detail"] ?? "",
                            originalPrice: ds["OriginalPrice"] ?? "",
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            ds["Image"],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 180,
                              color: Colors.grey.shade100,
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: EdgeInsets.all(5),
                                height: 60,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(83, 0, 0, 0),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ds["Name"],
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        if (ds["OriginalPrice"] != null &&
                                            ds["OriginalPrice"]
                                                .toString()
                                                .isNotEmpty)
                                          Text(
                                            "₹${ds["OriginalPrice"]} ",
                                            style: GoogleFonts.lato(
                                              color: Colors.white60,
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w500,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor: Colors.white60,
                                            ),
                                          ),
                                        Text(
                                          "₹${ds["Price"]}",
                                          style: GoogleFonts.lato(
                                            color: Colors.white,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        if (ds["OriginalPrice"] != null &&
                                            ds["OriginalPrice"]
                                                .toString()
                                                .isNotEmpty)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              "${(((int.tryParse(ds["OriginalPrice"].toString()) ?? 0) - (int.tryParse(ds["Price"].toString()) ?? 0)) / (int.tryParse(ds["OriginalPrice"].toString()) ?? 1) * 100).toStringAsFixed(0)}% OFF",
                                              style: GoogleFonts.lato(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
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
                      ],
                    ),
                  );
                },
              )
            : Container();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff9f6f3),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.only(top: 46.0, left: 16.0, right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Location",
                    style: GoogleFonts.lato(
                      color: const Color.fromARGB(136, 0, 0, 0),
                      fontWeight: FontWeight.w400,
                      fontSize: 14.0,
                    ),
                  ),
                  SizedBox(height: 1.0),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Color(0xff6e5038), size: 21.0),
                      Expanded(
                        child: Text(
                          address,
                          style: GoogleFonts.lato(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.0),
                  Container(
                    key: _searchKey,  
                    padding: EdgeInsets.only(left: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color.fromARGB(86, 0, 0, 0),
                        width: 1.1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            style: GoogleFonts.lato(fontSize: 15),
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Search Clothings...",
                              hintStyle: GoogleFonts.lato(fontSize: 15),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? GestureDetector(
                                      onTap: _clearSearch,
                                      child: Icon(Icons.close,
                                          color: Colors.grey, size: 18),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          height: 48,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xff6e5038),
                            borderRadius: BorderRadius.only(topRight: Radius.circular(9), bottomRight: Radius.circular(9))
                          ),
                          child:
                              Icon(Icons.search, color: Colors.white, size: 25),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 18.0),

                  Image.asset("images/banner.png"),
                  SizedBox(height: 6.0),

                  Text(
                    "Category",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _categoryItem(
                          label: "T-shirt",
                          imagePath: "images/t-shirt.png",
                          category: "T-Shirt"),
                      _categoryItem(
                          label: "Pant",
                          imagePath: "images/jeans.png",
                          category: "Pants"),
                      _categoryItem(
                          label: "Dress",
                          imagePath: "images/dress.png",
                          category: "Dress"),
                      _categoryItem(
                          label: "Jacket",
                          imagePath: "images/jacket.png",
                          category: "Jacket"),
                    ],
                  ),

                  SizedBox(height: 30.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flash_on, color: Colors.red, size: 20),
                          SizedBox(width: 4),
                          Text(
                            "Flash Sale",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FlashSaleAllPage(),
                            ),
                          );
                        },
                        child: Text(
                          "See All",
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: Color(0xff6e5038),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  allProduct(),
                  SizedBox(height: 20.0),
                ],
              ),
            ),
          ),

          if (isSearching)
            Positioned.fill(
              child: GestureDetector(
                onTap: _clearSearch,
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),
          if (isSearching)
            Positioned(
              top: _searchBarBottom,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoadingSearch
                      ? Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xff6e5038)),
                          ),
                        )
                      : searchResults.isEmpty
                          ? Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 40, color: Colors.grey.shade400),
                                    SizedBox(height: 8),
                                    Text(
                                      "No results for \"$searchQuery\"",
                                      style: GoogleFonts.lato(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(14, 12, 14, 6),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${searchResults.length} results",
                                        style: GoogleFonts.lato(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _clearSearch,
                                        child: Text(
                                          "Close",
                                          style: GoogleFonts.lato(
                                            fontSize: 12,
                                            color: Color(0xff6e5038),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(height: 1, color: Colors.grey.shade200),
                                Flexible(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    itemCount: searchResults.length,
                                    separatorBuilder: (_, _) => Divider(
                                        height: 1,
                                        color: Colors.grey.shade100),
                                    itemBuilder: (context, index) {
                                      return _searchSuggestionItem(
                                          searchResults[index]);
                                    },
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _searchSuggestionItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isFlash = _isFlashDoc(doc);
    final int originalPrice =
        int.tryParse(data['OriginalPrice']?.toString() ?? '0') ?? 0;
    final int salePrice =
        int.tryParse(data['Price']?.toString() ?? '0') ?? 0;
    final int discount = originalPrice > 0
        ? (((originalPrice - salePrice) / originalPrice) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () {
        _clearSearch();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(
              image: data['Image'] ?? '',
              name: data['Name'] ?? '',
              price: data['Price']?.toString() ?? '0',
              detail: data['Detail'] ?? '',
              originalPrice: data['OriginalPrice']?.toString() ?? '',
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: Colors.transparent,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: data['Image'] != null && data['Image'].toString().isNotEmpty
                  ? Image.network(
                      data['Image'],
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 50,
                        width: 50,
                        color: Colors.grey.shade100,
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 20),
                      ),
                    )
                  : Container(
                      height: 50,
                      width: 50,
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image, color: Colors.grey, size: 20),
                    ),
            ),

            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['Name'] ?? '',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFlash)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            "🔥 Sale",
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      if (originalPrice > 0)
                        Text(
                          "₹$originalPrice  ",
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        "₹${data['Price']}",
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isFlash
                              ? Colors.deepOrange
                              : Color(0xff6e5038),
                        ),
                      ),
                      if (discount > 0) ...[
                        SizedBox(width: 6),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "$discount% OFF",
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  Widget _categoryItem({
    required String label,
    required String imagePath,
    required String category,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Shopping(initialCategory: category),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 222, 216, 210),
              borderRadius: BorderRadius.circular(56),
            ),
            child: Image.asset(
              imagePath,
              height: 40,
              width: 40,
              fit: BoxFit.cover,
              color: Color(0xff6e5038),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}