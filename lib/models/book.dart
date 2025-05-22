// Book model class to represent a book
// This model handles JSON serialization/deserialization and SQLite mapping

import 'package:g_livres/services/image_helper_service.dart';

class Book {
  // Properties to store book details
  final String id;
  final String title;
  final List<String> authors;
  final String? imageUrl;
  final String? description;

  // Constructor
  Book({
    required this.id,
    required this.title,
    required this.authors,
    this.imageUrl,
    this.description,
  });

  // Factory constructor to create a Book from JSON data (Google Books API response)
  factory Book.fromJson(Map<String, dynamic> json) {
    // Extract volume info which contains most of the book details
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>;
    
    // Extract and handle authors (which may be missing)
    List<String> authorsList = [];
    if (volumeInfo.containsKey('authors') && volumeInfo['authors'] != null) {
      authorsList = List<String>.from(volumeInfo['authors']);
    }
    
    // Extract thumbnail URL if available
    String? thumbnail;
    if (volumeInfo.containsKey('imageLinks') && 
        volumeInfo['imageLinks'] != null &&
        volumeInfo['imageLinks'].containsKey('thumbnail')) {
      thumbnail = volumeInfo['imageLinks']['thumbnail'] as String;
      // Ensure the image URL uses HTTPS instead of HTTP
      thumbnail = thumbnail.replaceFirst('http://', 'https://');
    }
    
    return Book(
      // Use the volume ID as the book ID
      id: json['id'] as String,
      // Default to 'Unknown Title' if title is missing
      title: volumeInfo['title'] as String? ?? 'Unknown Title',
      // Use the extracted authors list
      authors: authorsList,
      // Use the extracted thumbnail URL
      imageUrl: thumbnail,
      // Handle potentially missing description
      description: volumeInfo['description'] as String?,
    );
  }
  
  // Convert Book object to a Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      // Join authors list into a comma-separated string for storage
      'authors': authors.join(','),
      'imageUrl': imageUrl ?? '',
      'description': description ?? '',
    };
  }
  
  // Factory constructor to create a Book from SQLite data
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      // Split the comma-separated authors string into a list
      authors: (map['authors'] as String).split(','),
      // Return null if imageUrl is empty
      imageUrl: map['imageUrl'] != '' ? map['imageUrl'] as String : null,
      // Return null if description is empty
      description: map['description'] != '' ? map['description'] as String : null,
    );
  }
  
  // Implement toString for better debugging
  @override
  String toString() {
    return 'Book{id: $id, title: $title, authors: $authors}';
  }
  
  // Get primary author or 'Unknown' if no authors
  String get primaryAuthor {
    return authors.isNotEmpty ? authors[0] : 'Unknown';
  }
  
  // Get all authors as a comma-separated string
  String get authorNames {
    return authors.isNotEmpty ? authors.join(', ') : 'Unknown';
  }
}
