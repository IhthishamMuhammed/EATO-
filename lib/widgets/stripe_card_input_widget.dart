// FILE: lib/widgets/stripe_card_input_widget.dart
// Simple Stripe test card input with predefined test cards

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eato/pages/theme/eato_theme.dart';

class StripeTestCard {
  final String number;
  final String name;
  final String description;
  final String expiry;
  final String cvv;
  final Color color;
  final IconData icon;

  const StripeTestCard({
    required this.number,
    required this.name,
    required this.description,
    required this.expiry,
    required this.cvv,
    required this.color,
    required this.icon,
  });
}

class StripeCardInputWidget extends StatefulWidget {
  final Function(Map<String, String>) onCardDataChanged;
  final bool showTestCards;

  const StripeCardInputWidget({
    Key? key,
    required this.onCardDataChanged,
    this.showTestCards = true,
  }) : super(key: key);

  @override
  State<StripeCardInputWidget> createState() => _StripeCardInputWidgetState();
}

class _StripeCardInputWidgetState extends State<StripeCardInputWidget> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  bool _showTestCards = false;
  
  // Stripe official test cards
  static const List<StripeTestCard> _testCards = [
    StripeTestCard(
      number: '4242424242424242',
      name: 'Visa - Success',
      description: 'Always succeeds',
      expiry: '12/28',
      cvv: '123',
      color: Colors.blue,
      icon: Icons.credit_card,
    ),
    StripeTestCard(
      number: '4000000000000002',
      name: 'Visa - Declined',
      description: 'Always declined',
      expiry: '12/28',
      cvv: '123',
      color: Colors.red,
      icon: Icons.block,
    ),
    StripeTestCard(
      number: '4000000000009995',
      name: 'Visa - Insufficient Funds',
      description: 'Insufficient funds',
      expiry: '12/28',
      cvv: '123',
      color: Colors.orange,
      icon: Icons.money_off,
    ),
    StripeTestCard(
      number: '5555555555554444',
      name: 'Mastercard - Success',
      description: 'Always succeeds',
      expiry: '12/28',
      cvv: '123',
      color: Colors.green,
      icon: Icons.credit_card,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _cardNumberController.addListener(_updateCardData);
    _expiryController.addListener(_updateCardData);
    _cvvController.addListener(_updateCardData);
    _nameController.addListener(_updateCardData);
  }

  void _updateCardData() {
    widget.onCardDataChanged({
      'cardNumber': _cardNumberController.text,
      'expiryDate': _expiryController.text,
      'cvv': _cvvController.text,
      'holderName': _nameController.text,
    });
  }

  void _selectTestCard(StripeTestCard card) {
    _cardNumberController.text = card.number;
    _expiryController.text = card.expiry;
    _cvvController.text = card.cvv;
    _nameController.text = 'Test User';
    setState(() => _showTestCards = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with test cards toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card, color: EatoTheme.primaryColor),
                    SizedBox(width: 12),
                    Text(
                      'Card Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: EatoTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                if (widget.showTestCards)
                  TextButton.icon(
                    onPressed: () => setState(() => _showTestCards = !_showTestCards),
                    icon: Icon(
                      _showTestCards ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                    ),
                    label: Text(
                      'Test Cards',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: EatoTheme.primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 16),

            // Test cards section (collapsible)
            if (widget.showTestCards && _showTestCards) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 Stripe Test Cards',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...(_testCards.map((card) => _buildTestCardTile(card)).toList()),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Card number input
            _buildCardNumberField(),
            SizedBox(height: 12),

            // Row with expiry and CVV
            Row(
              children: [
                Expanded(child: _buildExpiryField()),
                SizedBox(width: 12),
                Expanded(child: _buildCVVField()),
              ],
            ),
            SizedBox(height: 12),

            // Cardholder name
            _buildCardHolderField(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCardTile(StripeTestCard card) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => _selectTestCard(card),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(card.icon, color: card.color, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      card.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                card.number.substring(12),
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardNumberField() {
    return TextField(
      controller: _cardNumberController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(19),
        CardNumberInputFormatter(),
      ],
      decoration: InputDecoration(
        labelText: 'Card Number',
        hintText: '1234 5678 9012 3456',
        prefixIcon: Icon(Icons.credit_card),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EatoTheme.primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EatoTheme.primaryColor),
        ),
        filled: true,
        fillColor: EatoTheme.backgroundColor,
      ),
    );
  }

  Widget _buildExpiryField() {
    return TextField(
      controller: _expiryController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
        ExpiryDateInputFormatter(),
      ],
      decoration: InputDecoration(
        labelText: 'Expiry',
        hintText: 'MM/YY',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EatoTheme.primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EatoTheme.primaryColor),
        ),
        filled: true,
        fillColor: EatoTheme.backgroundColor,
      ),
    );
  }

  Widget _buildCVVField() {
    return TextField(
      controller: _cvvController,
      keyboardType: TextInputType.number,
      obscureText: true,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(
        labelText: 'CVV',
        hintText: '123',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EatoTheme.primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EatoTheme.primaryColor),
        ),
        filled: true,
        fillColor: EatoTheme.backgroundColor,
      ),
    );
  }

  Widget _buildCardHolderField() {
    return TextField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Cardholder Name',
        hintText: 'John Doe',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EatoTheme.primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EatoTheme.primaryColor),
        ),
        filled: true,
        fillColor: EatoTheme.backgroundColor,
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

// Helper formatters
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.length >= 2 && !text.contains('/')) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    }
    
    return newValue;
  }
}