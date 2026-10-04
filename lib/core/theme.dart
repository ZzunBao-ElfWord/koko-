import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF5865F2);
  static const Color secondaryColor = Color(0xFFEB459E);
  static const Color successColor = Color(0xFF57F287);
  static const Color warningColor = Color(0xFFFEE75C);
  static const Color errorColor = Color(0xFFED4245);

  static const Color darkBackground = Color(0xFF36393F);
  static const Color darkSurface = Color(0xFF2F3136);
  static const Color darkChannel = Color(0xFF36393F);
  static const Color darkInput = Color(0xFF40444B);
  static const Color darkSidebar = Color(0xFF2F3136);

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF2F3F5);
  static const Color lightChannel = Color(0xFFFFFFFF);
  static const Color lightInput = Color(0xFFEBEDEF);
  static const Color lightSidebar = Color(0xFFF2F3F5);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: darkSurface,
          background: darkBackground,
          error: errorColor,
        ),
        scaffoldBackgroundColor: darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkInput,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: lightSurface,
          background: lightBackground,
          error: errorColor,
        ),
        scaffoldBackgroundColor: lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: lightSurface,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightInput,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      );
}
