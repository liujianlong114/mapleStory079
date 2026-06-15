import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color darkBrown = Color(0xFF5D3A1A);
  static const Color orange = Color(0xFFD2691E);
  static const Color gold = Color(0xFFFFD700);
  static const Color beige = Color(0xFFF5DEB3);
  static const Color darkText = Color(0xFF1C1C1C);
  static const Color titleOrange = Color(0xFFFF8C00);

  static ThemeData get mapleStory079 {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: beige,
      canvasColor: beige,
      cardColor: const Color(0xFFFAF3E0),
      primaryColor: darkBrown,
      hintColor: Colors.brown.shade300,
      colorScheme: ColorScheme.light(
        primary: darkBrown,
        secondary: orange,
        surface: beige,
        error: Colors.red.shade700,
      ),
      fontFamily: 'PixelMplus10',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: darkText,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        displayMedium: TextStyle(
          color: darkText,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        displaySmall: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: titleOrange,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: darkText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: darkText, fontSize: 15, height: 1.4),
        bodyMedium: TextStyle(color: darkText, fontSize: 13, height: 1.4),
        bodySmall: TextStyle(color: darkBrown, fontSize: 12, height: 1.3),
        labelLarge: TextStyle(
          color: darkText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBrown,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: gold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: mapleButtonStyle(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: beige,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(color: darkBrown, fontSize: 14),
        hintStyle: TextStyle(color: darkBrown.withValues(alpha: 0.6), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBrown, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBrown, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      iconTheme: const IconThemeData(color: darkBrown, size: 22),
      dividerTheme: DividerThemeData(
        color: darkBrown.withValues(alpha: 0.3),
        thickness: 1,
        space: 16,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFAF3E0),
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: darkBrown, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFAF3E0),
        titleTextStyle: const TextStyle(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: darkText, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: darkBrown, width: 2),
        ),
      ),
    );
  }

  static ThemeData get light => mapleStory079;

  static ThemeData get dark => mapleStory079;

  static ButtonStyle mapleButtonStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.brown.shade300;
        }
        return orange;
      }),
      foregroundColor: WidgetStateProperty.all(Colors.white),
      elevation: WidgetStateProperty.resolveWith<double>((states) {
        if (states.contains(WidgetState.pressed)) return 1;
        if (states.contains(WidgetState.hovered)) return 4;
        return 2;
      }),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      minimumSize: WidgetStateProperty.all(const Size(120, 40)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: darkBrown, width: 2),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  static InputDecoration mapleInputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: darkBrown),
      filled: true,
      fillColor: beige,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: const TextStyle(color: darkBrown, fontSize: 14),
      hintStyle: TextStyle(color: darkBrown.withValues(alpha: 0.6), fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkBrown, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkBrown, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: orange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  static BoxDecoration mapleGradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFF5DEB3), Color(0xFFDEB887)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }
}
