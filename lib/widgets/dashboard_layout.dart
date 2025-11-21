// lib/widgets/dashboard_layout.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nav_top_bar.dart';
import 'floating_menu.dart';
import '../models/search_filter_models.dart';

class DashboardLayout extends StatefulWidget {
  final Widget body;
  final String title;
  final String subtitle;
  final int initialIndex;
  final bool showBackButton;
  final ValueChanged<int>? onTabSelected;
  // Search/Filter related properties - null means no search functionality
  final List<SearchFilterOption>? searchFilters;
  final ValueChanged<Map<String, dynamic>>? onFilterChanged;
  final String? searchHint;
  final bool showGreeting;

  const DashboardLayout({
    required this.body,
    this.title = "Dashboard",
    this.subtitle = "",
    this.initialIndex = 0,
    this.onTabSelected,
    this.showBackButton = false,
    this.searchFilters,
    this.onFilterChanged,
    this.searchHint = "Search...",
    this.showGreeting = false,
    super.key,
  });

  @override
  _DashboardLayoutState createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late int _selectedIndex;
  bool _showFloatingMenu = true;
  bool _isCheckingUserType = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final typeName = prefs.getString('typeName');

      setState(() {
        _showFloatingMenu = typeName != 'DEALER';
        _isCheckingUserType = false;
      });
    } catch (e) {
      // If error occurs, default to showing the menu
      setState(() {
        _showFloatingMenu = true;
        _isCheckingUserType = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    if (widget.onTabSelected != null) widget.onTabSelected!(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            NavTopBar(
              title: widget.title,
              subtitle: widget.subtitle,
              searchFilters: widget.searchFilters,
              onFilterChanged: widget.onFilterChanged,
              searchHint: widget.searchHint,
              showGreeting: widget.showGreeting,
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - _slideAnimation.value)),
                    child: Opacity(
                      opacity: _slideAnimation.value,
                      child: widget.body,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: (!_isCheckingUserType && _showFloatingMenu)
          ? FloatingMenu(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      )
          : null,
    );
  }
}