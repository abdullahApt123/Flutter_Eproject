import 'dart:convert';
import 'dart:typed_data';
import 'package:babyhubshop/ProductDetail.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProductsearchPage(),
    );
  }
}

class ProductsearchPage extends StatefulWidget {
  const ProductsearchPage({Key? key}) : super(key: key);

  @override
  _ProductsearchPageState createState() => _ProductsearchPageState();
}

class _ProductsearchPageState extends State<ProductsearchPage> {
  @override
  void initState() {
    super.initState();
    loadWishlistStatus().then((_) {
      setState(() {}); 
    });
  }
  
  int currentPage = 0;
  Map<String, bool> wishlistStatus = {};
  User? currentUser = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';
  Set<String> selectedCategories = {};
  Set<String> selectedBrands = {};

  Stream<List<String>> getCategoryStream() {
    return FirebaseFirestore.instance.collection('categ').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => doc['name'].toString()).toList());
  }

  Stream<List<String>> getBrandStream() {
    return FirebaseFirestore.instance.collection('brand').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => doc['name'].toString()).toList());
  }

  List<Uint8List> _decodeBase64Images(List<String> base64Images) {
    return base64Images
        .map((base64Image) => base64Decode(base64Image))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Added background color
      appBar: AppBar(
        backgroundColor:  Color(0xFFF5F5DC),
              title: Text(
              "Search",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                backgroundColor:  Color(0xFFF5F5DC)
              ),
                            ),
       ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: "Filter",
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: const Color.fromARGB(255, 239, 238, 238),
                            elevation: 5,
                            child: Container(
                              width: 250,
                              height: double.infinity,
                              padding: const EdgeInsets.all(12),
                              child: ListView(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text("Filter",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      CloseButton(),
                                    ],
                                  ),
                                  const Divider(),
                                  const Text('CATEGORY',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  StreamBuilder<List<String>>(
                                    stream: getCategoryStream(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const CircularProgressIndicator();
                                      }
                                      final categories = snapshot.data!;
                                      return Column(
                                        children: categories.map((category) {
                                          return CheckboxListTile(
                                            title: Text(category),
                                            value: selectedCategories
                                                .contains(category),
                                            onChanged: (value) {
                                              setState(() {
                                                value!
                                                    ? selectedCategories
                                                        .add(category)
                                                    : selectedCategories
                                                        .remove(category);
                                              });
                                              Navigator.pop(
                                                  context); // close filter dialog
                                            },
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                  const Divider(),
                                  const Text('BRAND',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  StreamBuilder<List<String>>(
                                    stream: getBrandStream(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const CircularProgressIndicator();
                                      }
                                      final brands = snapshot.data!;
                                      return Column(
                                        children: brands.map((brand) {
                                          return CheckboxListTile(
                                            title: Text(brand),
                                            value: selectedBrands
                                                .contains(brand),
                                            onChanged: (value) {
                                              setState(() {
                                                value!
                                                    ? selectedBrands
                                                        .add(brand)
                                                    : selectedBrands
                                                        .remove(brand);
                                              });
                                              Navigator.pop(context);
                                            },
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Products')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text('Error: ${snapshot.error}'));
                      }

                      List<DocumentSnapshot> products = snapshot.data!.docs;

                      List<DocumentSnapshot> filteredProducts =
                          products.where((product) {
                        final data = product.data() as Map<String, dynamic>;
                        final name = (data['productName'] ?? '')
                            .toString()
                            .toLowerCase();
                        final desc = (data['productDetails'] ?? '')
                            .toString()
                            .toLowerCase();
                        final price = (data['productPrice'] ?? '')
                            .toString()
                            .toLowerCase();
                        final category = data['category'] ?? '';
                        final brand = data['brand'] ?? '';

                        final matchesSearch = name.contains(_searchQuery) ||
                            desc.contains(_searchQuery) ||
                            price.contains(_searchQuery);
                        final matchesCategory = selectedCategories.isEmpty ||
                            selectedCategories.contains(category);
                        final matchesBrand = selectedBrands.isEmpty ||
                            selectedBrands.contains(brand);

                        return matchesSearch &&
                            matchesCategory &&
                            matchesBrand;
                      }).toList();

                      if (filteredProducts.isEmpty) {
                        return const Center(
                            child: Text('No products found.'));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 250,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(filteredProducts[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> addToWishlist(DocumentSnapshot product) async {
    CollectionReference wishlistCollection =
        FirebaseFirestore.instance.collection('wishlist');

    QuerySnapshot existingProducts = await wishlistCollection
        .where('userId', isEqualTo: currentUser?.uid)
        .where('productId', isEqualTo: product.id)
        .get();

    if (existingProducts.docs.isEmpty) {
      await wishlistCollection.add({
        'productName': product['productName'],
        'productPrice': product['productPrice'],
        'productDetails': product['productDetails'],
        'userId': currentUser?.uid,
        'productId': product.id,
        'image': product['images'][0],
      });
    }
  }

  Future<void> removeFromWishlist(String productid) async {
    CollectionReference wishlistCollection =
        FirebaseFirestore.instance.collection('wishlist');

    QuerySnapshot wishlistSnapshot = await wishlistCollection
        .where('userId', isEqualTo: currentUser?.uid)
        .where('productId', isEqualTo: productid)
        .get();

    wishlistSnapshot.docs.forEach((doc) {
      wishlistCollection.doc(doc.id).delete();
    });
  }

  Future<void> loadWishlistStatus() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      print("User not logged in.");
      return;
    }

    final userWishlist = await FirebaseFirestore.instance
        .collection('wishlist')
        .where('userId', isEqualTo: currentUserId)
        .get();

    for (var doc in userWishlist.docs) {
      final productId = doc['productId'];
      wishlistStatus[productId] = true;
    }
  }

  Widget _buildProductCard(DocumentSnapshot snapshot) {
    final product = snapshot.data() as Map<String, dynamic>;
    final base64Images = List<String>.from(product['images'] ?? []);
    final decodedImages = _decodeBase64Images(base64Images);

    bool showGreenBorder = false;

    String productId = snapshot.id;
    if (!wishlistStatus.containsKey(productId)) {
      wishlistStatus[productId] = false;
    }
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            // Navigate to product details or any action
          },
          child: Container(
            width: 150,
            height: 280,
            child: Stack(
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CarouselSlider(
                          options: CarouselOptions(
                            viewportFraction: 1.0,
                            height: 160,
                            autoPlay: true,
                          ),
                          items: decodedImages.map((bytes) {
                            return Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product['productName'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Price: \$${product['productPrice']}',
                          style: const TextStyle(color: Colors.green, fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(product: {},),
                              ),
                            );
                          },
                          child: Text(
                            'Product Details: ... ',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color.fromARGB(255, 12, 80, 136),
                        child: IconButton(
                          icon: const Icon(Icons.shopping_cart, color: Colors.white),
                          tooltip: 'Add to Cart',
                          onPressed: () {
                            // Add to cart logic
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: showGreenBorder ? Colors.green : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color.fromARGB(255, 197, 30, 30),
                          child: IconButton(
                            icon: Icon(
                              wishlistStatus[productId] == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: wishlistStatus[productId] == true
                                  ? Colors.red
                                  : Colors.white,
                            ),
                            tooltip: 'Add to Wishlist',
                            onPressed: () async {
                              int quantity = snapshot['quantity'] ?? 0;

                              if (quantity <= 0) {
                                setState(() {
                                  showGreenBorder = true;
                                });

                                await Future.delayed(Duration(seconds: 1));
                                setState(() {
                                  showGreenBorder = false;
                                });
                                return;
                              }

                              final isInWishlist = wishlistStatus[productId] ?? false;

                              setState(() {
                                wishlistStatus[productId] = !isInWishlist;
                              });

                              if (!isInWishlist) {
                                await addToWishlist(snapshot);
                              } else {
                                await removeFromWishlist(productId);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}