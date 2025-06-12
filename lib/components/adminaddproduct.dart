import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//  Colors.teal

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AddPage(),
    );
  }
}

class AddPage extends StatefulWidget {
  const AddPage({super.key});
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  List<XFile>? _images;
  List<Uint8List>? _imageBytes = [];
  final picker = ImagePicker();
  TextEditingController textController1 = TextEditingController();
  TextEditingController textController2 = TextEditingController();
  TextEditingController textController3 = TextEditingController();
  TextEditingController textController4 = TextEditingController();
  var selectedCurrency;
  var selectedBrand;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            'assets/auth2.png', // Put your background image in assets folder
            fit: BoxFit.cover,
          ),
        ),
        // Blur effect
      
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Center(child: Text("Add Product")),
            backgroundColor: const Color.fromARGB(255, 9, 99, 156),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildStyledTextField(textController1, 'Product Name'),
                SizedBox(height: 16),
                _buildStyledTextField(textController2, 'Product Price',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                SizedBox(height: 16),
                _buildStyledTextField(textController3, 'Product Details',
                    maxLines: 3),
                SizedBox(height: 16),
                _buildDropdown(),
                SizedBox(height: 16),
                _buildBrandsDropdown(),
                SizedBox(height: 16),
                _buildStyledTextField(
                  textController4,
                  'Product Quantities',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                SizedBox(height: 20),
                _buildImagePicker(),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _imageBytes != null && _imageBytes!.isNotEmpty
                        ? _addProduct
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 9, 99, 156),
                      // padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Add Product',
                        style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color.fromARGB(255, 3, 82, 130)),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categ').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Text("Loading...",
                style: TextStyle(color: Colors.white));

          List<DropdownMenuItem> items = snapshot.data!.docs.map((doc) {
            return DropdownMenuItem(
              value: doc['name'],
              child: Text(doc['name'], style: TextStyle(color: Colors.white)),
            );
          }).toList();

          return DropdownButtonHideUnderline(
            child: DropdownButton(
              dropdownColor: const Color.fromARGB(255, 9, 99, 156),
              value: selectedCurrency,
              items: items,
              onChanged: (value) {
                setState(() {
                  selectedCurrency = value;
                });
              },
              hint: Center(
                  child: Text("Choose Category",
                      style: TextStyle(color: Colors.black))),
              icon: Icon(Icons.arrow_drop_down, color: Colors.black),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandsDropdown() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('brand').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Loading...", style: TextStyle(color: Colors.white)),
            );
          }

          List<DropdownMenuItem> brandItems = snapshot.data!.docs.map((doc) {
            return DropdownMenuItem(
              value: doc['name'],
              child: Text(doc['name'], style: TextStyle(color: Colors.white)),
            );
          }).toList();

          return DropdownButtonHideUnderline(
            child: DropdownButton(
              dropdownColor: const Color.fromARGB(255, 9, 99, 156),
              value: selectedBrand,
              items: brandItems,
              onChanged: (value) {
                setState(() {
                  selectedBrand = value;
                });
              },
              hint: Center(
                  child: Text("Choose Brand",
                      style: TextStyle(color: Colors.black))),
              icon: Icon(Icons.arrow_drop_down, color: Colors.black),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        child: _imageBytes != null && _imageBytes!.isNotEmpty
            ? ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageBytes!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _imageBytes![index],
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Icon(Icons.add_a_photo, color: Colors.white60, size: 40),
              ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final pickedFiles = await picker.pickMultiImage(imageQuality: 50);
    if (pickedFiles != null) {
      List<Uint8List> bytesList = [];
      for (var file in pickedFiles) {
        Uint8List bytes = await file.readAsBytes();
        bytesList.add(bytes);
      }
      setState(() {
        _images = pickedFiles;
        _imageBytes = bytesList;
      });
    }
  }

  Future<List<String>> convertImagesToBase64(List<Uint8List> images) async {
    return images.map((bytes) => base64Encode(bytes)).toList();
  }

  Future<void> _addProduct() async {
    if (_images == null || _images!.isEmpty) return;

    List<String> base64Images = await convertImagesToBase64(_imageBytes!);
    String productName = textController1.text;
    int productPrice = int.tryParse(textController2.text) ?? 0;
    String productDetails = textController3.text;
    int quantity = int.tryParse(textController4.text) ?? 0;

    await FirebaseFirestore.instance.collection('Products').add({
      'productName': productName,
      'productPrice': productPrice,
      'productDetails': productDetails,
      'category': selectedCurrency,
      'brand': selectedBrand,
      'quantity': quantity,
      'images': base64Images,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product added successfully with images!')),
    );
  }
}
