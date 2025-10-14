// lib/screens/salesman/dealer_sales_view.dart
import 'package:flutter/material.dart';
import '../../utils/formatters.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/common_dropdowns.dart';
import '../../models/search_filter_models.dart';
import '../dealer/menu_navigator.dart';
import 'data_service.dart';
import '../../services/common_data_service.dart';

class DealerSalesView extends StatefulWidget {
  const DealerSalesView({super.key});

  @override
  _DealerSalesViewState createState() => _DealerSalesViewState();
}

class _DealerSalesViewState extends State<DealerSalesView> {
  final DataService _dataService = DataService();
  final CommonDataService _commonDataService = CommonDataService();

  bool _isDealerTab = true;
  bool _isMomSelected = true;
  bool _showAll = false;
  String _selectedPeriod = 'This Month';

  List<String> _brands = [];
  List<String> _materialGroups = [];
  List<String> _routes = [];
  List<Map<String, String>> _dealers = [];

  String? _selectedBrand;
  String? _selectedMaterialGroup;
  String? _selectedRoute;
  String? _selectedDealer;

  List<Map<String, dynamic>> _allDisplayData = [];
  List<Map<String, dynamic>> _displayData = [];
  bool _loading = false;
  String _errorMessage = '';
  int selectedMenuIndex = 0;

