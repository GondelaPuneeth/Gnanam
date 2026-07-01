import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E88E5), // Spark primary color
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF1A1A1A),
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF64B5F6), // Lighter Spark primary for dark theme
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F10),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1C),
      foregroundColor: Color(0xFFE8E8E8),
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: const Color(0xFFE8E8E8),
      displayColor: const Color(0xFFE8E8E8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFF2A2A2D),
    ),
  );

  // Scholar theme colors
  static const scholarPrimary = Color(0xFF00897B);
  static const scholarPrimaryLight = Color(0xFF4EBAAA);

  // Sage theme colors
  static const sagePrimary = Color(0xFF5E35B1);
  static const sagePrimaryLight = Color(0xFF9162E4);

  // Get theme based on grade
  static Color getPrimaryColorForGrade(int grade) {
    if (grade >= 1 && grade <= 4) {
      return const Color(0xFF1E88E5); // Spark
    } else if (grade >= 5 && grade <= 8) {
      return scholarPrimary; // Scholar
    } else {
      return sagePrimary; // Sage
    }
  }

  static Color getPrimaryLightColorForGrade(int grade) {
    if (grade >= 1 && grade <= 4) {
      return const Color(0xFF64B5F6); // Spark light
    } else if (grade >= 5 && grade <= 8) {
      return scholarPrimaryLight; // Scholar light
    } else {
      return sagePrimaryLight; // Sage light
    }
  }
}