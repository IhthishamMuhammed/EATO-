import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/pages/theme/eato_theme.dart';

class StoreAvailabilityFAB extends StatefulWidget {
  final String storeId;

  const StoreAvailabilityFAB({
    Key? key,
    required this.storeId,
  }) : super(key: key);

  @override
  State<StoreAvailabilityFAB> createState() => _StoreAvailabilityFABState();
}

class _StoreAvailabilityFABState extends State<StoreAvailabilityFAB> {
  bool _isAvailable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    if (widget.storeId.isEmpty) return;

    try {
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .get();

      if (storeDoc.exists && mounted) {
        final data = storeDoc.data()!;
        setState(() {
          _isAvailable = data['isAvailable'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading store status: $e');
    }
  }

  Future<void> _toggleAvailability() async {
    if (_isLoading || widget.storeId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      HapticFeedback.mediumImpact();

      final newStatus = !_isAvailable;

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .update({
        'isAvailable': newStatus,
      });

      setState(() {
        _isAvailable = newStatus;
      });

      // Show status change confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus ? Icons.store : Icons.store_mall_directory_outlined,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  newStatus ? 'Store is now OPEN' : 'Store is now CLOSED',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: newStatus ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: _toggleAvailability,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error toggling store availability: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update store status'),
            backgroundColor: EatoTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if no store ID
    if (widget.storeId.isEmpty) return SizedBox.shrink();

    return Positioned(
      bottom: 20,
      left: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main FAB
          FloatingActionButton(
            heroTag: "store_availability_fab_${widget.storeId}",
            onPressed: _isLoading ? null : _toggleAvailability,
            backgroundColor: _isAvailable ? Colors.green : Colors.red,
            elevation: 6,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _isAvailable
                        ? Icons.store
                        : Icons.store_mall_directory_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
          ),

          // Status text
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _isAvailable ? 'OPEN' : 'CLOSED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _isAvailable ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
