import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  // Spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Edge insets shortcuts
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

/// Border radius constants for consistent rounded corners
class AppRadius {
  // Operational UI: restrained rounding (better information density).
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 14.0;
  static const double xl = 18.0;
}

// =============================================================================
// TEXT STYLE EXTENSIONS
// =============================================================================

/// Extension to add text style utilities to BuildContext
/// Access via context.textStyles
extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

/// Helper methods for common text style modifications
extension TextStyleExtensions on TextStyle {
  /// Make text bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// Make text semi-bold
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// Make text medium weight
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Make text normal weight
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);

  /// Make text light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Add custom color
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Add custom size
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

// =============================================================================
// COLORS
// =============================================================================

class LightModeColors {
  /// Operational palette:
  /// - Primary action/accent: #E11D48
  /// - Primary dark/navy:     #0B1220
  static const navy = Color(0xFF0B1220);
  static const accent = Color(0xFFE11D48);

  static const lightPrimary = accent;
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFFDE7EF); // subtle rose tint
  static const lightOnPrimaryContainer = navy;

  static const lightSecondary = navy;
  static const lightOnSecondary = Color(0xFFFFFFFF);

  static const lightTertiary = Color(0xFF1F2937); // slate (neutral)
  static const lightOnTertiary = Color(0xFFFFFFFF);

  // Error colors
  static const lightError = Color(0xFFBA1A1A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);

  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = navy;
  static const lightBackground = Color(0xFFF7F8FA);
  static const lightSurfaceVariant = Color(0xFFF1F3F6);
  static const lightOnSurfaceVariant = Color(0xFF475569);

  // Outline and shadow
  static const lightOutline = Color(0xFFCBD5E1); // light slate border
  static const lightShadow = Color(0xFF000000);
  static const lightInversePrimary = accent;
}

/// Dark mode colors with good contrast
class DarkModeColors {
  static const navy = Color(0xFF0B1220);
  static const accent = Color(0xFFE11D48);

  static const darkPrimary = accent;
  static const darkOnPrimary = Color(0xFFFFFFFF);
  static const darkPrimaryContainer = Color(0xFF2B0B16);
  static const darkOnPrimaryContainer = Color(0xFFFDE7EF);

  static const darkSecondary = Color(0xFF94A3B8); // slate
  static const darkOnSecondary = navy;

  static const darkTertiary = Color(0xFFCBD5E1);
  static const darkOnTertiary = navy;

  // Error colors
  static const darkError = Color(0xFFFFB4AB);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD6);

  static const darkSurface = Color(0xFF0B1220);
  static const darkOnSurface = Color(0xFFE5E7EB);
  static const darkSurfaceVariant = Color(0xFF111B2E);
  static const darkOnSurfaceVariant = Color(0xFFB6C2D1);

  // Outline and shadow
  static const darkOutline = Color(0xFF22304A);
  static const darkShadow = Color(0xFF000000);
  static const darkInversePrimary = accent;
}

/// Semantic colors used across FireOps Path UI (status + header)
class FireOpsSemanticColors {
  static const headerDark = Color(0xFF0B1220);

  // Status semantics: keep meaning consistent across the app.
  static const green = Color(0xFF16A34A); // approved/current/complete
  static const amber = Color(0xFFF59E0B); // attention/in progress/expiring
  static const red = Color(0xFFDC2626); // overdue/expired/returned/restricted
  static const blue = Color(0xFF2563EB); // informational/pending
  static const gray = Color(0xFF64748B); // inactive/not started

  // Convenience aliases used by existing widgets.
  static const current = green;
  static const expiring = amber;
  static const expired = red;
  static const complete = green;

  // Back-compat (older references)
  static const completed = complete;
  static const warning = expiring;
}

/// Shared card styling tokens.
///
/// Prefer using `Card` (Theme.cardTheme) for most containers. When a widget
/// needs a manual decoration (e.g., Material+InkWell), keep its radius/border
/// aligned to these constants.
class AppCardTokens {
  static const double borderAlpha = 0.14;
  static const double subtleBorderAlpha = 0.10;
  static const double toneBorderAlpha = 0.28;
  static const EdgeInsets padding = AppSpacing.paddingMd;
  static const double radius = AppRadius.lg;
}

/// Shared sizing for touch targets.
class AppTouchTargets {
  static const double minButtonHeight = 48;
  static const double minFieldHeight = 52;
}

