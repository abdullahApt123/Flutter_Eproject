import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  Future<List<Map<String, dynamic>>> fetchOrderHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final orderSnapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(userId)
        .collection('orderHistory')
        .get();

    List<Map<String, dynamic>> allItems = [];

    for (var doc in orderSnapshot.docs) {
      final items = List.from(doc['items']);
      final orderNo = doc.id; // Using document ID as orderNo
      for (var item in items) {
        final newItem = Map<String, dynamic>.from(item);
        newItem['orderNo'] = orderNo;
        allItems.add(newItem);
      }
    }

    return allItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBE5C9),
        title: const Text("Order History"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchOrderHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No order history found."));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final item = orders[index];
              final imageBase64 = item['image'] ?? '';
              final imageBytes = base64Decode(imageBase64);

              return Card(
                color: const Color(0xFFEBE5C9),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Image.memory(
                    imageBytes,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Order No: ${item['orderNo']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(item['name'] ?? '', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  subtitle: Text(
                    "Description: ${item['description']}\n"
                    "Qty: ${item['quantity']}  Price: \$${item['price']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
