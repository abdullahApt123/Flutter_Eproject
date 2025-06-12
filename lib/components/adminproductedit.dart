import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProductEditPage extends StatefulWidget {
  final String productId;

  ProductEditPage({required this.productId});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<ProductEditPage> {
  List<String> _existingImageBase64 = [];
  List<String?> _newImageBase64 = [];
  final picker = ImagePicker();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _detailsController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();
  var selectedCategory;
  var selectedBrand;


  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  void _fetchProductDetails() {
    FirebaseFirestore.instance
        .collection('Products')
        .doc(widget.productId)
        .get()
        .then((docSnapshot) {
      if (docSnapshot.exists) {
        setState(() {
          _nameController.text = docSnapshot['productName'];
          _priceController.text = docSnapshot['productPrice'].toString();
          _detailsController.text = docSnapshot['productDetails'];
          selectedCategory = docSnapshot['category'];
           selectedBrand = docSnapshot['brand'];
           _quantityController.text = docSnapshot['quantity'].toString();
          _existingImageBase64 = List<String>.from(docSnapshot['images']);
          _newImageBase64 =
              List<String?>.filled(_existingImageBase64.length, null);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Background image
      Positioned.fill(
        child: Image.asset(
          'assets/decentbabs.jpg',
          fit: BoxFit.cover,
        ),
      ),
      // Blur effect
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
          child: Container(color: Colors.black.withOpacity(0.2)),
        ),
      ),

      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Center(child: Text("Edit Product")),
          backgroundColor: const Color.fromARGB(255, 9, 99, 156),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Product Name'),
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Product Price'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _detailsController,
                  decoration: InputDecoration(labelText: 'Product Details'),
                  maxLines: 3,
                ),
                SizedBox(height: 16.0),
Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
SizedBox(height: 8.0),
_buildCategoryDropdown(),

                SizedBox(height: 16.0),
                Text("Brands", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
SizedBox(height: 8.0),
_buildBrandDropdown(),
SizedBox(height: 16.0),
TextFormField(
  controller: _quantityController,
  decoration: InputDecoration(labelText: 'Quantity'),
  keyboardType: TextInputType.number,
),

                SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImageBase64.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _pickImages(index),
                              child: Container(
                                margin: EdgeInsets.only(right: 8.0),
                                width: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: _newImageBase64[index] != null
                                    ? Image.memory(
                                        base64Decode(_newImageBase64[index]!),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.memory(
                                        base64Decode(
                                            _existingImageBase64[index]),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _updateProduct,
                  
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 9, 99, 156),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Product',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    ]);
  }

  Widget _buildCategoryDropdown() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categ').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Loading...", style: TextStyle(color: Colors.white)),
            );
          }

          List<DropdownMenuItem> categoryItems = snapshot.data!.docs.map((doc) {
            return DropdownMenuItem(
              value: doc['name'],
              child: Text(doc['name'], style: TextStyle(color: Colors.white)),
            );
          }).toList();

          return DropdownButtonHideUnderline(
            child: DropdownButton(
              dropdownColor: const Color.fromARGB(255, 9, 99, 156),
              value: selectedCategory,
              items: categoryItems,
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              icon: Icon(Icons.arrow_drop_down, color: Colors.black),
              isExpanded: true,
            ),
          );
        },
      ),
    );
  }

   Widget _buildBrandDropdown() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('brand').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Loading...", style: TextStyle(color: Colors.white)),
            );
          }

          List<DropdownMenuItem> brandItens = snapshot.data!.docs.map((doc) {
            return DropdownMenuItem(
              value: doc['name'],
              child: Text(doc['name'], style: TextStyle(color: Colors.white)),
            );
          }).toList();

          return DropdownButtonHideUnderline(
            child: DropdownButton(
              dropdownColor: const Color.fromARGB(255, 9, 99, 156),
              value: selectedBrand,
              items: brandItens,
              onChanged: (value) {
                setState(() {
                  selectedBrand = value;
                });
              },
              icon: Icon(Icons.arrow_drop_down, color: Colors.black),
              isExpanded: true,
            ),
          );
        },
      ),
    );
  }



  Future<void> _updateProduct() async {
    List<String> updatedImageBase64 = [];

    for (int i = 0; i < _newImageBase64.length; i++) {
      if (_newImageBase64[i] != null) {
        updatedImageBase64.add(_newImageBase64[i]!);
      } else {
        updatedImageBase64.add(_existingImageBase64[i]);
      }
    }

    int productPrice = int.tryParse(_priceController.text) ?? 0;

    await FirebaseFirestore.instance
        .collection('Products')
        .doc(widget.productId)
        .update({
      'productName': _nameController.text,
      'productPrice': productPrice,
      'productDetails': _detailsController.text,
      'category': selectedCategory,
      'brand': selectedBrand,
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'images': updatedImageBase64,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product Updated Successfully!')),
    );
  }

  Future<void> _pickImages(int index) async {
    final List<XFile>? pickedFiles =
        await picker.pickMultiImage(imageQuality: 50);

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      Uint8List bytes = await pickedFiles[0].readAsBytes(); // Only first image
      String base64String = base64Encode(bytes);

      setState(() {
        _newImageBase64[index] = base64String;
      });
    }
  }
}
