// FILE: lib/widgets/RatingDialog.dart
import 'package:eato/Provider/RatingProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eato/Model/Order.dart';
import 'package:eato/pages/theme/eato_theme.dart';

class RatingDialog extends StatefulWidget {
  final CustomerOrder order;
  final String customerId;
  final String customerName;
  final bool isEditMode;
  final Map<String, Map<String, dynamic>>? existingRatings;

  const RatingDialog({
    Key? key,
    required this.order,
    required this.customerId,
    required this.customerName,
    this.isEditMode = false,
    this.existingRatings,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final Map<String, double> _ratings = {};
  bool _isSubmitting = false;
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    for (var item in widget.order.items) {
      if (widget.isEditMode && widget.existingRatings != null) {
        final existing = widget.existingRatings![item.foodId];
        _ratings[item.foodId] = existing?['rating'] ?? 0.0;
      } else {
        _ratings[item.foodId] = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Flexible(child: _buildContent()),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EatoTheme.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate Your Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'From ${widget.order.storeName}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text(
            '${_currentPage + 1} of ${widget.order.items.length}',
            style: TextStyle(
              color: EatoTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / widget.order.items.length,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(EatoTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: widget.order.items.length,
      itemBuilder: (context, index) {
        final item = widget.order.items[index];
        return _buildRatingPage(item);
      },
    );
  }

  Widget _buildRatingPage(OrderItem item) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Food Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(58),
              child: item.foodImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.foodImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child:
                            Icon(Icons.fastfood, color: Colors.grey.shade400),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child:
                            Icon(Icons.fastfood, color: Colors.grey.shade400),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.fastfood, color: Colors.grey.shade400),
                    ),
            ),
          ),

          SizedBox(height: 16),

          // Food Name
          Text(
            item.foodName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: EatoTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8),

          Text(
            'Quantity: ${item.quantity}',
            style: TextStyle(
              color: EatoTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),

          SizedBox(height: 24),

          // Rating Stars
          Text(
            'How was this item?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: EatoTheme.textPrimaryColor,
            ),
          ),

          SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (starIndex) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _ratings[item.foodId] = (starIndex + 1).toDouble();
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starIndex < (_ratings[item.foodId] ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              );
            }),
          ),

          // Remove the review TextField section completely
          // The SizedBox and TextField that were here are now removed
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text('Previous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EatoTheme.primaryColor,
                  side: BorderSide(color: EatoTheme.primaryColor),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleNextOrSubmit,
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_currentPage == widget.order.items.length - 1
                      ? 'Submit Ratings'
                      : 'Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EatoTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextOrSubmit() {
    // Check if current item is rated
    final currentItem = widget.order.items[_currentPage];
    if ((_ratings[currentItem.foodId] ?? 0) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please rate this item before proceeding'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentPage == widget.order.items.length - 1) {
      _submitRatings();
    } else {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitRatings() async {
    setState(() => _isSubmitting = true);

    try {
      final ratingProvider =
          Provider.of<RatingProvider>(context, listen: false);

      await ratingProvider.submitOrderRatings(
        customerId: widget.customerId,
        customerName: widget.customerName,
        storeId: widget.order.storeId,
        orderId: widget.order.id,
        ratings: _ratings,
        isEditMode: widget.isEditMode, // Pass edit mode flag
      );

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditMode
              ? 'Ratings updated successfully!'
              : 'Thank you for your ratings!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditMode
              ? 'Failed to update ratings. Please try again.'
              : 'Failed to submit ratings. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

Future<bool?> showRatingDialog({
  required BuildContext context,
  required CustomerOrder order,
  required String customerId,
  required String customerName,
  bool isEditMode = false,
  Map<String, Map<String, dynamic>>? existingRatings,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => RatingDialog(
      order: order,
      customerId: customerId,
      customerName: customerName,
      isEditMode: isEditMode,
      existingRatings: existingRatings,
    ),
  );
}
