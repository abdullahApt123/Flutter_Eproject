import 'dart:convert';
import 'package:babyhubshop/ProductDetail.dart';
import 'package:babyhubshop/Search.dart';
import 'package:babyhubshop/SignIn.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Homescreen extends StatefulWidget {
  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  Future<void> _addToCart(Map<String, dynamic> product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please login to add items to cart")),
        );
        return;
      }

      final name = product['productName'] ?? 'Unknown';
      final subtitle = product['subtitle'] ?? '';
      final price = product['productPrice'] ?? 0;
      final imageList = product['images'];
      final image = imageList is List && imageList.isNotEmpty ? imageList[0] : '';

      final cartItem = {
        'name': name,
        'description': subtitle,
        'price': price,
        'quantity': 1,
        'image': image,
      };

      final cartDocRef = FirebaseFirestore.instance.collection('Cart').doc(user.email);

      await cartDocRef.set({
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final itemsRef = cartDocRef.collection('items');
      final existing = await itemsRef.where('name', isEqualTo: cartItem['name']).limit(1).get();

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update({
          'quantity': FieldValue.increment(1),
        });
      } else {
        await itemsRef.add(cartItem);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name added to cart')),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart')),
      );
    }
  }

  int currentPage = 0;
  Map<String, bool> wishlistStatus = {};
  User? currentUser = FirebaseAuth.instance.currentUser;
  String productIdForGreenBorder = '';

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Logout Button
            Container(
              color: Color(0xFFF5F5DC),
              padding: EdgeInsets.fromLTRB(20, 60, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Find the best\noutfit for you.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                 IconButton(
  icon: const Icon(Icons.logout, size: 20, color: Colors.black),
  onPressed: () {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignIn()),
    );
  },
  tooltip: 'Logout',
),
                ],
              ),
            ),

// Carousel Section
    Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      color: Color(0xFFF5F5DC),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 170,
          autoPlay: true,
          enlargeCenterPage: true,
        ),
        items: [
          'assets/image1.jpg',
          'assets/image2.jpg',
          'assets/image3.jpg',
        ].map((imagePath) {
          return Builder(
               builder: (BuildContext context) {
          return Container(
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.symmetric(horizontal: 5.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8), // Rounded corners
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
          );
        }).toList(),
      ),
    ),
 SizedBox(height: 10),


            // Category Section
            Container(
              padding: EdgeInsets.all(15),
              color: Color(0xFFD8D4B8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Category",
                      style: TextStyle(color: Colors.black, fontSize: 16)),
                ],
              ),
            ),
            Container(
              color: Color(0xFFD8D4B8),
              height: 80,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categ').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Colors.black87));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No categories", style: TextStyle(color: Colors.black87)));
                  }
                  final categories = snapshot.data!.docs;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final name = category['name'] ?? 'Unknown';
                      return _buildCategoryItem(name);
                    },
                  );
                },
              ),
            ),

            // View More Button
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
              child: Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductsearchPage()),
                    );
                  },
                  child: Text(
                    "View More",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),

            // Products Grid - Now properly constrained
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No products found"));
                }

                final products = snapshot.data!.docs;
                
                return Container(
                  height: MediaQuery.of(context).size.height * 0.7, // Constrained height
                  padding: EdgeInsets.all(15),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.65,
                    ),
                    itemBuilder: (context, index) {
                      final doc = products[index];
                      final product = doc.data() as Map<String, dynamic>;
                      final productId = doc.id;
                      final quantity = product['quantity'] ?? 0;
                      final base64Images = List<String>.from(product['images'] ?? []);
                      final decodedImages = base64Images.map((img) => base64Decode(img)).toList();

                      if (!wishlistStatus.containsKey(productId)) {
                        wishlistStatus[productId] = false;
                      }

                      return StatefulBuilder(
                        builder: (context, setState) {
                          bool showGreenBorder = false;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailPage(product: product),
                                ),
                              );
                            },
                            child: Container(
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
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                                                  builder: (_) => ProductDetailPage(product: product),
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
                                              _addToCart(product);
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
                                                  await addToWishlist(productId, product);
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
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Chip(
        label: Text(name),
        backgroundColor: Colors.white,
        shape: StadiumBorder(side: BorderSide(color: Colors.black87)),
      ),
    );
  }

  Future<void> addToWishlist(String productId, Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final wishlistRef = FirebaseFirestore.instance
        .collection('wishlist')
        .doc(user.email)
        .collection('items');
    await wishlistRef.doc(productId).set(product);
  }

  Future<void> removeFromWishlist(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final wishlistRef = FirebaseFirestore.instance
        .collection('wishlist')
        .doc(user.email)
        .collection('items');
    await wishlistRef.doc(productId).delete();
  }
}