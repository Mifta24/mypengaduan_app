import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Dark Forest Green Palette (sesuai desain) ────────────────────────────
  // Warna utama UI (digunakan di komponen, button, icon, dsb.)
  static const Color primary      = Color(0xFF2E7D32); // Hijau medium — logo & button
  static const Color primaryDark  = Color(0xFF1B5E20); // Hijau gelap
  static const Color primaryLight = Color(0xFF4CAF50); // Hijau terang — badge & aksen
  static const Color accent       = Color(0xFF66BB6A); // Lime hijau — subtitle & highlight
  static const Color secondary    = Color(0xFF1E6B3A); // Hijau forest — logo circle

  // Background splash/landing (dark forest green)
  static const Color bgDeep  = Color(0xFF071A0F); // Paling gelap
  static const Color bgDark  = Color(0xFF0D2B1A); // Gelap
  static const Color bgMid   = Color(0xFF0F3D23); // Sedang

  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Selesai
  static const Color warning = Color(0xFFD97706); // Pending
  static const Color danger  = Color(0xFFDC2626); // Ditolak
  static const Color info    = Color(0xFF1E6B3A); // Info

  // Neutral Colors (untuk layar terang — home, form, dsb.)
  static const Color surface       = Color(0xFFF1FDF4); // Hijau sangat pucat
  static const Color card          = Colors.white;
  static const Color border        = Color(0xFFA5D6A7); // Hijau border lembut
  static const Color textPrimary   = Color(0xFF1B5E20); // Hijau tua
  static const Color textSecondary = Color(0xFF4B7A5C); // Hijau abu

  // Gradient helpers
  static const List<Color> splashGradient = [bgDeep, bgDark, bgMid];
  static const List<Color> primaryGradient = [primary, primaryDark];

  // ─── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        surface: surface,
        tertiary: primaryLight,
      ),
      scaffoldBackgroundColor: surface,
    );

    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: border),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : textSecondary,
          );
        }),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        elevation: 3,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        textStyle: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(
            fontWeight: FontWeight.w500, color: Colors.white),
      ),
      dividerColor: border,
    );
  }
}
