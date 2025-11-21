// lib/screens/salesman/dealer_count_screen.dart
import 'package:flutter/material.dart';

import '../../../models/search_filter_models.dart';
import '../../../services/common_data_service.dart';
import '../../../widgets/common_dropdowns.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../widgets/glass_container.dart';

import '../menu_navigator.dart';
import 'data_service.dart';


class DealerCountScreen extends StatefulWidget {
  const DealerCountScreen({super.key});

  @override
  _DealerCountScreenState createState() => _DealerCountScreenState();
}

class _DealerCountScreenState extends State<DealerCountScreen> {
  final DataService _dataService = DataService();
  final CommonDataService _commonDataService = CommonDataService();

  List<String> _brands = [];
  List<String> _routes = [];
  String? _selectedBrand;
  String? _selectedRoute;
  String _selectedPeriod = 'THIS_MONTH';
  bool _isMomSelected = true;

  List<Map<String, dynamic>> _allDealerCountData = [];
  List<Map<String, dynamic>> _allTotalDealerCountData = [];
  List<Map<String, dynamic>> _dealerCountData = [];
  List<Map<String, dynamic>> _dealerCountDataByBrand = []; // ADDED: New variable for brand totals
  bool _loading = false;
  String _errorMessage = '';
  int selectedMenuIndex = 0;

  final Map<String, bool> _expandedBrands = {};
  bool _showAll = false;

