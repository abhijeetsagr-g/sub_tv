import 'package:flutter/material.dart';

/// Brand palette — warm near-blacks + phosphor red, like a CRT screen.
abstract final class AppColors {
  // Core (kept from the original v1 API).
  static const Color bg = Color(0xFF181617);
  static const Color text = Color(0xFFD3CFD0);
  static const Color primary = Color(0xFFFF0033);

  // Surfaces, lightest → darkest.
  static const Color surfaceLowest = Color(0xFF110F10);
  static const Color surface = bg;
  static const Color surfaceContainerLow = Color(0xFF1E1B1C);
  static const Color surfaceContainer = Color(0xFF211F20);
  static const Color surfaceContainerHigh = Color(0xFF262325);
  static const Color surfaceContainerHighest = Color(0xFF302D2F);

  // Text.
  static const Color textMuted = Color(0xFF928B8E);

  // Phosphor accents.
  static const Color crimsonContainer = Color(0xFF4A0D1E);
  static const Color onCrimsonContainer = Color(0xFFFFE0E3);
  static const Color cyan = Color(0xFF4FD8FF);
  static const Color cyanContainer = Color(0xFF004E5E);
  static const Color amber = Color(0xFFFFC24B);
  static const Color amberContainer = Color(0xFF5E4400);

  // Lines.
  static const Color outline = Color(0xFF5C5659);
  static const Color outlineVariant = Color(0xFF383335);
}

abstract final class AppTheme {
  /// App is dark-only by design, so `theme` is just an alias of [dark].
  static ThemeData get theme => dark;

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: _appBarTheme,
    filledButtonTheme: _filledButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    cardTheme: _cardTheme,
    inputDecorationTheme: _inputDecorationTheme,
    popupMenuTheme: _popupMenuTheme,
    dialogTheme: _dialogTheme,
    dividerTheme: const DividerThemeData(
      color: AppColors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: _snackBarTheme,
    navigationBarTheme: _navigationBarTheme,
    // CRT extras for future screens (scanline overlay, glowing text, bezel).
    extensions: const [RetroExt()],
  );

  // ── Color scheme ────────────────────────────────────────────────────────────
  // Explicit roles so every Material widget (containers, chips, inputs…) uses
  // the CRT palette instead of a generic generated one.
  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.crimsonContainer,
    onPrimaryContainer: AppColors.onCrimsonContainer,
    secondary: AppColors.cyan,
    onSecondary: Color(0xFF00333E),
    secondaryContainer: AppColors.cyanContainer,
    onSecondaryContainer: Color(0xFFC4EEFF),
    tertiary: AppColors.amber,
    onTertiary: Color(0xFF3B2C00),
    tertiaryContainer: AppColors.amberContainer,
    onTertiaryContainer: Color(0xFFFFE1A3),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.surface,
    onSurface: AppColors.text,
    surfaceContainerLowest: AppColors.surfaceLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    onSurfaceVariant: AppColors.textMuted,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: Color(0xFFE7E1E3),
    onInverseSurface: AppColors.surfaceContainerHigh,
    inversePrimary: Color(0xFFFF5270),
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: AppColors.primary,
  );

  // ── Component themes ────────────────────────────────────────────────────────

  /// AppBar as a TV bezel: flat, no shadow, thin outline along the bottom.
  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.text,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppColors.text,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );

  static final FilledButtonThemeData _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.cyan,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );

  static final CardThemeData _cardTheme = CardThemeData(
    color: AppColors.surfaceContainer,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.outlineVariant),
    ),
  );

  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cyan, width: 2),
        ),
      );

  static final PopupMenuThemeData _popupMenuTheme = PopupMenuThemeData(
    color: AppColors.surfaceContainerHigh,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: AppColors.outlineVariant),
    ),
  );

  static final DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: AppColors.surfaceContainerHigh,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.outlineVariant),
    ),
  );

  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.surfaceContainerHighest,
    contentTextStyle: TextStyle(color: AppColors.text),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      side: BorderSide(color: AppColors.outlineVariant),
    ),
  );

  static const NavigationBarThemeData _navigationBarTheme =
      NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        indicatorColor: AppColors.crimsonContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      );
}

/// CRT-only colors for screens that want the phosphor treatment.
///
/// Retrieve with `Theme.of(context).extension<RetroExt>()`. Not cosmetic-only
/// plumbing: the [scanline] overlay and [glow] shadow have real consumers
/// coming (channel grid, "now playing" bar).
@immutable
class RetroExt extends ThemeExtension<RetroExt> {
  const RetroExt({
    /// Translucent horizontal band used by the CRT scanline overlay.
    this.scanline = const Color(0x1A000000),

    /// Phosphor-colored shadow for glowing text/icons.
    this.glow = const Color(0x80FF0033),

    /// Bold bezel outline for TV-frame surfaces (AppBar, cards).
    this.frame = const Color(0xFF3A3335),
  });

  final Color scanline;
  final Color glow;
  final Color frame;

  @override
  RetroExt copyWith({Color? scanline, Color? glow, Color? frame}) {
    return RetroExt(
      scanline: scanline ?? this.scanline,
      glow: glow ?? this.glow,
      frame: frame ?? this.frame,
    );
  }

  @override
  RetroExt lerp(ThemeExtension<RetroExt>? other, double t) {
    if (other is! RetroExt) return this;
    return RetroExt(
      scanline: Color.lerp(scanline, other.scanline, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      frame: Color.lerp(frame, other.frame, t)!,
    );
  }
}
