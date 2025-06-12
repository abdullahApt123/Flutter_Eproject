import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:babyhubshop/components/admincategory.dart';
import 'package:babyhubshop/components/admineditcateg.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShowCategories extends StatefulWidget {
  const ShowCategories({Key? key}) : super(key: key);

  @override
  _ShowCategoriesState createState() => _ShowCategoriesState();
}

class _ShowCategoriesState extends State<ShowCategories> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
            title: const Center(child: Text("Categories")),
            backgroundColor: const Color.fromARGB(255, 9, 99, 156),
            elevation: 0,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('categ').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                List<DocumentSnapshot> categories = snapshot.data!.docs;
                if (categories.isEmpty) {
                  return const Center(child: Text("No categories found", style: TextStyle(color: Colors.white)));
                }
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        _buildCategoryTile(categories[index]),
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddCategoryPage()));
            },
            tooltip: 'Add Category',
            child: Icon(Icons.add),
            backgroundColor: const Color.fromARGB(255, 9, 99, 156),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        ),
      ],
    );
  }

  Widget _buildCategoryTile(DocumentSnapshot categorySnapshot) {
    Map<String, dynamic> category = categorySnapshot.data() as Map<String, dynamic>;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      tileColor: Colors.white.withOpacity(0.1),
      leading: const Icon(Icons.category, color: Colors.white, size: 50),
      title: Text(
        category['name'] ?? 'No Name',
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            tooltip: "Edit",
            onPressed: () {
           String categoryId = categorySnapshot.id;
              if (categoryId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryEditPage(categoryId: categoryId),
                  ),
                );
              }
          },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: "Delete",
            onPressed: () async {
              await FirebaseFirestore.instance.collection('Categories').doc(categorySnapshot.id).delete();
            },
          ),
        ],
      ),
    );
  }
}
