// Create a Firebase Storage Service to use in multiple places
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance =
      FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  // Cache for image URLs to avoid unnecessary network requests
  final Map<String, String> _imageCache = {};

  // Firebase Storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get image URL from Firebase Storage
  Future<String> getImageUrl(String imagePath) async {
    // Check if URL is already cached
    if (_imageCache.containsKey(imagePath)) {
      return _imageCache[imagePath]!;
    }

    try {
      // Get download URL from Firebase Storage
      final ref = _storage.ref().child(imagePath);
      final url = await ref.getDownloadURL();

      // Cache the URL for future use
      _imageCache[imagePath] = url;

      return url;
    } catch (e) {
      debugPrint('Error getting image URL for $imagePath: $e');
      return ''; // Return empty string on error
    }
  }

  // Get multiple image URLs at once
  Future<Map<String, String>> getMultipleImageUrls(
      List<String> imagePaths) async {
    final Map<String, String> results = {};

    // Create a list of futures to fetch all URLs in parallel
    final futures = imagePaths.map((path) async {
      final url = await getImageUrl(path);
      results[path] = url;
    }).toList();

    // Wait for all futures to complete
    await Future.wait(futures);

    return results;
  }

  // Clear the image cache
  void clearCache() {
    _imageCache.clear();
  }
}
