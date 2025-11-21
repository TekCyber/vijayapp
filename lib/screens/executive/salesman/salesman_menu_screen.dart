import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultra_sales_dashboard/screens/executive/salesman/salesman_target_screen.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../widgets/glass_container.dart';
import '../menu_navigator.dart';
import 'cheque_return_screen.dart';
import 'dealer_count_screen.dart';
import 'dealer_sales_view.dart';
import 'dealer_scheme_screen.dart';
import 'pending_orders_screen.dart';

class SalesmanMenuScreen extends StatefulWidget {
  final String title;
  final Function(int)? onMenuSelected;

  SalesmanMenuScreen({required this.title, this.onMenuSelected});

  @override
  _SalesmanMenuScreenState createState() => _SalesmanMenuScreenState();
}

class _SalesmanMenuScreenState extends State<SalesmanMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  int selectedMenuIndex = 0;
  bool _isGridView = true; // Add view toggle functionality

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800), // Match DealerMenuScreen timing
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Centralized menu navigation
  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {"title": "Sales", "icon": Icons.trending_up, "color": Colors.green, "description": "View sales performance & trends"},
      {"title": "Scheme", "icon": Icons.card_giftcard, "color": Colors.purple, "description": "Available schemes & offers"},
      {"title": "Target", "icon": Icons.track_changes, "color": Colors.blue, "description": "Sales targets & achievements"},
      {"title": "Pending Orders", "icon": Icons.pending_actions, "color": Colors.orange, "description": "Track pending orders"},
      {"title": "Dealer Count", "icon": Icons.group, "color": Colors.teal, "description": "Dealer network analytics"},
      {"title": "Cheque Return", "icon": Icons.assignment_return, "color": Colors.red, "description": "Returned cheque management"},
    ];

    return DashboardLayout(
      title: "Salesman Menu",
      subtitle: widget.title, // Salesman name as subtitle
      onTabSelected: _onMenuSelected,
      showBackButton: true,

      body: SafeArea(
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - _slideAnimation.value)),
              child: Opacity(
                opacity: _slideAnimation.value,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // View toggle button (matching DealerMenuScreen)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isGridView = false;
                                    });
                                    HapticFeedback.lightImpact();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: !_isGridView
                                          ? Colors.blueAccent.withOpacity(0.8)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.view_list,
                                      color: !_isGridView ? Colors.white : Colors.white60,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isGridView = true;
                                    });
                                    HapticFeedback.lightImpact();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _isGridView
                                          ? Colors.blueAccent.withOpacity(0.8)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.grid_view,
                                      color: _isGridView ? Colors.white : Colors.white60,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Dynamic content based on view type
                      _isGridView
                          ? _buildGridView(menuItems)
                          : _buildModernMenuGrid(menuItems),

                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

    );
  }

  // Grid view layout
  Widget _buildGridView(List<Map<String, dynamic>> menuItems) {
    int crossAxisCount = MediaQuery.of(context).orientation == Orientation.portrait ? 2 : 4;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: menuItems.map((item) {
        return _buildGridCard(item["title"], item["icon"], item["color"]);
      }).toList(),
    );
  }

  // Grid card (consistent with DealerMenuScreen)
  Widget _buildGridCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _handleNavigation(title),
      child: GlassContainer(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // List view layout (new addition)
  Widget _buildModernMenuGrid(List<Map<String, dynamic>> menuItems) {
    return Column(
      children: menuItems.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildModernMenuCard(
            item["title"],
            item["icon"],
            item["color"],
            item["description"],
          ),
        );
      }).toList(),
    );
  }

  // Modern list view card (matching DealerMenuScreen style)
  Widget _buildModernMenuCard(String title, IconData icon, Color color, String description) {
    return GestureDetector(
      onTap: () => _handleNavigation(title),
      child: GlassContainer(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon container with modern styling
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),

              const SizedBox(width: 20),

              // Content section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with colored container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation logic (extracted from original implementation)
  void _handleNavigation(String title) {
    HapticFeedback.lightImpact();

    // Navigate to different screens based on menu item
    if (title == "Sales") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DealerSalesView(),
        ),
      );
    } else if (title == "Scheme") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DealerSchemeScreen(title : "Scheme Reports" ),
        ),
      );
    } else if (title == "Target") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SalesmanTargetScreen(title : "Target Details "),
        ),
      );
    } else if (title == "Pending Orders") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PendingOrdersScreen(title: "Pending Orders"),
        ),
      );
    } else if (title == "Dealer Count") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DealerCountScreen(),
        ),
      );
    } else if (title == "Cheque Return") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChequeReturnScreen(),
        ),
      );
    } else {
      // Fallback for any other items
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$title clicked")),
      );
    }
  }
}