import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';
import '../widgets/book_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  
  List<Book> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Method to perform book search
  Future<void> _searchBooks(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final results = await _apiService.searchBooks(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _errorMessage = 'Error searching books: ${e.toString()}';
      });
    }
  }
  
  // Check if a book is favorited
  Future<bool> _isBookFavorited(String bookId) async {
    return await _dbService.isBookFavorite(bookId);
  }
  
  // Toggle favorite status of a book
  Future<void> _toggleFavorite(Book book) async {
    final isFavorite = await _dbService.isBookFavorite(book.id);
    
    if (isFavorite) {
      await _dbService.deleteBook(book.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.title} removed from favorites')),
      );
    } else {
      await _dbService.insertBook(book);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.title} added to favorites')),
      );
    }
    
    // Refresh the UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for books',
                hintText: 'Enter book title, author, or keywords',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                  },
                ),
              ),
              onSubmitted: (value) => _searchBooks(value),
            ),
          ),
          
          // Error message
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          
          // Loading indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
            
          // Search results
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final book = _searchResults[index];
                  return FutureBuilder<bool>(
                    future: _isBookFavorited(book.id),
                    builder: (context, snapshot) {
                      final isFavorited = snapshot.data ?? false;
                      return BookListItem(
                        book: book,
                        isFavorited: isFavorited,
                        onFavoriteTap: () => _toggleFavorite(book),
                      );
                    },
                  );
                },
              ),
            ),
          
          // Empty state - no results after search
          if (!_isLoading && _searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No books found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('Try a different search term'),
                  ],
                ),
              ),
            ),
            
          // Empty state - initial state
          if (!_isLoading && _searchResults.isEmpty && _searchController.text.isEmpty && _errorMessage.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Search for books',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('Enter a search term to find books'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
