import 'package:babyhubshop/AddCard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentMethod extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: SafeArea(
        child: Column(
          children: [
            // Custom back button row (replacing AppBar)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: currentUser == null
                  ? Center(child: Text("Please sign in to view payment methods"))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('User')
                          .doc(currentUser.uid)
                          .collection('Cards')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text("Error loading cards"));
                        }

                        final cards = snapshot.data?.docs ?? [];

                        if (cards.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.credit_card, size: 50, color: Colors.grey),
                                SizedBox(height: 16),
                                Text("No payment methods saved"),
                                SizedBox(height: 8),
                                Text(
                                  "Add a payment method to make checkout faster",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: cards.length,
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            final data = card.data() as Map<String, dynamic>;
                            return _buildCardItem(
                              context,
                              card.id,
                              data['cardNumber'] ?? '',
                              data['expDate'] ?? '',
                              data['cvv'] ?? '',
                              data['cardHolderName'] ?? 'Cardholder Name',
                              data['cardType'] ?? 'Card',
                              data['cardImage'],
                            );
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE0D9BA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddCard()),
                    );
                  },
                  child: Text(
                    'ADD PAYMENT METHOD',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(
    BuildContext context,
    String cardId,
    String cardNumber,
    String expDate,
    String cvv,
    String cardHolderName,
    String cardType,
    String? cardImage,
  ) {
    final last4 = cardNumber.length > 4 
        ? cardNumber.substring(cardNumber.length - 4)
        : '••••';

    return Card(
      color: Color(0xFFEBE5C9),
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getCardIcon(cardType, cardImage),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardType.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '•••• •••• •••• $last4',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.black54),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddCard(
                          cardId: cardId,
                          cardNumber: cardNumber,
                          expDate: expDate,
                          cvv: cvv,
                          cardHolderName: cardHolderName,
                          cardType: cardType,
                          isEditing: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARDHOLDER NAME',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      cardHolderName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(width: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPIRES',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      expDate,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCardIcon(String type, String? imagePath) {
    final iconSize = 40.0;
    
    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.asset(imagePath, width: iconSize);
    } else if (type.toLowerCase().contains('visa')) {
      return Image.asset('assets/visa.png', width: iconSize);
    } else if (type.toLowerCase().contains('mastercard')) {
      return Image.asset('assets/mastercard.png', width: iconSize);
    } else if (type.toLowerCase().contains('amex')) {
      return Image.asset('assets/amex.png', width: iconSize);
    } else {
      return Icon(Icons.credit_card, size: iconSize, color: Colors.black54);
    }
  }
}