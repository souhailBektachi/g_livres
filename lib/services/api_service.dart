import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class ApiService {
  // Base URL for the Google Books API
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  
  // Maximum number of results to fetch per API call
  static const int _maxResults = 40;

  // Fetch books based on search query
  Future<List<Book>> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // Encode the search query for URL
      final encodedQuery = Uri.encodeComponent(query.trim());
      
      // Build the full URL with search parameters
      final url = '$_baseUrl?q=$encodedQuery&maxResults=$_maxResults';
      
      // Perform the HTTP GET request
      final response = await http.get(Uri.parse(url));
      
      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response body
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Check if the response contains items
        if (data.containsKey('items') && data['items'] != null) {
          // Convert each item to a Book object
          return (data['items'] as List)
              .map((item) => Book.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          // No books found for the query
          return [];
        }
      } else {
        // Handle HTTP error
        throw Exception('Failed to load books: HTTP ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors that occur during the API call
      throw Exception('Failed to search books: $e');
    }
  }

  // Fetch a specific book by ID
  Future<Book?> getBookById(String id) async {
    try {
      // Build the URL for a specific book
      final url = '$_baseUrl/$id';
      
      // Perform the HTTP GET request
      final response = await http.get(Uri.parse(url));
      
      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response body and create a Book object
        final Map<String, dynamic> data = json.decode(response.body);
        return Book.fromJson(data);
      } else {
        // Handle HTTP error
        throw Exception('Failed to load book: HTTP ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors that occur during the API call
      throw Exception('Failed to get book by ID: $e');
    }
  }
}
