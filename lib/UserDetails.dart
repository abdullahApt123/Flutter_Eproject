import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  String? selectedGender;
  Uint8List? _profileImage;
  String? email;
  String? age;

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  late TextEditingController _ageController;
  late TextEditingController _nameController;

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Container(width: 100, height: 100, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.grey[300])),
            SizedBox(height: 8),
            Container(width: 100, height: 16, color: Colors.grey[300]),
            SizedBox(height: 30),
            Container(height: 56, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!)))),
            SizedBox(height: 20),
            Container(height: 56, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!)))),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 60, height: 16, color: Colors.grey[300]),
                SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(child: Container(height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[300]))),
                    SizedBox(width: 8),
                    Expanded(child: Container(height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[300]))),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(height: 56, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!)))),
            SizedBox(height: 30),
            Container(width: double.infinity, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[300])),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController();
    _nameController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'No user logged in';
        });
        return;
      }

      final doc = await _firestore.collection('User').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['UserName'] ?? _auth.currentUser?.displayName ?? '';
          email = data['UserEmail'] ?? _auth.currentUser?.email;
          selectedGender = data['gender'];
          age = data['age']?.toString();
          _ageController.text = age ?? '';
          if (data['profileImageBase64'] != null) {
            try {
              _profileImage = base64Decode(data['profileImageBase64']);
            } catch (e) {
              print('Error decoding image: $e');
            }
          }
          isLoading = false;
        });
      } else {
        setState(() {
          _nameController.text = _auth.currentUser?.displayName ?? '';
          email = _auth.currentUser?.email;
          _ageController.text = '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Failed to load user data: $e';
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _profileImage = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _updateProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      setState(() => isLoading = true);

      Map<String, dynamic> updates = {
        'UserName': _nameController.text.trim(),
        'UserEmail': email,
        'age': _ageController.text.trim(),
        'gender': selectedGender,
      };

      if (_profileImage != null) {
        updates['profileImageBase64'] = base64Encode(_profileImage!);
      }

      await _firestore.collection('User').doc(uid).update(updates);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC), // Beige background
      body: Stack(
        children: [
          isLoading
              ? _buildSkeletonLoader()
              : hasError
                  ? Center(child: Text(errorMessage))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          SizedBox(height: 40),
                          GestureDetector(
                            onTap: _pickProfileImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.grey),
                              ),
                              child: _profileImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.memory(_profileImage!, fit: BoxFit.cover),
                                    )
                                  : Icon(Icons.person, size: 40, color: Colors.grey[600]),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Upload Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 30),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(labelText: 'Name', border: UnderlineInputBorder()),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: _ageController,
                            decoration: InputDecoration(labelText: 'Age', border: UnderlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gender', style: TextStyle(color: Colors.grey[600])),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  _buildGenderOption('Male'),
                                  SizedBox(width: 8),
                                  _buildGenderOption('Female'),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          TextField(
                            readOnly: true,
                            controller: TextEditingController(text: email),
                            decoration: InputDecoration(labelText: 'Email', border: UnderlineInputBorder()),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF008080),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: isLoading
                                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text('UPDATE PROFILE', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),

          // ✅ Back Button (SafeArea ensures it stays within top screen bounds)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedGender = gender),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Color(0xFF008080) : Colors.transparent,
            border: Border.all(color: isSelected ? Color(0xFF008080) : Colors.grey, width: 1.5),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                child: Radio<String>(
                  value: gender,
                  groupValue: selectedGender,
                  onChanged: (value) => setState(() => selectedGender = value),
                  activeColor: Colors.white,
                  fillColor: MaterialStateProperty.resolveWith<Color>(
                    (states) => states.contains(MaterialState.selected) ? Colors.white : Colors.grey,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              SizedBox(width: 4),
              Text(
                gender,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
