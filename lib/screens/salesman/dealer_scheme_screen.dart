// lib/screens/salesman/dealer_scheme_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/common_dropdowns.dart';
import '../../models/search_filter_models.dart';
import '../../utils/formatters.dart';

import '../../screens/salesman/data_service.dart';
import '../dealer/menu_navigator.dart';

class DealerSchemeScreen extends StatefulWidget {
  final String title; // Dealer name

  DealerSchemeScreen({required this.title});

  @override
  _DealerSchemeScreenState createState() => _DealerSchemeScreenState();
}

class _DealerSchemeScreenState extends State<DealerSchemeScreen> {
  List<Map<String, dynamic>> _schemeData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _selectedRoute;
  String? _selectedSchemeName;
  int selectedMenuIndex = 0;
  Set<String> _expandedSchemeTypes = {}; // Track expanded scheme type cards

  List<String> _routes = [];
  List<String> _schemeNames = ['All Schemes'];
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _selectedSchemeName = _schemeNames.first;
    _fetchRouteList();
    _fetchAllSchemeNames(); // Fetch all scheme names first
    _fetchSchemeData();
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  List<SearchFilterOption> _getSearchFilters() {
    return [
      SearchFilterOption(
        key: 'routeFilter',
        widget: BrandDropdownFilter(
          brands: _routes,
          selectedBrand: _selectedRoute,
          label: "Filter by Route",
          onChanged: _onRouteChanged,
        ),
      ),
      SearchFilterOption(
        key: 'schemeNameFilter',
        widget: BrandDropdownFilter(
          brands: _schemeNames,
          selectedBrand: _selectedSchemeName,
          label: "Filter by Scheme",
          onChanged: _onSchemeNameChanged,
        ),
      ),
    ];
  }

  void _handleFilterChanged(Map<String, dynamic> filters) {
    print('DealerSchemeScreen: Received filters: $filters');
    _fetchSchemeData();
  }

