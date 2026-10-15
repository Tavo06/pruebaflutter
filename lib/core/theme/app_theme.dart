import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colores semánticos adicionales accesibles con `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.accent,
    required this.sidebar,
    required this.onSidebar,
    required this.subtleFill,
    required this.border,
    required this.shadow,
  });

  final Color textSecondary;
  final Color success;
  final Color warning;

  /// Terracota: detalles y acciones secundarias, nunca errores.
  final Color accent;

  /// Fondo de la barra lateral y del panel de bienvenida del login.
  final Color sidebar;
  final Color onSidebar;

  /// Relleno suave (verde oliva claro) para iconos, chips y estados.
  final Color subtleFill;
  final Color border;
  final Color shadow;

  static const light = AppPalette(
    textSecondary: AppColors.textSecondary,
    success: AppColors.success,
    warning: AppColors.warning,
    accent: AppColors.terracotta,
    sidebar: AppColors.oliveDark,
    onSidebar: Colors.white,
    subtleFill: AppColors.oliveSoft,
    border: AppColors.border,
    shadow: AppColors.oliveDark,
  );

  static const dark = AppPalette(
    textSecondary: AppColors.darkTextSecondary,
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    accent: AppColors.darkTerracotta,
    sidebar: AppColors.darkSidebar,
    onSidebar: AppColors.darkTextPrimary,
    subtleFill: AppColors.darkOliveSoft,
    border: AppColors.darkBorder,
    shadow: Colors.black,
  );

  @override
  AppPalette copyWith({
    Color? textSecondary,
    Color? success,
    Color? warning,
    Color? accent,
    Color? sidebar,
    Color? onSidebar,
    Color? subtleFill,
    Color? border,
    Color? shadow,
  }) {
    return AppPalette(
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      accent: accent ?? this.accent,
      sidebar: sidebar ?? this.sidebar,
      onSidebar: onSidebar ?? this.onSidebar,
      subtleFill: subtleFill ?? this.subtleFill,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      onSidebar: Color.lerp(onSidebar, other.onSidebar, t)!,
      subtleFill: Color.lerp(subtleFill, other.subtleFill, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
}

/// Radios comunes (moderados).
class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
}

/// Sombras muy suaves.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: context.palette.shadow.withValues(alpha: dark ? 0.3 : 0.05),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ];
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.olive,
      onPrimary: Colors.white,
      primaryContainer: AppColors.oliveSoft,
      onPrimaryContainer: AppColors.oliveDark,
      secondary: AppColors.terracotta,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHigh,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    ),
    background: AppColors.background,
    inputFill: AppColors.background,
    palette: AppPalette.light,
  );

  static ThemeData get dark => _build(
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkOlive,
      onPrimary: AppColors.darkOnOlive,
      primaryContainer: AppColors.darkOliveSoft,
      onPrimaryContainer: AppColors.darkTextPrimary,
      secondary: AppColors.darkTerracotta,
      onSecondary: AppColors.darkOnOlive,
      error: AppColors.darkError,
      onError: AppColors.darkOnOlive,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      surfaceContainerLowest: AppColors.darkSurface,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: AppColors.darkSurfaceHigh,
      surfaceContainerHighest: AppColors.darkSurfaceHigh,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
    ),
    background: AppColors.darkBackground,
    inputFill: AppColors.darkSurfaceHigh,
    palette: AppPalette.dark,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required Color inputFill,
    required AppPalette palette,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final textPrimary = scheme.onSurface;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
    );

    final textTheme = base.textTheme
        .apply(bodyColor: textPrimary, displayColor: textPrimary)
        .copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            color: textPrimary,
            height: 1.45,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            color: palette.textSecondary,
            height: 1.45,
          ),
        );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: color, width: width),
        );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );
    const buttonText = TextStyle(fontWeight: FontWeight.w600, fontSize: 15);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      extensions: [palette],
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
      iconTheme: IconThemeData(color: palette.textSecondary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: palette.textSecondary.withValues(alpha: 0.8),
        ),
        labelStyle: TextStyle(color: palette.textSecondary),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused)
              ? scheme.primary
              : palette.textSecondary,
        ),
        suffixIconColor: palette.textSecondary,
        border: border(palette.border),
        enabledBorder: border(palette.border),
        focusedBorder: border(scheme.primary, 1.4),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.4),
        disabledBorder: border(palette.border.withValues(alpha: 0.6)),
        errorStyle: TextStyle(color: scheme.error),
        errorMaxLines: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.4),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.8),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          elevation: 0,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? textPrimary : AppColors.oliveDark,
          backgroundColor: scheme.surface,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: palette.border),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: buttonShape,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? palette.subtleFill
                : scheme.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : palette.textSecondary,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: palette.border)),
          shape: WidgetStatePropertyAll(buttonShape),
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: palette.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: palette.subtleFill,
        headerForegroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: palette.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: palette.shadow.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: palette.border),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceHigh : AppColors.oliveDark,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : Colors.white,
          fontSize: 12,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceHigh : AppColors.oliveDark,
        contentTextStyle: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: palette.border,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.subtleFill,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : palette.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : palette.textSecondary,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: palette.textSecondary, width: 1.4),
      ),
      listTileTheme: ListTileThemeData(iconColor: palette.textSecondary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
