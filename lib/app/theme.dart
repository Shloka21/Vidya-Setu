import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════════════════════
// VidyaSetu Premium Design System v2.0
// Modern • Glassmorphism • Vibrant • Professional
// ══════════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BRAND COLORS - Vibrant & Eye-catching
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary Brand
  static const Color brandPrimary = Color(0xFF6366F1); // Indigo
  static const Color brandSecondary = Color(0xFF8B5CF6); // Purple
  static const Color brandAccent = Color(0xFF06B6D4); // Cyan

  // Legacy compat
  static const Color primaryNavy = Color(0xFF1E1B4B);
  static const Color primaryDark = Color(0xFF0F0D24);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Semantic Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF0EA5E9);

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME PALETTE
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color _lightBg = Color(0xFFF8FAFF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightCardAlt = Color(0xFFF1F5F9);

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME PALETTE - Rich & Deep
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color _darkBg = Color(0xFF0A0A1A);
  static const Color _darkSurface = Color(0xFF12122A);
  static const Color _darkCard = Color(0xFF1A1A3A);
  static const Color _darkCardAlt = Color(0xFF242450);

  // Legacy compat
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color background = _lightBg;
  static const Color surface = _lightSurface;
  static const Color cardShadow = Color(0x1A6366F1);

  // ═══════════════════════════════════════════════════════════════════════════
  // STUNNING GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════════
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x40FFFFFF), Color(0x10FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A1A3A), Color(0xFF12122A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // PREMIUM SHADOWS
  // ═══════════════════════════════════════════════════════════════════════════
  static List<BoxShadow> get cardBoxShadow => [
    BoxShadow(
      color: brandPrimary.withOpacity(0.08),
      blurRadius: 32,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardBoxShadowDark => [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: brandPrimary.withOpacity(0.1),
      blurRadius: 32,
      spreadRadius: -8,
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: brandPrimary.withOpacity(0.3),
      blurRadius: 40,
      offset: const Offset(0, 16),
      spreadRadius: -8,
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: brandPrimary.withOpacity(0.4),
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════════
  static const double radiusXS = 8.0;
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;
  static const double radiusRound = 100.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING TOKENS
  // ═══════════════════════════════════════════════════════════════════════════
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double spacingHuge = 64.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      background: _lightBg,
      surface: _lightSurface,
      card: _lightCard,
      cardAlt: _lightCardAlt,
      textPrimary: const Color(0xFF1E1B4B),
      textSecondary: const Color(0xFF64748B),
      textTertiary: const Color(0xFF94A3B8),
      dividerColor: const Color(0xFFE2E8F0),
      inputFill: const Color(0xFFF1F5F9),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: _darkBg,
      surface: _darkSurface,
      card: _darkCard,
      cardAlt: _darkCardAlt,
      textPrimary: const Color(0xFFF8FAFC),
      textSecondary: const Color(0xFFA5B4FC),
      textTertiary: const Color(0xFF6366F1),
      dividerColor: const Color(0xFF2D2D5A),
      inputFill: const Color(0xFF1A1A3A),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME BUILDER
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color card,
    required Color cardAlt,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color dividerColor,
    required Color inputFill,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final Color primary = brandPrimary;
    final Color onPrimary = Colors.white;
    final Color secondary = brandSecondary;
    final Color tertiary = brandAccent;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primary,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: isDark
            ? const Color(0xFF312E81)
            : const Color(0xFFE0E7FF),
        onPrimaryContainer: isDark
            ? const Color(0xFFC7D2FE)
            : const Color(0xFF1E1B4B),
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: isDark
            ? const Color(0xFF3B0764)
            : const Color(0xFFF3E8FF),
        onSecondaryContainer: isDark
            ? const Color(0xFFE9D5FF)
            : const Color(0xFF3B0764),
        tertiary: tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: isDark
            ? const Color(0xFF164E63)
            : const Color(0xFFCFFAFE),
        onTertiaryContainer: isDark
            ? const Color(0xFFCFFAFE)
            : const Color(0xFF164E63),
        error: errorRed,
        onError: Colors.white,
        errorContainer: isDark
            ? const Color(0xFF450A0A)
            : const Color(0xFFFEE2E2),
        onErrorContainer: isDark
            ? const Color(0xFFFECACA)
            : const Color(0xFF7F1D1D),
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: cardAlt,
        outline: dividerColor,
        outlineVariant: dividerColor.withOpacity(0.5),
        shadow: isDark ? Colors.black87 : const Color(0x1A000000),
      ),

      // Typography
      textTheme: _buildTextTheme(textPrimary, textSecondary, textTertiary),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 24),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: dividerColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textTertiary,
          fontSize: 15,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 15,
        ),
        prefixIconColor: textTertiary,
        suffixIconColor: textTertiary,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: inputFill,
        selectedColor: primary,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF1A1A3A)
            : const Color(0xFF1E1B4B),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return dividerColor;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: dividerColor,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.1),
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        iconColor: textSecondary,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textTertiary,
        indicatorColor: primary,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: dividerColor,
      ),

      // Icon Theme
      iconTheme: IconThemeData(color: textSecondary, size: 24),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT THEME - Plus Jakarta Sans for modern look
  // ═══════════════════════════════════════════════════════════════════════════
  static TextTheme _buildTextTheme(
    Color primary,
    Color secondary,
    Color tertiary,
  ) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        color: primary,
        fontSize: 56,
        fontWeight: FontWeight.w800,
        letterSpacing: -2,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        color: primary,
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        height: 1.1,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        color: primary,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        color: primary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        color: primary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        color: primary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        color: primary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        color: primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: secondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        color: tertiary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        color: primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        color: secondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        color: tertiary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// THEME EXTENSIONS
// ══════════════════════════════════════════════════════════════════════════════
extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  List<BoxShadow> get cardShadow =>
      isDark ? AppTheme.cardBoxShadowDark : AppTheme.cardBoxShadow;

  Color get navBarSelected =>
      isDark ? AppTheme.brandPrimary : AppTheme.brandPrimary;
}
