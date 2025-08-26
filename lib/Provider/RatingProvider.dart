import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eato/Model/Order.dart';
import 'dart:async';

class RatingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Check if user has already rated food items from a specific order

  /// Check if user has already rated food items from a specific order
  Future<Map<String, bool>> checkExistingRatings(
      String customerId, String storeId, List<OrderItem> items) async {
    try {
      Map<String, bool> ratingStatus = {};

      for (var item in items) {
        final ratingDoc = await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('foods')
            .doc(item.foodId)
            .collection('ratings')
            .doc(customerId)
            .get();

        // This returns TRUE if rating EXISTS, FALSE if it doesn't
        ratingStatus[item.foodId] = ratingDoc.exists;
        print('Food ${item.foodId} rating exists: ${ratingDoc.exists}');
      }

      return ratingStatus;
    } catch (e) {
      print('Error checking existing ratings: $e');
      return {};
    }
  }

  /// Submit rating for a food item
  Future<void> submitFoodRating({
    required String customerId,
    required String customerName,
    required String storeId,
    required String foodId,
    required double rating,
    String? review,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final batch = _firestore.batch();

      // Add individual rating document
      final ratingRef = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('foods')
          .doc(foodId)
          .collection('ratings')
          .doc(customerId);

      batch.set(ratingRef, {
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'review': review,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update food's overall rating
      await _updateFoodAverageRating(storeId, foodId);

      await batch.commit();
      print('✅ Rating submitted successfully');
    } catch (e) {
      _error = 'Error submitting rating: $e';
      print('❌ $_error');
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update food's average rating
  Future<void> _updateFoodAverageRating(String storeId, String foodId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('foods')
          .doc(foodId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      double totalRating = 0.0;
      int count = 0;

      for (var doc in ratingsSnapshot.docs) {
        final data = doc.data();
        totalRating += (data['rating'] as num).toDouble();
        count++;
      }

      final averageRating = totalRating / count;

      // Update food document with new average
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('foods')
          .doc(foodId)
          .update({
        'rating': averageRating,
        'ratingCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating average rating: $e');
    }
  }

  Future<void> _updateFoodAverageRatingSafely(String storeId, String foodId,
      {int retryCount = 0}) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get all rating documents first (outside transaction)
        final ratingsSnapshot = await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('foods')
            .doc(foodId)
            .collection('ratings')
            .get();

        if (ratingsSnapshot.docs.isEmpty) return;

        double totalRating = 0.0;
        int count = 0;

        for (var doc in ratingsSnapshot.docs) {
          final data = doc.data();
          if (data['rating'] != null) {
            totalRating += (data['rating'] as num).toDouble();
            count++;
          }
        }

        if (count > 0) {
          final averageRating = totalRating / count;
          final foodRef = _firestore
              .collection('stores')
              .doc(storeId)
              .collection('foods')
              .doc(foodId);

          // Use transaction only for the update
          transaction.update(foodRef, {
            'rating': averageRating,
            'ratingCount': count,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error updating average rating: $e');
      // Retry up to 3 times with exponential backoff
      if (retryCount < 3) {
        await Future.delayed(Duration(milliseconds: 100 * (retryCount + 1)));
        await _updateFoodAverageRatingSafely(storeId, foodId,
            retryCount: retryCount + 1);
      } else {
        print('Failed to update average rating after 3 retries');
      }
    }
  }

  Future<void> updateFoodRating({
    required String customerId,
    required String customerName,
    required String storeId,
    required String foodId,
    required double newRating,
    String? newReview,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Update individual rating document
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('foods')
          .doc(foodId)
          .collection('ratings')
          .doc(customerId)
          .update({
        'rating': newRating,
        'review': newReview,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recalculate and update food's average rating
      await _updateFoodAverageRating(storeId, foodId);

      print('✅ Rating updated successfully');
    } catch (e) {
      _error = 'Error updating rating: $e';
      print('❌ $_error');
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, Map<String, dynamic>>> getExistingRatings({
    required String customerId,
    required String storeId,
    required List<OrderItem> items,
  }) async {
    try {
      Map<String, Map<String, dynamic>> existingRatings = {};

      for (var item in items) {
        final ratingDoc = await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('foods')
            .doc(item.foodId)
            .collection('ratings')
            .doc(customerId)
            .get();

        if (ratingDoc.exists) {
          final data = ratingDoc.data() as Map<String, dynamic>;
          existingRatings[item.foodId] = {
            'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
            'review': data['review'] ?? '',
          };
        }
      }

      return existingRatings;
    } catch (e) {
      print('Error getting existing ratings: $e');
      return {};
    }
  }

  /// Get food's current rating info
  Future<Map<String, dynamic>> getFoodRatingInfo(
      String storeId, String foodId) async {
    try {
      final foodDoc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('foods')
          .doc(foodId)
          .get();

      if (foodDoc.exists) {
        final data = foodDoc.data() as Map<String, dynamic>;
        return {
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
          'ratingCount': data['ratingCount'] ?? 0,
        };
      }
      return {'rating': 0.0, 'ratingCount': 0};
    } catch (e) {
      print('Error getting rating info: $e');
      return {'rating': 0.0, 'ratingCount': 0};
    }
  }

  Future<void> submitOrderRatings({
    required String customerId,
    required String customerName,
    required String storeId,
    required String orderId,
    required Map<String, double> ratings,
    Map<String, String>? reviews,
    bool isEditMode = false,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // FIX 3: Use transaction to prevent race conditions
      await _firestore.runTransaction((transaction) async {
        final batch = _firestore.batch();

        // Submit individual ratings
        for (var entry in ratings.entries) {
          final foodId = entry.key;
          final rating = entry.value;
          final review = reviews?[foodId];

          final ratingRef = _firestore
              .collection('stores')
              .doc(storeId)
              .collection('foods')
              .doc(foodId)
              .collection('ratings')
              .doc(customerId);

          final ratingData = {
            'customerId': customerId,
            'customerName': customerName,
            'orderId': orderId,
            'rating': rating,
            'review': review,
            'timestamp': FieldValue.serverTimestamp(),
          };

          if (isEditMode) {
            ratingData['updatedAt'] = FieldValue.serverTimestamp();
            batch.update(ratingRef, ratingData);
          } else {
            batch.set(ratingRef, ratingData);
          }
        }

        // Only mark order as rated if it's not edit mode
        if (!isEditMode) {
          final orderRef = _firestore.collection('orders').doc(orderId);
          batch.update(orderRef, {
            'isRated': true,
            'ratedAt': FieldValue.serverTimestamp(),
          });
        }

        // Commit all changes atomically
        await batch.commit();
      });

      // Update average ratings for all foods (outside transaction to avoid deadlock)
      for (String foodId in ratings.keys) {
        await _updateFoodAverageRatingSafely(storeId, foodId);
      }

      print(
          '✅ Order ratings ${isEditMode ? 'updated' : 'submitted'} successfully');
    } catch (e) {
      _error = 'Error ${isEditMode ? 'updating' : 'submitting'} ratings: $e';
      print('❌ $_error');
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
