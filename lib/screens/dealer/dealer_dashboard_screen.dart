// lib/screens/dealer/dealer_dashboard_screen.dart - DEALER LOGIN DASHBOARD
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../services/api_service.dart';
import '../../../theme/theme_helpers.dart';
import '../executive/dealer/dealer_outstanding_screen.dart';
import '../executive/dealer/dealer_pdc_screen.dart';
import '../executive/dealer/dealer_sales_comparison_screen.dart';
import '../executive/dealer/dealer_scheme_screen.dart';
import '../executive/dealer/invoice_screen.dart';
import '../executive/dealer/pending_orders_screen.dart';
import '../more_screen.dart';


class DealerDashboardScreen extends StatefulWidget {
  const DealerDashboardScreen({super.key});

  @override
  _DealerDashboardScreenState createState() => _DealerDashboardScreenState();
}

class _DealerDashboardScreenState extends State<DealerDashboardScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _outstandingList = [];
  bool _loading = false;
  bool _loadingOutstanding = false;
  String _errorMessage = '';
  String _dealerName = '';
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fetchDealerData();
    _fetchOutstandingData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDealerData() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? dealerName = prefs.getString('name');

      setState(() {
        _dealerName = dealerName ?? 'Dealer';
      });

      Map<String, dynamic> payload = {
        "sqlKey": "GET_DEALER_SALES_DATA",
        "dealerName": dealerName,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData =
        List<Map<String, dynamic>>.from(response.data!).map((item) {
          return {
            'brand': item['brand'] ?? '',
            'monthlySale':
            double.tryParse(item['monthlySale']?.toString() ?? '0') ?? 0.0,
            'yearlySale':
            double.tryParse(item['yearlySale']?.toString() ?? '0') ?? 0.0,
          };
        }).toList();

        setState(() {
          _salesData = fetchedData;
          _loading = false;
        });

        _animationController.forward();
      } else {
        throw Exception(response.error ?? 'Failed to fetch sales data');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Error fetching sales data: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchOutstandingData() async {
    try {
      setState(() {
        _loadingOutstanding = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? dealerName = prefs.getString('name');

      Map<String, dynamic> payload = {
        "sqlKey": "GET_OUTSTANDING_LIST_BY_DEALER",
        "dealername": dealerName,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        setState(() {
          _outstandingList = List<Map<String, dynamic>>.from(response.data!);
          _loadingOutstanding = false;
        });
      } else {
        setState(() {
          _outstandingList = [];
          _loadingOutstanding = false;
        });
      }
    } catch (e) {
      print('Error fetching outstanding data: $e');
      setState(() {
        _outstandingList = [];
        _loadingOutstanding = false;
      });
    }
  }

  Future<void> _refreshAllData() async {
    await Future.wait([
      _fetchDealerData(),
      _fetchOutstandingData(),
    ]);
  }

  double _calculateTotalOutstanding() {
    if (_outstandingList.isEmpty) return 0.0;

    return _outstandingList.fold(0.0, (sum, item) {
      final pending = item['Pending'];
      if (pending is num) {
        return sum + pending.toDouble();
      }
      return sum;
    });
  }

  String _getCurrentMonthName() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
  }

  String _getUptoLastMonthName() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Upto ${months[lastMonth.month - 1]}-${lastMonth.year.toString().substring(2)}';
  }

  double _calculateTotalMonthly() {
    return _salesData.fold(0.0, (sum, item) => sum + (item['monthlySale'] as double));
  }

  double _calculateTotalYearly() {
    return _salesData.fold(0.0, (sum, item) => sum + (item['yearlySale'] as double));
  }

  double _calculateVariance() {
    double totalMonthly = _calculateTotalMonthly();
    double totalYearly = _calculateTotalYearly();
    return totalMonthly - totalYearly;
  }

  double _calculateVariancePercentage() {
    double totalYearly = _calculateTotalYearly();
    if (totalYearly == 0) return 0.0;
    return (_calculateVariance() / totalYearly) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: "My Dashboard",
      subtitle: _dealerName,
      showBackButton: false,
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: _loading
            ? Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        )
            : _errorMessage.isNotEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: ThemeHelper.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: ThemeHelper.bodyStyle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshAllData,
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - _slideAnimation.value)),
              child: Opacity(
                opacity: _slideAnimation.value,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickActionsCard(),
                      const SizedBox(height: 24),
                      _buildSalesTable(),
                      const SizedBox(height: 24),
                      _buildCategoriesCard(), // NEW CATEGORIES CARD
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

  Widget _buildSalesTable() {
    final brandColors = [
      ThemeHelper.accentRed,
      ThemeHelper.accentBlue,
      ThemeHelper.accentPurple,
      ThemeHelper.accentTeal,
      ThemeHelper.accentOrange,
      ThemeHelper.successColor,
    ];

    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Purchase Summary",
              style: ThemeHelper.titleStyle(context),
            ),
            const SizedBox(height: 20),

            // Table Header
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      'Brand',
                      style: ThemeHelper.captionStyle(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      _getCurrentMonthName(),
                      style: ThemeHelper.captionStyle(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      _getUptoLastMonthName(),
                      style: ThemeHelper.captionStyle(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: ThemeHelper.dividerColor(context), thickness: 1, height: 24),

            // Brand Rows
            ..._salesData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final color = brandColors[index % brandColors.length];
              return _buildTableRow(
                data['brand'] as String,
                data['monthlySale'] as double,
                data['yearlySale'] as double,
                color,
              );
            }).toList(),

            Divider(color: ThemeHelper.dividerColor(context), thickness: 1, height: 16),

            // Total Row
            _buildTableRow(
              "Total Purchase",
              _calculateTotalMonthly(),
              _calculateTotalYearly(),
              null,
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, double cdAmount, double regAmount,
      [Color? indicatorColor, bool isMainRow = false]) {
    return Container(
      margin: EdgeInsets.only(bottom: isMainRow ? 8 : 4),
      padding: EdgeInsets.symmetric(vertical: isMainRow ? 8 : 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (!isMainRow && indicatorColor != null)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8, left: 8),
                    decoration: BoxDecoration(
                      color: indicatorColor.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (isMainRow)
                  const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: isMainRow
                        ? ThemeHelper.subtitleStyle(context)
                        : ThemeHelper.bodyStyle(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                Formatters.formatCurrency(cdAmount.abs()),
                style: TextStyle(
                  color: cdAmount < 0
                      ? ThemeHelper.errorColor
                      : (isMainRow
                      ? ThemeHelper.textColor(context)
                      : ThemeHelper.subtleTextColor(context)),
                  fontSize: isMainRow ? 16 : 13,
                  fontWeight: isMainRow ? FontWeight.w700 : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                Formatters.formatCurrency(regAmount.abs()),
                style: TextStyle(
                  color: regAmount < 0
                      ? ThemeHelper.errorColor
                      : (isMainRow
                      ? ThemeHelper.textColor(context)
                      : ThemeHelper.subtleTextColor(context)),
                  fontSize: isMainRow ? 16 : 13,
                  fontWeight: isMainRow ? FontWeight.w700 : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    final List<Map<String, dynamic>> quickActions = [
      {
        "title": "Outstanding",
        "icon": Icons.account_balance_wallet,
        "color": ThemeHelper.errorColor,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DealerOutstandingScreen(title: _dealerName),
            ),
          );
        },
      },
      {
        "title": "Purchase",
        "icon": Icons.shopping_cart,
        "color": ThemeHelper.accentBlue,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DealerSalesComparisonScreen(
                title: 'Purchase Analytics',
                dealername: _dealerName,
              ),
            ),
          );
        },
      },
      {
        "title": "Scheme",
        "icon": Icons.card_giftcard,
        "color": ThemeHelper.accentPurple,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DealerSchemeScreen(
                title: _dealerName,
              ),
            ),
          );
        },
      },
      {
        "title": "Pending Order",
        "icon": Icons.pending_actions,
        "color": ThemeHelper.warningColor,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PendingOrdersScreen(title: _dealerName),
            ),
          );
        },
      },
      {
        "title": "PDC",
        "icon": Icons.event_note,
        "color": ThemeHelper.successColor,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DealerPDCScreen(
                title: _dealerName,
              ),
            ),
          );
        },
      },
      {
        "title": "Invoices",
        "icon": Icons.receipt_long,
        "color": ThemeHelper.accentTeal,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceScreen(
                dealerName: _dealerName,
              ),
            ),
          );
        },
      },


    ];

    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quick Actions",
              style: ThemeHelper.titleStyle(context),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: quickActions.map((action) {
                return InkWell(
                  onTap: action["onTap"],
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          action["color"].withOpacity(0.2),
                          action["color"].withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: action["color"].withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          action["icon"],
                          color: action["color"],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action["title"],
                          style: TextStyle(
                            color: ThemeHelper.textColor(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Categories Card for Documents
  Widget _buildCategoriesCard() {
    final List<Map<String, dynamic>> categories = [
      {
        "title": "CATALOGUE",
        "icon": Icons.menu_book,
        "color": ThemeHelper.accentOrange,
        "category": "CATALOGUE",
      },
      {
        "title": "DISCOUNT STRUCTURE",
        "icon": Icons.discount,
        "color": ThemeHelper.accentPurple,
        "category": "DISCOUNT STRUCTURE",
      },
      {
        "title": "PRICE LIST",
        "icon": Icons.price_change,
        "color": ThemeHelper.accentBlue,
        "category": "PRICE LIST",
      },
      {
        "title": "SCHEME POSTER",
        "icon": Icons.campaign,
        "color": ThemeHelper.accentTeal,
        "category": "SCHEME POSTER",
      },
    ];

    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Document Categories",
              style: ThemeHelper.titleStyle(context),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: categories.map((category) {
                return InkWell(
                  onTap: () {
                    // Navigate to MoreScreen with selected category filter
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MoreScreen(
                          initialCategory: category["category"],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          category["color"].withOpacity(0.2),
                          category["color"].withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: category["color"].withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category["icon"],
                          color: category["color"],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category["title"],
                          style: TextStyle(
                            color: ThemeHelper.textColor(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}