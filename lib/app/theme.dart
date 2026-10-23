import 'package:flutter/material.dart';

/// Paleta de colores oficial inspirada fielmente en el Logotipo de Panamá Histórica.
/// Respeta la armonía del Escudo y Sello Oficial:
/// - Azul Profundo Institucional (#012B59): Soberanía, fondo de honores y autoridad histórica.
/// - Oro Histórico (#C89018): Letras, orlas de gloria y estrellas de la república.
/// - Rojo Carmesí (#D00820): Sangre patriótica de la gesta de 1964 y la bandera nacional.
/// - Verde Esmeralda Istmeño (#084030): Naturaleza y soberanía del canal y del istmo.
/// - Blanco y Pergamino (#FFFFFF / #FEF9EE): Documentos históricos, limpieza y lectura clara.
class AppColors {
  // Azul Profundo del Logo (Color primario absoluto)
  static const Color logoNavy = Color(0xFF012B59);
  static const Color logoNavyDark = Color(0xFF001B3A);
  static const Color logoNavyLight = Color(0xFF0C3D7A);

  // Oro y Ámbar Histórico del Logo (Acento secundario y de prestigio)
  static const Color logoGold = Color(0xFFC89018);
  static const Color logoGoldDark = Color(0xFFA5730E);
  static const Color logoGoldLight = Color(0xFFE5A93C);
  static const Color logoGoldBg = Color(0xFFFEF7E6);

  // Rojo Patrio del Logo (Acento activo y gesta heroica)
  static const Color logoRed = Color(0xFFD00820);
  static const Color logoRedDark = Color(0xFF9E0616);
  static const Color logoRedLight = Color(0xFFEA263B);

  // Verde Istmeño del Escudo del Logo
  static const Color logoForest = Color(0xFF084030);
  static const Color logoForestLight = Color(0xFF166534);

  // Superficies y Fondos
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color parchmentAccent = Color(0xFFFEF9EE);
  static const Color borderGrey = Color(0xFFE2E8F0);

  // Textos
  static const Color textDark = Color(0xFF0B192C);
  static const Color textMuted = Color(0xFF5A6A80);

  // Mapeos de compatibilidad con la arquitectura del proyecto:
  static const Color patrioticBlue = logoNavy;
  static const Color patrioticBlueDark = logoNavyDark;
  static const Color patrioticBlueLight = logoNavyLight;

  static const Color patrioticRed = logoRed;
  static const Color patrioticRedDark = logoRedDark;
  static const Color patrioticRedLight = logoRedLight;

  static const Color goldAccent = logoGold;
  static const Color amberBadge = logoGold;
  static const Color sandAccent = parchmentAccent;

  static const Color primaryTeal = logoNavy;
  static const Color primaryTealDark = logoNavyDark;
  static const Color forestGreen = logoForest;
  static const Color forestGreenDark = logoForest;
  static const Color dangerRed = logoRed;
  static const Color dangerBg = Color(0xFFFEE2E2);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.logoNavy,
        primary: AppColors.logoNavy,
        secondary: AppColors.logoGold,
        tertiary: AppColors.logoRed,
        surface: AppColors.surfaceWhite,
        error: AppColors.logoRed,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.logoNavy),
        titleTextStyle: TextStyle(
          color: AppColors.logoNavy,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Serif',
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 1.5,
        shadowColor: AppColors.logoNavy.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGrey, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.logoNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 2,
          shadowColor: AppColors.logoNavy.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.logoNavy, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.logoNavy,
        brightness: Brightness.dark,
        primary: AppColors.logoGold,
        secondary: AppColors.logoGoldLight,
        tertiary: AppColors.logoRed,
        surface: const Color(0xFF0F1B2E),
        error: AppColors.logoRed,
      ),
      scaffoldBackgroundColor: const Color(0xFF07101E),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F1B2E),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.logoGold),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Serif',
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF12233C),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1D3557), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.logoGold,
          foregroundColor: const Color(0xFF001B3A),
          minimumSize: const Size(double.infinity, 52),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF102038),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1D3557), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.logoGold, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
    );
  }
}
