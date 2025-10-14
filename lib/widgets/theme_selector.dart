// lib/widgets/theme_selector.dart
import 'package:flutter/material.dart';
import '../main.dart';

// Compact floating button version - perfect for login screen
class FloatingThemeButton extends StatelessWidget {
  const FloatingThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (themeProvider == null) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => _showThemeBottomSheet(context, themeProvider),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.palette_outlined,
            color: isDark ? Colors.white : Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context, ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3);

    final themes = {
      'Nord': 'nord',
      'Classic Dark': 'dark',
      'Clean Light': 'light',
      'GitHub Dark': 'github',
      'Monokai': 'monokai',
      'Dracula': 'dracula',
      'Material Light': 'material',
      'One Dark': 'oneDark',
      'Gruvbox': 'gruvbox',
      'Solarized Dark': 'solarized',
      'Tokyo Night': 'tokyo',
      'Catppuccin Mocha': 'catppuccin',
      'High Contrast Light': 'highContrast',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark
              ? theme.scaffoldBackgroundColor.withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: subtleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.palette, color: theme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Choose Theme',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: themes.entries.map((entry) {
                  final isSelected = entry.value == themeProvider.currentTheme;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.primaryColor.withOpacity(0.2)
                          : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor
                            : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? theme.primaryColor
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: textColor,
                        ),
                      ),
                      onTap: () {
                        themeProvider.changeTheme(entry.value);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);

    if (themeProvider == null) return const SizedBox.shrink();

    final themes = {
      'Nord': 'nord',
      'Dark': 'dark',
      'Light': 'light',
      'GitHub Dark': 'github',
      'Monokai': 'monokai',
      'Dracula': 'dracula',
      'Material': 'material',
      'One Dark': 'oneDark',
      'Gruvbox': 'gruvbox',
      'Solarized': 'solarized',
      'Tokyo Night': 'tokyo',
      'Catppuccin': 'catppuccin',
      'High Contrast': 'highContrast',
    };

    return PopupMenuButton<String>(
      icon: const Icon(Icons.palette),
      tooltip: 'Change Theme',
      onSelected: (String themeKey) {
        themeProvider.changeTheme(themeKey);
      },
      itemBuilder: (BuildContext context) {
        return themes.entries.map((entry) {
          final isSelected = entry.value == themeProvider.currentTheme;
          return PopupMenuItem<String>(
            value: entry.value,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
                const SizedBox(width: 12),
                Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

// Alternative: Drawer-based theme selector
class ThemeDrawer extends StatelessWidget {
  const ThemeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);

    if (themeProvider == null) return const SizedBox.shrink();

    final themes = {
      'Nord': 'nord',
      'Classic Dark': 'dark',
      'Clean Light': 'light',
      'GitHub Dark': 'github',
      'Monokai': 'monokai',
      'Dracula': 'dracula',
      'Material Light': 'material',
      'One Dark': 'oneDark',
      'Gruvbox': 'gruvbox',
      'Solarized Dark': 'solarized',
      'Tokyo Night': 'tokyo',
      'Catppuccin Mocha': 'catppuccin',
      'High Contrast Light': 'highContrast',
    };

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.palette, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Choose Theme',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...themes.entries.map((entry) {
            final isSelected = entry.value == themeProvider.currentTheme;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
              title: Text(
                entry.key,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onTap: () {
                themeProvider.changeTheme(entry.value);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}