import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductDetailPage({super.key, required this.product});

  Future<DocumentSnapshot?> getFirstProduct() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Products')
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F9),
      body: Stack(
        children: [
          ProductDetailView(
            productId: product['id'] ?? '',
            productData: product,
          ),
          FutureBuilder<DocumentSnapshot?>(
            future: getFirstProduct(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                return const Center(child: Text('No product found.'));
              }

              final productDoc = snapshot.data!;
              final productId = productDoc.id;
              final productData = productDoc.data() as Map<String, dynamic>;

              return ProductDetailView(
                productId: productId,
                productData: productData,
              );
            },
          ),
          Positioned(
            top: 40,
            left: 16,
            child: ClipOval(
              child: Material(
                color: Colors.white.withOpacity(0.9),
                child: InkWell(
                  splashColor: Colors.grey,
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailView extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ProductDetailView({
    super.key,
    required this.productId,
    required this.productData,
  });

  Future<void> addToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add items to cart')),
      );
      return;
    }

    final userEmail = user.email!;
    final cartRef = FirebaseFirestore.instance
        .collection('Cart')
        .doc(userEmail)
        .collection('items')
        .doc(productId);

    try {
      final docSnapshot = await cartRef.get();
      if (docSnapshot.exists) {
        await cartRef.update({'quantity': FieldValue.increment(1)});
      } else {
        final imageString = (productData['images'] != null &&
                             productData['images'].isNotEmpty &&
                             productData['images'][0] is String)
            ? productData['images'][0]
            : '';

        await cartRef.set({
          'productId': productId,
          'productName': productData['productName'] ?? '',
          'subtitle': productData['subtitle'] ?? '',
          'productPrice': productData['productPrice'] ?? 0,
          'image': imageString,
          'quantity': 1,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added to cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName = productData['productName'] ?? 'Product Name';
    final productPrice = productData['productPrice'] ?? 0;
    final productDetails = productData['productDetails'] ?? 'No details available';

    final productImageBase64 = (productData['images'] != null &&
                                 productData['images'].isNotEmpty &&
                                 productData['images'][0] is String)
        ? productData['images'][0]
        : '';

    Uint8List? imageBytes;
    try {
      if (productImageBase64.isNotEmpty) {
        imageBytes = base64Decode(productImageBase64);
      }
    } catch (e) {
      imageBytes = null;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.image_not_supported, size: 100),
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFFF5F5DC),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  productDetails,
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$$productPrice',
                  style: const TextStyle(fontSize: 20, color: Colors.green),
                ),
                const SizedBox(height: 24),
                DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.black,
                        tabs: [
                          Tab(text: 'Overview'),
                          Tab(text: 'Reviews'),
                        ],
                      ),
                      SizedBox(
                        height: 200,
                        child: TabBarView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                productDetails,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text(
                                'No reviews yet.',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () => addToCart(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE0D9BA),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add to Cart', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
