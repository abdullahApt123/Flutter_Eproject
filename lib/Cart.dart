import 'dart:convert';
import 'package:babyhubshop/OrderReview.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Cart App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyCart(cartItems: []),
    );
  }
}

class MyCart extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  MyCart({required List<Map<String, dynamic>> cartItems})
      : cartItems = List<Map<String, dynamic>>.from(cartItems);

  @override
  _MyCartState createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> with TickerProviderStateMixin {
  final double _maxDrag = 80.0;
  late List<double> _dragExtents;
  late List<Map<String, dynamic>> _cartItems;
  late List<AnimationController> _animationControllers;
  List<String> _productIds = [];

  @override
  void initState() {
    super.initState();
    _cartItems = List<Map<String, dynamic>>.from(widget.cartItems);
    _dragExtents = List<double>.filled(_cartItems.length, 0.0);
    _animationControllers = [];
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('Cart')
            .doc(email)
            .collection('items')
            .get();

        final List<Map<String, dynamic>> cartItems = [];
        final List<String> productIds = [];

        for (var doc in snapshot.docs) {
          if (doc.id == 'totalAmount') continue;

          final data = doc.data();
          cartItems.add({
            'id': doc.id,
            'productId': data['productId'] ?? '',
            'name': data['productName'] ?? 'Unknown',
            'price': (data['productPrice'] as num?)?.toDouble() ?? 0.0,
            'image': data['image'] ?? '',
            'description': data['description'] ?? '',
            'quantity': data['quantity'] ?? 1,
          });

          productIds.add(data['productId']);
        }

        setState(() {
          _cartItems = cartItems;
          _productIds = productIds;
          _dragExtents = List<double>.filled(_cartItems.length, 0.0);
          _animationControllers = List.generate(
            _cartItems.length,
            (index) => AnimationController(
              vsync: this,
              duration: Duration(milliseconds: 300),
            ),
          );
        });
        _updateTotalAmount();
      } catch (e) {
        print('Error loading cart items: $e');
      }
    }
  }

  Future<void> _removeItem(int index) async {
    if (index < 0 || index >= _cartItems.length) return;

    final item = _cartItems[index];
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Cart')
            .doc(email)
            .collection('items')
            .doc(item['id'])
            .delete();

        await Future.delayed(Duration(milliseconds: 300));

        if (mounted) {
          setState(() {
            if (index < _cartItems.length) _cartItems.removeAt(index);
            if (index < _productIds.length) _productIds.removeAt(index);
            if (index < _dragExtents.length) _dragExtents.removeAt(index);
            if (index < _animationControllers.length) {
              _animationControllers[index].dispose();
              _animationControllers.removeAt(index);
            }
          });
        }

        _updateTotalAmount();
      } catch (e) {
        print('Error removing item from Firestore: $e');
      }
    }
  }

  Future<void> _updateQuantity(int index, int newQuantity) async {
    final item = _cartItems[index];
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      final cartItemRef = FirebaseFirestore.instance
          .collection('Cart')
          .doc(email)
          .collection('items')
          .doc(item['id']);

      try {
        if (newQuantity > 0) {
          await cartItemRef.update({'quantity': newQuantity});
          setState(() {
            _cartItems[index]['quantity'] = newQuantity;
          });
        } else {
          await _animationControllers[index].forward();
          await _removeItem(index);
        }
        _updateTotalAmount();
      } catch (e) {
        print('Error updating quantity: $e');
      }
    }
  }

  int _getTotalQuantity() {
    return _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  double _getSubtotal() {
    return _cartItems.fold(0.0, (sum, item) {
      final price = item['price'] as double;
      final qty = item['quantity'] as int;
      return sum + price * qty;
    });
  }

 double _getTotalCash() {
  return _getSubtotal();
}


  Future<void> _updateTotalAmount() async {
    final totalAmount = _getTotalCash();
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Cart')
            .doc(email)
            .set({'totalAmount': totalAmount}, SetOptions(merge: true));
      } catch (e) {
        print('Error saving total amount: $e');
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed background color here
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Stack(
              children: [
                Icon(Icons.shopping_bag, color: Colors.black, size: 28),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(minWidth: 17, minHeight: 17),
                    child: Text(
                      '${_getTotalQuantity()}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("My Cart",
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Expanded(
                    child: _cartItems.isEmpty
                        ? Center(
                            child: Text(
                              "Your cart is empty!",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cartItems.length,
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              return SlideTransition(
                                key: ValueKey(item['id']),
                                position: Tween<Offset>(
                                  begin: Offset.zero,
                                  end: Offset(-1.0, 0.0),
                                ).animate(CurvedAnimation(
                                  parent: _animationControllers[index],
                                  curve: Curves.easeInOut,
                                )),
                                child: _buildCartItem(item, index),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          _buildCheckoutBar(),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total (${_getTotalQuantity()} items):",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              Text("\$${_getTotalCash().toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ],
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              await _updateTotalAmount();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrderReview()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Proceed to Checkout",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    final imageBytes = base64Decode(item['image']);
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  imageBytes,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text("\$${item['price']}",
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () =>
                        _updateQuantity(index, item['quantity'] - 1),
                  ),
                  Text('${item['quantity']}'),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () =>
                        _updateQuantity(index, item['quantity'] + 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}