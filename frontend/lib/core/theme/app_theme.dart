import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TwineTheme {
  // ─── COLORS ────────────────────────────────────────────────────────────────
  static const Color rose = Color(0xFFFF4B6E);
  static const Color roseLight = Color(0xFFFF8FA3);
  static const Color roseDark = Color(0xFFC62A47);
  static const Color plum = Color(0xFF0E0818);
  static const Color plumMid = Color(0xFF2D1B4E);
  static const Color plumAccent = Color(0xFF4A2D7A);
  static const Color plumLight = Color(0xFF7B5EA7);
  static const Color gold = Color(0xFFF5C842);
  static const Color goldSoft = Color(0xFFFFE68A);
  static const Color surface = Color(0xFF1A1030);
  static const Color surfaceElevated = Color(0xFF221540);
  static const Color border = Color(0x20FFFFFF);
  static const Color textPrimary = Color(0xFFF0EAF8);
  static const Color textSecondary = Color(0x99F0EAF8);
  static const Color textHint = Color(0x55F0EAF8);
  static const Color online = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);

  // ─── GRADIENTS ─────────────────────────────────────────────────────────────
  static const LinearGradient roseGradient = LinearGradient(
    colors: [rose, Color(0xFFE03560)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [plum, plumMid, plumAccent],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const LinearGradient bondGradient = LinearGradient(
    colors: [rose, gold],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0x26FF4B6E), Color(0x334A2D7A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ─── THEME ──────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: plum,
    colorScheme: const ColorScheme.dark(
      primary: rose,
      secondary: plumLight,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSurface: textPrimary,
    ),
    fontFamily: 'DMSans',
    textTheme: _textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(fontFamily: 'DMSans', fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: rose, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        textStyle: TextStyle(fontFamily: 'DMSans', fontSize: 15, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: const BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        textStyle: TextStyle(fontFamily: 'DMSans', fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: rose, width: 1.5)),
      labelStyle: TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textHint),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: border)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: rose,
      unselectedItemColor: textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 48, fontWeight: FontWeight.w400, color: textPrimary, letterSpacing: -1.5),
    displayMedium: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 36, fontWeight: FontWeight.w400, color: textPrimary, letterSpacing: -1),
    displaySmall: TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 28, fontWeight: FontWeight.w400, color: textPrimary, letterSpacing: -0.5),
    headlineLarge: TextStyle(fontFamily: 'DMSans', fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
    headlineMedium: TextStyle(fontFamily: 'DMSans', fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
    headlineSmall: TextStyle(fontFamily: 'DMSans', fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
    bodyLarge: TextStyle(fontFamily: 'DMSans', fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
    bodyMedium: TextStyle(fontFamily: 'DMSans', fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
    bodySmall: TextStyle(fontFamily: 'DMSans', fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
    labelLarge: TextStyle(fontFamily: 'DMSans', fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
    labelMedium: TextStyle(fontFamily: 'DMSans', fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
    labelSmall: TextStyle(fontFamily: 'DMSans', fontSize: 10, fontWeight: FontWeight.w500, color: textHint, letterSpacing: 1),
  );
}
