import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/db_service.dart';
import '../widgets/book_list_item.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Book> _favoriteBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteBooks();
  }

  // Load favorite books from the database
  Future<void> _loadFavoriteBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final books = await _dbService.getBooks();
      setState(() {
        _favoriteBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading favorites: ${e.toString()}');
    }
  }

  // Remove book from favorites
  Future<void> _removeFromFavorites(Book book) async {
    try {
      await _dbService.deleteBook(book.id);
      _showSnackBar('${book.title} removed from favorites');
      _loadFavoriteBooks(); // Refresh the list
    } catch (e) {
      _showErrorSnackBar('Error removing book: ${e.toString()}');
    }
  }

  // Show a snackbar with the given message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Show an error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Books'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavoriteBooks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteBooks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No favorite books yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Books you save will appear here'),
                    ],
                  ),
                )
              : ListView.builder(
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
  
  // Show book details in a dialog
  void _showBookDetails(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (book.imageUrl != null) ...[
                Center(
                  child: Image.network(
                    book.imageUrl!,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 100);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('Author(s): ${book.authorNames}'),
              const SizedBox(height: 8),
              if (book.description != null && book.description!.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(book.description!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _removeFromFavorites(book);
              Navigator.of(context).pop();
            },
            child: const Text('Remove from Favorites'),
          ),
        ],
      ),
    );
  }
}