/// App-wide motion constants.
class AppMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 240);
  static const Curve standard = Curves.easeOutCubic;
}

/// Font size constants
class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

// =============================================================================
// THEMES
// =============================================================================

/// Light theme with modern, neutral aesthetic
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
    surfaceContainerHighest: LightModeColors.lightSurfaceVariant,
    onSurfaceVariant: LightModeColors.lightOnSurfaceVariant,
    outline: LightModeColors.lightOutline,
    shadow: LightModeColors.lightShadow,
    inversePrimary: LightModeColors.lightInversePrimary,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: LightModeColors.lightBackground,
  iconTheme: const IconThemeData(color: LightModeColors.lightOnSurface),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: LightModeColors.lightOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleSpacing: 16,
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    minLeadingWidth: 18,
  ),
  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: LightModeColors.lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: LightModeColors.lightOutline.withValues(alpha: 0.9)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: LightModeColors.lightOutline.withValues(alpha: 0.9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: LightModeColors.lightPrimary.withValues(alpha: 0.95), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: LightModeColors.lightError.withValues(alpha: 0.95)),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppCardTokens.radius),
      side: BorderSide(
        color: LightModeColors.lightOutline.withValues(alpha: 0.9),
        width: 1,
      ),
    ),
  ),
  dividerTheme: DividerThemeData(
    color: LightModeColors.lightOutline.withValues(alpha: 0.14),
    space: 1,
    thickness: 1,
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    elevation: 0,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, AppTouchTargets.minButtonHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, AppTouchTargets.minButtonHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: const Size(0, AppTouchTargets.minButtonHeight),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
    ),
  ),
  chipTheme: ChipThemeData(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
      side: BorderSide(color: LightModeColors.lightOutline.withValues(alpha: 0.9)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 68,
    elevation: 0,
    indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    indicatorColor: LightModeColors.lightPrimaryContainer,
    backgroundColor: LightModeColors.lightSurface,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w600);
      },
    ),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return IconThemeData(color: selected ? LightModeColors.lightPrimary : LightModeColors.lightOnSurfaceVariant);
    }),
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  textTheme: _buildTextTheme(Brightness.light),
);

/// Dark theme with good contrast and readability
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
    surfaceContainerHighest: DarkModeColors.darkSurfaceVariant,
    onSurfaceVariant: DarkModeColors.darkOnSurfaceVariant,
    outline: DarkModeColors.darkOutline,
    shadow: DarkModeColors.darkShadow,
    inversePrimary: DarkModeColors.darkInversePrimary,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: DarkModeColors.darkSurface,
  iconTheme: const IconThemeData(color: DarkModeColors.darkOnSurface),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: DarkModeColors.darkOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleSpacing: 16,
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    minLeadingWidth: 18,
  ),
  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: DarkModeColors.darkSurfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: DarkModeColors.darkOutline.withValues(alpha: 0.95)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: DarkModeColors.darkOutline.withValues(alpha: 0.95)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: DarkModeColors.darkPrimary.withValues(alpha: 0.95), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: DarkModeColors.darkError.withValues(alpha: 0.95)),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppCardTokens.radius),
      side: BorderSide(
        color: DarkModeColors.darkOutline.withValues(alpha: 0.95),
        width: 1,
      ),
    ),
  ),
  dividerTheme: DividerThemeData(
    color: DarkModeColors.darkOutline.withValues(alpha: 0.14),
    space: 1,
    thickness: 1,
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    elevation: 0,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, AppTouchTargets.minButtonHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, AppTouchTargets.minButtonHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: const Size(0, AppTouchTargets.minButtonHeight),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
    ),
  ),
  chipTheme: ChipThemeData(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
      side: BorderSide(color: DarkModeColors.darkOutline.withValues(alpha: 0.95)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 68,
    elevation: 0,
    indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    indicatorColor: DarkModeColors.darkPrimaryContainer,
    backgroundColor: DarkModeColors.darkSurface,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w600);
      },
    ),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return IconThemeData(color: selected ? DarkModeColors.darkPrimary : DarkModeColors.darkOnSurfaceVariant);
    }),
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  textTheme: _buildTextTheme(Brightness.dark),
);

/// Build text theme using Inter font family
TextTheme _buildTextTheme(Brightness brightness) {
  return TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w600,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.35,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.3,
    ),
  );
}
