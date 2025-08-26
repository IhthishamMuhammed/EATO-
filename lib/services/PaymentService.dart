// FILE: lib/services/payment_service.dart
// Updated PaymentService with Stripe test card integration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

enum PaymentType {
  cash('Cash Payment'),
  card('Card Payment');

  const PaymentType(this.displayName);
  final String displayName;
}

enum DeliveryType {
  pickup('Pickup'),
  delivery('Delivery');

  const DeliveryType(this.displayName);
  final String displayName;
}

class FeeCalculation {
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double paymentProcessingFee;
  final double totalAmount;
  final String breakdown;

  FeeCalculation({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.paymentProcessingFee,
    required this.totalAmount,
    required this.breakdown,
  });

  Map<String, dynamic> toMap() {
    return {
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'paymentProcessingFee': paymentProcessingFee,
      'totalAmount': totalAmount,
      'breakdown': breakdown,
    };
  }
}

class PaymentService {
  static const double _baseDeliveryFee = 100.0;
  static const double _cardProcessingFeeRate = 0.05; // 5%
  static const double _deliveryServiceFeeRate = 0.05; // 5%

  // Stripe test card numbers for validation
  static const List<String> _stripeTestCards = [
    '4242424242424242', // Visa - Always succeeds
    '4000000000000002', // Visa - Always declined
    '4000000000009995', // Visa - Insufficient funds
    '5555555555554444', // Mastercard - Always succeeds
    '4000000000000341', // Visa - Requires authentication
  ];

  /// Get available payment methods
  static List<PaymentType> getAvailablePaymentMethods() {
    return PaymentType.values;
  }

  /// Check if payment method supports the delivery type
  static bool isPaymentMethodAvailable(
      PaymentType payment, DeliveryType delivery) {
    return true;
  }

  /// Calculate fees with updated structure
  static FeeCalculation calculateFees({
    required double subtotal,
    required PaymentType paymentMethod,
    required DeliveryType deliveryMethod,
    double? customDeliveryFee,
  }) {
    double deliveryFee = 0.0;
    double serviceFee = 0.0;
    double paymentProcessingFee = 0.0;
    List<String> breakdownItems = [];

    // 1. Delivery Fee
    if (deliveryMethod == DeliveryType.delivery) {
      deliveryFee = customDeliveryFee ?? _baseDeliveryFee;
      breakdownItems.add('Delivery Fee: Rs. ${deliveryFee.toStringAsFixed(2)}');
    }

    // 2. Service Fee Structure
    if (paymentMethod == PaymentType.cash &&
        deliveryMethod == DeliveryType.pickup) {
      serviceFee = 0.0;
      breakdownItems.add('Service Fee: Rs. 0.00 (Cash + Pickup)');
    } else {
      // Calculate service fees
      if (paymentMethod != PaymentType.cash) {
        paymentProcessingFee = subtotal * _cardProcessingFeeRate;
        breakdownItems.add(
            'Card Processing (5%): Rs. ${paymentProcessingFee.toStringAsFixed(2)}');
      }

      if (deliveryMethod == DeliveryType.delivery) {
        serviceFee = subtotal * _deliveryServiceFeeRate;
        breakdownItems
            .add('Delivery Service (5%): Rs. ${serviceFee.toStringAsFixed(2)}');
      }
    }

    final totalAmount =
        subtotal + deliveryFee + serviceFee + paymentProcessingFee;
    final breakdown = breakdownItems.join('\n');

    return FeeCalculation(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      paymentProcessingFee: paymentProcessingFee,
      totalAmount: totalAmount,
      breakdown: breakdown,
    );
  }

  /// Get payment method icon
  static String getPaymentMethodIcon(PaymentType paymentMethod) {
    switch (paymentMethod) {
      case PaymentType.cash:
        return '💵';
      case PaymentType.card:
        return '💳';
    }
  }

  /// Get payment method description
  static String getPaymentMethodDescription(PaymentType paymentMethod) {
    switch (paymentMethod) {
      case PaymentType.cash:
        return 'Pay with cash when your order arrives';
      case PaymentType.card:
        return 'Pay securely with Stripe (Test mode)';
    }
  }

