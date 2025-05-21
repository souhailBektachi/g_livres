import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/book.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // Singleton pattern to ensure only one instance of the database service
  factory DatabaseService() => _instance;

  DatabaseService._internal();

  // Get database instance, creating it if it doesn't exist
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    // Get the database path
    String path = join(await getDatabasesPath(), 'books_database.db');

    // Open/create the database
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  // Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        authors TEXT NOT NULL,
        imageUrl TEXT,
        description TEXT
      )
    ''');
  }

  // CRUD Operations

  // Insert a book into the database
  Future<void> insertBook(Book book) async {
    final db = await database;
    
    // Insert the book, replacing any previous entry with the same ID
    await db.insert(
      'books',
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all saved books
  Future<List<Book>> getBooks() async {
    final db = await database;

    // Query the table for all books
    final List<Map<String, dynamic>> maps = await db.query('books');

    // Convert the List<Map<String, dynamic>> to List<Book>
    return List.generate(maps.length, (i) {
      return Book.fromMap(maps[i]);
    });
  }

  // Delete a book with a specific ID
  Future<void> deleteBook(String id) async {
    final db = await database;

    // Delete the book with the given ID
    await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Check if a book exists in the favorites by ID
  Future<bool> isBookFavorite(String id) async {
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
  }

  // Clear all books from the database (useful for testing or reset)
  Future<void> clearAllBooks() async {
    final db = await database;
    await db.delete('books');
  }
}