  static const int _defaultDisplayLimit = 5;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _loading = true);

    await Future.wait([
      _loadBrands(),
      _loadRoutes(),
    ]);

    await _loadDealerCount();
    setState(() => _loading = false);
  }

  Future<void> _loadBrands() async {
    final brands = await _commonDataService.getBrandsByExecutive();
    setState(() {
      _brands = ['All Brands', ...brands];
      _selectedBrand = _brands.isNotEmpty ? _brands.first : null;
    });
  }

  Future<void> _loadRoutes() async {
    final routes = await _dataService.getRoutesByExecutive();
    setState(() {
      _routes = ['All Routes', ...routes];
      _selectedRoute = _routes.isNotEmpty ? _routes.first : null;
    });
  }

  Future<void> _loadDealerCount() async {
    setState(() => _loading = true);

    try {
      // UPDATED: Added getDealerCountByBrand API call as result[2]
      final results = await Future.wait([
        _dataService.getDealerCount(
          period: _selectedPeriod,
          brand: _selectedBrand == 'All Brands' ? null : _selectedBrand,
          route: _selectedRoute == 'All Routes' ? null : _selectedRoute,
        ),
        _dataService.getTotalDealerCount(
          period: _selectedPeriod,
          brand: _selectedBrand == 'All Brands' ? null : _selectedBrand,
          route: _selectedRoute == 'All Routes' ? null : _selectedRoute,
        ),
        _dataService.getDealerCountByBrand(
          period: _selectedPeriod,
          brand: _selectedBrand == 'All Brands' ? null : _selectedBrand,
          route: _selectedRoute == 'All Routes' ? null : _selectedRoute,
        ),
      ]);

      setState(() {
        _allDealerCountData = results[0];
        _allTotalDealerCountData = results[1];
        _dealerCountDataByBrand = results[2]; // ADDED: Store brand totals from result[2]
        _updateDisplayData();
        _errorMessage = '';
        _initializeExpandedBrands();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading dealer count: ${e.toString()}';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _initializeExpandedBrands() {
    _expandedBrands.clear();
    final brands = _allDealerCountData
        .map((item) => item['brand']?.toString() ?? 'Unknown')
        .toSet();

    for (String brand in brands) {
      _expandedBrands[brand] = false;
    }
  }

  void _updateDisplayData() {
    Map<String, List<Map<String, dynamic>>> groupedByBrand = {};
    for (var item in _allDealerCountData) {
      String brand = item['brand']?.toString() ?? 'Unknown';
      if (!groupedByBrand.containsKey(brand)) {
        groupedByBrand[brand] = [];
      }
      groupedByBrand[brand]!.add(item);
    }

    var brandList = groupedByBrand.entries.toList();
    brandList.sort((a, b) {
      int totalA = a.value.fold(0, (sum, item) =>
      sum + (item['current'] as int? ?? 0) + (item['previous'] as int? ?? 0));
      int totalB = b.value.fold(0, (sum, item) =>
      sum + (item['current'] as int? ?? 0) + (item['previous'] as int? ?? 0));
      return totalB.compareTo(totalA);
    });

    List<String> brandsToShow;
    if (_showAll) {
      brandsToShow = brandList.map((e) => e.key).toList();
    } else {
      brandsToShow = brandList.take(_defaultDisplayLimit).map((e) => e.key).toList();
    }

    _dealerCountData = _allDealerCountData.where((item) {
      String brand = item['brand']?.toString() ?? 'Unknown';
      return brandsToShow.contains(brand);
    }).toList();

    _expandedBrands.clear();
    for (String brand in brandsToShow) {
      _expandedBrands[brand] = _showAll;
    }
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  List<SearchFilterOption> _getSearchFilters() {
    if (_brands.isEmpty && _routes.isEmpty) return [];

    return [
      SearchFilterOption(
        key: 'filterRow',
        widget: Row(
          children: [
            Expanded(
              child: BrandDropdownFilter(
                brands: _brands.isEmpty ? ['Loading...'] : _brands,
                selectedBrand: _selectedBrand ?? (_brands.isNotEmpty ? _brands.first : null),
                label: "Brand",
                onChanged: (value) async {
                  if (value != _selectedBrand && value != 'Loading...') {
                    setState(() => _selectedBrand = value);
                    await _loadDealerCount();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RouteDropdownFilter(
                routes: _routes.isEmpty ? ['Loading...'] : _routes,
                selectedRoute: _selectedRoute ?? (_routes.isNotEmpty ? _routes.first : null),
                label: "Route",
                onChanged: (value) async {
                  if (value != _selectedRoute && value != 'Loading...') {
                    setState(() => _selectedRoute = value);
                    await _loadDealerCount();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PeriodDropdownFilter(
                periods: ['LY', 'THIS_MONTH'],
                selectedPeriod: _selectedPeriod,
                label: "Period",
                onChanged: (value) async {
                  if (value != _selectedPeriod) {
                    setState(() => _selectedPeriod = value ?? 'LY');
                    await _loadDealerCount();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ];
  }

  void _handleFilterChanged(Map<String, dynamic> filters) {
    print('DealerCountScreen: Received filters: $filters');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return DashboardLayout(
      title: "Dealer Count Analytics",
      onTabSelected: _onMenuSelected,
      searchFilters: _getSearchFilters(),
      onFilterChanged: _handleFilterChanged,
      body: RefreshIndicator(
        onRefresh: _initializeData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade300,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: TextStyle(color: textColor, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildDealerCountView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDealerCountView() {
    if (_dealerCountData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    Map<String, List<Map<String, dynamic>>> groupedByBrand = {};
    for (var item in _dealerCountData) {
      String brand = item['brand']?.toString() ?? 'Unknown';
      if (!groupedByBrand.containsKey(brand)) {
        groupedByBrand[brand] = [];
      }
      groupedByBrand[brand]!.add(item);
    }

    var brandList = groupedByBrand.entries.toList();

    brandList.sort((a, b) {
      int totalA = a.value.fold(0, (sum, item) =>
      sum + (item['current'] as int? ?? 0) + (item['previous'] as int? ?? 0));
      int totalB = b.value.fold(0, (sum, item) =>
      sum + (item['current'] as int? ?? 0) + (item['previous'] as int? ?? 0));
      return totalB.compareTo(totalA);
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    bool hasMoreBrands = _allDealerCountData
        .map((item) => item['brand']?.toString() ?? 'Unknown')
        .toSet()
        .length > _defaultDisplayLimit;

    return Column(
      children: [
        _buildOverallTotalCard(),
        const SizedBox(height: 20),
        ...brandList.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildBrandCountCard(entry.key, entry.value),
        )).toList(),
        if (hasMoreBrands && !_showAll)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showAll = true;
                  _updateDisplayData();
                });
              },
              icon: const Icon(Icons.expand_more),
              label: const Text('Show All Brands'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        if (_showAll)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showAll = false;
                  _updateDisplayData();
                });
              },
              icon: const Icon(Icons.expand_less),
              label: const Text('Show Less'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverallTotalCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white70 : Colors.black54;

    int overallCurrentTotal = _allTotalDealerCountData.isNotEmpty ? _allTotalDealerCountData[0]['current'] : 0;
    int overallPreviousTotal = _allTotalDealerCountData.isNotEmpty ? _allTotalDealerCountData[0]['previous'] : 0;

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.group,
                    color: Colors.orangeAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Overall Dealer Count',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data Table
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCurrentMonthName(),
                        style: TextStyle(
                          color: subtleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overallCurrentTotal.toString(),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getUptoLastMonthName(),
                        style: TextStyle(
                          color: subtleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overallPreviousTotal.toString(),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Growth Indicator
            _buildGrowthIndicator(overallCurrentTotal.toDouble(), overallPreviousTotal.toDouble()),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandCountCard(String brandName, List<Map<String, dynamic>> brandData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white70 : Colors.black54;

    bool isExpanded = _expandedBrands[brandName] ?? false;

    // UPDATED: Use same totals for both collapsed and expanded states
    int brandCurrentTotal = 0;
    int brandPreviousTotal = 0;

    // Get brand total from _dealerCountDataByBrand (result[2]) for consistency
    try {
      final brandTotal = _dealerCountDataByBrand.firstWhere(
            (item) => item['brand']?.toString() == brandName,
        orElse: () => {},
      );

      if (brandTotal.isNotEmpty) {
        brandCurrentTotal = brandTotal['current'] as int? ?? 0;
        brandPreviousTotal = brandTotal['previous'] as int? ?? 0;
      }
    } catch (e) {
      print('Error getting brand total for $brandName: $e');
      // Fallback to calculating from brandData if there's an error
      brandCurrentTotal = brandData.fold(0, (sum, item) => sum + (item['current'] as int? ?? 0));
      brandPreviousTotal = brandData.fold(0, (sum, item) => sum + (item['previous'] as int? ?? 0));
    }

    brandData.sort((a, b) {
      int totalA = (a['current'] as int? ?? 0) + (a['previous'] as int? ?? 0);
      int totalB = (b['current'] as int? ?? 0) + (b['previous'] as int? ?? 0);
      return totalB.compareTo(totalA);
    });

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                setState(() {
                  _expandedBrands[brandName] = !isExpanded;
                });
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            brandName,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.blueAccent
                                  : Colors.blue.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        if (!isExpanded) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Total',
                            style: TextStyle(
                              color: subtleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_getCurrentMonthName()}: $brandCurrentTotal',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${_getUptoLastMonthName()}: $brandPreviousTotal',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      color: isDark
                          ? Colors.blueAccent
                          : Colors.blue.shade700,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

            // EXPANDED CONTENT STARTS HERE
            if (isExpanded) ...[
              const SizedBox(height: 16),

              // Header Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: Text("")),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          _getCurrentMonthName(),
                          style: TextStyle(
                            color: subtleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          _getUptoLastMonthName(),
                          style: TextStyle(
                            color: subtleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: isDark ? Colors.white24 : Colors.black26, thickness: 1, height: 16),

              // Material Group Rows
              ...brandData.map((item) {
                String materialGroup = item['materialGroup']?.toString() ?? 'Unknown';
                int current = item['current'] as int? ?? 0;
                int previous = item['previous'] as int? ?? 0;

                // Skip empty material groups or show them as "Other"
                if (materialGroup.isEmpty) {
                  materialGroup = 'Other';
                }

                return _buildMaterialGroupRow(materialGroup, current, previous);
              }).toList(),

              const SizedBox(height: 12),

              // Brand Total Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            "Brand Total",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          brandCurrentTotal.toString(),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          brandPreviousTotal.toString(),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Growth Indicator
              _buildGrowthIndicator(brandCurrentTotal.toDouble(), brandPreviousTotal.toDouble()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialGroupRow(String materialGroup, int current, int previous) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final textColorBold = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    materialGroup,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                current.toString(),
                style: TextStyle(
                  color: textColorBold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                previous.toString(),
                style: TextStyle(
                  color: textColorBold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthIndicator(double current, double previous) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? Colors.white60 : Colors.black54;

    if (previous == 0) return const SizedBox.shrink();

    double growthAmount = current - previous;
    double growthPercentage = (growthAmount / previous.abs()) * 100;
    bool isPositive = growthAmount >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPositive
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '${isPositive ? '+' : ''}${growthAmount.toInt()} dealers (${growthPercentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            (_selectedPeriod == 'THIS_MONTH') ? 'vs Previous Month' : 'vs LY Same Month',
            style: TextStyle(
              color: subtleColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentMonthName() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (_selectedPeriod == 'THIS_MONTH' && _isMomSelected) {
      return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'LY' && _isMomSelected) {
      return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'THIS_MONTH' && !_isMomSelected) {
      int quarter = ((now.month - 1) ~/ 3) + 1;
      return 'Q$quarter-${now.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'LY' && !_isMomSelected) {
      int quarter = ((now.month - 1) ~/ 3) + 1;
      return 'Q$quarter-${now.year.toString().substring(2)}';
    }

    return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
  }

  String _getUptoLastMonthName() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastYear = DateTime(now.year - 1, now.month);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (_selectedPeriod == 'THIS_MONTH' && _isMomSelected) {
      return '${months[lastMonth.month - 1]}-${lastMonth.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'LY' && _isMomSelected) {
      return '${months[lastYear.month - 1]}-${lastYear.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'THIS_MONTH' && !_isMomSelected) {
      int currentQuarter = ((now.month - 1) ~/ 3) + 1;
      int previousQuarter = currentQuarter - 1;
      int quarterYear = now.year;

      if (previousQuarter <= 0) {
        previousQuarter = 4;
        quarterYear = now.year - 1;
      }

      return 'Q$previousQuarter-${quarterYear.toString().substring(2)}';
    } else if (_selectedPeriod == 'LY' && !_isMomSelected) {
      int quarter = ((now.month - 1) ~/ 3) + 1;
      int lastYear = now.year - 1;
      return 'Q$quarter-${lastYear.toString().substring(2)}';
    }

    return 'Upto ${months[lastMonth.month - 1]}-${lastMonth.year.toString().substring(2)}';
  }
}