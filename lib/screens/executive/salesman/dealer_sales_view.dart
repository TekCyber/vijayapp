// lib/screens/salesman/dealer_sales_view.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../models/search_filter_models.dart';
import '../../../services/common_data_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common_dropdowns.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../widgets/glass_container.dart';
import '../menu_navigator.dart';
import '../../../theme/theme_helpers.dart';
import 'data_service.dart';


class DealerSalesView extends StatefulWidget {
  const DealerSalesView({super.key});

  @override
  _DealerSalesViewState createState() => _DealerSalesViewState();
}

class _DealerSalesViewState extends State<DealerSalesView> {
  final DataService _dataService = DataService();
  final CommonDataService _commonDataService = CommonDataService();
  final TextEditingController _searchController = TextEditingController();

  bool _isDealerTab = true;
  bool _isMomSelected = true;
  bool _showAll = false;
  String _selectedPeriod = 'This Month';
  String _dealerSearchText = '';

  List<String> _brands = [];
  List<String> _subGroup2s = [];
  List<String> _routes = [];
  List<Map<String, String>> _dealers = [];

  String? _selectedBrand;
  String? _selectedSubGroup2;
  String? _selectedRoute;
  String? _selectedDealer;

  List<Map<String, dynamic>> _allDisplayData = [];
  List<Map<String, dynamic>> _displayData = [];
  bool _loading = false;
  String _errorMessage = '';
  int selectedMenuIndex = 0;

  final Map<String, bool> _expandedDealers = {};
  final Map<String, bool> _expandedBrands = {};
  final Map<String, String?> _brandIcons = {}; // Store base64 brand icons
  bool _allExpanded = false;

