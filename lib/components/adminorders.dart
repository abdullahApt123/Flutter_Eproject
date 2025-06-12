import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrders extends StatefulWidget {
  const AdminOrders({super.key});

  @override
  State<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends State<AdminOrders> {
  Future<void> updateStatus(
      String userId, String orderId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('User')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: Image.asset(
          'assets/aby.jpg',
          fit: BoxFit.cover,
        ),
      ),
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Container(color: Colors.black.withOpacity(0.2)),
        ),
      ),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Center(child: Text("All Orders")),
          backgroundColor: const Color.fromARGB(255, 9, 99, 156),
          elevation: 0,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('User').snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final userDocs = userSnapshot.data!.docs;

            return FutureBuilder<List<DataRow>>(
              future: _fetchAllOrders(userDocs),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allRows = snapshot.data!;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            MaterialStateProperty.all(Colors.white),
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
                        rows: allRows.isEmpty
                            ? [
                                const DataRow(cells: [
                                  DataCell(Text("No Orders Available")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                  DataCell(Text("")),
                                ])
                              ]
                            : allRows,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      )
    ]);
  }

  Future<List<DataRow>> _fetchAllOrders(
      List<QueryDocumentSnapshot> userDocs) async {
    List<DataRow> allRows = [];

    for (final userDoc in userDocs) {
      final userId = userDoc.id;

      final orderSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(userId)
          .collection('orders')
          .get();

      for (final orderDoc in orderSnapshot.docs) {
        final order = orderDoc.data();
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

        final orderUserName = order['userName'] ?? 'Unknown';

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

        allRows.add(DataRow(cells: [
          DataCell(Text(order['orderNo'] ?? '')),
          DataCell(Text(orderUserName)),
          DataCell(imageBytes != null
              ? Image.memory(imageBytes, width: 50, height: 50)
              : const Icon(Icons.image_not_supported)),
          DataCell(Text(firstItem['name'] ?? '')),
          DataCell(Text(order['paymentMethod'] ?? '')),
          DataCell(Text(formattedDate)),
          DataCell(SizedBox(width: 150, child: Text(shippingDisplay))),
          DataCell(Text("\$${(order['totalAmount'] ?? 0).toStringAsFixed(2)}")),
          DataCell(_StatusDropdown(
            currentStatus: order['status'] ?? 'Processing',
            onChanged: (newStatus) {
              updateStatus(userId, orderDoc.id, newStatus);
            },
          )),
        ]));
      }
    }

    return allRows;
  }
}

class _StatusDropdown extends StatefulWidget {
  final String currentStatus;
  final void Function(String) onChanged;

  const _StatusDropdown({
    required this.currentStatus,
    required this.onChanged,
  });

  @override
  State<_StatusDropdown> createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<_StatusDropdown> {
  late String selectedStatus;

  final List<String> statusOptions = ['Processing', 'Shipping', 'Delivered'];

  @override
  void initState() {
    super.initState();
    selectedStatus = statusOptions.firstWhere(
      (s) => s.toLowerCase() == widget.currentStatus.toLowerCase(),
      orElse: () => statusOptions.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color dropdownColor;
    Color textColor = Colors.white;

    switch (selectedStatus) {
      case 'Processing':
        dropdownColor = Colors.blue.shade100;
        break;
      case 'Shipping':
        dropdownColor = Colors.yellow.shade200;
        break;
      case 'Delivered':
        dropdownColor = Colors.green.shade100;
        break;
      default:
        dropdownColor = Colors.grey.shade100;
    }

    return Container(
      color: dropdownColor,
      child: DropdownButton<String>(
        value: selectedStatus,
        style: TextStyle(color: textColor),
        alignment: Alignment.center,
        underline: const SizedBox(),
        items: statusOptions
            .map((status) => DropdownMenuItem(
                  value: status,
                  child: Container(
                    color: status == 'Processing'
                        ? Colors.blue.shade100
                        : status == 'Shipping'
                            ? Colors.yellow.shade200
                            : Colors.green.shade100,
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null && value != selectedStatus) {
            setState(() {
              selectedStatus = value;
            });
            widget.onChanged(value);
          }
        },
      ),
    );
  }
}
