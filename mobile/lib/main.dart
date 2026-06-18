import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/ar_viewer_screen.dart';
import 'screens/scan_result_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ApiService(),
      child: const EdutechApp(),
    ),
  );
}

class EdutechApp extends StatelessWidget {
  const EdutechApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1); // Indigo
    const secondaryColor = Color(0xFF8B5CF6); // Violet
    const darkBackgroundColor = Color(0xFF0F172A); // Slate 900
    const darkSurfaceColor = Color(0xFF1E293B); // Slate 800

    return MaterialApp(
      title: 'ARise Learn',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Default to dark mode for premium sci-fi feel
      
      // Light Theme Design
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
      ),

      // Dark Theme Design (Premium Sci-Fi Glow)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: darkSurfaceColor,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: darkSurfaceColor,
          shadowColor: Colors.black.withOpacity(0.4),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: darkBackgroundColor,
          elevation: 0,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF334155), // Slate 700
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
      ),
      
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/ar': (context) => const ARViewerScreen(),
        '/result': (context) => const ScanResultScreen(),
      },
    );
  }
}