  static const int _defaultDisplayLimit = 5;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _loading = true);

    await Future.wait([
      _loadBrands(),
      _loadRoutes(),
      // No need to load dealers - showing "All Dealers" label in Product tab
    ]);

    if (_isDealerTab && _selectedBrand != null && _selectedBrand != 'All Brands') {
      await _loadSubGroup2s(_selectedBrand!);
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

  Future<void> _loadSubGroup2s(String brand) async {
    if (brand == 'All Brands') {
      setState(() {
        _subGroup2s = ['All Sub Group 2'];
        _selectedSubGroup2 = 'All Sub Group 2';
      });
      return;
    }

    final groups = await _dataService.getSubGroup2ByBrand(brand);
    setState(() {
      _subGroup2s = ['All Sub Group 2', ...groups];
      _selectedSubGroup2 = 'All Sub Group 2';
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

  // Load brand icons for Product tab
  Future<void> _loadBrandIcons(List<String> brandNames) async {
    for (String brandName in brandNames) {
      if (!_brandIcons.containsKey(brandName)) {
        try {
          print('Loading icon for brand: $brandName');
          String? icon = await _commonDataService.getBrandIconByBrandName(brandName);

          if (icon != null && icon.isNotEmpty) {
            // Clean the base64 string by removing newlines and whitespace
            icon = icon.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '');
            print('✅ Icon loaded for $brandName (length: ${icon.length})');
          } else {
            print('⚠️ No icon returned for $brandName');
          }

          setState(() {
            _brandIcons[brandName] = icon;
          });
        } catch (e) {
          print('❌ Error loading icon for $brandName: $e');
          setState(() {
            _brandIcons[brandName] = null;
          });
        }
      }
    }
  }

  Future<void> _loadDisplayData() async {
    setState(() => _loading = true);

    try {
      String period = _selectedPeriod == 'This Month' ? 'THIS_MONTH' : 'LY';
      String comparison = _isMomSelected ? 'MOM' : 'QTR';

      List<Map<String, dynamic>> data;

      if (_isDealerTab) {
        print('DEBUG: Calling getFilteredDealers with brand=${_selectedBrand == 'All Brands' ? 'null' : _selectedBrand}');

        data = await _dataService.getFilteredDealers(
          period: period,
          comparison: comparison,
          brand: _selectedBrand == 'All Brands' ? null : _selectedBrand,
          subgroup2: _selectedSubGroup2 == 'All Sub Group 2' ? null : _selectedSubGroup2,
          route : _selectedRoute == 'All Routes' ? null : _selectedRoute,
        );

        print('DEBUG: Received ${data.length} total records from API');

        // Check G.Shanmugam data
        var shanmugamData = data.where((item) =>
        (item['dealername']?.toString() ?? '').contains('Shanmugam') &&
            (item['dealername']?.toString() ?? '').contains('Ch-1')
        ).toList();

        print('DEBUG _loadDisplayData: G.Shanmugam Traders Ch-1 records from API: ${shanmugamData.length}');
        for (var record in shanmugamData) {
          print('  Brand: ${record['brand']}, Current: ${record['current']}, Previous: ${record['previous']}');
        }

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

        print('DEBUG: Before _updateDisplayData(), _allDisplayData.length = ${_allDisplayData.length}');

        _updateDisplayData();

        print('DEBUG: After _updateDisplayData(), _displayData.length = ${_displayData.length}');

        // Check G.Shanmugam in _displayData
        if (_isDealerTab) {
          var shanmugamDisplay = _displayData.where((item) =>
          (item['dealername']?.toString() ?? '').contains('Shanmugam') &&
              (item['dealername']?.toString() ?? '').contains('Ch-1')
          ).toList();

          print('DEBUG: G.Shanmugam in _displayData: ${shanmugamDisplay.length} records');
          for (var record in shanmugamDisplay) {
            print('  Brand: ${record['brand']}, Current: ${record['current']}, Previous: ${record['previous']}');
          }
        }

        _errorMessage = '';

        _expandedDealers.clear();
        _expandedBrands.clear();

        if (_isDealerTab) {
          for (var item in _displayData) {
            String dealername = item['dealername'] ?? item['Name'] ?? item['name'] ?? 'Unknown';
            _expandedDealers[dealername] = false; // Always keep collapsed
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
          print('📦 Product Tab - Brands found: ${groupedByBrand.keys.toList()}');

          // Load brand icons for Product tab
          _loadBrandIcons(groupedByBrand.keys.toList());
        }
      });
    } catch (e) {
      print('DEBUG: Error loading data: $e');
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _updateDisplayData() {
    // First, filter by search text if in Dealer tab
    List<Map<String, dynamic>> filteredData = _allDisplayData;

    if (_isDealerTab && _dealerSearchText.isNotEmpty) {
      filteredData = _allDisplayData.where((item) {
        String dealerName = (item['dealername'] ?? item['Name'] ?? item['name'] ?? '').toString().toLowerCase();
        return dealerName.contains(_dealerSearchText.toLowerCase());
      }).toList();
    }

    if (_showAll) {
      _displayData = filteredData;
    } else {
      // Group by dealer first, then take top N dealers (keeping all brands per dealer)
      if (_isDealerTab) {
        Map<String, List<Map<String, dynamic>>> groupedByDealer = {};

        for (var item in filteredData) {
          String dealerName = item['dealername'] ?? item['Name'] ?? item['name'] ?? 'Unknown';
          if (!groupedByDealer.containsKey(dealerName)) {
            groupedByDealer[dealerName] = [];
          }
          groupedByDealer[dealerName]!.add(item);
        }

        // Take top N dealers and flatten their records
        _displayData = groupedByDealer.entries
            .take(_defaultDisplayLimit)
            .expand((entry) => entry.value)
            .toList();

        print('DEBUG _updateDisplayData: Grouped into ${groupedByDealer.length} dealers, showing top $_defaultDisplayLimit dealers = ${_displayData.length} total records');
      } else {
        _displayData = filteredData.take(_defaultDisplayLimit).toList();
      }
    }

    _expandedDealers.clear();
    for (var item in _displayData) {
      String dealername = _isDealerTab
          ? (item['dealername'] ?? item['Name'] ?? item['name'] ?? 'Unknown')
          : (item['productName'] ?? item['brand'] ?? item['name'] ?? 'Unknown');

      _expandedDealers[dealername] = false; // Always keep collapsed
    }
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  List<SearchFilterOption> _getSearchFilters() {
    if (_brands.isEmpty && _routes.isEmpty) return [];

    return [
      // Search box row (only for Dealer tab)
      if (_isDealerTab)
        SearchFilterOption(
          key: 'searchRow',
          widget: _buildDealerSearchBox(),
        ),

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
                      await _loadSubGroup2s(value);
                    }

                    await _loadDisplayData();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _isDealerTab
                  ? SubGroup2DropdownFilter(
                subGroup2s: _subGroup2s.isEmpty ? ['All Sub Group 2'] : _subGroup2s,
                selectedSubGroup2: _selectedSubGroup2 ?? 'All Sub Group 2',
                label: "Sub Group 2",
                onChanged: (value) async {
                  if (value != _selectedSubGroup2) {
                    setState(() => _selectedSubGroup2 = value);
                    await _loadDisplayData();
                  }
                },
              )
                  : Container(
                // Simple "All Dealers" label for Product tab (no dropdown, no API call)
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: ThemeHelper.inputDecoration(context),
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: ThemeHelper.iconColor(context),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'All Dealers',
                      style: ThemeHelper.subtitleStyle(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                periods: ['This Month', 'Last Year'],
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

                    //                     // If in Product tab, load filtered dealers by route
                    //                     if (!_isDealerTab) {
                    //                       if (value == 'All Routes') {
                    //                         // Load all dealers
                    //                         await _loadDealers();
                    //                       } else {
                    //                         // Load dealers filtered by the selected route
                    //                         final dealers = await _dataService.getDealersByExecutiveAndRoute(value!);
                    //                         setState(() {
                    //                           _dealers = [
                    //                             {'name': 'All Dealers', 'route': ''},
                    //                             ...dealers
                    //                           ];
                    //                           // Reset to 'All Dealers' when route changes
                    //                           _selectedDealer = 'All Dealers';
                    //                         });
                    //                       }
                    //                     }

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

  Widget _buildDealerSearchBox() {
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
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: 'Search Dealer',
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 12,
          ),
          hintText: 'Type dealer name...',
          hintStyle: TextStyle(
            color: hintColor.withOpacity(0.6),
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: iconColor,
            size: 20,
          ),
          suffixIcon: _dealerSearchText.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: iconColor,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _dealerSearchText = '';
                _updateDisplayData();
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _dealerSearchText = value;
            _updateDisplayData();
          });
        },
      ),
    );
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
                        setState(() {
                          _isDealerTab = false;
                          // Clear dealer search when switching to Product tab
                          _searchController.clear();
                          _dealerSearchText = '';
                        });
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
                  _allExpanded = false; // Keep collapsed

                  for (var key in _expandedBrands.keys) {
                    _expandedBrands[key] = false; // Always keep collapsed
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

      // Debug logging
      if (dealerName.contains('Shanmugam') && dealerName.contains('Ch-1')) {
        print('DEBUG: Dealer=$dealerName');
        print('DEBUG: Number of items received: ${dealerItems.length}');
        for (var item in dealerItems) {
          print('  - Brand: ${item['brand']}, Current: ${item['current']}, Previous: ${item['previous']}');
        }
        var transformed = _transformDataForDealerCard(dealerItems);
        print('DEBUG: After transformation: ${transformed.length} brands');
        for (var item in transformed) {
          print('  - Brand: ${item['brand']}, Current: ${item['current']}, Previous: ${item['previous']}');
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _buildDealerCard(dealerName, _transformDataForDealerCard(dealerItems)),
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

    Map<String, List<Map<String, dynamic>>> groupNames = _groupBygroupNameSorted(brandItems);

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
                          width: 120,  // Fixed width
                          height: 40,  // Fixed height
                          padding: const EdgeInsets.all(2),  // Minimal padding for maximum icon size
                          decoration: BoxDecoration(
                            color: Colors.white,  // White background
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _brandIcons.containsKey(brandName)
                              ? (_brandIcons[brandName] != null && _brandIcons[brandName]!.isNotEmpty
                              ? Image.memory(
                            base64Decode(_brandIcons[brandName]!),
                            width: 116,  // Maximum icon width (120 - 4)
                            height: 36,  // Maximum icon height (40 - 4)
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) {
                              print('❌ Error displaying icon for $brandName: $error');
                              return Center(
                                child: Text(
                                  brandName,
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          )
                              : Center(
                            child: Text(
                              brandName,
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                              : const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                              ),
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
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          '% Change',
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

              ...groupNames.entries.map((groupEntry) {
                String groupName = groupEntry.key;
                List<Map<String, dynamic>> groupItems = groupEntry.value;

                double groupCurrentTotal = groupItems.fold(0.0, (sum, item) => sum + (item['current'] as double? ?? 0.0));
                double groupPreviousTotal = groupItems.fold(0.0, (sum, item) => sum + (item['previous'] as double? ?? 0.0));

                return _buildTableRow(
                  '$groupName',
                  groupCurrentTotal,
                  groupPreviousTotal,
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

  Map<String, List<Map<String, dynamic>>> _groupBygroupName(List<Map<String, dynamic>> brandItems) {
    Map<String, List<Map<String, dynamic>>> groupedBygroup = {};

    for (var item in brandItems) {
      String groupName = item['groupName']?.toString() ?? 'Unknown';
      if (!groupedBygroup.containsKey(groupName)) {
        groupedBygroup[groupName] = [];
      }
      groupedBygroup[groupName]!.add(item);
    }

    return groupedBygroup;
  }

  Map<String, List<Map<String, dynamic>>> _groupBygroupNameSorted(List<Map<String, dynamic>> brandItems) {
    Map<String, List<Map<String, dynamic>>> grouped = _groupBygroupName(brandItems);

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

            /*Container(
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
            const SizedBox(height: 12),*/

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

  List<Map<String, dynamic>> _transformDataForDealerCard(dynamic input) {
    List<Map<String, dynamic>> items;

    // Handle both single item and list of items
    if (input is List<Map<String, dynamic>>) {
      items = input;
    } else if (input is Map<String, dynamic>) {
      items = [input];
    } else {
      return [];
    }

    // If it's a single item with nested brands or products
    if (items.length == 1) {
      var item = items.first;
      if (item['brands'] != null && item['brands'] is List) {
        return List<Map<String, dynamic>>.from(item['brands']);
      }
      if (item['products'] != null && item['products'] is List) {
        return List<Map<String, dynamic>>.from(item['products']);
      }
    }

    // Group by brand and aggregate sales for the same brand
    Map<String, Map<String, dynamic>> brandSales = {};

    for (var item in items) {
      String brandName = item['brand']?.toString() ?? 'Unknown';
      double current = double.tryParse(item['current']?.toString() ?? '0') ?? 0.0;
      double previous = double.tryParse(item['previous']?.toString() ?? '0') ?? 0.0;

      if (brandSales.containsKey(brandName)) {
        // Aggregate if same brand appears multiple times
        brandSales[brandName]!['current'] = (brandSales[brandName]!['current'] as double) + current;
        brandSales[brandName]!['previous'] = (brandSales[brandName]!['previous'] as double) + previous;
      } else {
        brandSales[brandName] = {
          'brand': brandName,
          'current': current,
          'previous': previous,
          'dealername': item['dealername'] ?? item['Name'] ?? item['name'] ?? 'Unknown',
          'route': item['route'] ?? '',
        };
      }
    }

    // Sort brands alphabetically
    var sortedBrands = brandSales.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Convert to list before filtering
    var allBrands = sortedBrands.map((e) => e.value).toList();

    // Filter out brands with zero or very small values in both columns
    // Threshold: Keep if current > 0.01 OR previous > 0.01
    var filteredBrands = allBrands.where((brand) {
      double current = brand['current'] as double;
      double previous = brand['previous'] as double;
      return current.abs() > 0.01 || previous.abs() > 0.01;
    }).toList();

    // Debug logging for specific dealer
    String dealerName = items.isNotEmpty ? (items.first['dealername']?.toString() ?? '') : '';
    if (dealerName.contains('Shanmugam') && dealerName.contains('Ch-1')) {
      print('DEBUG _transformDataForDealerCard:');
      print('  Input items: ${items.length}');
      print('  After grouping: ${brandSales.length} brands');
      for (var brand in allBrands) {
        print('    ${brand['brand']}: current=${brand['current']}, previous=${brand['previous']}');
      }
      print('  After filtering: ${filteredBrands.length} brands');
      for (var brand in filteredBrands) {
        print('    ${brand['brand']}: current=${brand['current']}, previous=${brand['previous']}');
      }
    }

    return filteredBrands;

    // Uncomment the next line if you want to show ALL brands including zeros
    // return allBrands;
  }

  Widget _buildDealerCard(String dealername, List<Map<String, dynamic>> sales) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white70 : Colors.black54;

    double totalMonthly = sales.fold(0.0, (sum, e) => sum + (e['current'] as double));
    double totalYearly = sales.fold(0.0, (sum, e) => sum + (e['previous'] as double));
    bool isExpanded = _expandedDealers[dealername] ?? false;

    // Hide expand/collapse button when a specific brand is selected (not "All Brands")
    bool showExpandButton = true;
    // _selectedBrand == null || _selectedBrand == 'All Brands';

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
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            '% Change',
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
                      e['brand'] ?? e['groupName'] ?? '',
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
          Expanded(
            flex: 2,
            child: Center(
              child: Builder(
                builder: (context) {
                  if (regAmount == 0) {
                    return Text(
                      'N/A',
                      style: TextStyle(
                        color: textColor,
                        fontSize: isMainRow ? 16 : 13,
                        fontWeight: isMainRow ? FontWeight.w700 : FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }
                  double percentage = ((cdAmount - regAmount) / regAmount.abs()) * 100;
                  bool isPositive = percentage >= 0;
                  return Text(
                    '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: isMainRow ? 16 : 13,
                      fontWeight: isMainRow ? FontWeight.w700 : FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /*String _getCurrentMonthName() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (_selectedPeriod == 'This Month' && _isMomSelected) {
      return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'Last Year' && _isMomSelected) {
      return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'This Month' && !_isMomSelected) {
      int quarter = ((now.month - 1) ~/ 3) + 1;
      return 'Q$quarter-${now.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'Last Year' && !_isMomSelected) {
      int quarter = ((now.month - 1) ~/ 3) + 1;
      return 'Q$quarter-${now.year.toString().substring(2)}';
    }

    return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
  }*/

  String _getCurrentMonthName() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (_selectedPeriod == 'This Month' && _isMomSelected) {
      return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'Last Year' && _isMomSelected) {
      return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'This Month' && !_isMomSelected) {
      // Current Financial Year Quarter
      int currentFYQuarter = _getFinancialQuarter(now.month);
      int fyYear = now.month >= 4 ? now.year : now.year - 1;

      return 'Q$currentFYQuarter-${fyYear.toString().substring(2)}';
    } else if (_selectedPeriod == 'Last Year' && !_isMomSelected) {
      // Last Year's same Financial Quarter
      int currentFYQuarter = _getFinancialQuarter(now.month);
      int fyYear = now.month >= 4 ? now.year : now.year - 1;

      return 'Q$currentFYQuarter-${fyYear.toString().substring(2)}';
    }

    return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
  }

  /*String _getUptoLastMonthName() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastYear = DateTime(now.year - 1, now.month);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (_selectedPeriod == 'This Month' && _isMomSelected) {
      return '${months[lastMonth.month - 1]}-${lastMonth.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'Last Year' && _isMomSelected) {
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
    } else if (_selectedPeriod == 'Last Year' && !_isMomSelected) {
      int quarter = ((now.month - 1) ~/ 3) + 1;
      int lastYear = now.year - 1;
      return 'Q$quarter-${lastYear.toString().substring(2)}';
    }

    return 'Upto ${months[lastMonth.month - 1]}-${lastMonth.year.toString().substring(2)}';
  }*/


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
    } else if (_selectedPeriod == 'Last Year' && _isMomSelected) {
      return '${months[lastYear.month - 1]}-${lastYear.year.toString().substring(2)}';
    } else if (_selectedPeriod == 'This Month' && !_isMomSelected) {
      // Financial Year Quarter (April to March)
      int currentFYQuarter = _getFinancialQuarter(now.month);
      int previousFYQuarter = currentFYQuarter - 1;
      int quarterYear = now.year;

      if (previousFYQuarter <= 0) {
        previousFYQuarter = 4;
        quarterYear = now.month >= 4 ? now.year - 1 : now.year - 2;
      } else {
        quarterYear = now.month >= 4 ? now.year : now.year - 1;
      }

      return 'Q$previousFYQuarter-${quarterYear.toString().substring(2)}';
    } else if (_selectedPeriod == 'Last Year' && !_isMomSelected) {
      // Last Year's same Financial Quarter
      int currentFYQuarter = _getFinancialQuarter(now.month);
      int fyYear = now.month >= 4 ? now.year - 1 : now.year - 2;

      return 'Q$currentFYQuarter-${fyYear.toString().substring(2)}';
    }

    return 'Upto ${months[lastMonth.month - 1]}-${lastMonth.year.toString().substring(2)}';
  }

// Helper method to get Financial Year Quarter
  int _getFinancialQuarter(int month) {
    if (month >= 4 && month <= 6) {
      return 1; // Q1: Apr, May, Jun
    } else if (month >= 7 && month <= 9) {
      return 2; // Q2: Jul, Aug, Sep
    } else if (month >= 10 && month <= 12) {
      return 3; // Q3: Oct, Nov, Dec
    } else {
      return 4; // Q4: Jan, Feb, Mar
    }
  }

  Widget SubGroup2DropdownFilter({
    required List<String> subGroup2s,
    String? selectedSubGroup2,
    required ValueChanged<String?> onChanged,
    String label = "Sub Group 2",
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
        value: selectedSubGroup2,
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
          return subGroup2s.map<Widget>((String group) {
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
        items: subGroup2s.map((String group) {
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