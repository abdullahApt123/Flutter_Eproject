import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class BrandEdit extends StatefulWidget {
  final String brandId;

  BrandEdit({required this.brandId});

  @override
  _BrandEditState createState() => _BrandEditState();
}

class _BrandEditState extends State<BrandEdit> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  String? _existingImageBase64;
  String? _newImageBase64;

  @override
  void initState() {
    super.initState();
    _fetchBrandDetails();
  }

void _fetchBrandDetails() async {
  final docSnapshot = await FirebaseFirestore.instance
      .collection('brand') // ✅ Correct collection name
      .doc(widget.brandId)
      .get();

  if (docSnapshot.exists) {
    setState(() {
      _nameController.text = docSnapshot['name'];
      _existingImageBase64 = docSnapshot['image']; // ✅ Correct field name
    });
  }
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
        // Blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Center(child: Text("Edit Brand")),
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
                    decoration: InputDecoration(labelText: 'Brand Name'),
                  ),
                  SizedBox(height: 16.0),
                  Text("Brand Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                  SizedBox(height: 8.0),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _newImageBase64 != null
                          ? Image.memory(
                              base64Decode(_newImageBase64!),
                              fit: BoxFit.cover,
                            )
                          : _existingImageBase64 != null
                              ? Image.memory(
                                  base64Decode(_existingImageBase64!),
                                  fit: BoxFit.cover,
                                )
                              : Center(child: Text("Tap to select image")),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _updateBrand,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 9, 99, 156),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Update Brand',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _newImageBase64 = base64Encode(bytes);
      });
    }
  }

Future<void> _updateBrand() async {
  final String finalImage = _newImageBase64 ?? _existingImageBase64 ?? "";

  await FirebaseFirestore.instance
      .collection('brand') // ✅ Correct collection name
      .doc(widget.brandId)
      .update({
    'name': _nameController.text,
    'image': finalImage, // ✅ Correct field name
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Brand Updated Successfully!')),
  );
}

}
