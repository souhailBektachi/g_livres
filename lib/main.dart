import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'services/error_reporting_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure device orientation - skip for web platform
  if (!kIsWeb) {
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
  }
  
  // Initialize CachedNetworkImage settings for better performance
  CachedNetworkImage.logLevel = CacheManagerLogLevel.verbose;
  
  // Configure global image error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    // If the error is related to image loading, handle it specially
    final exception = details.exception;
    if (exception is NetworkImageLoadException) {
      ErrorReportingService().reportImageError(
        exception.uri.toString(), 
        exception.statusCode
      );
    } else if (exception.toString().contains('image') || 
              exception.toString().contains('Failed to load')) {
      // Try to extract the URL from the error message
      final errorStr = exception.toString();
      final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(errorStr);
      if (urlMatch != null) {
        ErrorReportingService().reportImageError(
          urlMatch.group(0) ?? 'Unknown URL', 
          exception
        );
      }
    }
    
    // Forward the error to the original handler
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
