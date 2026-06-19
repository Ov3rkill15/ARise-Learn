import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/ar_viewer_screen.dart';
import 'screens/scan_result_screen.dart';
import 'services/api_service.dart';

// Coursera Design System Colors
const _kPrimary = Color(0xFF0056D2);
const _kInk = Color(0xFF1F1F1F);
const _kCanvas = Color(0xFFFFFFFF);
const _kCanvasSubdued = Color(0xFFF5F7F9);
const _kBorder = Color(0xFFD6DBDF);
const _kBorderSubtle = Color(0xFFEEF0F2);
const _kGold = Color(0xFFF5AF02);
const _kDarkBg = Color(0xFF111827);
const _kDarkSurface = Color(0xFF1F2937);
const _kDarkCard = Color(0xFF374151);

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
    return MaterialApp(
      title: 'ARise Learn',
      debugShowCheckedModeBanner: false,
      themeMode: context.watch<ApiService>().themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: _kCanvasSubdued,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _kPrimary,
          primary: _kPrimary,
          onPrimary: Colors.white,
          secondary: _kGold,
          brightness: Brightness.light,
          surface: _kCanvas,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _kBorderSubtle),
          ),
          color: _kCanvas,
          shadowColor: Colors.black.withOpacity(0.08),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: _kCanvas,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kInk,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _kCanvas,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kPrimary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        dividerTheme: const DividerThemeData(color: _kBorderSubtle),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _kDarkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _kPrimary,
          primary: _kPrimary,
          onPrimary: Colors.white,
          secondary: _kGold,
          surface: _kDarkSurface,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          color: _kDarkSurface,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: _kDarkBg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _kDarkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kPrimary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.08),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
