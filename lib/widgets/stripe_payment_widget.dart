// File: lib/components/stripe_payment_widget.dart
// Stripe Payment UI using EatoComponents and EatoTheme

import 'package:flutter/material.dart';
import 'package:eato/EatoComponents.dart';
import 'package:eato/pages/theme/eato_theme.dart';
import 'package:eato/services/StripePaymentService.dart';

class StripePaymentWidget extends StatefulWidget {
  final double amount;
  final String orderId;
  final String customerId;
  final Function(Map<String, dynamic>) onPaymentSuccess;
  final Function(String) onPaymentError;

  const StripePaymentWidget({
    super.key,
    required this.amount,
    required this.orderId,
    required this.customerId,
    required this.onPaymentSuccess,
    required this.onPaymentError,
  });

  @override
  State<StripePaymentWidget> createState() => _StripePaymentWidgetState();
}

class _StripePaymentWidgetState extends State<StripePaymentWidget> {
  bool _isProcessing = false;
  String? _paymentIntentId;

  @override
  void initState() {
    super.initState();
    _createPaymentIntent();
  }

  Future<void> _createPaymentIntent() async {
    setState(() => _isProcessing = true);

    try {
      final result = await StripePaymentService.createPaymentIntent(
        amount: widget.amount,
        currency: 'lkr',
        customerId: widget.customerId,
        orderId: widget.orderId,
      );

      if (result['success']) {
        setState(() {
          _paymentIntentId = result['paymentIntentId'];
        });
      } else {
        widget.onPaymentError(result['error'] ?? 'Failed to initialize payment');
      }
    } catch (e) {
      widget.onPaymentError('Payment initialization error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processPayment() async {
    if (_paymentIntentId == null) {
      widget.onPaymentError('Payment not initialized');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await StripePaymentService.processStripePayment(
        paymentIntentId: _paymentIntentId!,
        paymentMethodId: 'pm_dummy_card_visa',
        orderId: widget.orderId,
      );

      if (result['success']) {
        await StripePaymentService.savePaymentRecord(
          orderId: widget.orderId,
          customerId: widget.customerId,
          paymentMethod: PaymentType.stripe,
          amount: widget.amount,
          transactionId: result['transactionId'],
          additionalData: {
            'paymentIntentId': result['paymentIntentId'],
            'receipt_url': result['receipt_url'],
          },
        );

        widget.onPaymentSuccess(result);
      } else {
        widget.onPaymentError(result['message'] ?? 'Payment failed');
      }
    } catch (e) {
      widget.onPaymentError('Payment processing error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Synchronous wrapper for async method - THIS IS THE KEY FIX
  void _handlePayment() {
    _processPayment();
  }

  void _cancelPayment() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EatoTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment,
                  color: EatoTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stripe Payment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: EatoTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    'Secure payment processing',
                    style: TextStyle(
                      fontSize: 12,
                      color: EatoTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Payment Amount
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EatoTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: EatoTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: EatoTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  'Rs. ${widget.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: EatoTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Payment Status
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: EatoTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _paymentIntentId == null
                        ? 'Initializing payment...'
                        : 'Processing payment...',
                    style: TextStyle(
                      color: EatoTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),

          // Payment Method Demo Info
          if (!_isProcessing && _paymentIntentId != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade600, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Demo Payment',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is a demo Stripe payment. In production, you would see Stripe\'s payment form here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment Intent ID: $_paymentIntentId',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Action Buttons - FIXED: Using synchronous wrapper
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _cancelPayment,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EatoTheme.primaryColor,
                    side: BorderSide(color: EatoTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: EatoComponents.primaryButton(
                  text: _isProcessing
                      ? 'Processing...'
                      : 'Pay Rs. ${widget.amount.toStringAsFixed(2)}',
                  onPressed: _isProcessing || _paymentIntentId == null
                      ? () {} // Disabled state - empty function
                      : _handlePayment, // Use synchronous wrapper
                  isLoading: _isProcessing,
                  height: 48,
                  icon: Icons.payment,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Security Notice
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 16, color: EatoTheme.textSecondaryColor),
              const SizedBox(width: 8),
              Text(
                'Secured by Stripe',
                style: TextStyle(
                  fontSize: 12,
                  color: EatoTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Usage Helper Function
class StripePaymentHelper {
  static void showStripePayment({
    required BuildContext context,
    required double amount,
    required String orderId,
    required String customerId,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        child: StripePaymentWidget(
          amount: amount,
          orderId: orderId,
          customerId: customerId,
          onPaymentSuccess: (result) {
            Navigator.pop(context);
            onSuccess(result);
          },
          onPaymentError: (error) {
            Navigator.pop(context);
            onError(error);
          },
        ),
      ),
    );
  }
}