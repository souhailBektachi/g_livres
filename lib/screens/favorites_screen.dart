import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../services/db_service.dart';
import '../services/image_helper_service.dart';
import '../widgets/book_list_item.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ImageHelperService _imageHelper = ImageHelperService();
  List<Book> _favoriteBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavoriteBooks();
  }

  // Load favorite books - unified approach for both web and mobile
  Future<void> _loadFavoriteBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kIsWeb) {
        // For web, get complete book data from shared preferences
        final favoriteData = await _imageHelper.getFavoriteBooks();
        final books = favoriteData.map<Book?>((data) {
          try {
            // Safely extract authors
            List<String> authors = [];
            final authorsData = data['authors'];
            if (authorsData is String && authorsData.isNotEmpty) {
              authors = authorsData.split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            } else if (authorsData is List) {
              authors = authorsData
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
            
            // Create Book object with safe data extraction
            return Book(
              id: (data['id'] ?? '').toString(),
              title: (data['title'] ?? 'Unknown Title').toString(),
              authors: authors,
              imageUrl: data['imageUrl']?.toString().isNotEmpty == true ? data['imageUrl'].toString() : null,
              description: data['description']?.toString().isNotEmpty == true ? data['description'].toString() : null,
            );
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing book data: $e, data: $data');
            }
            return null;
          }
        }).where((book) => book != null).cast<Book>().toList();
        
        setState(() {
          _favoriteBooks = books;
          _isLoading = false;
        });
      } else {
        // For mobile, use DatabaseService
        final dbService = DatabaseService();
        if (!dbService.isAvailable) {
          setState(() {
            _favoriteBooks = [];
            _isLoading = false;
          });
          _showErrorSnackBar('Favorites are not available on this platform');
          return;
        }

        final books = await dbService.getBooks();
        setState(() {
          _favoriteBooks = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading favorites: $e');
      }
      setState(() {
        _favoriteBooks = [];
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading favorites: ${e.toString()}');
    }
  }

  // Remove book from favorites - unified approach
  Future<void> _removeFromFavorites(Book book) async {
    try {
      bool success = false;
      
      if (kIsWeb) {
        success = await _imageHelper.removeFromFavorites(book.id);
      } else {
        final dbService = DatabaseService();
        if (!dbService.isAvailable) {
          _showErrorSnackBar('Favorites are not available on this platform');
          return;
        }
        await dbService.deleteBook(book.id);
        success = true;
      }
      
      if (success) {
        _showSnackBar('${book.title} removed from favorites');
        _loadFavoriteBooks(); // Refresh the list
      } else {
        _showErrorSnackBar('Failed to remove from favorites');
      }
    } catch (e) {
      _showErrorSnackBar('Error removing book: ${e.toString()}');
    }
  }

  // Show a snackbar with the given message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Show an error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Books'),
        centerTitle: true,
        elevation: 2,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavoriteBooks,
            tooltip: 'Refresh favorites',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }
  
  Widget _buildBody() {
    // Unified approach - always show book list with images and names
    if (_favoriteBooks.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadFavoriteBooks,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _favoriteBooks.length,
        itemBuilder: (context, index) {
          final book = _favoriteBooks[index];
          return BookListItem(
            book: book,
            isFavorited: true,
            onFavoriteTap: () => _removeFromFavorites(book),
            onTap: () => _showBookDetails(context, book),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No favorite books yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Books you save will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.search),
            label: const Text('Search for Books'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show book details in a modal bottom sheet
  void _showBookDetails(BuildContext context, Book book) {
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
                              ElevatedButton.icon(
                                onPressed: () {
                                  _removeFromFavorites(book);
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.favorite, color: Colors.red),
                                label: const Text('Remove from Favorites'),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
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
        ),      ),
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
