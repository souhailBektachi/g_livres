import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Helper service for handling image loading and cleaning URLs
class ImageHelperService {
  // Singleton instance
  static final ImageHelperService _instance = ImageHelperService._internal();
  factory ImageHelperService() => _instance;
  ImageHelperService._internal();

  // Web-compatible favorites storage
  static const String _favoritesKey = 'user_favorites';
  static const String _favoriteBooksKey = 'favorite_books_data';

  /// Add a book to favorites with complete data (web-compatible)
  Future<bool> addBookToFavorites(Map<String, dynamic> bookData) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final String bookId = bookData['id'] ?? '';
        
        if (bookId.isEmpty) return false;
        
        // Get existing favorites
        final favorites = prefs.getStringList(_favoritesKey) ?? [];
        final existingBooksJson = prefs.getString(_favoriteBooksKey) ?? '{}';
        
        Map<String, dynamic> booksData = {};
        try {
          booksData = jsonDecode(existingBooksJson);
        } catch (_) {
          booksData = {};
        }
        
        // Add to favorites list if not already there
        if (!favorites.contains(bookId)) {
          favorites.add(bookId);
          await prefs.setStringList(_favoritesKey, favorites);
        }
        
        // Store complete book data
        booksData[bookId] = {
          'id': bookData['id'] ?? '',
          'title': bookData['title'] ?? 'Unknown Title',
          'authors': bookData['authors'] is List 
              ? (bookData['authors'] as List).join(',')
              : (bookData['authors'] ?? '').toString(),
          'imageUrl': bookData['imageUrl'] ?? '',
          'description': bookData['description'] ?? '',
        };
        
        return await prefs.setString(_favoriteBooksKey, jsonEncode(booksData));
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding book to favorites: $e');
      }
      return false;
    }
  }

  /// Get complete book data for favorites
  Future<List<Map<String, dynamic>>> getFavoriteBooks() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final favorites = prefs.getStringList(_favoritesKey) ?? [];
        final booksDataJson = prefs.getString(_favoriteBooksKey) ?? '{}';
        
        Map<String, dynamic> booksData = {};
        try {
          booksData = jsonDecode(booksDataJson);
        } catch (_) {
          return [];
        }
        
        List<Map<String, dynamic>> result = [];
        for (String bookId in favorites) {
          if (booksData.containsKey(bookId)) {
            final bookData = booksData[bookId];
            if (bookData is Map<String, dynamic>) {
              result.add(Map<String, dynamic>.from(bookData));
            }
          }
        }
        
        return result;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting favorite books: $e');
      }
      return [];
    }
  }

  /// Add a book to favorites (web-compatible) - overloaded method for backward compatibility
  Future<bool> addToFavorites(String bookId, {Map<String, dynamic>? bookData}) async {
    if (bookData != null) {
      // If bookData is provided, use the complete book data method
      return await addBookToFavorites(bookData);
    } else {
      // Otherwise use the simple ID-only method
      try {
        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          final favorites = prefs.getStringList(_favoritesKey) ?? [];
          if (!favorites.contains(bookId)) {
            favorites.add(bookId);
            return await prefs.setStringList(_favoritesKey, favorites);
          }
          return true;
        }
        return false;
      } catch (e) {
        if (kDebugMode) {
          print('Error adding to favorites: $e');
        }
        return false;
      }
    }
  }

  /// Remove a book from favorites (web-compatible)
  Future<bool> removeFromFavorites(String bookId) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final favorites = prefs.getStringList(_favoritesKey) ?? [];
        favorites.remove(bookId);
        
        // Also remove from book data
        final booksDataJson = prefs.getString(_favoriteBooksKey) ?? '{}';
        Map<String, dynamic> booksData = {};
        try {
          booksData = jsonDecode(booksDataJson);
          booksData.remove(bookId);
          await prefs.setString(_favoriteBooksKey, jsonEncode(booksData));
        } catch (_) {}
        
        return await prefs.setStringList(_favoritesKey, favorites);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error removing from favorites: $e');
      }
      return false;
    }
  }

  /// Check if a book is in favorites (web-compatible)
  Future<bool> isFavorite(String bookId) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final favoritesList = prefs.getStringList(_favoritesKey) ?? [];
        
        return favoritesList.any((item) {
          try {
            final data = Map<String, dynamic>.from(Uri.splitQueryString(item));
            return data['id'] == bookId;
          } catch (e) {
            return false;
          }
        });
      }
      // For mobile platforms, you can still use SQLite here
      // TODO: Implement SQLite storage for mobile
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking favorites: $e');
      }
      return false;
    }
  }

  /// Get all favorite books as Book objects (web-compatible)
  Future<List<Map<String, dynamic>>> getAllFavoriteBooks() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final favoritesList = prefs.getStringList(_favoritesKey) ?? [];
        
        return favoritesList.map((item) {
          try {
            return Map<String, dynamic>.from(Uri.splitQueryString(item));
          } catch (e) {
            return <String, dynamic>{};
          }
        }).where((data) => data.isNotEmpty).toList();
      }
      // For mobile platforms, you can still use SQLite here
      // TODO: Implement SQLite storage for mobile
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting favorite books: $e');
      }
      return [];
    }
  }

  /// Get all favorite book IDs (web-compatible) - kept for backward compatibility
  Future<List<String>> getFavorites() async {
    try {
      final books = await getAllFavoriteBooks();
      return books.map((book) => book['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting favorites: $e');
      }
      return [];
    }
  }

  /// Show success/error message safely without context dependency
  void showMessage(BuildContext? context, String message, {bool isError = false}) {
    if (context != null && context.mounted) {
      // Use post-frame callback to ensure the widget tree is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isError ? Colors.red : Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  /// Clean and fix a book cover image URL with specific handling for web platform
  String? cleanImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    try {
      String cleanedUrl = url.trim();
      
      // Skip validation if URL is empty after trimming
      if (cleanedUrl.isEmpty) return null;
      
      // Try to parse URL first - if it fails, return the original
      final uri = Uri.tryParse(cleanedUrl);
      if (uri == null) {
        // Don't report error, just return null silently for invalid URLs
        return null;
      }
      
      // Only validate if it looks like a web URL
      if (cleanedUrl.contains('://')) {
        // Ensure HTTPS protocol for web URLs
        if (cleanedUrl.startsWith('http://')) {
          cleanedUrl = cleanedUrl.replaceFirst('http://', 'https://');
        }
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
    } catch (e, stackTrace) {
      // Log error but don't block - return original URL as fallback
      // Note: ErrorReportingService interface not available, using debug print instead
      if (kDebugMode) {
        print('Error cleaning image URL: $url - $e');
      }
      
      // Return original URL as last resort
      return url;
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
