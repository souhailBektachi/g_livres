import 'package:flutter/material.dart';
import '../models/book.dart';

class BookListItem extends StatelessWidget {
  final Book book;
  final bool isFavorited;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onTap;

  const BookListItem({
    Key? key,
    required this.book,
    required this.isFavorited,
    required this.onFavoriteTap,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Book Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.imageUrl != null
                    ? Image.network(
                        book.imageUrl!,
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 80,
                            height: 120,
                            child: Center(
                              child: Icon(Icons.image_not_supported, size: 40),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.book, size: 40),
                      ),
              ),
              const SizedBox(width: 16),
              
              // Book Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authorNames,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.description != null && book.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        book.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Favorite Button
              IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : null,
                ),
                onPressed: onFavoriteTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
