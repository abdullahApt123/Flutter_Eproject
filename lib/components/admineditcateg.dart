import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class CategoryEditPage extends StatefulWidget {
  final String categoryId;

  const CategoryEditPage({required this.categoryId});

  @override
  _CategoryEditPageState createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategoryDetails();
  }

  void _fetchCategoryDetails() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('categ')
        .doc(widget.categoryId)
        .get();

    if (docSnapshot.exists) {
      setState(() {
        _nameController.text = docSnapshot['name'];
      });
    }
  }

  Future<void> _updateCategory() async {
    await FirebaseFirestore.instance
        .collection('categ')
        .doc(widget.categoryId)
        .update({
      'name': _nameController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category Updated Successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/decentbabs.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // Blur Effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Center(child: Text("Edit Category")),
            backgroundColor: const Color.fromARGB(255, 9, 99, 156),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _updateCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 9, 99, 156),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Update Category',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