  /// Enhanced validation with Stripe test card support
  static Map<String, String?> validatePaymentMethod(
    PaymentType paymentMethod,
    Map<String, dynamic> paymentDetails,
  ) {
    Map<String, String?> errors = {};

    switch (paymentMethod) {
      case PaymentType.card:
        // Card number validation
        final cardNumber = paymentDetails['cardNumber']?.toString().replaceAll(' ', '') ?? '';
        if (cardNumber.isEmpty) {
          errors['cardNumber'] = 'Card number is required';
        } else if (cardNumber.length < 13 || cardNumber.length > 19) {
          errors['cardNumber'] = 'Invalid card number length';
        } else if (!_isValidCardNumber(cardNumber)) {
          errors['cardNumber'] = 'Invalid card number';
        }

        // Expiry validation
        final expiry = paymentDetails['expiryDate']?.toString() ?? '';
        if (expiry.isEmpty) {
          errors['expiryDate'] = 'Expiry date is required';
        } else if (!_isValidExpiryDate(expiry)) {
          errors['expiryDate'] = 'Invalid or expired date';
        }

        // CVV validation
        final cvv = paymentDetails['cvv']?.toString() ?? '';
        if (cvv.isEmpty) {
          errors['cvv'] = 'CVV is required';
        } else if (cvv.length < 3 || cvv.length > 4) {
          errors['cvv'] = 'Invalid CVV';
        }

        // Cardholder name validation
        final holderName = paymentDetails['holderName']?.toString() ?? '';
        if (holderName.isEmpty) {
          errors['holderName'] = 'Cardholder name is required';
        }
        break;

      case PaymentType.cash:
        // No validation needed for cash
        break;
    }

    return errors;
  }

