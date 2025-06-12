import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MyOrders extends StatefulWidget {
  const MyOrders({super.key});

  @override
  State<MyOrders> createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Map<String, TextEditingController> _productReviewControllers = {};
  final Map<String, TextEditingController> _sellerReviewControllers = {};
  final Map<String, int> _productRatings = {};
  final Map<String, int> _sellerRatings = {};
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  @override
  void dispose() {
    for (var controller in _productReviewControllers.values) {
      controller.dispose();
    }
    for (var controller in _sellerReviewControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('User').doc(user!.uid).get();
        if (doc.exists) {
          setState(() {
            _userName = doc.data()?['UserName'] ?? 'Unknown User';
          });
        }
      } catch (e) {
        debugPrint('Error fetching user name: $e');
        setState(() {
          _userName = 'Unknown User';
        });
      }
    }
  }

  Future<bool> _isOrderFullyReviewed(List<dynamic> items) async {
    final userEmail = user!.email;
    final reviewCollection = FirebaseFirestore.instance
        .collection('Reviews')
        .doc(userEmail)
        .collection('productReviews');

    for (var item in items) {
      final String productId = item['productId'] ?? '';
      final doc = await reviewCollection.doc(productId).get();
      if (!doc.exists) return false;
    }
    return true;
  }

  Future<void> _moveToHistory(String orderId, Map<String, dynamic> orderData) async {
    try {
      await FirebaseFirestore.instance
          .collection('User')
          .doc(user!.uid)
          .collection('orderHistory')
          .doc(orderId)
          .set(orderData);

      await FirebaseFirestore.instance
          .collection('User')
          .doc(user!.uid)
          .collection('orders')
          .doc(orderId)
          .delete();
    } catch (e) {
      debugPrint('Error moving to history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: user == null
                  ? const Center(child: Text("User not logged in"))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('User')
                          .doc(user!.uid)
                          .collection('orders')
                          .orderBy('orderDate', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("No orders found."));
                        }

                        final docs = snapshot.data!.docs;

                        return FutureBuilder(
                          future: Future.wait(docs.map((doc) async {
                            final order = doc.data() as Map<String, dynamic>;
                            final orderId = doc.id;
                            final items = order['items'] ?? [];
                            final String status = order['status']?.toString().toLowerCase() ?? '';

                            final allReviewed = await _isOrderFullyReviewed(items);

                            if (status == 'delivered' && allReviewed) {
                              await _moveToHistory(orderId, order);
                              return null;
                            }

                            return _buildOrderCard(order, orderId);
                          })),
                          builder: (context, AsyncSnapshot<List<Widget?>> asyncSnapshot) {
                            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final visibleOrders = asyncSnapshot.data!.whereType<Widget>().toList();

                            if (visibleOrders.isEmpty) {
                              return const Center(child: Text("No pending reviews."));
                            }

                            return ListView(
                              padding: const EdgeInsets.all(16),
                              children: visibleOrders,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String orderId) {
    final String status = order['status']?.toString().trim() ?? "Unknown";
    final String orderNo = order['orderNo']?.toString() ?? "N/A";
    final Timestamp? dateTimestamp = order['orderDate'];
    final String orderDate = dateTimestamp != null
        ? DateFormat('dd MMM yyyy').format(dateTimestamp.toDate())
        : "Unknown";
    final List<dynamic> items = order['items'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE5C9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusChip(status),
              const Spacer(),
              Text(orderDate, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.confirmation_number, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Text("Order"),
              Spacer(),
            ],
          ),
          Row(
            children: [
              const Spacer(),
              Text("#$orderNo", style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.local_shipping_outlined, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Text("Shipping Date"),
              Spacer(),
            ],
          ),
          Row(
            children: [
              const Spacer(),
              Text(orderDate, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          if (_isDelivered(status)) ...[
            const SizedBox(height: 16),
            const Text("Rate Your Experience", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...items.map((item) {
              final String productId = item['productId'] ?? '';
              final String productName = item['productName'] ?? 'Product';

              _productReviewControllers.putIfAbsent(productId, () => TextEditingController());
              _sellerReviewControllers.putIfAbsent(productId, () => TextEditingController());
              _productRatings.putIfAbsent(productId, () => 0);
              _sellerRatings.putIfAbsent(productId, () => 0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildStarRating(_productRatings[productId]!, (rating) {
                    setState(() => _productRatings[productId] = rating);
                  }),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _productReviewControllers[productId],
                    decoration: InputDecoration(
                      hintText: 'Write your product review...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Text("Seller Rating*", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildStarRating(_sellerRatings[productId]!, (rating) {
                    setState(() => _sellerRatings[productId] = rating);
                  }),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sellerReviewControllers[productId],
                    decoration: InputDecoration(
                      hintText: 'Write your seller review...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 2,
                  ),
                ],
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _submitReview(orderId, items, orderNo),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Submit Review'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating(int currentRating, Function(int) onRatingChanged) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            color: Colors.orange,
            size: 30,
          ),
          onPressed: () => onRatingChanged(index + 1),
        );
      }),
    );
  }

  Future<void> _submitReview(String orderId, List<dynamic> items, String orderNo) async {
    if (user == null) return;

    try {
      for (var item in items) {
        final String productId = item['productId'] ?? '';
        final String productName = item['productName'] ?? 'Products';
        final int productRating = _productRatings[productId] ?? 0;
        final String productReview = _productReviewControllers[productId]?.text.trim() ?? '';
        final int sellerRating = _sellerRatings[productId] ?? 0;
        final String sellerReview = _sellerReviewControllers[productId]?.text.trim() ?? '';

        if (productId.isEmpty || productRating == 0 || productReview.isEmpty || sellerRating == 0 || sellerReview.isEmpty) {
          continue;
        }

        await FirebaseFirestore.instance
            .collection('Reviews')
            .doc(user!.email)
            .collection('productReviews')
            .doc(productId)
            .set({
          'userId': user!.uid,
          'userEmail': user!.email,
          'userName': _userName ?? 'Unknown User',
          'productId': productId,
          'productName': productName,
          'orderId': orderId,
          'orderNo': orderNo,
          'productRating': productRating,
          'productReview': productReview,
          'sellerRating': sellerRating,
          'sellerReview': sellerReview,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      final orderSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(user!.uid)
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderSnapshot.exists) {
        final orderData = orderSnapshot.data()!;
        final status = orderData['status']?.toString().toLowerCase() ?? '';
        final allReviewed = await _isOrderFullyReviewed(items);

        if (status == 'delivered' && allReviewed) {
          await _moveToHistory(orderId, orderData);
        }
      }

      setState(() {
        _productRatings.clear();
        _productReviewControllers.clear();
        _sellerRatings.clear();
        _sellerReviewControllers.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
    } catch (e) {
      debugPrint('Error submitting review: $e');
    }
  }

  bool _isDelivered(String status) {
    return status.toLowerCase().contains('delivered');
  }

  Widget _buildStatusChip(String status) {
    final statusLower = status.toLowerCase();
    late final Color chipColor;
    late final Color textColor;

    if (statusLower.contains('processing')) {
      chipColor = Colors.blue.shade100;
      textColor = Colors.blue.shade800;
    } else if (statusLower.contains('shipping') || statusLower.contains('shipped')) {
      chipColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    } else if (statusLower.contains('delivered')) {
      chipColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    } else {
      chipColor = Colors.grey.shade300;
      textColor = Colors.black;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}