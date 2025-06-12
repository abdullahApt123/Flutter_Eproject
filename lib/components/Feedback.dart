import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeedbackView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      appBar: AppBar(
        title: Text("All User Feedbacks"),
        backgroundColor: Color(0xFFE0D9BA),
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('feedbacks').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final feedbackDocs = snapshot.data?.docs ?? [];

          if (feedbackDocs.isEmpty) {
            return Center(child: Text("No feedback submitted yet."));
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            separatorBuilder: (_, __) => Divider(),
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              final data = feedbackDocs[index].data() as Map<String, dynamic>;
              final email = feedbackDocs[index].id;
              final name = data['name'] ?? 'Unknown';
              final feedback = data['feedback'] ?? 'No feedback';
              final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: $name", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("Email: $email"),
                      SizedBox(height: 8),
                      Text("Feedback:", style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(feedback),
                      SizedBox(height: 8),
                      if (submittedAt != null)
                        Text(
                          "Submitted on: ${submittedAt.toLocal()}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
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
