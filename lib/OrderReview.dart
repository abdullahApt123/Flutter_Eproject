import 'package:babyhubshop/Cart.dart';
import 'package:babyhubshop/OrderDetails.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class OrderReview extends StatefulWidget {
  @override
  _OrderReviewState createState() => _OrderReviewState();
}

class _OrderReviewState extends State<OrderReview> {
  String? selectedCardType = 'Cash';
  String? selectedCardNumber;
  String? selectedImagePath;
  List<Map<String, dynamic>> shippingAddresses = [];
  Map<String, dynamic>? selectedAddress;

  double fetchedSubtotal = 0.0;

  @override
  void initState() {
    super.initState();
    fetchShippingAddresses();
    fetchSubtotal();
  }

  void fetchShippingAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .collection('shippingAddresses')
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        shippingAddresses =
            snapshot.docs.map((doc) => doc.data()).toList().cast<Map<String, dynamic>>();
        selectedAddress = shippingAddresses.first;
      });
    }
  }

  void fetchSubtotal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final totalDoc = await FirebaseFirestore.instance
        .collection('Cart')
        .doc(user.email)
        .get();

    if (totalDoc.exists) {
      setState(() {
        fetchedSubtotal = (totalDoc.data()?['totalAmount'] ?? 0).toDouble();
      });
    }
  }

  void _showPaymentMethods(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFFF5F5DC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('User')
              .doc(user.uid)
              .collection('Cards')
              .orderBy('timestamp', descending: true)
              .get(),
          builder: (context, snapshot) {
            final cards = snapshot.data?.docs ?? [];

            return Container(
              decoration: BoxDecoration(
                color: Color(0xFFF5F5DC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Select Payment Method', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Card(
                            color: Color(0xFFEBE5C9),
                            child: ListTile(
                              leading: Icon(Icons.money, color: Colors.black),
                              title: Text("Cash"),
                              onTap: () {
                                setState(() {
                                  selectedCardType = 'Cash';
                                  selectedCardNumber = null;
                                  selectedImagePath = null;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          if (cards.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(child: Text("No cards added.")),
                            ),
                          for (var card in cards)
                            Card(
                              color: Color(0xFFEBE5C9),
                              child: ListTile(
                                leading: _getCardIcon(card['cardType'], card['cardImage']),
                                title: Text(_formatCardNumber(card['cardNumber'])),
                                subtitle: Text('Expires ${card['expDate']}'),
                                onTap: () {
                                  setState(() {
                                    selectedCardType = card['cardType'];
                                    selectedCardNumber = card['cardNumber'];
                                    selectedImagePath = card['cardImage'];
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddressSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFFF5F5DC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFFF5F5DC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Select Shipping Address', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(16),
                  shrinkWrap: true,
                  children: shippingAddresses.map((address) {
                    return Card(
                      color: Color(0xFFEBE5C9),
                      child: ListTile(
                        title: Text(address['name'] ?? '', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${address['street']}"),
                            Text("${address['city']}, ${address['country']}"),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            selectedAddress = address;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCardNumber(String number) {
    if (number.length < 4) return number;
    return '**** ${number.substring(number.length - 4)}';
  }

  Widget _getCardIcon(String type, String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.asset(imagePath, width: 40);
    } else if (type == 'Visa') {
      return Image.asset('assets/visa.png', width: 40);
    } else if (type == 'Mastercard') {
      return Image.asset('assets/mastercard.png', width: 40);
    } else {
      return Icon(Icons.credit_card);
    }
  }

  String _generateOrderNumber() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(10, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _checkout(List<QueryDocumentSnapshot> cartItems, double total) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('User').doc(user.uid).get();
    final userName = userDoc.data()?['UserName'] ?? 'Unknown';

    final orderData = {
      'userName': userName,
      'orderNo': _generateOrderNumber(),
      'orderDate': Timestamp.now(),
      'totalAmount': total,
      'paymentMethod': selectedCardType ?? 'Cash',
      'paymentDetails': {
        'cardType': selectedCardType ?? 'Cash',
        'cardNumber': selectedCardNumber ?? '',
        'cardImage': selectedImagePath ?? '',
      },
      'shippingAddress': selectedAddress ?? {},
      'status': 'Processing',
      'items': cartItems.map((item) {
        final data = item.data() as Map<String, dynamic>;
        return {
          'productId': item.id,
          'name': data['name'],
          'price': data['price'],
          'quantity': data['quantity'],
          'image': data['image'],
          'description': data['description'],
        };
      }).toList(),
    };

    final orderRef = await FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .collection('orders')
        .add(orderData);

    for (var item in cartItems) {
      await item.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Order placed successfully!")),
    );

    // Changed from MyCart to OrderDetailsScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Cart')
                  .doc(user!.email)
                  .collection('items')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return Center(child: Text("Your cart is empty."));

                final cartItems = snapshot.data!.docs;

                const double deliveryFee = 100;
                final double total = fetchedSubtotal + deliveryFee;

                final productList = cartItems.where((doc) => doc.id != 'total').map((cartItem) {
                  final item = cartItem.data() as Map<String, dynamic>;
                  final name = item['name'] ?? '';
                  final description = item['description'] ?? '';
                  final base64Image = item['image'] ?? '';
                  Uint8List? imageBytes;
                  try {
                    imageBytes = base64Decode(base64Image);
                  } catch (_) {
                    imageBytes = null;
                  }

                  return _buildProductItem(name, description, imageBytes);
                }).toList();

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Column(children: productList),
                      SizedBox(height: 20),
                      _buildSummaryCard(fetchedSubtotal, deliveryFee, total),
                      SizedBox(height: 20),
                      _buildSectionCard(
                        title: "Payment Method",
                        onChange: () => _showPaymentMethods(context),
                        child: selectedCardType == 'Cash'
                            ? ListTile(
                                leading: Icon(Icons.money),
                                title: Text("Cash"),
                              )
                            : ListTile(
                                leading: _getCardIcon(selectedCardType!, selectedImagePath),
                                title: Text(_formatCardNumber(selectedCardNumber ?? '')),
                              ),
                      ),
                      SizedBox(height: 20),
                      _buildSectionCard(
                        title: "Shipping Address",
                        onChange: () => _showAddressSelector(context),
                        child: selectedAddress == null
                            ? Center(child: Text('No shipping address selected'))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(selectedAddress!['name'] ?? '', 
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 16),
                                      SizedBox(width: 5),
                                      Text("${selectedAddress!['street']}", 
                                        style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Text("${selectedAddress!['city']}, ${selectedAddress!['country']}", 
                                    style: TextStyle(fontSize: 14)),
                                ],
                              ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _checkout(cartItems, total),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE0D9BA),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text("Place Order", 
                            style: TextStyle(fontSize: 16, color: Colors.black)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Modified back button without circle avatar
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double subtotal, double deliveryFee, double total) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFEBE5C9),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryRow("Subtotal", "\$${subtotal.toStringAsFixed(2)}"),
          SizedBox(height: 10),
          _buildSummaryRow("Shipping Fee", "\$${deliveryFee.toStringAsFixed(2)}"),
          Divider(),
          _buildSummaryRow("Total", "\$${total.toStringAsFixed(2)}", isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, 
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black)),
        Text(value, 
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black)),
      ],
    );
  }

  Widget _buildProductItem(String name, String description, Uint8List? imageBytes) {
    return Card(
      color: Color(0xFFEBE5C9),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: imageBytes != null
            ? Image.memory(imageBytes, width: 50, height: 50, fit: BoxFit.cover)
            : Icon(Icons.image_not_supported),
        title: Text(name, style: TextStyle(color: Colors.black)),
        subtitle: Text(description, style: TextStyle(color: Colors.black54)),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required VoidCallback onChange, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFEBE5C9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: Colors.black)),
              InkWell(
                onTap: onChange,
                child: Text("Change", 
                  style: TextStyle(color: Colors.blue[800])),
              ),
            ],
          ),
          SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}