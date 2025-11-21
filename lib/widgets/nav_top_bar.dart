// lib/widgets/nav_top_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';
import '../screens/user_profile_screen.dart';
import '../models/search_filter_models.dart';

class NavTopBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final String subtitle;
  final List<SearchFilterOption>? searchFilters;
  final ValueChanged<Map<String, dynamic>>? onFilterChanged;
  final String? searchHint;
  final bool showGreeting;

  NavTopBar({
    Key? key,
    this.title,
    this.subtitle = "",
    this.searchFilters,
    this.onFilterChanged,
    this.searchHint = "Search...",
    this.showGreeting = false,
  }) : super(key: key);

  @override
  _NavTopBarState createState() => _NavTopBarState();

  @override
  Size get preferredSize => Size.fromHeight(_hasSearchFilters() ? 56 : 56);

  bool _hasSearchFilters() => searchFilters != null && searchFilters!.isNotEmpty;
}

class _NavTopBarState extends State<NavTopBar>
    with TickerProviderStateMixin {
  String _userName = 'User';
  bool _isSearchExpanded = false;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  late Animation<double> _fadeAnimation;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _searchAnimationController = AnimationController(
      duration: Duration(milliseconds: 350),
      vsync: this,
    );
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentOrientation = MediaQuery.of(context).orientation;

    if (_lastOrientation != null &&
        _lastOrientation != currentOrientation &&
        currentOrientation == Orientation.landscape &&
        _isSearchExpanded) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isSearchExpanded) {
          setState(() {
            _isSearchExpanded = false;
          });
          _searchAnimationController.reverse();
        }
      });
    }

    _lastOrientation = currentOrientation;
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedName = prefs.getString('name');
      setState(() {
        _userName = savedName ?? 'User';
      });
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });

    if (_isSearchExpanded) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }
    HapticFeedback.lightImpact();
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasSearchFilters = widget.searchFilters != null && widget.searchFilters!.isNotEmpty;

    return Column(
      children: [
        // Main AppBar
        Container(
          height: 56,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            leading: GestureDetector(
              onTap: () {
               /* HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfileScreen(),
                  ),
                );*/
              },
              child: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
            title: _buildTitleSection(),
            actions: [
              if (hasSearchFilters)
                Container(
                  margin: EdgeInsets.only(right: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _toggleSearch,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        child: AnimatedRotation(
                          turns: _isSearchExpanded ? 0.125 : 0.0,
                          duration: Duration(milliseconds: 350),
                          child: Icon(
                            _isSearchExpanded ? Icons.expand_less : Icons.filter_alt_outlined,
                            color: _isSearchExpanded
                                ? theme.primaryColor
                                : (isDark ? Colors.white : Colors.black87),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              IconButton(
                padding: EdgeInsets.all(6),
                icon: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 22
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                },
              ),
              IconButton(
                padding: EdgeInsets.all(6),
                icon: Icon(Icons.logout, color: Colors.redAccent, size: 22),
                onPressed: _logout,
              ),
            ],
          ),
        ),

        // Expandable Search/Filter Section
        if (hasSearchFilters)
          AnimatedBuilder(
            animation: _searchAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Container(
                  height: _searchAnimation.value * _getExpandedHeight(),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildSearchFilters(),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTitleSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.showGreeting)
          Text(
            _getGreeting(),
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.6),
            ),
          ),
        Text(
          widget.title ?? _userName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        if (widget.subtitle.isNotEmpty)
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.6),
            ),
          ),
      ],
    );
  }

  double _getExpandedHeight() {
    if (widget.searchFilters == null) return 0;

    final orientation = MediaQuery.of(context).orientation;

    final filterCount = widget.searchFilters!.length;

    if (orientation == Orientation.landscape) {
      double height = 10;
      height += filterCount * 40;
      height += (filterCount - 1) * 4;
      return height;
    } else {
      double height = 16;
      height += filterCount * 55;
      height += (filterCount - 1) * 8;
      return height;
    }
  }

  Widget _buildSearchFilters() {
    if (!_isSearchExpanded || widget.searchFilters == null) {
      return Container();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isLandscape ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? theme.scaffoldBackgroundColor.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: theme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < widget.searchFilters!.length; i++) ...[
            Container(
              height: isLandscape ? 35 : 50,
              child: widget.searchFilters![i].widget,
            ),
            if (i < widget.searchFilters!.length - 1)
              SizedBox(height: isLandscape ? 4 : 8),
          ],
        ],
      ),
    );
  }
}