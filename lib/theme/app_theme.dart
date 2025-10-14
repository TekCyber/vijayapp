// lib/theme/app_theme.dart - Simplified version
import 'package:flutter/material.dart';

class AppTheme {
  // Fixed TextThemes without context dependency
  static const TextTheme _darkTextTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      color: Color(0xFFE5E5E5),
    ),
    bodyLarge: TextStyle(
      fontSize: 12,
      color: Color(0xFFF0F0F0),
    ),
    bodyMedium: TextStyle(
      fontSize: 10,
      color: Color(0xFFCCCCCC),
    ),
  );

  static const TextTheme _lightTextTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Color(0xFF1A1A1A),
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      color: Color(0xFF2A2A2A),
    ),
    bodyLarge: TextStyle(
      fontSize: 12,
      color: Color(0xFF1A1A1A),
    ),
    bodyMedium: TextStyle(
      fontSize: 10,
      color: Color(0xFF4A4A4A),
    ),
  );

  // 1. Nord Theme
  static ThemeData get nordTheme => ThemeData(
    primaryColor: const Color(0xFF88C0D0),
    scaffoldBackgroundColor: const Color(0xFF2E3440),
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3B4252),
      foregroundColor: Color(0xFFECEFF4),
      elevation: 0,
    ),
  );

  // 2. GitHub Dark Theme
  static ThemeData get githubDarkTheme => ThemeData(
    primaryColor: const Color(0xFF58A6FF),
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF161B22),
      foregroundColor: Color(0xFFF0F6FC),
      elevation: 0,
    ),
  );

  // 3. Material Light Theme
  static ThemeData get materialLightTheme => ThemeData(
    primaryColor: const Color(0xFF6750A4),
    scaffoldBackgroundColor: const Color(0xFFFFFBFE),
    brightness: Brightness.light,
    fontFamily: 'Inter',
    textTheme: _lightTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F2FA),
      foregroundColor: Color(0xFF1D1B20),
      elevation: 0,
    ),
  );

  // 4. One Dark Theme
  static ThemeData get oneDarkTheme => ThemeData(
    primaryColor: const Color(0xFF61AFEF),
    scaffoldBackgroundColor: const Color(0xFF282C34),
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF21252B),
      foregroundColor: Color(0xFFABB2BF),
      elevation: 0,
    ),
  );

  // 5. Monokai Theme
  static ThemeData get monokaiTheme => ThemeData(
    primaryColor: const Color(0xFFE6DB74),
    scaffoldBackgroundColor: const Color(0xFF272822),
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3E3D32),
      foregroundColor: Color(0xFFF8F8F2),
      elevation: 0,
    ),
  );

  // 6. Dracula Theme
  static ThemeData get draculaTheme => ThemeData(
    primaryColor: const Color(0xFFBD93F9),
    scaffoldBackgroundColor: const Color(0xFF282A36),
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF44475A),
      foregroundColor: Color(0xFFF8F8F2),
      elevation: 0,
    ),
  );

  // 7. Classic Dark Theme
  static ThemeData get darkTheme => ThemeData(
    primaryColor: const Color(0xFF6366F1),
    scaffoldBackgroundColor: const Color(0xFF0F0F23),
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A35),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );

  // 8. Clean Light Theme
  static ThemeData get lightTheme => ThemeData(
    primaryColor: const Color(0xFF6366F1),
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    brightness: Brightness.light,
    fontFamily: 'Inter',
    textTheme: _lightTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A1A),
      elevation: 1,
    ),
  );



  // 9. Gruvbox Theme (Warm, Eye-Friendly)
  static ThemeData get gruvboxTheme => ThemeData(
    primaryColor: const Color(0xFFB8BB26),
    scaffoldBackgroundColor: const Color(0xFF282828),
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3C3836),
      foregroundColor: Color(0xFFFBF1C7),
      elevation: 0,
    ),
  );

  // 10. Solarized Dark (Scientifically Designed for Eye Strain)
  static ThemeData get solarizedDarkTheme => ThemeData(
    primaryColor: const Color(0xFF268BD2),
    scaffoldBackgroundColor: const Color(0xFF002B36),
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF073642),
      foregroundColor: Color(0xFF93A1A1),
      elevation: 0,
    ),
  );

  // 11. Tokyo Night (Modern, Vibrant)
  static ThemeData get tokyoNightTheme => ThemeData(
    primaryColor: const Color(0xFF7AA2F7),
    scaffoldBackgroundColor: const Color(0xFF1A1B26),
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF24283B),
      foregroundColor: Color(0xFFC0CAF5),
      elevation: 0,
    ),
  );

  // 12. Catppuccin Mocha (Pastel, Soft)
  static ThemeData get catppuccinMochaTheme => ThemeData(
    primaryColor: const Color(0xFF89B4FA),
    scaffoldBackgroundColor: const Color(0xFF1E1E2E),
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    textTheme: _darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF313244),
      foregroundColor: Color(0xFFCDD6F4),
      elevation: 0,
    ),
  );

  // 13. High Contrast Light (Daytime Optimized)
  static ThemeData get highContrastLightTheme => ThemeData(
    primaryColor: const Color(0xFF0066CC),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    brightness: Brightness.light,
    fontFamily: 'Inter',
    textTheme: _lightTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF000000),
      elevation: 1,
    ),
  );

}