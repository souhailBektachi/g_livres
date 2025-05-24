import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';
import '../services/image_helper_service.dart';
import '../widgets/book_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ImageHelperService _imageHelper = ImageHelperService(); // Use ImageHelperService instead
  late AnimationController _animationController;
  
  List<Book> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Debounce mechanism for search
  Future<void>? _debounce;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // Method to perform book search with debounce
  Future<void> _searchBooks(String query) async {
    // Cancel previous debounce if it exists
    _debounce?.ignore();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    // Create a new debounce
    _debounce = Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        _animationController.forward();
        final results = await _apiService.searchBooks(query);
        
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
          _animationController.reverse();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isLoading = false;
            _errorMessage = 'Error searching books: ${e.toString()}';
          });
          _animationController.reverse();
        }
      }
    });
  }
  
  // Check if a book is favorited using ImageHelperService
  Future<bool> _isBookFavorited(String bookId) async {
    if (kIsWeb) {
      return await _imageHelper.isFavorite(bookId);
    } else {
      // For mobile, still use DatabaseService
      final dbService = DatabaseService();
      return await dbService.isBookFavorite(bookId);
    }
  }
  
  // Toggle favorite status using ImageHelperService for web
  Future<void> _toggleFavorite(Book book) async {
    try {
      bool success = false;
      bool wasFavorite = false;
      
      if (kIsWeb) {
        wasFavorite = await _imageHelper.isFavorite(book.id);
        if (wasFavorite) {
          success = await _imageHelper.removeFromFavorites(book.id);
        } else {
          // Pass complete book data for web storage
          final bookData = {
            'id': book.id,
            'title': book.title,
            'authors': book.authors.join(','),
            'imageUrl': book.imageUrl ?? '',
            'description': book.description ?? '',
          };
          success = await _imageHelper.addToFavorites(book.id, bookData: bookData);
        }
      } else {
        // For mobile, use DatabaseService
        final dbService = DatabaseService();
        wasFavorite = await dbService.isBookFavorite(book.id);
        if (wasFavorite) {
          await dbService.deleteBook(book.id);
          success = true;
        } else {
          await dbService.insertBook(book);
          success = true;
        }
      }
      
      if (success) {
        final message = wasFavorite 
            ? '${book.title} removed from favorites'
            : '${book.title} added to favorites';
        _showSnackBar(message, isError: false);
        
        // Refresh the UI
        setState(() {});
      } else {
        _showSnackBar('Failed to update favorites', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error updating favorites: ${e.toString()}', isError: true);
    }
  }
  
  // Show a snackbar with custom styling
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  // Show book details in a modal bottom sheet
  void _showBookDetails(Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Book image and title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book cover
                        Hero(
                          tag: 'book-${book.id}',
                          child: Container(
                            width: 100,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _buildBookCover(book),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Book info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                book.authorNames,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Favorite button
                              FutureBuilder<bool>(
                                future: _isBookFavorited(book.id),
                                builder: (context, snapshot) {
                                  final isFavorited = snapshot.data ?? false;
                                  return ElevatedButton.icon(
                                    onPressed: () {
                                      _toggleFavorite(book);
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(
                                      isFavorited ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorited ? Colors.red : null,
                                    ),
                                    label: Text(isFavorited ? 'Remove from Favorites' : 'Add to Favorites'),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Description section
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.description ?? 'No description available.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Search'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },
            tooltip: 'View Favorites',
          ),
        ],
      ),
      body: Column(
        children: [
          // Animated search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for books',
                hintText: 'Enter book title, author, or keywords',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[50],
              ),
              onChanged: _searchBooks,
              textInputAction: TextInputAction.search,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (_, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 2 * 3.14159,
                      child: child,
                    );
                  },
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
            
          // Search results
          if (_searchResults.isNotEmpty)
            Expanded(
              child: AnimatedOpacity(
                opacity: _isLoading ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 300),
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
                          onTap: () => _showBookDetails(book),
                        );
                      },
                    );
                  },
                ),
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
                    Icon(Icons.menu_book, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Search for books',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('Enter a search term to find books'),
                  ],
                ),
              ),
            ),
        ],      ),
    );
  }

  Widget _buildBookCover(Book book) {
    final imageHelper = ImageHelperService();
    final cleanUrl = imageHelper.cleanImageUrl(book.imageUrl);
    
    if (cleanUrl == null || cleanUrl.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.book, size: 50),
      );
    }
    
    return CachedNetworkImage(
      imageUrl: cleanUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) {
        // Try fallback URL
        final fallbackUrl = imageHelper.getFallbackUrl(book.id);
        if (fallbackUrl != null && fallbackUrl != url) {
          return CachedNetworkImage(
            imageUrl: fallbackUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.book, size: 50),
            ),
          );
        }
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.book, size: 50),
        );
      },
    );
  }
}
