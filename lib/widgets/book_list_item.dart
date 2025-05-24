import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../services/image_helper_service.dart';

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
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Book Cover Image with enhanced styling
              Hero(
                tag: 'book-${book.id}',
                child: Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildBookCover(context),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Book Information with enhanced styling
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authorNames,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
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
              
              // Favorite Button with enhanced styling
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey<bool>(isFavorited),
                      color: isFavorited ? Colors.red : Colors.grey,
                      size: 28,
                    ),
                  ),
                  onPressed: onFavoriteTap,
                ),
              ),
            ],
          ),
        ),      ),
    );
  }
  Widget _buildBookCover(BuildContext context) {
    final imageHelper = ImageHelperService();
    final cleanUrl = imageHelper.cleanImageUrl(book.imageUrl);
    
    if (cleanUrl == null || cleanUrl.isEmpty) {
      return imageHelper.buildPlaceholder(context, 80, 120);
    }
    
    return CachedNetworkImage(
      imageUrl: cleanUrl,
      width: 80,
      height: 120,
      fit: BoxFit.cover,
      placeholder: (context, url) => imageHelper.buildPlaceholder(
        context, 
        80, 
        120, 
        showLoader: true,
      ),
      errorWidget: (context, url, error) {
        // Try fallback URL
        final fallbackUrl = imageHelper.getFallbackUrl(book.id);
        if (fallbackUrl != null && fallbackUrl != url) {
          return CachedNetworkImage(
            imageUrl: fallbackUrl,
            width: 80,
            height: 120,
            fit: BoxFit.cover,
            placeholder: (context, url) => imageHelper.buildPlaceholder(
              context, 
              80, 
              120, 
              showLoader: true,
            ),
            errorWidget: (context, url, error) => imageHelper.buildPlaceholder(
              context, 
              80, 
              120,
            ),
          );
        }
        return imageHelper.buildPlaceholder(context, 80, 120);
      },
    );
  }
}
