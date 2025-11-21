// lib/screens/dealer/dealer_sales_view.dart - COMPLETE THEME-AWARE VERSION
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../services/api_service.dart';
import '../../../models/search_filter_models.dart';
import '../../../theme/theme_helpers.dart';
import 'dealer_menu_screen.dart';
import '../menu_navigator.dart';

class DealerSalesView extends StatefulWidget {
  const DealerSalesView({super.key});

  @override
  _DealerSalesViewState createState() => _DealerSalesViewState();
}

class _DealerSalesViewState extends State<DealerSalesView> {
  List<String> _routes = [];
  final Map<String, bool> _expandedDealers = {};
  bool _allExpanded = false;
  List<Map<String, dynamic>> _salesData = [];
  Map<String, Map<String, dynamic>> _creditData = {}; // Store credit & outstanding data
  bool _loading = false;
  String _errorMessage = '';
  int selectedMenuIndex = 0;
  bool _showAll = false;

  String _searchText = '';
  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
    _fetchSalesData();
    _fetchCreditAndOutstanding();
  }

  List<SearchFilterOption> _getSearchFilters() {
    if (_routes.isEmpty) return [];

    return [
      SearchFilterOption(
        key: 'search',
        widget: SearchTextFilter(
          initialValue: _searchText,
          hint: "Search dealers... (min 3 characters)",
          minCharacters: 3,
          onChanged: (value) {
            setState(() {
              _searchText = value;
            });
          },
        ),
      ),

      SearchFilterOption(
        key: 'route',
        widget: RouteDropdownFilter(
          routes: _routes,
          selectedRoute: _selectedRoute ?? (_routes.isNotEmpty ? _routes.first : null),
          label: "Select Route",
          onChanged: (value) {
            setState(() {
              _selectedRoute = value;
            });
          },
        ),
      ),
    ];
  }

  void _handleFilterChanged(Map<String, dynamic> filters) {
    print('DealerSalesView: Received filters: $filters');
  }

  Future<void> _fetchRoutes() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      Map<String, dynamic> payload = {
        "sqlKey": "ROUTE_LIST_BY_EXECUTIVE",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<String> fetchedRoutes = List<Map<String, dynamic>>.from(response.data!)
            .map((item) => item['Route']?.toString() ?? '')
            .where((route) => route.isNotEmpty)
            .toList();

        setState(() {
          _routes = ['All Routes', ...fetchedRoutes];
          _selectedRoute = _routes.isNotEmpty ? _routes.first : null;
        });
      } else {
        setState(() {
          _routes = ['All Routes'];
          _selectedRoute = 'All Routes';
        });
      }
    } catch (e) {
      setState(() {
        _routes = ['All Routes'];
        _selectedRoute = 'All Routes';
      });
    }
  }

  Future<void> _fetchCreditAndOutstanding() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      Map<String, dynamic> payload = {
        "sqlKey": "GET_DEALER_CREDIT_AND_OUTSTANDING",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        Map<String, Map<String, dynamic>> creditMap = {};

        List<Map<String, dynamic>>.from(response.data!).forEach((item) {
          String dealername = item['dealername']?.toString() ?? '';
          if (dealername.isNotEmpty) {
            creditMap[dealername] = {
              'creditLimit': item['creditLimit']?.toString() ?? '0',
              'totalOutstanding': (item['totalOutstanding'] as num?)?.toDouble() ?? 0.0,
            };
          }
        });

        setState(() {
          _creditData = creditMap;
        });
      }
    } catch (e) {
      print('Error fetching credit and outstanding: ${e.toString()}');
    }
  }

  Future<void> _fetchSalesData() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      Map<String, dynamic> payload = {
        "sqlKey": "GET_SALES_BY_DEALER_AND_EXECUTIVE",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData =
        List<Map<String, dynamic>>.from(response.data!).map((item) {
          return {
            'dealername': item['dealername'] ?? '',
            'brand': item['brand'] ?? '',
            'monthlySale':
            double.tryParse(item['monthlySale']?.toString() ?? '0') ?? 0.0,
            'yearlySale':
            double.tryParse(item['yearlySale']?.toString() ?? '0') ?? 0.0,
            'route': item['Route'] ?? '',
          };
        }).toList();

        setState(() {
          _salesData = fetchedData;
          _allExpanded = false;
          _expandedDealers.clear();
          for (var dealer in _groupByDealer(_salesData).keys) {
            _expandedDealers[dealer] = false;
          }
          _loading = false;
        });
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

  Map<String, List<Map<String, dynamic>>> _groupByDealer(
      List<Map<String, dynamic>> data) {
    final Map<String, Map<String, Map<String, dynamic>>> grouped = {};

    for (var item in data) {
      final dealer = item['dealername'] ?? '';
      final brand = item['brand'] ?? '';
      final monthlySale = (item['monthlySale'] as double?) ?? 0.0;
      final yearlySale = (item['yearlySale'] as double?) ?? 0.0;

      grouped.putIfAbsent(dealer, () => {});

      if (grouped[dealer]!.containsKey(brand)) {
        grouped[dealer]![brand]!['monthlySale'] += monthlySale;
        grouped[dealer]![brand]!['yearlySale'] += yearlySale;
      } else {
        grouped[dealer]![brand] = {
          'dealername': dealer,
          'brand': brand,
          'monthlySale': monthlySale,
          'yearlySale': yearlySale,
        };
      }
    }

    final Map<String, List<Map<String, dynamic>>> result = {};
    grouped.forEach((dealer, brandsMap) {
      result[dealer] = brandsMap.values.toList();
    });

    return result;
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

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final searchText = _searchText.toLowerCase().trim();

    List<Map<String, dynamic>> filtered = _salesData;

    if (_salesData.isNotEmpty) {
      filtered = _salesData.where((item) {
        bool dealerMatch = true;
        if (searchText.isNotEmpty && searchText.length >= 3) {
          dealerMatch = item['dealername'].toString().toLowerCase().contains(searchText);
        }

        bool routeMatch = true;
        if (_selectedRoute != null && _selectedRoute != 'All Routes') {
          routeMatch = item['route'] == _selectedRoute;
        }

        return dealerMatch && routeMatch;
      }).toList();
    }

    final groupedData = _groupByDealer(filtered);
    final entries = groupedData.entries.toList();
    final visibleEntries = _showAll ? entries : entries.take(5).toList();

    return DashboardLayout(
      title: "My Dealers",
      onTabSelected: _onMenuSelected,
      searchFilters: _getSearchFilters(),
      onFilterChanged: _handleFilterChanged,
      searchHint: "Search dealers... (min 3 characters)",
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loading = true;
          });
          await _fetchRoutes();
          await _fetchSalesData();
          await _fetchCreditAndOutstanding();
          setState(() {
            _loading = false;
          });
        },
        child: _loading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Loading sales data...",
                style: ThemeHelper.subtitleStyle(context),
              ),
            ],
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
                style: ThemeHelper.bodyStyle(context).copyWith(
                  color: ThemeHelper.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSalesData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : visibleEntries.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: ThemeHelper.subtleTextColor(context),
              ),
              const SizedBox(height: 16),
              Text(
                searchText.isNotEmpty && searchText.length < 3
                    ? 'Type at least 3 characters to search'
                    : 'No dealers found',
                style: ThemeHelper.subtitleStyle(context),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: ThemeHelper.glassBackground(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showAll = !_showAll;
                                // Keep all dealers collapsed when toggling show all
                                for (var dealer in groupedData.keys) {
                                  _expandedDealers[dealer] = false;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _showAll ? ThemeHelper.accentGreen.withOpacity(0.8) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                _showAll ? Icons.remove : Icons.add,
                                color: _showAll ? Colors.white : ThemeHelper.subtleTextColor(context),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildOverallSalesCard(groupedData),
              ),

              const SizedBox(height: 20),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleEntries.length,
                itemBuilder: (context, index) {
                  final entry = visibleEntries[index];
                  final dealerName = entry.key;
                  final sales = entry.value;
                  final isExpanded = _expandedDealers[dealerName] ?? false;

                  return _buildDealerCard(dealerName, sales, isExpanded);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallSalesCard(Map<String, List<Map<String, dynamic>>> groupedData) {
    double overallCurrentTotal = 0.0;
    double overallPreviousTotal = 0.0;

    for (var dealerSales in groupedData.values) {
      double dealerCurrentTotal = dealerSales.fold(0.0, (sum, e) => sum + (e['monthlySale'] as double));
      double dealerPreviousTotal = dealerSales.fold(0.0, (sum, e) => sum + (e['yearlySale'] as double));

      overallCurrentTotal += dealerCurrentTotal;
      overallPreviousTotal += dealerPreviousTotal;
    }

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Sales Total - No inner card decoration
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First Row: Title
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: ThemeHelper.accentOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Overall Sales Total',
                      style: ThemeHelper.subtitleStyle(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Second Row: Sales Data
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _getCurrentMonthName(),
                      style: ThemeHelper.bodyStyle(context).copyWith(
                        color: ThemeHelper.subtleTextColor(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ':',
                      style: ThemeHelper.bodyStyle(context).copyWith(
                        color: ThemeHelper.subtleTextColor(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.formatCurrency(overallCurrentTotal.abs()),
                      style: TextStyle(
                        color: overallCurrentTotal < 0 ? ThemeHelper.errorColor : ThemeHelper.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '|',
                        style: ThemeHelper.bodyStyle(context).copyWith(
                          color: ThemeHelper.subtleTextColor(context),
                        ),
                      ),
                    ),
                    Text(
                      _getUptoLastMonthName(),
                      style: ThemeHelper.bodyStyle(context).copyWith(
                        color: ThemeHelper.subtleTextColor(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ':',
                      style: ThemeHelper.bodyStyle(context).copyWith(
                        color: ThemeHelper.subtleTextColor(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.formatCurrency(overallPreviousTotal.abs()),
                      style: TextStyle(
                        color: overallPreviousTotal < 0 ? ThemeHelper.errorColor : ThemeHelper.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // _buildSalesGrowthIndicator(overallCurrentTotal, overallPreviousTotal),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesGrowthIndicator(double current, double previous) {
    if (previous == 0) return const SizedBox.shrink();

    double growthAmount = current - previous;
    double growthPercentage = (growthAmount / previous.abs()) * 100;
    bool isPositive = growthAmount >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPositive
            ? ThemeHelper.successColor.withOpacity(0.1)
            : ThemeHelper.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPositive
              ? ThemeHelper.successColor.withOpacity(0.3)
              : ThemeHelper.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? ThemeHelper.successColor : ThemeHelper.errorColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '${isPositive ? '+' : ''}${Formatters.formatCurrency(growthAmount.abs())} (${growthPercentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: isPositive ? ThemeHelper.successColor : ThemeHelper.errorColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'vs Previous Period',
            style: ThemeHelper.captionStyle(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerCard(String dealerName, List<Map<String, dynamic>> sales, bool isExpanded) {
    double totalMonthly = 0;
    double totalYearly = 0;
    for (var sale in sales) {
      totalMonthly += (sale['monthlySale'] as double?) ?? 0.0;
      totalYearly += (sale['yearlySale'] as double?) ?? 0.0;
    }

    // Get credit and outstanding data
    final creditInfo = _creditData[dealerName];
    final creditLimit = creditInfo?['creditLimit'] ?? '0';
    final totalOutstanding = creditInfo?['totalOutstanding'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(                          // ← OUTER GestureDetector for navigation
        onTap: () {
          Navigator.push(                              // ← Navigates to DealerMenuScreen
            context,
            MaterialPageRoute(
              builder: (context) => DealerMenuScreen(title: dealerName),
            ),
          );
        },
        child: GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(                                    // ← Header row
                  children: [
                    Expanded(
                      child: Text(
                        dealerName,
                        style: ThemeHelper.titleStyle(context).copyWith(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    GestureDetector(                   // ← INNER GestureDetector for expand/collapse
                      behavior: HitTestBehavior.opaque, // ← Prevents tap from bubbling to outer GestureDetector
                      onTap: () {
                        setState(() {
                          _expandedDealers[dealerName] = !isExpanded;  // ← Expands/collapses
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ThemeHelper.accentBlue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpanded ? Icons.remove : Icons.add,
                          color: ThemeHelper.accentBlue,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          icon: Icons.calendar_today,
                          label: _getCurrentMonthName(),
                          value: Formatters.formatCurrency(totalMonthly),
                          color: ThemeHelper.accentBlue,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: ThemeHelper.dividerColor(context),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          icon: Icons.trending_up,
                          label: _getUptoLastMonthName(),
                          value: Formatters.formatCurrency(totalYearly),
                          color: ThemeHelper.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  // Credit and Outstanding Info Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeHelper.accentGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ThemeHelper.accentGreen.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final credit = double.tryParse(creditLimit) ?? 0.0;
                        final balance = credit - totalOutstanding;
                        final balanceColor = balance < 0
                            ? ThemeHelper.errorColor
                            : balance < (credit * 0.2)
                            ? ThemeHelper.accentOrange
                            : ThemeHelper.accentGreen;

                        return Column(
                          children: [
                            // First Row - Labels
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.credit_card,
                                        size: 16,
                                        color: ThemeHelper.accentGreen,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Credit Limit',
                                        style: ThemeHelper.bodyStyle(context).copyWith(
                                          fontSize: 12,
                                          color: ThemeHelper.subtleTextColor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        size: 16,
                                        color: totalOutstanding > 0 ? ThemeHelper.accentOrange : ThemeHelper.accentGreen,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Outstanding',
                                        style: ThemeHelper.bodyStyle(context).copyWith(
                                          fontSize: 12,
                                          color: ThemeHelper.subtleTextColor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        balance < 0 ? Icons.warning : Icons.account_balance,
                                        size: 16,
                                        color: balanceColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Balance',
                                        style: ThemeHelper.bodyStyle(context).copyWith(
                                          fontSize: 12,
                                          color: ThemeHelper.subtleTextColor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Second Row - Amounts
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    Formatters.formatCurrencyWithDecimal (credit,2),
                                    style: ThemeHelper.bodyStyle(context).copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeHelper.accentGreen,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    Formatters.formatCurrencyWithDecimal(totalOutstanding.abs(),2),
                                    style: ThemeHelper.bodyStyle(context).copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: totalOutstanding > 0 ? ThemeHelper.accentOrange : ThemeHelper.accentGreen,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    Formatters.formatCurrencyWithDecimal(balance.abs(),2),
                                    style: ThemeHelper.bodyStyle(context).copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: balanceColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeHelper.surfaceColor(context).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ThemeHelper.dividerColor(context),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Brand',
                                  style: ThemeHelper.subtitleStyle(context),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    _getCurrentMonthName(),
                                    style: ThemeHelper.bodyStyle(context),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    _getUptoLastMonthName(),
                                    style: ThemeHelper.bodyStyle(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: ThemeHelper.dividerColor(context), thickness: 1, height: 16),

                        Column(
                          children: sales.map((e) {
                            return _buildTableRow(
                              e['brand'] ?? '',
                              e['monthlySale'] as double,
                              e['yearlySale'] as double,
                              ThemeHelper.accentBlue,
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 12),
                        Divider(color: ThemeHelper.dividerColor(context), thickness: 1, height: 16),

                        _buildTableRow("Total Sales", totalMonthly, totalYearly, null, true),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: ThemeHelper.bodyStyle(context).copyWith(
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: ThemeHelper.titleStyle(context).copyWith(
            fontSize: 16,
            color: color,
          ),
        ),
      ],
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
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: indicatorColor.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
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
                      : (isMainRow ? ThemeHelper.textColor(context) : ThemeHelper.subtleTextColor(context)),
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
                      : (isMainRow ? ThemeHelper.textColor(context) : ThemeHelper.subtleTextColor(context)),
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
}

// Search Text Widget
class SearchTextFilter extends StatefulWidget {
  final String? initialValue;
  final String hint;
  final ValueChanged<String> onChanged;
  final int minCharacters;

  const SearchTextFilter({
    Key? key,
    this.initialValue,
    this.hint = "Search...",
    required this.onChanged,
    this.minCharacters = 3,
  }) : super(key: key);

  @override
  State<SearchTextFilter> createState() => _SearchTextFilterState();
}

class _SearchTextFilterState extends State<SearchTextFilter> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ThemeHelper.inputDecoration(context),
      child: TextField(
        controller: _controller,
        style: ThemeHelper.subtitleStyle(context),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: ThemeHelper.hintTextColor(context),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: ThemeHelper.iconColor(context),
            size: 22,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: ThemeHelper.iconColor(context),
              size: 20,
            ),
            onPressed: () {
              _controller.clear();
              widget.onChanged('');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
      ),
    );
  }
}

// Route Dropdown Widget
class RouteDropdownFilter extends StatefulWidget {
  final List<String> routes;
  final String? selectedRoute;
  final ValueChanged<String?> onChanged;
  final String label;

  const RouteDropdownFilter({
    Key? key,
    required this.routes,
    this.selectedRoute,
    required this.onChanged,
    this.label = "Select Route",
  }) : super(key: key);

  @override
  State<RouteDropdownFilter> createState() => _RouteDropdownFilterState();
}

class _RouteDropdownFilterState extends State<RouteDropdownFilter> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ThemeHelper.inputDecoration(context),
      child: DropdownButtonFormField<String>(
        value: widget.selectedRoute,
        decoration: InputDecoration(
          hintText: widget.label,
          hintStyle: TextStyle(
            color: ThemeHelper.hintTextColor(context),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.route,
            color: ThemeHelper.iconColor(context),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        dropdownColor: ThemeHelper.dropdownColor(context),
        style: ThemeHelper.subtitleStyle(context),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: ThemeHelper.iconColor(context),
        ),
        isExpanded: true,
        items: widget.routes.map((String route) {
          return DropdownMenuItem<String>(
            value: route,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 48,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  route,
                  style: ThemeHelper.subtitleStyle(context),
                  maxLines: null,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: widget.onChanged,
      ),
    );
  }
}