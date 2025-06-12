import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCard extends StatefulWidget {
  final String? cardId;
  final String? cardNumber;
  final String? expDate;
  final String? cvv;
  final String? cardHolderName;
  final String? cardType;
  final bool isEditing;

  const AddCard({
    Key? key,
    this.cardId,
    this.cardNumber,
    this.expDate,
    this.cvv,
    this.cardHolderName,
    this.cardType,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _AddCardState createState() => _AddCardState();
}

class _AddCardState extends State<AddCard> {
  bool isDefault = false;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController cardNumberController;
  late final TextEditingController expDateController;
  late final TextEditingController cvvController;
  late final TextEditingController cardHolderNameController;

  String? username;
  String? selectedCardLabel;
  String? selectedCardImage;

  @override
  void initState() {
    super.initState();
    cardNumberController = TextEditingController(text: widget.cardNumber ?? '');
    expDateController = TextEditingController(text: widget.expDate ?? '');
    cvvController = TextEditingController(text: widget.cvv ?? '');
    cardHolderNameController = TextEditingController(text: widget.cardHolderName ?? '');
    selectedCardLabel = widget.cardType;
    _loadUserInfo();
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    expDateController.dispose();
    cvvController.dispose();
    cardHolderNameController.dispose();
    super.dispose();
  }

  void _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('User').doc(user.uid).get();
      setState(() {
        username = doc['UserName'] ?? 'User';
        if (widget.cardHolderName == null) {
          cardHolderNameController.text = username ?? '';
        }
      });
    }
  }

  Future<void> _saveCardDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _formKey.currentState!.validate()) {
      try {
        final cardData = {
          'cardNumber': cardNumberController.text.trim(),
          'expDate': expDateController.text.trim(),
          'cvv': cvvController.text.trim(),
          'cardHolderName': cardHolderNameController.text.trim(),
          'cardType': selectedCardLabel,
          'cardImage': selectedCardImage,
          'timestamp': FieldValue.serverTimestamp(),
        };

        if (widget.isEditing && widget.cardId != null) {
          await FirebaseFirestore.instance
              .collection('User')
              .doc(user.uid)
              .collection('Cards')
              .doc(widget.cardId)
              .update(cardData);
        } else {
          await FirebaseFirestore.instance
              .collection('User')
              .doc(user.uid)
              .collection('Cards')
              .add(cardData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEditing ? 'Card updated successfully!' : 'Card saved successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving card: ${e.toString()}')),
        );
      }
    }
  }

  void _showCardSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F5DC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => CardSelectorBottomSheet(
        initialSelection: selectedCardLabel,
        onCardSelected: (label, imagePath) {
          Navigator.pop(context);
          setState(() {
            selectedCardLabel = label;
            selectedCardImage = imagePath;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label card selected!')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        widget.isEditing ? "Edit Card" : "Add Card",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildCardPreview(),
                        SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                cardHolderNameController,
                                'Cardholder Name',
                                TextInputType.text,
                                icon: Icons.person,
                              ),
                              SizedBox(height: 10),
                              _buildTextField(
                                cardNumberController,
                                'Card number',
                                TextInputType.number,
                                icon: Icons.credit_card,
                                onChanged: (_) => setState(() {}),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      expDateController,
                                      'Exp Date (MM/YY)',
                                      TextInputType.datetime,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      cvvController,
                                      'CVV Code',
                                      TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 100), // Space for floating button
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Floating Action Button
            Positioned(
              right: 20,
              bottom: 80,
              child: FloatingActionButton(
                onPressed: _showCardSelector,
                child: Icon(Icons.add, size: 30),
                backgroundColor: const Color(0xFFE0D9BA),
                elevation: 6,
              ),
            ),
            // Add Card Button
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0D9BA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _saveCardDetails,
                  child: Text(
                    widget.isEditing ? "UPDATE CARD" : "ADD CARD",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE5C9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cardHolderNameController.text.isEmpty
                      ? username ?? 'Cardholder Name'
                      : cardHolderNameController.text,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (selectedCardImage != null)
                Image.asset(
                  selectedCardImage!,
                  width: 60,
                  height: 60,
                ),
            ],
          ),
          SizedBox(height: 12),
          Text("CARD NUMBER", style: TextStyle(fontSize: 13)),
          Text(
            cardNumberController.text.isEmpty
                ? "XXXX XXXX XXXX XXXX"
                : cardNumberController.text,
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("EXPIRY DATE", style: TextStyle(fontSize: 13)),
                    Text(
                      expDateController.text.isEmpty
                          ? "MM/YY"
                          : expDateController.text,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CVV", style: TextStyle(fontSize: 13)),
                    Text(
                      cvvController.text.isEmpty ? "•••" : cvvController.text,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    TextInputType keyboardType, {
    IconData? icon,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: UnderlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }
}

class CardSelectorBottomSheet extends StatefulWidget {
  final String? initialSelection;
  final void Function(String label, String imagePath) onCardSelected;

  const CardSelectorBottomSheet({
    required this.onCardSelected,
    this.initialSelection,
    Key? key,
  }) : super(key: key);

  @override
  _CardSelectorBottomSheetState createState() => _CardSelectorBottomSheetState();
}

class _CardSelectorBottomSheetState extends State<CardSelectorBottomSheet> {
  int? _selectedIndex;

  final List<Map<String, String>> cards = [
    {'image': 'assets/Mastercard.png', 'label': 'Mastercard'},
    {'image': 'assets/VisaLogo.png', 'label': 'Visa'},
    {'image': 'assets/Paypal logo.png', 'label': 'Paypal'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _selectedIndex = cards.indexWhere(
        (card) => card['label'] == widget.initialSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.6,
      child: Container(
        color: const Color(0xFFF5F5DC),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            children: [
              Container(height: 4, width: 40, color: Colors.grey[400]),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      color: const Color(0xFFEBE5C9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Image.asset(card['image']!, width: 60, height: 60),
                        title: Text(card['label']!),
                        trailing: Radio<int>(
                          value: index,
                          groupValue: _selectedIndex,
                          onChanged: (val) {
                            setState(() => _selectedIndex = val);
                          },
                        ),
                        onTap: () {
                          setState(() => _selectedIndex = index);
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0D9BA),
                  ),
                  onPressed: () {
                    if (_selectedIndex != null) {
                      final selectedCard = cards[_selectedIndex!];
                      widget.onCardSelected(
                        selectedCard['label']!,
                        selectedCard['image']!,
                      );
                    }
                  },
                  child: Text(
                    "SELECT CARD",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}