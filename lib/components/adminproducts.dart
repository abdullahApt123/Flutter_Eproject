import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'adminaddproduct.dart';
import 'adminproductedit.dart';

class ShowProducts extends StatefulWidget {
  const ShowProducts({super.key});

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ShowProducts> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image with blur
        Positioned.fill(
          child: Image.asset(
            'assets/decentbabs.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Center(child: Text("Products")),
            backgroundColor: const Color.fromARGB(255, 9, 99, 156),
            elevation: 0,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No products available'));
              }

              final products = snapshot.data!.docs;

              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      _buildProductTile(products[index]),
                      const Divider(color: Colors.white54, thickness: 0.5, indent: 16, endIndent: 16),
                    ],
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddPage()));
            },
            tooltip: 'Add Product',
            child: const Icon(Icons.add),
            backgroundColor: const Color.fromARGB(255, 9, 99, 156),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        ),
      ],
    );
  }

  Widget _buildProductTile(DocumentSnapshot productSnapshot) {
    final product = productSnapshot.data() as Map<String, dynamic>?;

    if (product == null) {
      return const ListTile(
        title: Text("Invalid product data"),
        tileColor: Colors.redAccent,
      );
    }

    final List<String> base64Images = (product['images'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        [];

    final List<Uint8List> imageBytes = base64Images
        .map((base64) => base64Decode(base64))
        .toList();

    final productName = product['productName'] ?? 'Unnamed';
    final productPrice = product['productPrice'] ?? 'N/A';
    final productDetails = product['productDetails'] ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      tileColor: Colors.white.withOpacity(0.1),
      leading: imageBytes.isNotEmpty
          ? SizedBox(
              width: 100,
              height: 100,
              child: CarouselSlider(
                options: CarouselOptions(
                  aspectRatio: 1.0,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  viewportFraction: 1.0,
                ),
                items: imageBytes.map((bytes) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.memory(bytes, fit: BoxFit.cover, width: 100, height: 100),
                  );
                }).toList(),
              ),
            )
          : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      title: Text(productName,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Price: $productPrice', style: const TextStyle(color: Colors.black45)),
          Text('Details: $productDetails', style: const TextStyle(color: Colors.black45)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            tooltip: "Edit",
            onPressed: () {
              final productId = productSnapshot.id;
              if (productId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductEditPage(productId: productId),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: "Delete",
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('Products')
                  .doc(productSnapshot.id)
                  .delete();
            },
          ),
        ],
      ),
    );
  }
}
