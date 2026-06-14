import 'package:clothing/pages/detail_page.dart';
import 'package:clothing/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Shopping extends StatefulWidget {
  final String initialCategory;
  const Shopping({super.key, this.initialCategory = "All"});

  @override
  State<Shopping> createState() => _ShoppingState();
}

class _ShoppingState extends State<Shopping> {
  String selectedCategory = "All";
  String searchQuery = "";
  TextEditingController searchController = TextEditingController();

  bool isSearching = false;
  bool isLoadingSearch = false;
  List<DocumentSnapshot> searchResults = [];
  final GlobalKey _searchKey = GlobalKey();
  double _searchBarBottom = 200;

  final List<Map<String, dynamic>> categories = [
    {"name": "All", "icon": Icons.grid_view_rounded},
    {"name": "Shirt", "icon": Icons.dry_cleaning_outlined},
    {"name": "T-Shirt", "icon": Icons.checkroom_outlined},
    {"name": "Pants", "icon": Icons.accessibility_new_outlined},
    {"name": "Jacket", "icon": Icons.layers_outlined},
    {"name": "Dress", "icon": Icons.style_outlined},
    {"name": "Flash Sale", "icon": Icons.local_fire_department_rounded},
  ];

  Stream<QuerySnapshot>? productStream;
  Stream<QuerySnapshot>? flashSaleStream;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    loadProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box =
          _searchKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final position = box.localToGlobal(Offset.zero);
        setState(() {
          _searchBarBottom = position.dy + box.size.height + 4;
        });
      }
    });
  }

  Future<void> loadProducts() async {
    final pStream = DatabaseMethods().getallProducts();
    final fStream = DatabaseMethods().getAllFlashSaleProducts();
    setState(() {
      productStream = pStream;
      flashSaleStream = fStream;
    });
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

  List<DocumentSnapshot> _filterProducts(List<DocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['Name'] ?? '').toString().toLowerCase();
      final category =
          (data['Category'] ?? '').toString().toLowerCase().trim();
      final selected = selectedCategory.toLowerCase().trim();
      final matchesCategory =
          selectedCategory == "All" || category == selected;
      final matchesSearch = searchQuery.isEmpty ||
          name.contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<DocumentSnapshot> _filterFlashSale(List<DocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['Name'] ?? '').toString().toLowerCase();
      return searchQuery.isEmpty ||
          name.contains(searchQuery.toLowerCase());
    }).toList();
  }
  Widget _buildFlashSaleGrid() {
  if (flashSaleStream == null) {
    return const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange));
  }
  return StreamBuilder<QuerySnapshot>(
    stream: flashSaleStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
            child: CircularProgressIndicator(color: Colors.deepOrange));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return _emptyState(
            "No flash sale products right now", Icons.flash_off);
      }
      final filtered = _filterFlashSale(snapshot.data!.docs);
      if (filtered.isEmpty) {
        return _emptyState("No results found", Icons.search_off);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  "${filtered.length} sale items",
                  style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text("🔥 Live",
                      style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final data =
                    filtered[index].data() as Map<String, dynamic>;
                return _flashCard(data);
              },
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildProductsGrid() {
  if (productStream == null) {
    return const Center(
        child: CircularProgressIndicator(color: Color(0xff6e5038)));
  }
  return StreamBuilder<QuerySnapshot>(
    stream: productStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
            child: CircularProgressIndicator(color: Color(0xff6e5038)));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return _emptyState(
            "No products found", Icons.shopping_bag_outlined);
      }
      final filtered = _filterProducts(snapshot.data!.docs);
      if (filtered.isEmpty) {
        return _emptyState("No results found", Icons.search_off);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              "${filtered.length} items found",
              style: GoogleFonts.lato(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final data =
                    filtered[index].data() as Map<String, dynamic>;
                return _productCard(data);
              },
            ),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final bool isFlashSale = selectedCategory == "Flash Sale";

    return Scaffold(
      backgroundColor:  Color(0xfff9f6f3),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    top: 50, left: 20, right: 20, bottom: 20),
                decoration: BoxDecoration(
                  gradient: isFlashSale
                      ? const LinearGradient(
                          colors: [Color(0xffbf360c), Color(0xffe64a19)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xff6e5038), Color(0xff8d6748)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isFlashSale)
                          const Icon(Icons.flash_on,
                              color: Colors.yellow, size: 22),
                        if (isFlashSale) const SizedBox(width: 6),
                        Text(
                          isFlashSale ? "Flash Sale" : "Shop",
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFlashSale
                          ? "Limited time deals — grab them fast!"
                          : "Find your perfect style",
                      style: GoogleFonts.lato(
                          color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      key: _searchKey,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.lato(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: isFlashSale
                              ? "Search flash sale..."
                              : "Search products...",
                          hintStyle: GoogleFonts.lato(
                              color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          icon: Icon(
                            Icons.search,
                            color: isFlashSale
                                ? Colors.deepOrange
                                : const Color(0xff6e5038),
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: _clearSearch,
                                  child: const Icon(Icons.close,
                                      color: Colors.grey, size: 18),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final bool isSelected =
                        selectedCategory == cat["name"];
                    final bool isFSChip = cat["name"] == "Flash Sale";

                    return GestureDetector(
                      onTap: () =>
                          setState(() => selectedCategory = cat["name"]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isFSChip
                                  ? Colors.deepOrange
                                  : const Color(0xff6e5038))
                              : (isFSChip
                                  ? Colors.deepOrange.withOpacity(0.08)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isFSChip
                                ? Colors.deepOrange
                                : isSelected
                                    ? const Color(0xff6e5038)
                                    : Colors.grey.shade300,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (isFSChip
                                            ? Colors.deepOrange
                                            : const Color(0xff6e5038))
                                        .withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat["icon"],
                              size: 15,
                              color: isSelected
                                  ? Colors.white
                                  : (isFSChip
                                      ? Colors.deepOrange
                                      : Colors.grey.shade700),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat["name"],
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isFSChip
                                        ? Colors.deepOrange
                                        : Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              Expanded(
                child: isFlashSale
                    ? _buildFlashSaleGrid()
                    : _buildProductsGrid(),
              ),
            ],
          ),
          if (isSearching)
            Positioned.fill(
              child: GestureDetector(
                onTap: _clearSearch,
                child:
                    Container(color: Colors.black.withOpacity(0.3)),
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
                    maxHeight:
                        MediaQuery.of(context).size.height * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoadingSearch
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: isFlashSale
                                  ? Colors.deepOrange
                                  : const Color(0xff6e5038),
                            ),
                          ),
                        )
                      : searchResults.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 40,
                                        color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
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
                                  padding: const EdgeInsets.fromLTRB(
                                      14, 12, 14, 6),
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
                                            color:
                                                const Color(0xff6e5038),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                    height: 1,
                                    color: Colors.grey.shade200),
                                Flexible(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    itemCount: searchResults.length,
                                    separatorBuilder: (_, _) => Divider(
                                        height: 1,
                                        color: Colors.grey.shade100),
                                    itemBuilder: (context, index) =>
                                        _searchSuggestionItem(
                                            searchResults[index]),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: Colors.transparent,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: data['Image'] != null &&
                      data['Image'].toString().isNotEmpty
                  ? Image.network(
                      data['Image'],
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 50,
                        width: 50,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 20),
                      ),
                    )
                  : Container(
                      height: 50,
                      width: 50,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image,
                          color: Colors.grey, size: 20),
                    ),
            ),
            const SizedBox(width: 12),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
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
                  const SizedBox(height: 3),
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
                              : const Color(0xff6e5038),
                        ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
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
            const Icon(Icons.arrow_forward_ios,
                size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _flashCard(Map<String, dynamic> data) {
    int originalPrice =
        int.tryParse(data['OriginalPrice']?.toString() ?? '0') ?? 0;
    int salePrice =
        int.tryParse(data['Price']?.toString() ?? '0') ?? 0;
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
              offset: const Offset(0, 2),
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
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: data['Image'] != null &&
                            data['Image'].toString().isNotEmpty
                        ? Image.network(
                            data['Image'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image,
                                color: Colors.grey, size: 40),
                          ),
                  ),
                  if (discountPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['Name'] ?? '',
                    style: GoogleFonts.lato(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
                          color: const Color(0xff6e5038),
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

  Widget _productCard(Map<String, dynamic> data) {
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
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: data['Image'] != null &&
                        data['Image'].toString().isNotEmpty
                    ? Image.network(
                        data['Image'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey, size: 40),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image,
                            color: Colors.grey, size: 40),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['Name'] ?? '',
                    style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(data['Category'] ?? '',
                      style: GoogleFonts.lato(
                          fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${data['Price']}",
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xff6e5038),
                        ),
                      ),
                      Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xff6e5038),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 18),
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

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                  color: Colors.grey.shade500, fontSize: 15)),
        ],
      ),
    );
  }
}