import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:babyhubshop/SignIn.dart';
import 'package:babyhubshop/components/Feedback.dart';
import 'package:babyhubshop/components/adminshowcateg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'adminbrands.dart';
import 'admincategory.dart';
import 'adminorders.dart';
import 'adminproducts.dart';
import 'adminprofile.dart';
import 'adminusers.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        cardTheme: CardTheme(
          elevation: 4,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: const AdminDashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});
  Future<void> updateStatus(
      String userId, String orderId, String newStatus) async {
    final validStatuses = ['processing', 'shipping', 'delivered'];
    final statusToUpdate = newStatus.toLowerCase().trim();
    if (validStatuses.contains(statusToUpdate)) {
      await FirebaseFirestore.instance
          .collection('User')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .update({'status': statusToUpdate});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Stack(children: [
      Positioned.fill(
        child: Image.asset(
          'assets/babyback.PNG',
          fit: BoxFit.cover,
        ),
      ),
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(color: Colors.black.withOpacity(0.2)),
        ),
      ),
      Scaffold(
        key: _scaffoldKey,
        drawer: screenWidth < 800 ? _buildDrawer(context) : null,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Row(
            children: [
              if (screenWidth >= 800)
                Container(
                  width: 250,
                  color: Colors.grey[200],
                  child: _buildDrawer(context),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (screenWidth >= 800)
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Admin Dashboard',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 20, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminProfile()),
              );
            },
            tooltip: 'Profile',
          ),
          const SizedBox(width: 2), // spacing between icons
         IconButton(
  icon: const Icon(Icons.logout, size: 20, color: Colors.black),
  onPressed: () {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignIn()),
    );
  },
  tooltip: 'Logout',
),

        ],
      ),
    ],
  ),
),


                      



                    if (screenWidth < 800)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                        child: Builder(
                          builder: (context) => Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                ' Dashboard',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                                 const SizedBox(width: 12),
                                    Row(
        children: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 25, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminProfile()),
              );
            },
            tooltip: 'Profile',
          ),
          const SizedBox(width: 4), // spacing between icons
          IconButton(
            icon: const Icon(Icons.logout, size: 25, color: Colors.black),
            onPressed: () {
              // Signout logic here (example: FirebaseAuth.instance.signOut())
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignIn()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
                            ],
                          ),
                        ),
                      ),




                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _buildSummaryCard(
                                    _getCollectionCount('brand'),
                                    'BRANDS',
                                    Icons.confirmation_num,
                                    screenWidth),
                                _buildSummaryCard(
                                    _getCollectionCount('categ'),
                                    'CATEGORIES',
                                    Icons.category,
                                    screenWidth),
                                _buildSummaryCard(_getCollectionCount('User'),
                                    'USERS', Icons.people, screenWidth),
                                _buildSummaryCard(_getTotalOrdersCount(),
                                    'ORDERS', Icons.list_alt, screenWidth),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildOrdersTable(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    ]);
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backbaby.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.transparent),
                child: Center(
                  child: Text(
                    'Wellcome to the Admin Panel',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              _drawerTile(
                  context, 'Products', Icons.shopping_bag, ShowProducts()),
              _drawerTile(
                  context, 'Category', Icons.category, ShowCategories()),
              _drawerTile(context, 'Users', Icons.people, UserMonitor()),
              _drawerTile(context, 'Orders', Icons.list_alt, AdminOrders()),
              _drawerTile(context, 'Brand', Icons.flag, ShowBrands()),
              
              _drawerTile(context, 'Feedback', Icons.list_alt, AdminFeedbackView()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
      BuildContext context, String title, IconData icon, Widget? page) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.black54)),
      onTap: () {
        if (page != null) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => page));
        }
      },
    );
  }

  Future<int> _getCollectionCount(String collectionPath) async {
    final aggregateQuery =
        FirebaseFirestore.instance.collection(collectionPath).count();
    final aggregateQuerySnapshot = await aggregateQuery.get();

    // Ensure we always return a non-null integer
    return aggregateQuerySnapshot.count ?? 0;
  }
  Future<int> _getTotalOrdersCount() async {
  int totalOrders = 0;
  final usersSnapshot = await FirebaseFirestore.instance.collection('User').get();
  for (var userDoc in usersSnapshot.docs) {
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(userDoc.id)
        .collection('orders')
        .get();
    totalOrders += ordersSnapshot.size;
  }
  return totalOrders;
}


  Widget _buildSummaryCard(Future<int> countFuture, String label, IconData icon,
      double screenWidth) {
    double cardWidth =
        screenWidth > 800 ? (screenWidth - 96) / 4 : screenWidth / 2 - 24;

    return SizedBox(
      width: cardWidth,
      child: Card(
        color: const Color.fromARGB(255, 223, 222, 222),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<int>(
            future: countFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                final count = snapshot.data ?? 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 40, color: Colors.deepPurple),
                    const SizedBox(height: 8),
                    Text(
                      '$count',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('User').snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userDocs = userSnapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: userDocs.map((userDoc) {
            final userId = userDoc.id;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('User')
                  .doc(userId)
                  .collection('orders')
                  .snapshots(),
              builder: (context, orderSnapshot) {
                if (!orderSnapshot.hasData ||
                    orderSnapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                final orders = orderSnapshot.data!.docs;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        MaterialStateProperty.all(Colors.grey[100]),
                    columns: const [
                      DataColumn(label: Text("Order No")),
                      DataColumn(label: Text("User")),
                      DataColumn(label: Text("Product")),
                      DataColumn(label: Text("Product Name")),
                      DataColumn(label: Text("Payment Method")),
                      DataColumn(label: Text("Order Date")),
                      DataColumn(label: Text("Shipping Address")),
                      DataColumn(label: Text("Total")),
                      DataColumn(label: Text("Status")),
                    ],
                    rows: orders.map((orderDoc) {
                      final order = orderDoc.data() as Map<String, dynamic>;
                      final items = order['items'] as List<dynamic>;
                      final firstItem = items.isNotEmpty ? items.first : {};
                      final base64Image = firstItem['image'] ?? '';
                      Uint8List? imageBytes;
                      try {
                        imageBytes = base64Decode(base64Image);
                      } catch (_) {}

                      final address = order['shippingAddress'] ?? {};
                      final shippingDisplay =
                          "${address['street'] ?? ''}, ${address['city'] ?? ''}, ${address['country'] ?? ''}";

                      final orderUserName = order['UserName'] ?? 'Unknown';
                      final orderDateRaw = order['orderDate'];
                      DateTime? parsedDate;
                      if (orderDateRaw is Timestamp) {
                        parsedDate = orderDateRaw.toDate();
                      } else if (orderDateRaw is String) {
                        parsedDate = DateTime.tryParse(orderDateRaw);
                      }

                      final formattedDate = parsedDate != null
                          ? "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}"
                          : "N/A";

                      final orderId = orderDoc.id;
                      final rawStatus = (order['status'] ?? 'processing')
                          .toString()
                          .toLowerCase()
                          .trim();
                      final validStatuses = [
                        'processing',
                        'shipping',
                        'delivered'
                      ];
                      final currentStatus = validStatuses.contains(rawStatus)
                          ? rawStatus
                          : 'processing';

                      return DataRow(cells: [
                        DataCell(Text(order['orderNo'] ?? '')),
                        DataCell(Text(orderUserName)),
                        DataCell(imageBytes != null
                            ? Image.memory(imageBytes, width: 50, height: 50)
                            : const Icon(Icons.image_not_supported)),
                        DataCell(Text(firstItem['productName'] ?? '')),
                        DataCell(Text(order['paymentMethod'] ?? '')),
                        DataCell(Text(formattedDate)),
                        DataCell(Text(shippingDisplay)),
                        DataCell(Text("\$${order['totalAmount'] ?? '0'}")),
                        DataCell(
                          DropdownButton<String>(
                            value: currentStatus,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                updateStatus(userId, orderId, newValue);
                              }
                            },
                            items: validStatuses
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
