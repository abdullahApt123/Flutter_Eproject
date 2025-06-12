import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'adminaddbrand.dart';
import 'adminbrandedit.dart';

class ShowBrands extends StatefulWidget {
  const ShowBrands({Key? key}) : super(key: key);

  @override
  _ShowBrandsState createState() => _ShowBrandsState();
}

class _ShowBrandsState extends State<ShowBrands> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/auth2.png',
            fit: BoxFit.cover,
          ),
        ),
       
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Center(child: Text("Brands")),
            backgroundColor: const Color.fromARGB(255, 9, 99, 156),
            elevation: 0,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('brand').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                List<DocumentSnapshot> brands = snapshot.data!.docs;
                if (brands.isEmpty) {
                  return const Center(child: Text("No brands found", style: TextStyle(color: Colors.white)));
                }
                return ListView.builder(
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        _buildBrandTile(brands[index]),
                        const Divider(color: Colors.white54, thickness: 0.5, indent: 16, endIndent: 16),
                      ],
                    );
                  },
                );
              }
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddBrand()));
            },
            tooltip: 'Add Brand',
            child: const Icon(Icons.add),
            backgroundColor: const Color.fromARGB(255, 9, 99, 156),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        ),
      ],
    );
  }

Widget _buildBrandTile(DocumentSnapshot brandSnapshot) {
  Map<String, dynamic> brand = brandSnapshot.data() as Map<String, dynamic>;

  Uint8List? imageBytes;
  if (brand['image'] != null && brand['image'] is String) {
    String imageStr = brand['image'];
    if (imageStr.contains(',')) {
      imageStr = imageStr.split(',').last;
    }
    imageBytes = base64Decode(imageStr);
  }

  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
    tileColor: Colors.white.withOpacity(0.1),
    leading: SizedBox(
      width: 100,
      height: 100,
      child: imageBytes != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.memory(imageBytes, fit: BoxFit.cover),
            )
          : const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
    ),
    title: Text(
      brand['name'] ?? 'No Name',
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.black87),
          tooltip: "Edit",
          onPressed: () {
           String brandId = brandSnapshot.id;
              if (brandId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BrandEdit(brandId: brandId),
                  ),
                );
              }
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: "Delete",
          onPressed: () async {
            await FirebaseFirestore.instance.collection('Brands').doc(brandSnapshot.id).delete();
          },
        ),
      ],
    ),
  );
}

}
