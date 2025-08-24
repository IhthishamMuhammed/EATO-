// FILE: lib/widgets/checkout_card_section.dart
import 'package:flutter/material.dart';
import 'stripe_card_input_widget.dart';
import '../services/PaymentService.dart';
import '../EatoComponents.dart';

class CheckoutCardSection extends StatefulWidget {
  final Function(Map<String, String>) onCardDataChanged;
  
  const CheckoutCardSection({
    Key? key,
    required this.onCardDataChanged,
  }) : super(key: key);

  @override
  State<CheckoutCardSection> createState() => _CheckoutCardSectionState();
}

class _CheckoutCardSectionState extends State<CheckoutCardSection> {
  Map<String, String> _cardData = {};
  Map<String, String?> _validationErrors = {};
  String? _testCardInfo;

  void _handleCardDataChanged(Map<String, String> cardData) {
    setState(() {
      _cardData = cardData;
      _validationErrors = PaymentService.validatePaymentMethod(
        PaymentType.card,
        cardData,
      );
      
      _testCardInfo = PaymentService.getTestCardInfo(cardData['cardNumber'] ?? '');
    });
    
    widget.onCardDataChanged(cardData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stripe card input widget
        StripeCardInputWidget(
          onCardDataChanged: _handleCardDataChanged,
          showTestCards: true,
        ),
        
        // Show test card info
        if (_testCardInfo != null) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _testCardInfo!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Show validation errors
        if (_validationErrors.isNotEmpty) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _validationErrors.entries
                  .map((error) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• ${error.value}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}