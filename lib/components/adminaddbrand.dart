import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBrand extends StatefulWidget {
  const AddBrand({super.key});

  @override
  _AddBrandState createState() => _AddBrandState();
}


class _AddBrandState extends State<AddBrand> {
  final TextEditingController _brandController = TextEditingController();
  Uint8List? _imageBytes;
  XFile? _pickedFile;

  final ImagePicker picker = ImagePicker();

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
        // Blur effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
// Background image
        Scaffold(
           backgroundColor: Colors.transparent,
       appBar: AppBar(
              title: Center(
                
                child: Text("Add Brands")),
              backgroundColor:  const Color.fromARGB(255, 9, 99, 156),
              elevation: 0,
            ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStyledTextField(_brandController, 'Brand Name'),
              const SizedBox(height: 20),
              _buildImagePicker(),
              const SizedBox(height: 20),
              
             SizedBox(
              width: double.infinity,
               child: ElevatedButton(
                
                 onPressed: _addBrand,
               style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 9, 99, 156),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                 child: const Text("Add Brand"),
               ),
             )

            ],
          ),
        ),
           ),
           ]
     );
  }

  Widget _buildStyledTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
          labelStyle: TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black),
        ),
        child: _imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
              )
            : const Center(
                child: Icon(Icons.add_a_photo, color: Colors.black, size: 40),
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedFile = picked;
        _imageBytes = bytes;
      });
    }
  }
String convertImageToBase64(Uint8List imageBytes) {
  return base64Encode(imageBytes);
}

Future<void> _addBrand() async {
  final String brandName = _brandController.text.trim();

  if (brandName.isEmpty || _imageBytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Brand name and image required')),
    );
    return;
  }

  try {
    // ✅ Convert image to base64
    String base64Image = convertImageToBase64(_imageBytes!);

    // ✅ Save to Firestore
    await FirebaseFirestore.instance.collection('brand').add({
      'name': brandName,
      'image': base64Image,
    });

    setState(() {
      _pickedFile = null;
      _imageBytes = null;
      _brandController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Brand added successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

}
