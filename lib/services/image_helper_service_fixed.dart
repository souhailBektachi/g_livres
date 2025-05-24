import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'error_reporting_service.dart';

/// Helper service for handling image loading and cleaning URLs
class ImageHelperService {
  // Singleton instance
  static final ImageHelperService _instance = ImageHelperService._internal();
  factory ImageHelperService() => _instance;
  ImageHelperService._internal();

  /// Clean and fix a book cover image URL with specific handling for web platform
  String? cleanImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    try {
      String cleanedUrl = url;
      
      // Ensure HTTPS protocol
      if (cleanedUrl.startsWith('http://')) {
        cleanedUrl = cleanedUrl.replaceFirst('http://', 'https://');
      }
      
      // For the web platform, simplify URLs to avoid cross-origin issues
      if (kIsWeb) {
        // Remove parameters that might cause issues in browsers
        if (cleanedUrl.contains('?')) {
          cleanedUrl = cleanedUrl.split('?').first;
        }
        
        return cleanedUrl;
      }
      
      // Handle common issues with Google Books API URLs
      if (cleanedUrl.contains('&edge=curl')) {
        cleanedUrl = cleanedUrl.replaceAll('&edge=curl', '');
      }
      
      if (cleanedUrl.contains('zoom=')) {
        cleanedUrl = cleanedUrl.replaceAll(RegExp(r'zoom=\d+'), 'zoom=1');
      }
      
      return cleanedUrl;
    } catch (e) {
      // If any error occurs during cleaning, try a simpler approach
      try {
        // Just encode the URL without parsing
        return Uri.encodeFull(url);
      } catch (e) {
        // If all fails, return null
        print('Failed to clean image URL: $url, error: $e');
        return null;
      }
    }
  }

  /// Get a fallback URL for a book cover using OpenLibrary
  String? getFallbackUrl(String id) {
    if (id.isEmpty) return null;
    
    // For web platform, use a web-safe placeholder
    if (kIsWeb) {
      return getWebSafePlaceholder(id);
    }
    
    return 'https://covers.openlibrary.org/b/isbn/$id-M.jpg';
  }

  /// Default placeholder widget for book covers
  Widget buildPlaceholder(
    BuildContext context, 
    double width, 
    double height, 
    {bool showLoader = false}
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: showLoader
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No cover',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  /// Get a web-safe placeholder image URL based on a book ID
  String getWebSafePlaceholder(String bookId) {
    // Create a deterministic placeholder based on the book ID
    // This ensures the same book always gets the same placeholder
    final colorSeed = bookId.hashCode % 100;
    return 'https://picsum.photos/seed/$colorSeed/200/300';
  }
}
