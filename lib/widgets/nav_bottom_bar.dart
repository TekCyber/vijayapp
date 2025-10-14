// lib/widgets/nav_bottom_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class NavBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final AnimationController animationController;

  const NavBottomBar({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.all(20),
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.scaffoldBackgroundColor.withOpacity(0.8)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(context, 0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                _buildNavItem(context, 1, Icons.analytics_outlined, Icons.analytics, 'Dealer'),
                _buildNavItem(context, 2, Icons.assessment_outlined, Icons.assessment, 'Salesman'),
                _buildNavItem(context, 3, Icons.more_horiz, Icons.more_horiz, 'More'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData outlineIcon, IconData filledIcon, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        onTabSelected(index);
        HapticFeedback.lightImpact();
        animationController.reset();
        animationController.forward();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor,
              theme.primaryColor.withOpacity(0.8),
            ],
          ) : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Icon(
                isSelected ? filledIcon : outlineIcon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : Colors.black54),
                size: 26,
              ),
            ),
            SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : Colors.black54),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}