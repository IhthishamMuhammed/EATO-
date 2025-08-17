import 'package:flutter/material.dart';
import '../pages/theme/eato_theme.dart';

class ThemeAdapter {
  // ✅ Convert your EatoTheme to MaterialApp ThemeData
  static ThemeData get materialTheme => ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: EatoTheme.primaryColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // Use your color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: EatoTheme.primaryColor,
          primary: EatoTheme.primaryColor,
          secondary: EatoTheme.accentColor,
          error: EatoTheme.errorColor,
          surface: EatoTheme.surfaceColor,
          background: EatoTheme.backgroundColor,
        ),

        // Use your text theme
        textTheme: TextTheme(
          headlineLarge: EatoTheme.headingLarge,
          headlineMedium: EatoTheme.headingMedium,
          headlineSmall: EatoTheme.headingSmall,
          bodyLarge: EatoTheme.bodyLarge,
          bodyMedium: EatoTheme.bodyMedium,
          bodySmall: EatoTheme.bodySmall,
          labelLarge: EatoTheme.labelLarge,
          labelMedium: EatoTheme.labelMedium,
          labelSmall: EatoTheme.labelSmall,
        ),

        // Use your button styles
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: EatoTheme.primaryButtonStyle,
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: EatoTheme.outlinedButtonStyle,
        ),
        textButtonTheme: TextButtonThemeData(
          style: EatoTheme.textButtonStyle,
        ),

        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: EatoTheme.backgroundColor,
          foregroundColor: EatoTheme.textPrimaryColor,
          elevation: 0,
          centerTitle: true,
        ),

        // Input decoration theme (uses your existing inputDecoration method)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: EatoTheme.primaryColor, width: 1.5),
          ),
        ),
      );
}
