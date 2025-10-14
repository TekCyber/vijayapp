import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/glass_container.dart';
import 'dealer_outstanding_screen.dart';
import 'dealer_pdc_screen.dart';
import 'dealer_sales_comparison_screen.dart';
import 'dealer_scheme_screen.dart';
import 'invoice_screen.dart';
import 'menu_navigator.dart';

class DealerMenuScreen extends StatefulWidget {
  final String title; // <-- use title instead of dealerName
  final Function(int)? onMenuSelected;

  DealerMenuScreen({required this.title, this.onMenuSelected});

  @override
  _DealerMenuScreenState createState() => _DealerMenuScreenState();
}

class _DealerMenuScreenState extends State<DealerMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  int selectedMenuIndex = 0;
  bool _isGridView = true; // Default to grid view

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800), // Match DealerSalesView timing
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
      {"title": "Sales", "icon": Icons.bar_chart, "color": Colors.blue, "description": "View sales data & analytics"},
      {"title": "Scheme", "icon": Icons.card_giftcard, "color": Colors.purple, "description": "Check available schemes"},
      {"title": "Outstanding", "icon": Icons.account_balance_wallet, "color": Colors.red, "description": "Outstanding & aging analysis"},
      {"title": "Pending Orders", "icon": Icons.assignment_late, "color": Colors.orange, "description": "Track pending orders"},
      {"title": "PDC", "icon": Icons.event_note, "color": Colors.green, "description": "Post-dated cheques"},
      {"title": "Invoices", "icon": Icons.receipt_long, "color": Colors.teal, "description": "Invoice management"},
    ];

    return DashboardLayout(
      title: "Dealer Menu",
      subtitle: widget.title, // Dealer name as subtitle
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
                        // View toggle button (top-right aligned)
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

  // Grid view layout - Updated to match SalesmanMenuScreen style
  Widget _buildGridView(List<Map<String, dynamic>> menuItems) {
    int crossAxisCount = MediaQuery.of(context).orientation == Orientation.portrait ? 2 : 4;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2, // Match SalesmanMenuScreen ratio
      children: menuItems.map((item) {
        return _buildGridCard(item["title"], item["icon"], item["color"]);
      }).toList(),
    );
  }

  // Updated Grid card to match SalesmanMenuScreen style
  Widget _buildGridCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _handleNavigation(title),
      child: GlassContainer(
        child: Container(
          padding: EdgeInsets.all(20), // Match SalesmanMenuScreen padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60, // Match SalesmanMenuScreen size
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
                  size: 30, // Match SalesmanMenuScreen icon size
                  color: color,
                ),
              ),
              SizedBox(height: 12), // Match SalesmanMenuScreen spacing
              Text(
                title,
                style: TextStyle(
                  fontSize: 16, // Match SalesmanMenuScreen font size
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

  // List view layout (existing)
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

  // Navigation logic extracted to shared method
  void _handleNavigation(String title) {
    HapticFeedback.lightImpact();

    if (title == "Sales") {
      Navigator.push(
        context,

        MaterialPageRoute(
          builder: (context) => DealerSalesComparisonScreen(title: widget.title),
        ),
      );
    } else if (title == "Outstanding") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DealerOutstandingScreen(title: widget.title),
        ),
      );
    }  else if (title == "Invoices") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceScreen(dealerName: widget.title),
        ),
      );
    } else if (title == "Scheme") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DealerSchemeScreen(title: widget.title),
        ),
      );
    } else if (title == "PDC") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DealerPDCScreen(title: widget.title),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$title - Coming Soon"),
          backgroundColor: Colors.blueAccent,
        ),
      );
    }
  }

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
}