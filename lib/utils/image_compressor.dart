import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImageCompressor {
  static const int targetSizeKB = 200;
  static const int targetSizeBytes = targetSizeKB * 1024;

  /// NO COMPRESSION - Just return original file
  /// We'll handle size reduction at the image picker level
  static Future<File?> compressImageFile(File file) async {
    try {
      int originalSize = await file.length();
      print('Original size: ${getFileSize(originalSize)}');
      
      // Return original file without any modification
      return file;
    } catch (e) {
      print('Error handling image: $e');
      return file;
    }
  }

  /// NO COMPRESSION for bytes either
  static Future<Uint8List?> compressImageBytes(Uint8List bytes) async {
    try {
      print('Image bytes size: ${getFileSize(bytes.length)}');
      return bytes;
    } catch (e) {
      print('Error handling image bytes: $e');
      return bytes;
    }
  }

  /// Helper method to pick image with AGGRESSIVE compression settings
  static Future<XFile?> pickCompressedImage({
    required ImageSource source,
    int maxWidth = 400,      // Much smaller (was 800)
    int maxHeight = 300,     // Much smaller (was 600)
    int imageQuality = 40,   // Much lower quality (was 70)
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      print('🎯 AGGRESSIVE Compression settings:');
      print('Max resolution: ${maxWidth}x${maxHeight}');
      print('Quality: ${imageQuality}%');
      print('Target size: ${getFileSize(targetSizeBytes)}');
      
      final result = await picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (result != null) {
        final fileSize = await File(result.path).length();
        print('📤 Compressed result: ${getFileSize(fileSize)}');
        print('✅ Target achieved: ${fileSize <= targetSizeBytes ? "YES" : "NO"}');
        
        // If still too big, suggest even more aggressive settings
        if (fileSize > targetSizeBytes) {
          print('⚠️  Still too big! Consider using pickUltraCompressedImage() instead');
        }
      }
      
      return result;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Ultra aggressive compression for very large images
  static Future<XFile?> pickUltraCompressedImage({
    required ImageSource source,
    int maxWidth = 250,      // Very small resolution
    int maxHeight = 200,     // Very small resolution  
    int imageQuality = 25,   // Very low quality
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      print('🔥 ULTRA AGGRESSIVE Compression settings:');
      print('Max resolution: ${maxWidth}x${maxHeight}');
      print('Quality: ${imageQuality}%');
      print('Target size: ${getFileSize(targetSizeBytes)}');
      
      final result = await picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (result != null) {
        final fileSize = await File(result.path).length();
        print('📤 Ultra compressed result: ${getFileSize(fileSize)}');
        print('✅ Target achieved: ${fileSize <= targetSizeBytes ? "YES" : "NO"}');
      }
      
      return result;
    } catch (e) {
      print('Error picking ultra compressed image: $e');
      return null;
    }
  }

  /// Extreme compression for when nothing else works
  static Future<XFile?> pickExtremeCompressedImage({
    required ImageSource source,
    int maxWidth = 150,      // Extreme small resolution
    int maxHeight = 120,     // Extreme small resolution
    int imageQuality = 15,   // Extreme low quality
  }) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      print('💥 EXTREME Compression settings:');
      print('Max resolution: ${maxWidth}x${maxHeight}');
      print('Quality: ${imageQuality}%');
      print('Target size: ${getFileSize(targetSizeBytes)}');
      
      final result = await picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (result != null) {
        final fileSize = await File(result.path).length();
        print('📤 Extreme compressed result: ${getFileSize(fileSize)}');
        print('✅ Target achieved: ${fileSize <= targetSizeBytes ? "YES" : "NO"}');
      }
      
      return result;
    } catch (e) {
      print('Error picking extreme compressed image: $e');
      return null;
    }
  }

  /// Smart compression - automatically chooses the right level
  static Future<XFile?> pickSmartCompressedImage({
    required ImageSource source,
  }) async {
    try {
      print('🧠 SMART Compression: Testing different levels...');
      
      // Try normal compression first
      XFile? result = await pickCompressedImage(source: source);
      if (result != null) {
        final fileSize = await File(result.path).length();
        if (fileSize <= targetSizeBytes) {
          print('✅ Normal compression successful!');
          return result;
        }
      }
      
      print('⚡ Normal failed, trying ultra compression...');
      
      // Try ultra compression
      result = await pickUltraCompressedImage(source: source);
      if (result != null) {
        final fileSize = await File(result.path).length();
        if (fileSize <= targetSizeBytes) {
          print('✅ Ultra compression successful!');
          return result;
        }
      }
      
      print('💥 Ultra failed, trying extreme compression...');
      
      // Try extreme compression as last resort
      result = await pickExtremeCompressedImage(source: source);
      if (result != null) {
        final fileSize = await File(result.path).length();
        print(fileSize <= targetSizeBytes ? '✅ Extreme compression successful!' : '❌ All compression levels failed');
        return result;
      }
      
      return null;
    } catch (e) {
      print('Error in smart compression: $e');
      return null;
    }
  }

  /// Get human readable file size
  static String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}