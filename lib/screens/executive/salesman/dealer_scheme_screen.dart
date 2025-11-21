// lib/screens/salesman/dealer_scheme_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/search_filter_models.dart';
import '../../../theme/theme_helpers.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common_dropdowns.dart';
import '../../../widgets/dashboard_layout.dart';
import '../menu_navigator.dart';
import 'data_service.dart';


class DealerSchemeScreen extends StatefulWidget {
  final String title;

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
  Set<String> _expandedSchemeTypes = {};

  List<String> _routes = [];
  List<String> _schemeNames = ['All Schemes'];
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _selectedSchemeName = _schemeNames.first;
    _fetchRouteList();
    _fetchAllSchemeNames();
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
      _fetchAllSchemeNames();
      _fetchSchemeData();
    }
  }

  void _onSchemeNameChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedSchemeName = newValue;
        _expandedSchemeTypes.clear();
      });
      _fetchSchemeData();
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
      String routeParam = (_selectedRoute == null || _selectedRoute == 'All Routes')
          ? '%'
          : _selectedRoute!;

      List<Map<String, dynamic>> allSchemes = await _dataService.getSchemesByExecutiveAndRoute(
        route: routeParam,
        schemeName: '%',
      );

      Set<String> uniqueSchemes = allSchemes
          .map((e) => e['scheme_name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();

      setState(() {
        _schemeNames = ['All Schemes', ...uniqueSchemes.toList()..sort()];
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
    final textColor = ThemeHelper.textColor(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Loading schemes...',
              style: TextStyle(color: ThemeHelper.subtleTextColor(context), fontSize: 14),
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
            Icon(Icons.error, color: ThemeHelper.errorColor, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: ThemeHelper.errorColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSchemeData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
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
            Icon(Icons.inbox, color: ThemeHelper.subtleTextColor(context), size: 48),
            SizedBox(height: 16),
            Text(
              'No scheme data available',
              style: TextStyle(color: ThemeHelper.subtleTextColor(context), fontSize: 16),
            ),
          ],
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> groupedSchemes = _groupBySchemeType();

    return RefreshIndicator(
      onRefresh: _fetchSchemeData,
      child: ListView(
        padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 140),
        children: [
          if (groupedSchemes['VALUE']!.isNotEmpty)
            _buildSchemeTypeCard('VALUE', groupedSchemes['VALUE']!, ThemeHelper.successColor),
          if (groupedSchemes['BASKET']!.isNotEmpty)
            _buildSchemeTypeCard('BASKET', groupedSchemes['BASKET']!, ThemeHelper.warningColor),
          if (groupedSchemes['QUANTITY']!.isNotEmpty)
            _buildSchemeTypeCard('QUANTITY', groupedSchemes['QUANTITY']!, ThemeHelper.accentPurple),
          if (groupedSchemes['POINTS']!.isNotEmpty)
            _buildSchemeTypeCard('POINTS', groupedSchemes['POINTS']!, ThemeHelper.infoColor),
        ],
      ),
    );
  }

  Widget _buildSchemeTypeCard(String schemeType, List<Map<String, dynamic>> schemes, Color color) {
    bool isExpanded = _expandedSchemeTypes.contains(schemeType);
    int schemeCount = schemes.length;

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
        color: ThemeHelper.cardBackground(context),
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
                            color: ThemeHelper.textColor(context),
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
                                color: ThemeHelper.subtleTextColor(context),
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 12,
                              color: ThemeHelper.borderColor(context),
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
    final textColor = ThemeHelper.textColor(context);
    final subtleColor = ThemeHelper.subtleTextColor(context);

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    schemeType == 'VALUE'
                        ? 'Amount'
                        : schemeType == 'BASKET'
                        ? 'Achieved'
                        :  schemeType == 'QUANTITY'
                        ? 'Achieved'
                        : 'Earned',

                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Current Slab',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Balance to Next Slab',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          ...schemes.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> scheme = entry.value;
            bool isLastRow = index == schemes.length - 1;

            return Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: ThemeHelper.rowBackground(context, index % 2 == 0),
                borderRadius: isLastRow
                    ? BorderRadius.vertical(bottom: Radius.circular(8))
                    : null,
                border: Border(
                  bottom: BorderSide(
                    color: isLastRow
                        ? Colors.transparent
                        : ThemeHelper.borderColor(context),
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
                            color: textColor,
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
                            color: subtleColor,
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

                      scheme['scheme_type'] == 'VALUE'
                          ? _formatAmount(scheme['total_value'])
                          : scheme['scheme_type'] == 'BASKET'
                          ? scheme['achieved_value'].toString()
                          :  scheme['scheme_type'] == 'QUANTITY'
                          ? scheme['total_qty'].toString()
                          : scheme['total_points'].toString(),

                     // _formatAmount(scheme['total_value']),
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
                        color: ThemeHelper.warningColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scheme['current_slab']?.toString() ?? '0.0',
                        style: TextStyle(
                          color: ThemeHelper.warningColor,
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
                        color: ThemeHelper.accentTeal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(


                        scheme['scheme_type'] == 'VALUE'
                            ? _formatAmount(scheme['amount_or_points_to_next'])
                            : (scheme['amount_or_points_to_next']?.toString() ?? '0.0'),







                        style: TextStyle(
                          color: ThemeHelper.accentTeal,
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
        color: ThemeHelper.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeHelper.borderColor(context),
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
                Icon(Icons.receipt_long, color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Total: $totalSchemes',
                  style: TextStyle(
                    color: ThemeHelper.textColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 20,
              color: ThemeHelper.borderColor(context),
            ),
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: ThemeHelper.successColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  _formatAmount(totalAmount),
                  style: TextStyle(
                    color: ThemeHelper.textColor(context),
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
}