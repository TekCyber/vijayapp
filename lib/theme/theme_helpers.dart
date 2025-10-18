// lib/theme/theme_helpers.dart
import 'package:flutter/material.dart';

/// Comprehensive theme-aware helper class
class ThemeHelper {
  ThemeHelper._();

  // ==================== TEXT COLORS ====================

  /// Primary text color
  static Color textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  /// Secondary/subtle text color
  static Color subtleTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
  }

  /// Hint/placeholder text color
  static Color hintTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white60
        : Colors.black54;
  }

  /// Icon color
  static Color iconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.7)
        : Colors.black54;
  }

  /// Inactive/disabled control color
  static Color inactiveColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
  }

  // ==================== BACKGROUND COLORS ====================

  /// Card/container background
  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A3F5F).withOpacity(0.6)
        : Colors.white;
  }

  /// Glass container background
  static Color glassBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);
  }

  /// Dropdown background
  static Color dropdownColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1a1a2e)
        : Colors.white;
  }

  /// Surface color for elevated elements
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2D3A)
        : Colors.white;
  }

  /// Alternating row background
  static Color rowBackground(BuildContext context, bool isEven) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isEven) {
      return isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.03);
    }
    return Colors.transparent;
  }

  // ==================== BORDERS & DIVIDERS ====================

  /// Border color
  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.1);
  }

  /// Divider color
  static Color dividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.black26;
  }

  // ==================== SEMANTIC COLORS ====================
  // These remain fixed as they convey meaning

  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;

  // Brand colors
  static const Color accentGreen = Colors.greenAccent;
  static const Color accentOrange = Colors.orangeAccent;
  static const Color accentBlue = Colors.blueAccent;
  static const Color accentPurple = Colors.purple;
  static const Color accentTeal = Colors.teal;
  static const Color accentPink = Color(0xFFEC4899);

  // Predefined chart colors (used in dashboard)
  static const List<Color> chartColors = [
    Color(0xFF4F46E5), // Bright Indigo
    Color(0xFFEC4899), // Bright Pink
    Color(0xFF10B981), // Bright Green
    Color(0xFFFF6B35), // Bright Orange
    Color(0xFF8B5CF6), // Bright Purple
    Color(0xFF06B6D4), // Bright Cyan
    Color(0xFFEF4444), // Bright Red
    Color(0xFFF59E0B), // Bright Amber
    Color(0xFF3B82F6), // Bright Blue
    Color(0xFF84CC16), // Bright Lime
    Color(0xFFF97316), // Bright Orange Red
    Color(0xFF14B8A6), // Bright Teal
    Color(0xFFD946EF), // Bright Magenta
    Color(0xFF22C55E), // Bright Green Light
    Color(0xFF6366F1), // Bright Indigo Light
    Color(0xFFFF4081), // Bright Pink Accent
    Color(0xFF00E676), // Bright Green Accent
    Color(0xFFFF9100), // Bright Orange Accent
    Color(0xFF651FFF), // Bright Deep Purple
    Color(0xFF00BCD4), // Bright Cyan Accent
  ];

  // ==================== DECORATIONS ====================

  /// Standard input decoration
  static BoxDecoration inputDecoration(BuildContext context) {
    return BoxDecoration(
      color: glassBackground(context),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: borderColor(context),
        width: 1,
      ),
    );
  }

  /// Table header decoration
  static BoxDecoration tableHeaderDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          theme.primaryColor.withOpacity(0.2),
          theme.primaryColor.withOpacity(0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: borderColor(context),
        width: 1,
      ),
    );
  }

  /// Badge/status decoration
  static BoxDecoration badgeDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(0.4),
        width: 1,
      ),
    );
  }

  /// Small badge decoration (for compact displays)
  static BoxDecoration smallBadgeDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: color.withOpacity(0.4),
        width: 1,
      ),
    );
  }

  /// Highlight decoration (for selected items)
  static BoxDecoration highlightDecoration(BuildContext context, Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  /// Button decoration
  static BoxDecoration buttonDecoration(BuildContext context, bool isActive) {
    return BoxDecoration(
      color: isActive
          ? Theme.of(context).primaryColor
          : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// Glass container decoration (with backdrop filter effect)
  static BoxDecoration glassContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: cardBackground(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor(context),
        width: 1,
      ),
    );
  }

  // ==================== TEXT STYLES ====================

  /// Header text style
  static TextStyle headerStyle(BuildContext context) {
    return TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: textColor(context),
    );
  }

  /// Title text style
  static TextStyle titleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textColor(context),
    );
  }

  /// Subtitle text style
  static TextStyle subtitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: textColor(context),
    );
  }

  /// Body text style
  static TextStyle bodyStyle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textColor(context),
    );
  }

  /// Caption text style
  static TextStyle captionStyle(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: subtleTextColor(context),
    );
  }

  /// Small text style
  static TextStyle smallStyle(BuildContext context) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: subtleTextColor(context),
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Get loading indicator color
  static Color loadingColor(BuildContext context) {
    return Theme.of(context).primaryColor;
  }

  /// Check if current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get primary color with opacity
  static Color primaryWithOpacity(BuildContext context, double opacity) {
    return Theme.of(context).primaryColor.withOpacity(opacity);
  }

  /// Get status color based on achievement
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'achieved':
      case 'completed':
      case 'success':
        return successColor;
      case 'partial':
      case 'in progress':
      case 'pending':
        return warningColor;
      case 'not achieved':
      case 'failed':
      case 'error':
        return errorColor;
      default:
        return infoColor;
    }
  }

  /// Get growth indicator color based on value
  static Color getGrowthColor(double value) {
    return value >= 0 ? successColor : errorColor;
  }

  /// Get aging color based on days
  static Color getAgingColor(String label) {
    if (label.contains('< 30') || label.contains('On Account')) {
      return successColor;
    } else if (label.contains('30 to 60')) {
      return infoColor;
    } else if (label.contains('60 to 75')) {
      return warningColor;
    } else if (label.contains('75 to 90')) {
      return const Color(0xFFFF5722); // Deep Orange
    } else if (label.contains('> 90')) {
      return errorColor;
    }
    return infoColor;
  }
}

// ==================== EXTENSION METHODS ====================

extension ThemeContextExtension on BuildContext {
  /// Quick access to primary color
  Color get primaryColor => Theme.of(this).primaryColor;

  /// Quick access to text color
  Color get textColor => ThemeHelper.textColor(this);

  /// Quick access to subtle text color
  Color get subtleTextColor => ThemeHelper.subtleTextColor(this);

  /// Quick check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}