// File: lib/services/PaymentService.dart
// Professional payment service with dynamic fee calculations

import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Get available payment methods
  static List<PaymentType> getAvailablePaymentMethods() {
    return PaymentType.values;
  }

  /// Check if payment method supports the delivery type
  static bool isPaymentMethodAvailable(
      PaymentType payment, DeliveryType delivery) {
    // All payment methods support both delivery types
    return true;
  }

  /// Calculate comprehensive fees based on payment and delivery method
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
      // ✅ Cash + Pickup = 0% service fee
      serviceFee = 0.0;
      breakdownItems.add('Service Fee: Rs. 0.00 (Cash + Pickup)');
    } else {
      // Calculate service fees
      if (paymentMethod != PaymentType.cash) {
        // Card/Digital payment processing fee
        paymentProcessingFee = subtotal * _cardProcessingFeeRate;
        breakdownItems.add(
            'Payment Processing (5%): Rs. ${paymentProcessingFee.toStringAsFixed(2)}');
      }

      if (deliveryMethod == DeliveryType.delivery) {
        // Delivery service fee
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
        return 'Pay securely with your debit/credit card';
    }
  }

  /// Validate payment details (for future use)
  static Map<String, String?> validatePaymentMethod(
    PaymentType paymentMethod,
    Map<String, dynamic> paymentDetails,
  ) {
    Map<String, String?> errors = {};

    switch (paymentMethod) {
      case PaymentType.card:
        if (paymentDetails['cardNumber'] == null ||
            paymentDetails['cardNumber'].toString().length < 16) {
          errors['cardNumber'] = 'Valid card number required';
        }
        if (paymentDetails['expiryDate'] == null) {
          errors['expiryDate'] = 'Expiry date required';
        }
        if (paymentDetails['cvv'] == null ||
            paymentDetails['cvv'].toString().length < 3) {
          errors['cvv'] = 'Valid CVV required';
        }
        break;

      case PaymentType.cash:
        // No validation needed for cash
        break;
    }

    return errors;
  }

  /// Process payment (for future integration)
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
          // TODO: Integrate with payment gateway (Stripe, etc.)
          await Future.delayed(Duration(seconds: 2)); // Simulate processing
          return {
            'success': true,
            'transactionId':
                'CARD_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
            'message': 'Card payment processed successfully',
          };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment processing failed: $e',
        'message': 'Please try again or choose a different payment method',
      };
    }
  }

  /// Save payment details to Firestore
  static Future<void> savePaymentRecord({
    required String orderId,
    required String customerId,
    required PaymentType paymentMethod,
    required double amount,
    required String transactionId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(transactionId)
          .set({
        'orderId': orderId,
        'customerId': customerId,
        'paymentMethod': paymentMethod.displayName,
        'amount': amount,
        'transactionId': transactionId,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
        'additionalData': additionalData ?? {},
      });

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
      return '🎉 You\'re saving on service fees with Cash + Pickup!';
    }

    if (paymentMethod == PaymentType.cash) {
      return '💰 Save 5% by choosing Cash payment!';
    }

    if (deliveryMethod == DeliveryType.pickup) {
      return '🚗 Save Rs. $_baseDeliveryFee with Pickup option!';
    }

    return null;
  }
}
