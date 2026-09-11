import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidad visual de la app (docs/GUIA_ESTUDIO.md no la cubre porque es
/// puramente de presentacion, no de rubrica). Flat design + tipografia
/// profesional (Lexend/Source Sans 3) en vez del Material default generico
/// que dejaba `flutter create`.
class AppTheme {
  AppTheme._();

  static const primary = Color(0xFF0369A1);
  static const navy = Color(0xFF0F172A);
  static const background = Color(0xFFF8FAFC);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const border = Color(0xFFE2E8F0);
  static const mutedText = Color(0xFF475569);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      secondary: navy,
      surface: Colors.white,
      error: danger,
    );

    final textTheme = TextTheme(
      headlineMedium: GoogleFonts.lexend(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: navy,
      ),
      headlineSmall: GoogleFonts.lexend(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: navy,
      ),
      titleLarge: GoogleFonts.lexend(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: navy,
      ),
      titleMedium: GoogleFonts.lexend(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: navy,
      ),
      bodyLarge: GoogleFonts.sourceSans3(fontSize: 16, color: navy, height: 1.5),
      bodyMedium: GoogleFonts.sourceSans3(
        fontSize: 14,
        color: mutedText,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.lexend(fontWeight: FontWeight.w600, fontSize: 15),
    );

    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: border),
    );
    final focusedOutlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primary, width: 2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: focusedOutlineBorder,
      ),
    );
  }
}

/// Presentacion de la respuesta facial binaria en la UI.
class EmotionStyle {
  const EmotionStyle({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  static const _neutral = EmotionStyle(
    label: 'Neutral',
    color: AppTheme.primary,
    icon: Icons.sentiment_neutral,
  );

  static const _porEmocion = <String, EmotionStyle>{
    'favorable': EmotionStyle(
      label: 'Respuesta favorable',
      color: AppTheme.success,
      icon: Icons.sentiment_satisfied_alt,
    ),
    'desfavorable': EmotionStyle(
      label: 'Respuesta desfavorable',
      color: AppTheme.danger,
      icon: Icons.sentiment_dissatisfied,
    ),
    'incierto': EmotionStyle(
      label: 'Lectura incierta',
      color: AppTheme.mutedText,
      icon: Icons.help_outline,
    ),
    // Estilos legados para registros anteriores a la migracion.
    'triste': EmotionStyle(
      label: 'Triste',
      color: Color(0xFF64748B),
      icon: Icons.sentiment_dissatisfied,
    ),
    'feliz': EmotionStyle(
      label: 'Feliz',
      color: Color(0xFFD97706),
      icon: Icons.sentiment_very_satisfied,
    ),
    'sorpresa': EmotionStyle(
      label: 'Sorpresa',
      color: Color(0xFF9333EA),
      icon: Icons.celebration,
    ),
    'neutral': _neutral,
    'enojo': EmotionStyle(
      label: 'Enojo',
      color: Color(0xFFDC2626),
      icon: Icons.sentiment_very_dissatisfied,
    ),
  };

  static EmotionStyle of(String emocion) => _porEmocion[emocion] ?? _neutral;
}
