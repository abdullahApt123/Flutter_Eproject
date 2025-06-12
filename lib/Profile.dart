import 'dart:typed_data';
import 'package:babyhubshop/HelpCenter.dart';
import 'package:babyhubshop/MyOrders.dart';
import 'package:babyhubshop/OrderHistory.dart';
import 'package:babyhubshop/PaymentMethod.dart';
import 'package:babyhubshop/ShippingAddress.dart';
import 'package:babyhubshop/UserDetails.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _userName;
  String? _userEmail;
  Uint8List? _profileImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot doc = await _firestore.collection('User').doc(user.uid).get();
        
        if (doc.exists) {
          setState(() {
            _userName = doc['UserName'] ?? user.displayName ?? 'User Name';
            _userEmail = doc['UserEmail'] ?? user.email ?? 'user@example.com';
            
            if (doc['profileImageBase64'] != null) {
              _profileImage = base64Decode(doc['profileImageBase64']);
            }
            
            _isLoading = false;
          });
        } else {
          setState(() {
            _userName = user.displayName ?? 'User Name';
            _userEmail = user.email ?? 'user@example.com';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _userName = 'User Name';
          _userEmail = 'user@example.com';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _userName = 'User Name';
        _userEmail = 'user@example.com';
        _isLoading = false;
      });
    }
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Card Skeleton
              Card(
                color: Color(0xFFF0EBD2), // Changed container color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: 180,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              
              // First Container Skeleton
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF0EBD2), // Changed container color
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey[300]!, width: 1.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) => Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Color(0xFFEBE5C9), // Changed icon background
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            SizedBox(width: 16.0),
                            Expanded(
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < 4)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Divider(height: 1, color: Colors.grey[300]),
                        ),
                    ],
                  )),
                ),
              ),
              SizedBox(height: 20.0),
              
              // Second Container Skeleton
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF0EBD2), // Changed container color
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey[300]!, width: 1.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(4, (index) => Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Color(0xFFEBE5C9), // Changed icon background
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            SizedBox(width: 16.0),
                            Expanded(
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < 3)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Divider(height: 1, color: Colors.grey[300]),
                        ),
                    ],
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      color: Color(0xFFF0EBD2), // Changed container color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFFEBE5C9), // Changed icon background
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: _profileImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.memory(_profileImage!, fit: BoxFit.cover),
                    )
                  : Icon(Icons.person, size: 40, color: Color(0xFFD8D4B8)), // Changed icon color
            ),
            SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName ?? 'User Name',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _userEmail ?? 'user@example.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(0xFFEBE5C9), // Changed icon background
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 18, color: Color(0xFFD8D4B8)), // Changed icon color
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              height: 1,
              color: Colors.grey[300],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC), // Changed background color
      body: _isLoading 
          ? _buildSkeletonLoader()
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProfileCard(),
                    SizedBox(height: 20.0),
                    
                    // First Options Container
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF0EBD2), // Changed container color
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.grey[300]!, width: 1.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildListOption(
                            icon: Icons.person_outline,
                            title: 'Personal Details',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UserProfilePage()),
                            ),
                          ),
                          _buildListOption(
                            icon: Icons.shopping_bag_outlined,
                            title: 'My Orders',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MyOrders()),
                            ),
                          ),
                          _buildListOption(
                            icon: Icons.location_on_outlined,
                            title: 'Shipping Address',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ShippingAddress()),
                            ),
                          ),
                          _buildListOption(
                            icon: Icons.credit_card_outlined,
                            title: 'My Cards',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PaymentMethod()),
                            ),
                          ),
                          _buildListOption(
                            icon: Icons.history,
                            title: 'History',
                            onTap: () => 
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => OrderHistoryPage()),
                            ),
                          ),
                          _buildListOption(
                            icon: Icons.help_center_outlined,
                            title: 'Help Center',
                            onTap: () => 
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FeedbackForm()),
                            ),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    
                  ],
                ),
              ),
            ),
    );
  }
}