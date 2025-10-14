// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultra_sales_dashboard/theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(UltraSalesApp());
}

// Theme Provider to access from anywhere
class ThemeProvider extends InheritedWidget {
  final String currentTheme;
  final Function(String) changeTheme;

  const ThemeProvider({
    super.key,
    required this.currentTheme,
    required this.changeTheme,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return currentTheme != oldWidget.currentTheme;
  }
}

class UltraSalesApp extends StatefulWidget {
  const UltraSalesApp({super.key});

  @override
  State<UltraSalesApp> createState() => _UltraSalesAppState();
}

class _UltraSalesAppState extends State<UltraSalesApp> {
  String _currentTheme = 'nord';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = prefs.getString('selected_theme') ?? 'nord';
    });
  }

  Future<void> _saveTheme(String theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', theme);
    setState(() {
      _currentTheme = theme;
    });
  }

  ThemeData get _currentThemeData {
    switch (_currentTheme) {
      case 'dark':
        return AppTheme.darkTheme;
      case 'light':
        return AppTheme.lightTheme;
      case 'nord':
        return AppTheme.nordTheme;
      case 'monokai':
        return AppTheme.monokaiTheme;
      case 'github':
        return AppTheme.githubDarkTheme;
      case 'dracula':
        return AppTheme.draculaTheme;
      case 'material':
        return AppTheme.materialLightTheme;
      case 'oneDark':
        return AppTheme.oneDarkTheme;
      case 'gruvbox':
        return AppTheme.gruvboxTheme;
      case 'solarized':
        return AppTheme.solarizedDarkTheme;
      case 'tokyo':
        return AppTheme.tokyoNightTheme;
      case 'catppuccin':
        return AppTheme.catppuccinMochaTheme;
      case 'highContrast':
        return AppTheme.highContrastLightTheme;
      default:
        return AppTheme.nordTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      currentTheme: _currentTheme,
      changeTheme: _saveTheme,
      child: MaterialApp(
        title: 'Ultra Modern Sales Dashboard',
        debugShowCheckedModeBanner: false,
        theme: _currentThemeData,
        home: LoginScreen(),
      ),
    );
  }
}