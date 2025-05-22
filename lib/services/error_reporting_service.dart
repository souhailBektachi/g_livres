// error_reporting_service.dart
// A simple service to log and track errors in the application

import 'package:flutter/foundation.dart';

class ErrorReportingService {
  // Singleton instance
  static final ErrorReportingService _instance = ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();
  
  // Keep track of logged image URLs to avoid duplicates
  final Set<String> _loggedImageUrls = {};
    // Report image loading error with enhanced information
  void reportImageError(String url, dynamic error) {
    // Make the URL a valid key by removing any special characters
    final String cleanKey = url.replaceAll(RegExp(r'[^\w\s]+'), '_');
    
    // Avoid reporting the same URL multiple times
    if (_loggedImageUrls.contains(cleanKey)) return;
    
    _loggedImageUrls.add(cleanKey);
    
    // Log the error with detailed information
    debugPrint('=== IMAGE LOADING ERROR ===');
    debugPrint('URL: $url');
    debugPrint('Error: $error');
    debugPrint('Error Type: ${error.runtimeType}');
    debugPrint('Time: ${DateTime.now()}');
    
    // Include platform information for context
    debugPrint('Platform: ${kIsWeb ? 'Web' : 'Native'}');
    if (kIsWeb) {
      debugPrint('This error occurred in the web platform.');
      debugPrint('Some image formats may not be supported in web browsers.');
      debugPrint('Consider converting images to JPEG or PNG format.');
    }
    
    debugPrint('========================');
    
    // In a production app, you might want to send this to a remote logging service
    // or analytics platform
  }
  
  // Clear the log history (useful for testing)
  void clearImageErrorLog() {
    _loggedImageUrls.clear();
  }
  
  // Get the count of unique image errors
  int get imageErrorCount => _loggedImageUrls.length;
}
