// File: lib/services/StripePaymentService.dart
// Enhanced PaymentService with Stripe integration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:math';

enum PaymentType {
  cash('Cash Payment'),
  card('Card Payment'),
  stripe('Stripe Payment'); // NEW

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

class StripePaymentService {
  static const double _baseDeliveryFee = 100.0;
  static const double _cardProcessingFeeRate = 0.05; // 5%
  static const double _stripeProcessingFeeRate = 0.029; // 2.9%
  static const double _deliveryServiceFeeRate = 0.05; // 5%

  // Dummy Stripe Configuration
  static const String _stripePublishableKey = 'pk_test_dummy_key_123';
  static const String _stripeSecretKey = 'sk_test_dummy_key_123';

  /// Get available payment methods including Stripe
  static List<PaymentType> getAvailablePaymentMethods() {
    return PaymentType.values;
  }

  /// Check if payment method supports the delivery type
  static bool isPaymentMethodAvailable(
      PaymentType payment, DeliveryType delivery) {
    return true;
  }

  /// Calculate fees with Stripe support
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

    // 2. Payment Processing Fees
    if (paymentMethod == PaymentType.cash &&
        deliveryMethod == DeliveryType.pickup) {
      // Cash + Pickup = 0% service fee
      serviceFee = 0.0;
      breakdownItems.add('Service Fee: Rs. 0.00 (Cash + Pickup)');
    } else {
      // Calculate service fees based on payment method
      switch (paymentMethod) {
        case PaymentType.card:
          paymentProcessingFee = subtotal * _cardProcessingFeeRate;
          breakdownItems.add(
              'Card Processing (5%): Rs. ${paymentProcessingFee.toStringAsFixed(2)}');
          break;
        case PaymentType.stripe:
          paymentProcessingFee = subtotal * _stripeProcessingFeeRate;
          breakdownItems.add(
              'Stripe Processing (2.9%): Rs. ${paymentProcessingFee.toStringAsFixed(2)}');
          break;
        case PaymentType.cash:
          // No processing fee for cash
          break;
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
      case PaymentType.stripe:
        return '🔷';
    }
  }

  /// Get payment method description
  static String getPaymentMethodDescription(PaymentType paymentMethod) {
    switch (paymentMethod) {
      case PaymentType.cash:
        return 'Pay with cash when your order arrives';
      case PaymentType.card:
        return 'Pay securely with your debit/credit card';
      case PaymentType.stripe:
        return 'Pay securely with Stripe (Cards, Digital Wallets)';
    }
  }

  /// Dummy Stripe Payment Intent Creation
  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String customerId,
    required String orderId,
  }) async {
    try {
      // Simulate API call delay
      await Future.delayed(Duration(seconds: 1));

      // Generate dummy payment intent
      final paymentIntentId = _generateDummyPaymentIntentId();
      final clientSecret = _generateDummyClientSecret();

      return {
        'success': true,
        'paymentIntentId': paymentIntentId,
        'clientSecret': clientSecret,
        'amount': (amount * 100).round(), // Amount in cents
        'currency': currency,
        'status': 'requires_payment_method',
        'created': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create payment intent: $e',
      };
    }
  }

  /// Dummy Stripe Payment Processing
  static Future<Map<String, dynamic>> processStripePayment({
    required String paymentIntentId,
    required String paymentMethodId,
    required String orderId,
  }) async {
    try {
      // Simulate processing time
      await Future.delayed(Duration(seconds: 2));

      // Simulate random success/failure (90% success rate)
      final random = Random();
      final success = random.nextDouble() > 0.1;

      if (success) {
        final transactionId = _generateDummyTransactionId();
        
        return {
          'success': true,
          'transactionId': transactionId,
          'paymentIntentId': paymentIntentId,
          'status': 'succeeded',
          'message': 'Payment processed successfully via Stripe',
          'receipt_url': 'https://pay.stripe.com/receipts/dummy_$transactionId',
        };
      } else {
        return {
          'success': false,
          'error': 'card_declined',
          'message': 'Your card was declined. Please try a different payment method.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'payment_failed',
        'message': 'Payment processing failed: $e',
      };
    }
  }

  /// Main payment processing method (enhanced with Stripe)
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
          await Future.delayed(Duration(seconds: 2));
          return {
            'success': true,
            'transactionId':
                'CARD_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
            'message': 'Card payment processed successfully',
          };

        case PaymentType.stripe:
          // Enhanced Stripe processing
          final paymentIntentResult = await createPaymentIntent(
            amount: amount,
            currency: 'lkr', // Sri Lankan Rupees
            customerId: paymentDetails?['customerId'] ?? 'dummy_customer',
            orderId: orderId,
          );

          if (!paymentIntentResult['success']) {
            return paymentIntentResult;
          }

          // Simulate payment method attachment and confirmation
          final paymentResult = await processStripePayment(
            paymentIntentId: paymentIntentResult['paymentIntentId'],
            paymentMethodId: paymentDetails?['paymentMethodId'] ?? 'pm_dummy_123',
            orderId: orderId,
          );

          return paymentResult;
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment processing failed: $e',
        'message': 'Please try again or choose a different payment method',
      };
    }
  }

  /// Save payment record with Stripe support
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

      // Add Stripe-specific data if applicable
      if (paymentMethod == PaymentType.stripe && additionalData != null) {
        paymentData['stripePaymentIntentId'] = additionalData['paymentIntentId'];
        paymentData['stripeReceiptUrl'] = additionalData['receipt_url'];
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

  /// Fee savings message with Stripe consideration
  static String? getFeeSavingsMessage(
      PaymentType paymentMethod, DeliveryType deliveryMethod) {
    if (paymentMethod == PaymentType.cash &&
        deliveryMethod == DeliveryType.pickup) {
      return '💰 Save 10%+ on fees by choosing Cash + Pickup!';
    }
    if (paymentMethod == PaymentType.stripe) {
      return '💳 Lower processing fees with Stripe (2.9% vs 5%)';
    }
    return null;
  }

  // Helper methods for dummy data generation
  static String _generateDummyPaymentIntentId() {
    return 'pi_dummy_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  static String _generateDummyClientSecret() {
    return 'pi_dummy_${DateTime.now().millisecondsSinceEpoch}_secret_${Random().nextInt(9999)}';
  }

  static String _generateDummyTransactionId() {
    return 'STRIPE_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  /// Validate Stripe payment details
  static Map<String, String?> validateStripePayment(
      Map<String, dynamic> paymentDetails) {
    Map<String, String?> errors = {};

    if (paymentDetails['paymentMethodId'] == null) {
      errors['paymentMethod'] = 'Payment method is required';
    }

    if (paymentDetails['customerId'] == null) {
      errors['customer'] = 'Customer information is required';
    }

    return errors;
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
}