import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({Key? key}) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? orderDetails;
  String? error;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();

    _fetchMostRecentOrder();
  }

  void _fetchMostRecentOrder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          error = "Invalid user.";
        });
      }
      return;
    }

    try {
      final ordersCollection = FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .collection('orders');

      final querySnapshot = await ordersCollection
          .orderBy('orderDate', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            orderDetails = querySnapshot.docs.first.data();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            error = "No orders found for this user.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = "Failed to fetch order details: $e";
        });
      }
      print("Error fetching order details: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildOrderField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          Expanded(
            child: Text(
              value ?? "Loading...",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddress(dynamic addressData) {
    if (addressData == null || addressData is! Map) {
      return buildOrderField('Shipping Address', 'Not available');
    }

    final fullAddress = [
      addressData['name'],
      addressData['street'],
      addressData['city'],
      addressData['state'],
      addressData['zip'],
      addressData['country']
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

    return buildOrderField('Shipping Address',
        fullAddress.isNotEmpty ? fullAddress : 'Not available');
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.blueGrey[800]),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green, width: 6),
                        color: Colors.green[50],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(40, 40),
                          painter: CheckmarkPainter(_animation.value),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Confirmed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your order has been placed successfully',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order No box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF0EBD2),
                        border: Border.all(color: Colors.blue[200]!, width: 1.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Order No: ${orderDetails?['orderNo'] ?? "N/A"}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Second box with Username and other fields
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF0EBD2),
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildOrderField('Username', orderDetails?['userName']),
                          const Divider(color: Colors.grey),
                          buildOrderField('Status', orderDetails?['status']),
                          const Divider(color: Colors.grey),
                          buildOrderField(
                              'Order Date', _formatTimestamp(orderDetails?['orderDate'])),
                          const Divider(color: Colors.grey),
                          buildOrderField(
                              'Payment Method', orderDetails?['paymentMethod']),
                          const Divider(color: Colors.grey),
                          buildOrderField(
                            'Total Amount',
                            orderDetails?['totalAmount'] != null
                                ? "\$${(orderDetails!['totalAmount'] as num).toStringAsFixed(2)}"
                                : null,
                          ),
                          const Divider(color: Colors.grey),
                          _buildShippingAddress(orderDetails?['shippingAddress']),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(6, size.height / 2);
    path.lineTo(size.width / 2, size.height - 10);
    path.lineTo(size.width - 4, 6);

    final pathMetric = path.computeMetrics().first;
    final extractedPath =
        pathMetric.extractPath(0, pathMetric.length * progress);
    canvas.drawPath(extractedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}