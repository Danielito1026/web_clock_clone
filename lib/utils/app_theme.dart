import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData themeData() {
    const h2Red = Color(0xFF970000);
    const grayColor = Color.fromRGBO(95, 96, 102, 1);
    const unfocusedBorderColor = Color.fromRGBO(36, 40, 44, 1);
    return ThemeData(
      fontFamily: 'Segoe UI',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontVariations: [FontVariation('wght', 700)]),
        displayMedium: TextStyle(fontVariations: [FontVariation('wght', 700)]),
        displaySmall: TextStyle(fontVariations: [FontVariation('wght', 700)]),
        headlineLarge: TextStyle(fontVariations: [FontVariation('wght', 700)]),
        headlineMedium: TextStyle(fontVariations: [FontVariation('wght', 600)]),
        headlineSmall: TextStyle(fontVariations: [FontVariation('wght', 600)]),
        titleLarge: TextStyle(fontVariations: [FontVariation('wght', 600)]),
        titleMedium: TextStyle(fontVariations: [FontVariation('wght', 500)]),
        titleSmall: TextStyle(fontVariations: [FontVariation('wght', 500)]),
        bodyLarge: TextStyle(fontVariations: [FontVariation('wght', 400)]),
        bodyMedium: TextStyle(fontVariations: [FontVariation('wght', 400)]),
        bodySmall: TextStyle(fontVariations: [FontVariation('wght', 400)]),
        labelLarge: TextStyle(fontVariations: [FontVariation('wght', 500)]),
        labelMedium: TextStyle(fontVariations: [FontVariation('wght', 400)]),
        labelSmall: TextStyle(fontVariations: [FontVariation('wght', 400)]),
      ),
      colorScheme: ColorScheme.fromSeed(seedColor: h2Red, primary: h2Red),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: h2Red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: h2Red,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color.fromARGB(255, 26, 28, 35),
        iconColor: grayColor,
        prefixIconColor: grayColor,
        suffixIconColor: grayColor,
        labelStyle: TextStyle(color: grayColor),
        hintStyle: TextStyle(color: grayColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 1, color: unfocusedBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 1, color: unfocusedBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(width: 1.5, color: h2Red),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 1, color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 1.5, color: Colors.red),
        ),
      ),
    );
  }
}
