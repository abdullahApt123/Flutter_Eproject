import 'dart:convert';
import 'dart:ui';
import 'package:babyhubshop/Search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductListwish extends StatefulWidget {
  const ProductListwish({super.key});

  @override
  _ProductListViewState createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListwish> {
  int currentPage = 0;
  final CollectionReference wishlist =
      FirebaseFirestore.instance.collection('wishlist');

  FirebaseAuth auth = FirebaseAuth.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;
  int totalCount = 0;

  void updateCartCount() async {
    CollectionReference cartCollection =
        FirebaseFirestore.instance.collection('cart');
    QuerySnapshot userCart =
        await cartCollection.where('uid', isEqualTo: currentUser?.uid).get();

    setState(() {
      totalCount = userCart.size;
    });
  }

  @override
  void initState() {
    super.initState();
    updateCartCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC), // Changed background color here
      appBar: AppBar(
        backgroundColor:  Color(0xFFF5F5DC),
              title: Text(
              "Wishlist",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                backgroundColor:  Color(0xFFF5F5DC)
              ),
                            ),
       ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            wishlist.where('userId', isEqualTo: currentUser?.uid).snapshots(),
        builder: (context, streamSnapshot) {
          if (!streamSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            itemCount: streamSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot product =
                  streamSnapshot.data!.docs[index];
              return ListTile(
                title: Text(product['productName']),
                subtitle: Text(
                    'Price: ${product['productPrice']},Details: ${product['productDetails']}'),
                leading: Image.memory(
                  base64Decode(product['image']),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() async {
                          var collection = FirebaseFirestore.instance
                              .collection('wishlist');
                          collection.doc(product.id).delete();
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add_shopping_cart),
                      onPressed: () async {
                        CollectionReference colref =
                            FirebaseFirestore.instance.collection('cart');

                        QuerySnapshot existingDocs = await colref
                            .where('pid', isEqualTo: product['productId'])
                            .where('uid', isEqualTo: currentUser?.uid)
                            .get();

                        if (existingDocs.docs.isNotEmpty) {
                          DocumentReference existingDocRef =
                              existingDocs.docs.first.reference;
                          int currentQty =
                              existingDocs.docs.first['qty'] ?? 0;

                          await existingDocRef.update({
                            'qty': currentQty + 1,
                            'fprice':
                                (currentQty + 1) * product['productPrice'],
                          });
                        } else {
                          await colref.add({
                            'pid': product.id,
                            'iniprice': product['productPrice'],
                            'qty': 1,
                            'fprice': product['productPrice'] * 1,
                            'uid': currentUser?.uid,
                            'image': product['images'][0],
                          });
                        }

                        setState(() {});
                        updateCartCount();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Product added to Cart successfully!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}