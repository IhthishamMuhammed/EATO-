import 'package:flutter/material.dart';

class EatoTheme {
  // Core colors
  static const Color primaryColor = Color(0xFF6A1B9A); // Deep Purple 800
  static const Color primaryDarkColor = Color(0xFF4A148C); // Deep Purple 900
  static const Color primaryLightColor = Color(0xFF9C27B0); // Purple 500
  static const Color accentColor = Color(0xFFE040FB); // Purple A200
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;

  // Status colors
  static const Color successColor = Color(0xFF43A047); // Green 600
  static const Color warningColor = Color(0xFFFFA000); // Amber 700
  static const Color errorColor = Color(0xFFE53935); // Red 600
  static const Color infoColor = Color(0xFF1E88E5); // Blue 600

  static const Color dividerColor = Color(0xFFE0E0E0); // Grey 300
  static const Color borderColor = Color(0xFFBDBDBD); // Grey 400
  static const Color shadowColor = Color(0xFF000000);

  // Text colors
  static const Color textPrimaryColor = Color(0xFF212121); // Grey 900
  static const Color textSecondaryColor = Color(0xFF757575); // Grey 600
  static const Color textLightColor = Color(0xFF9E9E9E); // Grey 500
  static const Color textOnPrimaryColor = Colors.white;

  // ✅ RESPONSIVE BREAKPOINTS
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  // ✅ RESPONSIVE HELPERS
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  // ✅ RESPONSIVE SPACING
  static double getHorizontalPadding(BuildContext context) =>
      isMobile(context) ? 16.0 : 24.0;

  static double getVerticalPadding(BuildContext context) =>
      isMobile(context) ? 12.0 : 16.0;

  static double getButtonSpacing(BuildContext context) =>
      isSmallScreen(context) ? 8.0 : 12.0;

  static double getCardSpacing(BuildContext context) =>
      isMobile(context) ? 12.0 : 16.0;

  // ✅ RESPONSIVE TEXT SCALING
  static double getTextScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 0.9; // Very small screens
    if (width < 400) return 0.95; // Small screens
    return 1.0; // Normal and larger screens
  }

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryLightColor, accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ✅ RESPONSIVE TEXT STYLES
  static TextStyle getResponsiveHeadingLarge(BuildContext context) => TextStyle(
        fontSize: 28 * getTextScale(context),
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        height: 1.2,
      );

  static TextStyle getResponsiveHeadingMedium(BuildContext context) =>
      TextStyle(
        fontSize: 22 * getTextScale(context),
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        height: 1.3,
      );

  static TextStyle getResponsiveHeadingSmall(BuildContext context) => TextStyle(
        fontSize: 18 * getTextScale(context),
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        height: 1.3,
      );

  static TextStyle getResponsiveBodyLarge(BuildContext context) => TextStyle(
        fontSize: 16 * getTextScale(context),
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
        height: 1.5,
      );

  static TextStyle getResponsiveBodyMedium(BuildContext context) => TextStyle(
        fontSize: 14 * getTextScale(context),
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
        height: 1.5,
      );

  static TextStyle getResponsiveBodySmall(BuildContext context) => TextStyle(
        fontSize: 12 * getTextScale(context),
        fontWeight: FontWeight.w400,
        color: textSecondaryColor,
        height: 1.4,
      );

  // Original text styles (kept for backward compatibility)
  static TextStyle get headingLarge => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        height: 1.2,
      );

  static TextStyle get headingMedium => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        height: 1.3,
      );

  static TextStyle get headingSmall => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        height: 1.3,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
        height: 1.5,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
        height: 1.5,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondaryColor,
        height: 1.4,
      );

  static TextStyle get labelLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
        height: 1.4,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
        height: 1.4,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
        height: 1.4,
      );

  // ✅ RESPONSIVE LAYOUT HELPERS
  // Quick fixes for the layout errors
// Add these fixed methods to your EatoTheme class
// Replace the existing buildResponsiveRow and buildResponsiveButtonRow methods

// ✅ FIXED: Responsive row with proper constraints
  static Widget buildResponsiveRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double? spacing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualSpacing = spacing ?? getButtonSpacing(context);

        if (constraints.maxWidth < 400) {
          // Stack vertically on very small screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .expand((child) => [
                      child,
                      if (child != children.last)
                        SizedBox(height: actualSpacing),
                    ])
                .toList(),
          );
        }

        // Horizontal layout with proper constraints
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: children
              .asMap()
              .entries
              .expand((entry) => [
                    if (entry.key == 0)
                      Flexible(child: entry.value)
                    else ...[
                      SizedBox(width: actualSpacing),
                      Flexible(child: entry.value),
                    ]
                  ])
              .toList(),
        );
      },
    );
  }

// ✅ FIXED: Responsive button row with proper constraints
  static Widget buildResponsiveButtonRow({
    required List<Widget> buttons,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.spaceEvenly,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isSmallScreen(context) || constraints.maxWidth < 380) {
          // Stack buttons vertically on small screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttons
                .expand((button) => [
                      SizedBox(
                        height: 48, // Fixed height for consistency
                        child: button,
                      ),
                      if (button != buttons.last)
                        SizedBox(height: getButtonSpacing(context)),
                    ])
                .toList(),
          );
        }

        // Horizontal layout for larger screens
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          children: buttons
              .map(
                (button) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: getButtonSpacing(context) / 2,
                    ),
                    child: SizedBox(
                      height: 48, // Fixed height for consistency
                      child: button,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  static ButtonStyle getResponsivePrimaryButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: getHorizontalPadding(context),
          vertical: getVerticalPadding(context),
        ),
        minimumSize: Size(
          isMobile(context) ? 80 : 100,
          isMobile(context) ? 40 : 48,
        ),
        textStyle: TextStyle(
          fontSize: 14 * getTextScale(context),
          fontWeight: FontWeight.w500,
        ),
      );

  static ButtonStyle getResponsiveOutlinedButtonStyle(BuildContext context) =>
      OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: getHorizontalPadding(context),
          vertical: getVerticalPadding(context),
        ),
        minimumSize: Size(
          isMobile(context) ? 80 : 100,
          isMobile(context) ? 40 : 48,
        ),
        textStyle: TextStyle(
          fontSize: 14 * getTextScale(context),
          fontWeight: FontWeight.w500,
        ),
      );

  // Reusable component styles
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get highlightedCardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // AppBar definition
  static PreferredSizeWidget appBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    bool centerTitle = true,
    PreferredSizeWidget? bottom,
    bool showBackButton = true,
  }) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: textPrimaryColor,
          fontSize: 18 * getTextScale(context),
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: centerTitle,
      leading: showBackButton && Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: textPrimaryColor),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }

  // Button styles (kept for backward compatibility)
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(100, 48),
      );

  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(100, 48),
      );

  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );

  // ✅ RESPONSIVE INPUT DECORATION
  static InputDecoration inputDecoration({
    required String hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    BuildContext? context,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: EdgeInsets.symmetric(
        horizontal: context != null ? getHorizontalPadding(context) : 16,
        vertical: context != null ? getVerticalPadding(context) : 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      hintStyle: context != null
          ? getResponsiveBodyMedium(context).copyWith(color: textSecondaryColor)
          : null,
    );
  }

  static PageRouteBuilder slideTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 500),
    Offset begin = const Offset(1.0, 0.0), // Default: slide from right
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var end = Offset.zero;
        var curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  static PageRouteBuilder fadeTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: duration,
    );
  }

  static Widget buildPageIndicators(int totalPages, int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          width: index == currentPage ? 24 : 10,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: index == currentPage
                ? primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  // Common spacing values
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
}
