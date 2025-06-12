import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserMonitor extends StatelessWidget {
  const UserMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Monitor"),
        centerTitle: true,
         backgroundColor: const Color.fromARGB(255, 9, 99, 156),
      ),
      body: Stack(
        children: [
          // Background image with blur
          Positioned.fill(
            child: Image.asset(
              'assets/decentbabs.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),

          // Foreground user list
          Positioned.fill(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("User").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found", style: TextStyle(color: Colors.white)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var userDoc = snapshot.data!.docs[index];
                    var data = userDoc.data() as Map<String, dynamic>;

                    String name = data['UserName'] ?? 'No data';
                    String email = data['UserEmail'] ?? 'No data';
                    String age = data['age'] ?? 'No data';
                    String gender = data['gender'] ?? 'No data';
                    String? base64Image = data['profileImageBase64'];

                    ImageProvider? profileImage;
                    if (base64Image != null && base64Image.isNotEmpty) {
                      try {
                        profileImage = MemoryImage(base64Decode(base64Image));
                      } catch (_) {
                        profileImage = null;
                      }
                    }

                    return Card(
                      color: const Color(0xFFF5F5DC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: profileImage ?? const AssetImage("assets/no_user.png"),
                              backgroundColor: Colors.grey[300],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Name: $name", style: const TextStyle(fontSize: 16)),
                                  Text("Email: $email", style: const TextStyle(fontSize: 16)),
                                  Text("Age: $age", style: const TextStyle(fontSize: 16)),
                                  Text("Gender: $gender", style: const TextStyle(fontSize: 16)),
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
            ),
          ),
        ],
      ),
    );
  }
}
