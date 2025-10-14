// lib/widgets/floating_menu.dart
import 'package:flutter/material.dart';
import 'dart:ui';

class FloatingMenu extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const FloatingMenu({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  State<FloatingMenu> createState() => _FloatingMenuState();
}

class _FloatingMenuState extends State<FloatingMenu> {
  bool _isExpanded = false;
  Offset _position = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenSize = MediaQuery.of(context).size;
        final safePadding = MediaQuery.of(context).padding;

        final centerX = (screenSize.width - 60) / 2;
        final bottomY = screenSize.height - safePadding.bottom - 100;

        setState(() {
          _position = Offset(centerX, bottomY);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    final safePadding = MediaQuery.of(context).padding;
    final topBarTotalHeight = 70.0 + safePadding.top;

    return Stack(
      children: [
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = false),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: Draggable(
            feedback: _buildFab(context),
            childWhenDragging: Container(),
            onDragEnd: (details) {
              setState(() {
                double x = details.offset.dx.clamp(0.0, screenSize.width - 60);
                double y = details.offset.dy.clamp(
                    topBarTotalHeight,
                    screenSize.height - 60
                );
                _position = Offset(x, y);
              });
            },
            child: _buildMenuWithFab(context, screenSize, topBarTotalHeight),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuWithFab(BuildContext context, Size screenSize, double topBarHeight) {
    final menuHeight = 200.0;

    final spaceAbove = _position.dy - topBarHeight;
    final shouldShowBelow = spaceAbove < menuHeight;

    final spaceBelow = screenSize.height - (_position.dy + 60);
    final forceShowAbove = spaceBelow < menuHeight && spaceAbove > menuHeight;

    final showBelow = shouldShowBelow && !forceShowAbove;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: showBelow
          ? [
        _buildFab(context),
        if (_isExpanded) _buildMenu(context, true),
      ]
          : [
        if (_isExpanded) _buildMenu(context, false),
        _buildFab(context),
      ],
    );
  }

  Widget _buildFab(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        width: 60,
        height: 60,
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
              blurRadius: 12,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _isExpanded ? Icons.close : Icons.menu,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, bool showBelow) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    final items = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
      {'icon': Icons.analytics_outlined, 'label': 'Dealer'},
      {'icon': Icons.assessment_outlined, 'label': 'Salesman'},
      {'icon': Icons.more_horiz, 'label': 'More'},
    ];

    return Container(
      margin: showBelow
          ? const EdgeInsets.only(top: 12)
          : const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: screenSize.width * 0.6,
        minWidth: 150,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? theme.scaffoldBackgroundColor.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        border: Border.all(
            color: theme.primaryColor.withOpacity(0.3),
            width: 1.5
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = widget.selectedIndex == index;

          return GestureDetector(
            onTap: () {
              widget.onTabSelected(index);
              setState(() => _isExpanded = false);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? theme.primaryColor.withOpacity(0.15)
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: isSelected
                        ? theme.primaryColor
                        : (isDark ? Colors.white70 : Colors.black54),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? theme.primaryColor
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}