  void _onRouteChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedRoute = newValue;
        _expandedSchemeTypes.clear();
      });
      _fetchAllSchemeNames(); // Refresh scheme names based on route
      _fetchSchemeData();
    }
  }

  void _onSchemeNameChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedSchemeName = newValue;
        _expandedSchemeTypes.clear();
      });
      _fetchSchemeData(); // Only fetch data, don't refresh scheme names
    }
  }

  Future<void> _fetchRouteList() async {
    try {
      List<String> routeList = await _dataService.getRoutesByExecutive();

      setState(() {
        _routes = ['All Routes', ...routeList];
        _selectedRoute = _routes.isNotEmpty ? _routes.first : null;
      });
    } catch (e) {
      print('Error fetching route list: $e');
    }
  }

  Future<void> _fetchAllSchemeNames() async {
    try {
      // Determine route parameter - use selected route or all routes
      String routeParam = (_selectedRoute == null || _selectedRoute == 'All Routes')
          ? '%'
          : _selectedRoute!;

      // Fetch all schemes for the current route to get scheme name list
      List<Map<String, dynamic>> allSchemes = await _dataService.getSchemesByExecutiveAndRoute(
        route: routeParam,
        schemeName: '%', // Get all scheme names
      );

      // Extract unique scheme names
      Set<String> uniqueSchemes = allSchemes
          .map((e) => e['scheme_name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();

      setState(() {
        _schemeNames = ['All Schemes', ...uniqueSchemes.toList()..sort()];
        // Reset to "All Schemes" if current selection is not in the new list
        if (_selectedSchemeName != null &&
            _selectedSchemeName != 'All Schemes' &&
            !_schemeNames.contains(_selectedSchemeName)) {
          _selectedSchemeName = 'All Schemes';
        }
      });
    } catch (e) {
      print('Error fetching scheme names: $e');
    }
  }

  Future<void> _fetchSchemeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      String routeParam = (_selectedRoute == null || _selectedRoute == 'All Routes')
          ? '%'
          : _selectedRoute!;

      String schemeNameParam = (_selectedSchemeName == null || _selectedSchemeName == 'All Schemes')
          ? '%'
          : _selectedSchemeName!;

      List<Map<String, dynamic>> fetchedData = await _dataService.getSchemesByExecutiveAndRoute(
        route: routeParam,
        schemeName: schemeNameParam,
      );

      setState(() {
        _schemeData = fetchedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading scheme data: ${e.toString()}';
      });
      print('Error fetching scheme data: $e');
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupBySchemeType() {
    Map<String, List<Map<String, dynamic>>> grouped = {
      'VALUE': [],
      'BASKET': [],
      'QUANTITY': [],
      'POINTS': [],
    };

    for (var scheme in _schemeData) {
      String schemeType = (scheme['scheme_type'] ?? '').toString().toUpperCase();
      if (grouped.containsKey(schemeType)) {
        grouped[schemeType]!.add(scheme);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Schemes',
      subtitle: widget.title,
      onTabSelected: _onMenuSelected,
      showBackButton: true,
      searchFilters: _getSearchFilters(),
      onFilterChanged: _handleFilterChanged,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 16),
              Expanded(
                child: _buildSchemeContent(),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSummaryBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2),
            SizedBox(height: 16),
            Text(
              'Loading schemes...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSchemeData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_schemeData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, color: Colors.white60, size: 48),
            SizedBox(height: 16),
            Text(
              'No scheme data available',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> groupedSchemes = _groupBySchemeType();

    return RefreshIndicator(
      onRefresh: _fetchSchemeData,
      child: ListView(
        padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 140), // Increased bottom padding
        children: [
          if (groupedSchemes['VALUE']!.isNotEmpty)
            _buildSchemeTypeCard('VALUE', groupedSchemes['VALUE']!, Colors.green),
          if (groupedSchemes['BASKET']!.isNotEmpty)
            _buildSchemeTypeCard('BASKET', groupedSchemes['BASKET']!, Colors.orange),
          if (groupedSchemes['QUANTITY']!.isNotEmpty)
            _buildSchemeTypeCard('QUANTITY', groupedSchemes['QUANTITY']!, Colors.purple),
          if (groupedSchemes['POINTS']!.isNotEmpty)
            _buildSchemeTypeCard('POINTS', groupedSchemes['POINTS']!, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSchemeTypeCard(String schemeType, List<Map<String, dynamic>> schemes, Color color) {
    bool isExpanded = _expandedSchemeTypes.contains(schemeType);
    int schemeCount = schemes.length;

    // Calculate total amount for this scheme type
    double totalAmount = 0.0;
    for (var scheme in schemes) {
      var amount = scheme['total_value'];
      if (amount != null) {
        if (amount is num) {
          totalAmount += amount.toDouble();
        } else if (amount is String) {
          totalAmount += double.tryParse(amount) ?? 0.0;
        }
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSchemeTypes.remove(schemeType);
                } else {
                  _expandedSchemeTypes.add(schemeType);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getSchemeTypeIcon(schemeType),
                      color: color,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$schemeType SCHEME',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$schemeCount Dealers',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 12,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            SizedBox(width: 12),
                            Text(
                              _formatAmount(totalAmount),
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: color.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      color: color,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(color: color.withOpacity(0.2), height: 1, thickness: 1),
            _buildSchemeTable(schemeType, schemes, color),
          ],
        ],
      ),
    );
  }

  IconData _getSchemeTypeIcon(String schemeType) {
    switch (schemeType) {
      case 'VALUE':
        return Icons.account_balance_wallet;
      case 'BASKET':
        return Icons.shopping_basket;
      case 'QUANTITY':
        return Icons.inventory_2;
      case 'POINTS':
        return Icons.stars;
      default:
        return Icons.receipt;
    }
  }

  Widget _buildSchemeTable(String schemeType, List<Map<String, dynamic>> schemes, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Dealer Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Current',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...schemes.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> scheme = entry.value;
            bool isLastRow = index == schemes.length - 1;

            return Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: index % 2 == 0
                    ? Colors.white.withOpacity(0.03)
                    : Colors.transparent,
                borderRadius: isLastRow
                    ? BorderRadius.vertical(bottom: Radius.circular(8))
                    : null,
                border: Border(
                  bottom: BorderSide(
                    color: isLastRow
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scheme['party_led'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          scheme['scheme_name'] ?? '',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatAmount(scheme['total_value']),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scheme['current_slab']?.toString() ?? '-',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scheme['next_slab']?.toString() ?? '-',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    String dateStr = date.toString();
    if (dateStr.length >= 10) {
      return dateStr.substring(0, 10);
    }
    return dateStr;
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '₹0';

    double value = 0.0;
    if (amount is num) {
      value = amount.toDouble();
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    }

    return Formatters.formatCurrency(value.abs());
  }

  Widget _buildBottomSummaryBar() {
    int totalSchemes = _schemeData.length;

    double totalAmount = 0.0;

    for (var scheme in _schemeData) {
      var amount = scheme['total_value'];
      if (amount != null) {
        if (amount is num) {
          totalAmount += amount.toDouble();
        } else if (amount is String) {
          totalAmount += double.tryParse(amount) ?? 0.0;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Total: $totalSchemes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 20,
              color: Colors.white.withOpacity(0.2),
            ),
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  _formatAmount(totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeCountBadge(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}