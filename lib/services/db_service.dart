import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../models/book.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static bool _isInitialized = false;
  static String? _initError;

  // Singleton pattern to ensure only one instance of the database service
  factory DatabaseService() => _instance;

  DatabaseService._internal();

  // Check if database is available (not on web)
  bool get isAvailable => !kIsWeb && _initError == null;

  // Get database instance, creating it if it doesn't exist
  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database is not supported on web platform');
    }

    if (_initError != null) {
      throw Exception('Database initialization failed: $_initError');
    }

    if (_database != null) return _database!;
    
    try {
      _database = await _initDatabase();
      _isInitialized = true;
      return _database!;
    } catch (e) {
      _initError = e.toString();
      if (kDebugMode) {
        print('Database initialization error: $e');
      }
      rethrow;
    }
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    try {
      // Get the database path
      String path = join(await getDatabasesPath(), 'books_database.db');
      
      if (kDebugMode) {
        print('Database path: $path');
      }

      // Open/create the database
      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDatabase,
        onOpen: (db) {
          if (kDebugMode) {
            print('Database opened successfully');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing database: $e');
      }
      rethrow;
    }
  }

  // Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE books(
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          authors TEXT NOT NULL,
          imageUrl TEXT,
          description TEXT
        )
      ''');
      
      if (kDebugMode) {
        print('Database tables created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating database tables: $e');
      }
      rethrow;
    }
  }

  // CRUD Operations with error handling

  // Insert a book into the database
  Future<void> insertBook(Book book) async {
    if (!isAvailable) {
      throw UnsupportedError('Database not available on this platform');
    }

    try {
      final db = await database;
      
      // Insert the book, replacing any previous entry with the same ID
      await db.insert(
        'books',
        book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      if (kDebugMode) {
        print('Book inserted: ${book.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting book: $e');
      }
      rethrow;
    }
  }

  // Get all saved books
  Future<List<Book>> getBooks() async {
    if (!isAvailable) {
      if (kIsWeb) {
        // Return empty list for web instead of throwing error
        return [];
      }
      throw UnsupportedError('Database not available on this platform');
    }

    try {
      final db = await database;

      // Query the table for all books
      final List<Map<String, dynamic>> maps = await db.query('books');

      // Convert the List<Map<String, dynamic>> to List<Book>
      final books = List.generate(maps.length, (i) {
        return Book.fromMap(maps[i]);
      });
      
      if (kDebugMode) {
        print('Retrieved ${books.length} books from database');
      }
      
      return books;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting books: $e');
      }
      // Return empty list instead of throwing error
      return [];
    }
  }

  // Delete a book with a specific ID
  Future<void> deleteBook(String id) async {
    if (!isAvailable) {
      throw UnsupportedError('Database not available on this platform');
    }

    try {
      final db = await database;

      // Delete the book with the given ID
      await db.delete(
        'books',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (kDebugMode) {
        print('Book deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting book: $e');
      }
      rethrow;
    }
  }

  // Check if a book exists in the favorites by ID
  Future<bool> isBookFavorite(String id) async {
    if (!isAvailable) {
      // Return false for web instead of throwing error
      return false;
    }

    try {
      final db = await database;
      
      // Count how many books have this ID (should be 0 or 1)
      final result = await db.query(
        'books',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      // If the result has any entries, the book is a favorite
      return result.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking book favorite status: $e');
      }
      // Return false instead of throwing error
      return false;
    }
  }

  // Clear all books from the database (useful for testing or reset)
  Future<void> clearAllBooks() async {
    if (!isAvailable) {
      throw UnsupportedError('Database not available on this platform');
    }

    try {
      final db = await database;
      await db.delete('books');
      
      if (kDebugMode) {
        print('All books cleared from database');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing books: $e');
      }
      rethrow;
    }
  }
}
