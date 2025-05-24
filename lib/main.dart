import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:cached_network_image/cached_network_image.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'services/error_reporting_service.dart';

// Conditional imports for platform-specific database setup
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory based on platform
  try {
    if (!kIsWeb) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Initialize FFI for desktop platforms
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        if (kDebugMode) {
          print('Initialized SQLite FFI for desktop platform');
        }
      } else {
        // Mobile platforms use the default factory
        if (kDebugMode) {
          print('Using default SQLite factory for mobile platform');
        }
      }
    } else {
      // Web platform - SQLite not available
      if (kDebugMode) {
        print('Web platform detected - SQLite not available');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing database: $e');
    }
  }

  // Configure device orientation - skip for web platform
  if (!kIsWeb) {
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // Configure transparent status bar
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error setting system UI: $e');
      }
    }
  }
  
  // Initialize CachedNetworkImage settings for better performance
  try {
    CachedNetworkImage.logLevel = CacheManagerLogLevel.none; // Reduce verbose logging
  } catch (e) {
    if (kDebugMode) {
      print('Error configuring image cache: $e');
    }
  }
  
  // Configure global image error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    // Handle image-related errors more gracefully
    final exception = details.exception;
    if (exception.toString().contains('image') || 
        exception.toString().contains('Failed to load') ||
        exception.toString().contains('NetworkImage')) {
      if (kDebugMode) {
        print('Image loading error: ${exception.toString()}');
      }
      // Don't crash the app for image errors
      return;
    }
    
    // Forward other errors to the original handler
    FlutterError.presentError(details);
  };
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Configure the image cache to be more robust
    PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 100; // 100 MB cache
    
    return MaterialApp(
      title: 'G-Livres',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade900,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      themeMode: ThemeMode.system,
      routes: {
        '/': (context) => const SearchScreen(),
        '/favorites': (context) => const FavoritesScreen(),
      },
      initialRoute: '/',
    );
  }
}