  /// Process payment with Stripe simulation
  static Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required PaymentType paymentMethod,
    required double amount,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      switch (paymentMethod) {
        case PaymentType.cash:
          return {
            'success': true,
            'transactionId':
                'CASH_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
            'message': 'Cash payment will be collected on delivery',
          };

        case PaymentType.card:
          return await _processStripeTestPayment(orderId, amount, paymentDetails ?? {});
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment processing failed: $e',
        'message': 'Please try again or choose a different payment method',
      };
    }
  }

  /// Simulate Stripe payment processing
  static Future<Map<String, dynamic>> _processStripeTestPayment(
    String orderId,
    double amount,
    Map<String, dynamic> paymentDetails,
  ) async {
    // Simulate processing delay
    await Future.delayed(Duration(seconds: 2));

    final cardNumber = paymentDetails['cardNumber']?.toString().replaceAll(' ', '') ?? '';
    
    // Check test card behavior
    if (_stripeTestCards.contains(cardNumber)) {
      return _getTestCardResult(cardNumber, orderId, amount);
    }

    // For non-test cards, simulate random success (90% success rate)
    final random = Random();
    final success = random.nextDouble() > 0.1;

    if (success) {
      return {
        'success': true,
        'transactionId': 'STRIPE_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Payment processed successfully',
        'paymentMethod': 'card',
        'last4': cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : '****',
      };
    } else {
      return {
        'success': false,
        'error': 'card_declined',
        'message': 'Your card was declined. Please try a different card.',
      };
    }
  }

  /// Get test card specific results
  static Map<String, dynamic> _getTestCardResult(
    String cardNumber,
    String orderId,
    double amount,
  ) {
    final transactionId = 'STRIPE_TEST_${orderId}_${DateTime.now().millisecondsSinceEpoch}';
    final last4 = cardNumber.substring(cardNumber.length - 4);

    switch (cardNumber) {
      case '4242424242424242': // Always succeeds
        return {
          'success': true,
          'transactionId': transactionId,
          'message': '✅ Test payment successful',
          'paymentMethod': 'card',
          'last4': last4,
          'testCard': true,
        };

      case '4000000000000002': // Always declined
        return {
          'success': false,
          'error': 'card_declined',
          'message': '❌ Test card: Payment declined',
          'testCard': true,
        };

      case '4000000000009995': // Insufficient funds
        return {
          'success': false,
          'error': 'insufficient_funds',
          'message': '💸 Test card: Insufficient funds',
          'testCard': true,
        };

      case '5555555555554444': // Mastercard success
        return {
          'success': true,
          'transactionId': transactionId,
          'message': '✅ Mastercard test payment successful',
          'paymentMethod': 'card',
          'last4': last4,
          'testCard': true,
        };

      case '4000000000000341': // Requires authentication
        return {
          'success': false,
          'error': 'authentication_required',
          'message': '🔐 Test card: Authentication required',
          'testCard': true,
        };

      default:
        return {
          'success': true,
          'transactionId': transactionId,
          'message': 'Test payment processed',
          'paymentMethod': 'card',
          'last4': last4,
          'testCard': true,
        };
    }
  }

  /// Basic card number validation using Luhn algorithm
  static bool _isValidCardNumber(String cardNumber) {
    if (cardNumber.isEmpty) return false;
    
    // Quick check for test cards
    if (_stripeTestCards.contains(cardNumber)) return true;
    
    // Luhn algorithm for basic validation
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.tryParse(cardNumber[i]) ?? -1;
      if (digit == -1) return false;
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit = (digit % 10) + 1;
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }

  /// Validate expiry date
  static bool _isValidExpiryDate(String expiry) {
    if (!expiry.contains('/') || expiry.length != 5) return false;
    
    final parts = expiry.split('/');
    if (parts.length != 2) return false;
    
    final month = int.tryParse(parts[0]);
    final year = int.tryParse('20${parts[1]}');
    
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    
    final now = DateTime.now();
    final expiryDate = DateTime(year, month + 1, 0); // Last day of expiry month
    
    return expiryDate.isAfter(now);
  }

  /// Save payment record
  static Future<void> savePaymentRecord({
    required String orderId,
    required String customerId,
    required PaymentType paymentMethod,
    required double amount,
    required String transactionId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final paymentData = {
        'orderId': orderId,
        'customerId': customerId,
        'paymentMethod': paymentMethod.displayName,
        'amount': amount,
        'transactionId': transactionId,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
        'additionalData': additionalData ?? {},
      };

      // Add test card flag if applicable
      if (additionalData?['testCard'] == true) {
        paymentData['isTestPayment'] = true;
      }

      await FirebaseFirestore.instance
          .collection('payments')
          .doc(transactionId)
          .set(paymentData);

      print('✅ Payment record saved: $transactionId');
    } catch (e) {
      print('❌ Error saving payment record: $e');
    }
  }

  /// Get fee breakdown text for UI display
  static String getFeeBreakdownText(FeeCalculation calculation) {
    final buffer = StringBuffer();
    buffer.writeln('Subtotal: Rs. ${calculation.subtotal.toStringAsFixed(2)}');

    if (calculation.deliveryFee > 0) {
      buffer.writeln(
          'Delivery Fee: Rs. ${calculation.deliveryFee.toStringAsFixed(2)}');
    }

    if (calculation.serviceFee > 0) {
      buffer.writeln(
          'Service Fee: Rs. ${calculation.serviceFee.toStringAsFixed(2)}');
    }

    if (calculation.paymentProcessingFee > 0) {
      buffer.writeln(
          'Processing Fee: Rs. ${calculation.paymentProcessingFee.toStringAsFixed(2)}');
    }

    buffer.writeln('─────────────────');
    buffer.write('Total: Rs. ${calculation.totalAmount.toStringAsFixed(2)}');

    return buffer.toString();
  }

  /// Get fee savings message
  static String? getFeeSavingsMessage(
      PaymentType paymentMethod, DeliveryType deliveryMethod) {
    if (paymentMethod == PaymentType.cash &&
        deliveryMethod == DeliveryType.pickup) {
      return '💰 Save 10%+ on fees by choosing Cash + Pickup!';
    }
    return null;
  }

  /// Check if card number is a Stripe test card
  static bool isStripeTestCard(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    return _stripeTestCards.contains(cleanNumber);
  }

  /// Get test card info
  static String? getTestCardInfo(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    
    switch (cleanNumber) {
      case '4242424242424242':
        return '✅ This test card will always succeed';
      case '4000000000000002':
        return '❌ This test card will always be declined';
      case '4000000000009995':
        return '💸 This test card will show insufficient funds';
      case '5555555555554444':
        return '✅ This Mastercard test card will succeed';
      case '4000000000000341':
        return '🔐 This test card requires authentication';
      default:
        return _stripeTestCards.contains(cleanNumber) 
            ? '🧪 This is a Stripe test card' 
            : null;
    }
  }
}