  final Map<String, bool> _expandedDealers = {};
  final Map<String, bool> _expandedBrands = {};
  bool _allExpanded = false;

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
      if (!_isDealerTab) _loadDealers(),
    ]);

    if (_isDealerTab && _selectedBrand != null && _selectedBrand != 'All Brands') {
      await _loadMaterialGroups(_selectedBrand!);
    }

    await _loadDisplayData();
    setState(() => _loading = false);
  }

  Future<void> _loadBrands() async {
    final brands = await _commonDataService.getBrandsByExecutive();
    setState(() {
      _brands = ['All Brands', ...brands];
      _selectedBrand = _brands.isNotEmpty ? _brands.first : null;
    });
  }

  Future<void> _loadMaterialGroups(String brand) async {
    if (brand == 'All Brands') {
      setState(() {
        _materialGroups = ['All Material Groups'];
        _selectedMaterialGroup = 'All Material Groups';
      });
      return;
    }

    final groups = await _dataService.getMaterialGroupsByBrand(brand);
    setState(() {
      _materialGroups = ['All Material Groups', ...groups];
      _selectedMaterialGroup = 'All Material Groups';
    });
  }

  Future<void> _loadRoutes() async {
    final routes = await _dataService.getRoutesByExecutive();
    setState(() {
      _routes = ['All Routes', ...routes];
      _selectedRoute = _routes.isNotEmpty ? _routes.first : null;
    });
  }

  Future<void> _loadDealers() async {
    final dealers = await _dataService.getDealersByExecutive();
    setState(() {
      _dealers = [
        {'name': 'All Dealers', 'route': ''},
        ...dealers
      ];
      _selectedDealer = _dealers.isNotEmpty ? _dealers.first['name'] : null;
    });
  }

  Future<void> _loadDisplayData() async {
    setState(() => _loading = true);

    try {
      String period = _selectedPeriod == 'This Month' ? 'THIS_MONTH' : 'LY';
      String comparison = _isMomSelected ? 'MOM' : 'QTR';

      List<Map<String, dynamic>> data;

      if (_isDealerTab) {
        data = await _dataService.getFilteredDealers(
          period: period,
          comparison: comparison,
          brand: _selectedBrand == 'All Brands' ? null : _selectedBrand,
          materialGroup: _selectedMaterialGroup == 'All Material Groups' ? null : _selectedMaterialGroup,
          route : _selectedRoute == 'All Routes' ? null : _selectedRoute,
        );
      } else {
        data = await _dataService.getFilteredProducts(
          period: period,
          comparison: comparison,
          brand: _selectedBrand == 'All Brands' ? null : _selectedBrand,
          dealer: _selectedDealer == 'All Dealers' ? null : _selectedDealer,
          route : _selectedRoute == 'All Routes' ? null : _selectedRoute,
        );
      }

      setState(() {
        _allDisplayData = data;
        _updateDisplayData();
        _errorMessage = '';

        _expandedDealers.clear();
        _expandedBrands.clear();

        if (_isDealerTab) {
          for (var item in _displayData) {
            String dealername = item['dealername'] ?? item['Name'] ?? item['name'] ?? 'Unknown';
            _expandedDealers[dealername] = _showAll;
          }
        } else {
          Map<String, List<Map<String, dynamic>>> groupedByBrand = {};
          for (var item in _allDisplayData) {
            String brandName = item['brand'] ?? item['productName'] ?? item['name'] ?? 'Unknown';
            groupedByBrand[brandName] = [];
          }
          for (String brand in groupedByBrand.keys) {
            _expandedBrands[brand] = false;
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _updateDisplayData() {
    if (_showAll) {
      _displayData = _allDisplayData;
    } else {
      _displayData = _allDisplayData.take(_defaultDisplayLimit).toList();
    }

    _expandedDealers.clear();
    for (var item in _displayData) {
      String dealername = _isDealerTab
          ? (item['dealername'] ?? item['Name'] ?? item['name'] ?? 'Unknown')
          : (item['productName'] ?? item['brand'] ?? item['name'] ?? 'Unknown');

      // In Dealer tab with Show All AND specific brand selected, keep all cards collapsed
      bool shouldCollapse = _isDealerTab && _showAll &&
          _selectedBrand != null &&
          _selectedBrand != 'All Brands';
      _expandedDealers[dealername] = shouldCollapse ? false : _showAll;
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
        key: 'firstRow',
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

                    if (_isDealerTab && value != null && value != 'All Brands') {
                      await _loadMaterialGroups(value);
                    }

                    await _loadDisplayData();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _isDealerTab
                  ? MaterialGroupDropdownFilter(
                materialGroups: _materialGroups.isEmpty ? ['All Material Groups'] : _materialGroups,
                selectedMaterialGroup: _selectedMaterialGroup ?? 'All Material Groups',
                label: "Material Group",
                onChanged: (value) async {
                  if (value != _selectedMaterialGroup) {
                    setState(() => _selectedMaterialGroup = value);
                    await _loadDisplayData();
                  }
                },
              )
                  : DealerDropdownFilter(
                dealers: _dealers.isEmpty ? ['Loading...'] : _dealers.map((d) => d['name']!).toList(),
                selectedDealer: _selectedDealer ?? (_dealers.isNotEmpty ? _dealers.first['name'] : null),
                label: "Dealer",
                onChanged: (value) async {
                  if (value != _selectedDealer && value != 'Loading...') {
                    setState(() => _selectedDealer = value);

                    // In Product tab, reload data when dealer changes
                    if (!_isDealerTab) {
                      await _loadDisplayData();
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),

      SearchFilterOption(
        key: 'secondRow',
        widget: Row(
          children: [
            Expanded(
              child: PeriodDropdownFilter(
                periods: ['This Month', 'LY'],
                selectedPeriod: _selectedPeriod,
                label: "Period",
                onChanged: (value) async {
                  if (value != _selectedPeriod) {
                    setState(() => _selectedPeriod = value ?? 'This Month');
                    await _loadDisplayData();
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

                    // If in Product tab, load filtered dealers by route
                    if (!_isDealerTab) {
                      if (value == 'All Routes') {
                        // Load all dealers
                        await _loadDealers();
                      } else {
                        // Load dealers filtered by the selected route
                        final dealers = await _dataService.getDealersByExecutiveAndRoute(value!);
                        setState(() {
                          _dealers = [
                            {'name': 'All Dealers', 'route': ''},
                            ...dealers
                          ];
                          // Reset to 'All Dealers' when route changes
                          _selectedDealer = 'All Dealers';
                        });
                      }
                    }

                    // Reload the display data with updated filters
                    await _loadDisplayData();
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
    print('DealerSalesView: Received filters: $filters');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return DashboardLayout(
      title: "Sales Analytics",
      onTabSelected: _onMenuSelected,
      searchFilters: _getSearchFilters(),
      onFilterChanged: _handleFilterChanged,
      body: RefreshIndicator(
        onRefresh: _initializeData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildControlsRow(),
              const SizedBox(height: 16),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage.isNotEmpty)
                Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (_displayData.isEmpty)
                  Center(
                    child: Text(
                      "No ${_isDealerTab ? 'dealers' : 'products'} found",
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                  )
                else
                  _buildDataList(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white70 : Colors.black54;

    return Row(
      children: [
        // Dealer/Product Toggle
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (!_isDealerTab) {
                        setState(() => _isDealerTab = true);
                        await _initializeData();
                      }
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isDealerTab ? Colors.blueAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Dealer',
                          style: TextStyle(
                            color: _isDealerTab ? Colors.white : inactiveColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (_isDealerTab) {
                        setState(() => _isDealerTab = false);
                        await _initializeData();
                      }
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: !_isDealerTab ? Colors.blueAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Product',
                          style: TextStyle(
                            color: !_isDealerTab ? Colors.white : inactiveColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  if (!_isMomSelected) {
                    setState(() => _isMomSelected = true);
                    await _loadDisplayData();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isMomSelected ? Colors.blueAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'MoM',
                    style: TextStyle(
                      color: _isMomSelected ? Colors.white : inactiveColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (_isMomSelected) {
                    setState(() => _isMomSelected = false);
                    await _loadDisplayData();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: !_isMomSelected ? Colors.blueAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'QTR',
                    style: TextStyle(
                      color: !_isMomSelected ? Colors.white : inactiveColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Combined Show All + Expand / Show Less + Collapse Button
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showAll = !_showAll;

                // Update display data (show all or show 5)
                _updateDisplayData();

                // Only expand/collapse cards in Product tab
                if (!_isDealerTab) {
                  _allExpanded = _showAll;

                  for (var key in _expandedBrands.keys) {
                    _expandedBrands[key] = _allExpanded;
                  }
                }
                // In Dealer tab with specific brand selected, cards remain collapsed when Show All is active
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _showAll ? Colors.greenAccent.withOpacity(0.8) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _showAll ? Icons.remove : Icons.add,
                color: _showAll ? Colors.white : inactiveColor,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataList() {
    double overallCurrentTotal = 0.0;
    double overallPreviousTotal = 0.0;

    if (_isDealerTab) {
      for (var item in _allDisplayData) {
        var transformedData = _transformDataForDealerCard(item);
        double itemCurrentTotal = transformedData.fold(0.0, (sum, e) => sum + (e['current'] as double));
        double itemPreviousTotal = transformedData.fold(0.0, (sum, e) => sum + (e['previous'] as double));

        overallCurrentTotal += itemCurrentTotal;
        overallPreviousTotal += itemPreviousTotal;
      }
    } else {
      for (var item in _allDisplayData) {
        overallCurrentTotal += (item['current'] as double? ?? 0.0);
        overallPreviousTotal += (item['previous'] as double? ?? 0.0);
      }
    }

    return Column(
      children: [
        _buildOverallTotalCard(overallCurrentTotal, overallPreviousTotal),
        const SizedBox(height: 20),

        if (_isDealerTab)
          ..._buildDealerTabContent()
        else
          ..._buildProductTabContent(),
      ],
    );
  }

  List<Widget> _buildDealerTabContent() {
    Map<String, List<Map<String, dynamic>>> groupedByDealer = {};

    for (var item in _displayData) {
      String dealerName = item['dealername'] ?? item['Name'] ?? item['name'] ?? 'Unknown';
      if (!groupedByDealer.containsKey(dealerName)) {
        groupedByDealer[dealerName] = [];
      }
      groupedByDealer[dealerName]!.add(item);
    }

    return groupedByDealer.entries.map((entry) {
      String dealerName = entry.key;
      List<Map<String, dynamic>> dealerItems = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _buildDealerCard(dealerName, _transformDataForDealerCard(dealerItems.first)),
      );
    }).toList();
  }

  List<Widget> _buildProductTabContent() {
    Map<String, List<Map<String, dynamic>>> groupedByBrand = {};

    for (var item in _allDisplayData) {
      String brandName = item['brand'] ?? item['productName'] ?? item['name'] ?? 'Unknown';
      if (!groupedByBrand.containsKey(brandName)) {
        groupedByBrand[brandName] = [];
      }
      groupedByBrand[brandName]!.add(item);
    }

    var brandList = groupedByBrand.entries.toList();
    brandList.sort((a, b) {
      double totalSalesA = a.value.fold(0.0, (sum, item) =>
      sum + (item['current'] as double? ?? 0.0) + (item['previous'] as double? ?? 0.0));
      double totalSalesB = b.value.fold(0.0, (sum, item) =>
      sum + (item['current'] as double? ?? 0.0) + (item['previous'] as double? ?? 0.0));
      return totalSalesB.compareTo(totalSalesA);
    });

    return brandList.map((entry) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _buildProductBrandCard(entry.key, entry.value),
    )).toList();
  }

  Widget _buildProductBrandCard(String brandName, List<Map<String, dynamic>> brandItems) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white70 : Colors.black54;

    double brandCurrentTotal = brandItems.fold(0.0, (sum, item) => sum + (item['current'] as double? ?? 0.0));
    double brandPreviousTotal = brandItems.fold(0.0, (sum, item) => sum + (item['previous'] as double? ?? 0.0));

    Map<String, List<Map<String, dynamic>>> materialGroups = _groupByMaterialGroupSorted(brandItems);

    bool isExpanded = _expandedBrands[brandName] ?? false;

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
                            style: const TextStyle(
                              color: Colors.blueAccent,
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
                                  '${_getCurrentMonthName()}: ${Formatters.formatCurrency(brandCurrentTotal.abs())}',
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
                                  '${_getUptoLastMonthName()}: ${Formatters.formatCurrency(brandPreviousTotal.abs())}',
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
                      color: Colors.blueAccent,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

            if (isExpanded) ...[
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: Text("")),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          _getCurrentMonthName(),
                          style: TextStyle(
                            color: subtleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          _getUptoLastMonthName(),
                          style: TextStyle(
                            color: subtleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: isDark ? Colors.white24 : Colors.black26, thickness: 1, height: 16),

              ...materialGroups.entries.map((materialEntry) {
                String materialGroup = materialEntry.key;
                List<Map<String, dynamic>> materialItems = materialEntry.value;

                double materialCurrentTotal = materialItems.fold(0.0, (sum, item) => sum + (item['current'] as double? ?? 0.0));
                double materialPreviousTotal = materialItems.fold(0.0, (sum, item) => sum + (item['previous'] as double? ?? 0.0));

                return _buildTableRow(
                  '$materialGroup',
                  materialCurrentTotal,
                  materialPreviousTotal,
                  Colors.blueAccent,
                );
              }).toList(),

              const SizedBox(height: 12),
              Divider(color: isDark ? Colors.white24 : Colors.black26, thickness: 1, height: 16),

              _buildTableRow("Total Sales", brandCurrentTotal, brandPreviousTotal, null, true),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByMaterialGroup(List<Map<String, dynamic>> brandItems) {
    Map<String, List<Map<String, dynamic>>> groupedByMaterial = {};

    for (var item in brandItems) {
      String materialGroup = item['materialGroup']?.toString() ?? 'Unknown';
      if (!groupedByMaterial.containsKey(materialGroup)) {
        groupedByMaterial[materialGroup] = [];
      }
      groupedByMaterial[materialGroup]!.add(item);
    }

    return groupedByMaterial;
  }

  Map<String, List<Map<String, dynamic>>> _groupByMaterialGroupSorted(List<Map<String, dynamic>> brandItems) {
    Map<String, List<Map<String, dynamic>>> grouped = _groupByMaterialGroup(brandItems);

    var sortedList = grouped.entries.toList();
    sortedList.sort((a, b) {
      double totalSalesA = a.value.fold(0.0, (sum, item) =>
      sum + (item['current'] as double? ?? 0.0) + (item['previous'] as double? ?? 0.0));
      double totalSalesB = b.value.fold(0.0, (sum, item) =>
      sum + (item['current'] as double? ?? 0.0) + (item['previous'] as double? ?? 0.0));
      return totalSalesB.compareTo(totalSalesA);
    });

    return Map.fromEntries(sortedList);
  }

  Widget _buildOverallTotalCard(double currentTotal, double previousTotal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white70 : Colors.black54;

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment,
                  color: Colors.orangeAccent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Overall Total',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Grand Total for all ${_allDisplayData.length} ${_isDealerTab ? 'dealers' : 'products'} (${!_showAll && _allDisplayData.length > _defaultDisplayLimit ? 'showing ${_displayData.length}' : 'all displayed'})',
                      style: TextStyle(
                        color: subtleColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: Text("")),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        _getCurrentMonthName(),
                        style: TextStyle(
                          color: subtleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        _getUptoLastMonthName(),
                        style: TextStyle(
                          color: subtleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: isDark ? Colors.white24 : Colors.black26, thickness: 1, height: 16),

            _buildOverallTotalRow("Grand Total", currentTotal, previousTotal),

            const SizedBox(height: 8),
            _buildGrowthIndicator(currentTotal, previousTotal),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallTotalRow(String label, double currentAmount, double previousAmount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                Formatters.formatCurrency(currentAmount.abs()),
                style: TextStyle(
                  color: currentAmount < 0 ? Colors.red : textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                Formatters.formatCurrency(previousAmount.abs()),
                style: TextStyle(
                  color: previousAmount < 0 ? Colors.red : textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
            '${isPositive ? '+' : ''}${Formatters.formatCurrency(growthAmount.abs())} (${growthPercentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'vs ${_isMomSelected ? 'Previous Month' : 'Previous Quarter'}',
            style: TextStyle(
              color: subtleColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _transformDataForDealerCard(Map<String, dynamic> item) {
    if (item['brands'] != null && item['brands'] is List) {
      return List<Map<String, dynamic>>.from(item['brands']);
    }
    if (item['products'] != null && item['products'] is List) {
      return List<Map<String, dynamic>>.from(item['products']);
    }

    return [
      {
        'dealername': _isDealerTab
            ? (item['dealername'] ?? item['Name'] ?? item['name'] ?? 'Unknown')
            : (item['productName'] ?? item['brand'] ?? item['name'] ?? 'Unknown'),
        'brand': item['brand'] ?? 'Unknown',
        'current': double.tryParse(item['current']?.toString() ?? '0') ?? 0.0,
        'previous': double.tryParse(item['previous']?.toString() ?? '0') ?? 0.0,
        'route': item['route'] ?? '',
      }
    ];
  }

  Widget _buildDealerCard(String dealername, List<Map<String, dynamic>> sales) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white70 : Colors.black54;

    double totalMonthly = sales.fold(0.0, (sum, e) => sum + (e['current'] as double));
    double totalYearly = sales.fold(0.0, (sum, e) => sum + (e['previous'] as double));
    bool isExpanded = _expandedDealers[dealername] ?? false;

    // Hide expand/collapse button when a specific brand is selected (not "All Brands")
    bool showExpandButton = _selectedBrand == null || _selectedBrand == 'All Brands';

    // Disable expansion when Show All is active in Dealer tab AND a specific brand is selected
    bool canExpand = !(_isDealerTab && _showAll &&
        _selectedBrand != null &&
        _selectedBrand != 'All Brands');

    return GestureDetector(
      onTap: () {
        print('Navigate to: $dealername');
      },
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: (canExpand && showExpandButton) ? () {
                  setState(() {
                    _expandedDealers[dealername] = !isExpanded;
                  });
                } : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              dealername.length > 30 ? '${dealername.substring(0, 30)}...' : dealername,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          if (!isExpanded || !showExpandButton) ...[
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
                                    '${_getCurrentMonthName()}: ${Formatters.formatCurrency(totalMonthly.abs())}',
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
                                    '${_getUptoLastMonthName()}: ${Formatters.formatCurrency(totalYearly.abs())}',
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
                    if (showExpandButton)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpanded ? Icons.remove : Icons.add,
                          color: Colors.greenAccent,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),

              if (isExpanded && canExpand && showExpandButton) ...[
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Expanded(flex: 3, child: Text("")),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            _getCurrentMonthName(),
                            style: TextStyle(
                              color: subtleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            _getUptoLastMonthName(),
                            style: TextStyle(
                              color: subtleColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: isDark ? Colors.white24 : Colors.black26, thickness: 1, height: 16),

                Column(
                  children: sales.map((e) {
                    return _buildTableRow(
                      e['brand'] ?? e['materialGroup'] ?? '',
                      e['current'] as double,
                      e['previous'] as double,
                      Colors.greenAccent,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),
                Divider(color: isDark ? Colors.white24 : Colors.black26, thickness: 1, height: 16),

                _buildTableRow("Total Sales", totalMonthly, totalYearly, null, true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, double cdAmount, double regAmount,
      [Color? indicatorColor, bool isMainRow = false]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isMainRow
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white70 : Colors.black87);

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
                    style: TextStyle(
                      color: textColor,
                      fontSize: isMainRow ? 16 : 14,
                      fontWeight: isMainRow ? FontWeight.w600 : FontWeight.w500,
                    ),
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
                      ? Colors.red
                      : textColor,
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
                      ? Colors.red
                      : textColor,
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

  String _getCurrentMonthName() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (_selectedPeriod == 'This Month' && _isMomSelected) {
      return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'LY' && _isMomSelected) {
      return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'This Month' && !_isMomSelected) {
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

    if (_selectedPeriod == 'This Month' && _isMomSelected) {
      return '${months[lastMonth.month - 1]}-${lastMonth.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'LY' && _isMomSelected) {
      return '${months[lastYear.month - 1]}-${lastYear.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'This Month' && !_isMomSelected) {
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

  Widget MaterialGroupDropdownFilter({
    required List<String> materialGroups,
    String? selectedMaterialGroup,
    required ValueChanged<String?> onChanged,
    String label = "Material Group",
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white.withOpacity(0.8) : Colors.black54;
    final iconColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return Container(
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
      ),
      child: DropdownButtonFormField<String>(
        value: selectedMaterialGroup,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.category,
            color: iconColor,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: iconColor,
        ),
        selectedItemBuilder: (BuildContext context) {
          return materialGroups.map<Widget>((String group) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Text(
                group,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            );
          }).toList();
        },
        items: materialGroups.map((String group) {
          return DropdownMenuItem<String>(
            value: group,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 48,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  group,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget DealerDropdownFilter({
    required List<String> dealers,
    String? selectedDealer,
    required ValueChanged<String?> onChanged,
    String label = "Dealer",
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white.withOpacity(0.8) : Colors.black54;
    final iconColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return Container(
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
      ),
      child: DropdownButtonFormField<String>(
        value: selectedDealer,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.store,
            color: iconColor,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: iconColor,
        ),
        selectedItemBuilder: (BuildContext context) {
          return dealers.map<Widget>((String dealer) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Text(
                dealer,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            );
          }).toList();
        },
        items: dealers.map((String dealer) {
          return DropdownMenuItem<String>(
            value: dealer,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 48,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  dealer,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}