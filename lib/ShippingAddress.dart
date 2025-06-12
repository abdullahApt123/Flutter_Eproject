import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ShippingAddress extends StatefulWidget {
  @override
  _ShippingAddressState createState() => _ShippingAddressState();
}

class _ShippingAddressState extends State<ShippingAddress> {
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('User')
        .doc(user!.uid)
        .collection('shippingAddresses')
        .get();

    setState(() {
      addresses = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'docId': doc.id,
              })
          .toList();
      isLoading = false;
    });
  }

  Future<void> saveAddressToFirestore(Map<String, dynamic> address) async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('User')
        .doc(user!.uid)
        .collection('shippingAddresses')
        .add({
      ...address,
      'timestamp': FieldValue.serverTimestamp(),
    });
    fetchAddresses();
  }

  Future<void> deleteAddress(String docId) async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('User')
        .doc(user!.uid)
        .collection('shippingAddresses')
        .doc(docId)
        .delete();
    fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Back button only
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF008080)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : addresses.isEmpty
                      ? const Center(
                          child: Text(
                            'No addresses saved yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: addresses.length,
                          itemBuilder: (context, index) =>
                              _buildAddressCard(addresses[index],
                                  addresses[index]['docId']),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressForm(context),
        backgroundColor: const Color(0xFFE0D9BA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address, String docId) {
    return Card(
      color: const Color(0xFFF0EBD2),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE5C9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEBE5C9)),
                  ),
                  child: const Icon(Icons.location_on,
                      color: Color(0xFFD8D4B8)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address['name'] ?? 'No Name Provided',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(address['street'] ?? 'No Street Provided',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                          '${address['city'] ?? 'No City Provided'}, ${address['country'] ?? 'No Country Provided'}',
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAddressForm(context,
                        isEditing: true, address: address, docId: docId),
                    child: const Text('EDIT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Color(0xFFE0D9BA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => deleteAddress(docId),
                    child: const Text('DELETE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0D9BA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressForm(BuildContext context,
      {bool isEditing = false, Map<String, dynamic>? address, String? docId}) {
    final nameController = TextEditingController(text: address?['name']);
    final streetController = TextEditingController(text: address?['street']);
    final cityController = TextEditingController(text: address?['city']);
    final countryController =
        TextEditingController(text: address?['country']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5DC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEditing ? 'Edit Address' : 'Add New Address',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: streetController,
                          decoration: const InputDecoration(
                            labelText: 'Street Address',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: cityController,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: countryController,
                                decoration: const InputDecoration(
                                  labelText: 'Country',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final addressData = {
                        'name': nameController.text,
                        'street': streetController.text,
                        'city': cityController.text,
                        'country': countryController.text,
                      };

                      if (isEditing) {
                        await deleteAddress(docId!);
                      }
                      await saveAddressToFirestore(addressData);
                      Navigator.pop(context);
                    },
                    child: Text(isEditing ? 'UPDATE' : 'SAVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0D9BA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
