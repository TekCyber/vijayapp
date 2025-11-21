// lib/screens/salesman/salesman_target_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/common_dropdowns.dart';
import '../../models/search_filter_models.dart';
import '../../utils/formatters.dart';
import '../../theme/theme_helpers.dart';
import '../../services/api_service.dart';
import '../dealer/menu_navigator.dart';

class SalesmanTargetScreen extends StatefulWidget {
  final String title;

  SalesmanTargetScreen({required this.title});

  @override
  _SalesmanTargetScreenState createState() => _SalesmanTargetScreenState();
}

class _SalesmanTargetScreenState extends State<SalesmanTargetScreen> {
  List<Map<String, dynamic>> _targetData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _selectedBrand;
  String? _selectedTargetType;
  int selectedMenuIndex = 0;

  // Track expanded target types and their item limits
  Map<String, bool> _expandedTargetTypes = {};
  Map<String, int> _displayLimits = {};
  static const int DEFAULT_DISPLAY_LIMIT = 5;

  List<String> _brands = ['All Brands'];
  List<String> _targetTypes = ['All Types'];

  @override
  void initState() {
    super.initState();
    _selectedBrand = _brands.first;
    _selectedTargetType = _targetTypes.first;
    _fetchBrandList();
    _fetchTargetTypeList();
    _fetchTargetData();
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  List<SearchFilterOption> _getSearchFilters() {
    return [
      SearchFilterOption(
        key: 'brandFilter',
        widget: BrandDropdownFilter(
          brands: _brands,
          selectedBrand: _selectedBrand,
          label: "Filter by Brand",
          onChanged: _onBrandChanged,
        ),
      ),
      SearchFilterOption(
        key: 'targetTypeFilter',
        widget: BrandDropdownFilter(
          brands: _targetTypes,
          selectedBrand: _selectedTargetType,
          label: "Filter by Target Type",
          onChanged: _onTargetTypeChanged,
        ),
      ),
    ];
  }

  void _handleFilterChanged(Map<String, dynamic> filters) {
    print('SalesmanTargetScreen: Received filters: $filters');
    _fetchTargetData();
  }

  void _onBrandChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedBrand = newValue;
        _expandedTargetTypes.clear();
        _displayLimits.clear();
      });
      _fetchTargetData();
    }
  }

  void _onTargetTypeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedTargetType = newValue;
        _expandedTargetTypes.clear();
        _displayLimits.clear();
      });
      _fetchTargetData();
    }
  }

  Future<void> _fetchBrandList() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_TARGET_BRAND_BY_SALESMAN",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<String> brandList = [];

        for (var item in response.data!) {
          String brand = item['BRAND']?.toString() ?? '';
          if (brand.isNotEmpty && !brandList.contains(brand)) {
            brandList.add(brand);
          }
        }

        setState(() {
          _brands = ['All Brands', ...brandList];
          if (_selectedBrand == null || !_brands.contains(_selectedBrand)) {
            _selectedBrand = _brands.first;
          }
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch brand list');
      }
    } catch (e) {
      print('Error fetching brand list: $e');
      setState(() {
        _brands = ['All Brands'];
        _selectedBrand = _brands.first;
      });
    }
  }

  Future<void> _fetchTargetTypeList() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_DISTINCT_TARGET_TYPE_BY_SALESMAN",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<String> targetTypeList = [];

        for (var item in response.data!) {
          String targetType = item['target_type']?.toString() ?? '';
          if (targetType.isNotEmpty && !targetTypeList.contains(targetType)) {
            targetTypeList.add(targetType);
          }
        }

        setState(() {
          _targetTypes = ['All Types', ...targetTypeList];
          if (_selectedTargetType == null || !_targetTypes.contains(_selectedTargetType)) {
            _selectedTargetType = _targetTypes.first;
          }
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch target type list');
      }
    } catch (e) {
      print('Error fetching target type list: $e');
      setState(() {
        _targetTypes = ['All Types'];
        _selectedTargetType = _targetTypes.first;
      });
    }
  }

  Future<void> _fetchTargetData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      String brandParam = (_selectedBrand == null || _selectedBrand == 'All Brands')
          ? '%'
          : _selectedBrand!;

      String targetTypeParam = (_selectedTargetType == null || _selectedTargetType == 'All Types')
          ? '%'
          : _selectedTargetType!;

      Map<String, dynamic> payload = {
        "sqlKey": "GET_SALESMAN_TARGET",
        "executive": username,
        "brand": brandParam,
        "targetType": targetTypeParam,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData = [];

        for (var item in response.data!) {
          fetchedData.add({
            'target_id': item['target_id'],
            'executive': item['executive'],
            'brand': item['brand_name'],
            'subgroups': item['subgroups'],
            'month': item['target_month'],
            'start_date': item['start_date'],
            'end_date': item['end_date'],
            'target_type': item['target_type'],
            'target': item['target_value'],
          });
        }

        setState(() {
          _targetData = fetchedData;
          _isLoading = false;
          _initializeDisplayLimits();
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch target data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading target data: ${e.toString()}';
      });
      print('Error fetching target data: $e');
    }
  }

  void _initializeDisplayLimits() {
    Map<String, List<Map<String, dynamic>>> grouped = _groupByTargetType();
    grouped.forEach((targetType, items) {
      if (!_displayLimits.containsKey(targetType)) {
        _displayLimits[targetType] = DEFAULT_DISPLAY_LIMIT;
      }
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupByTargetType() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var target in _targetData) {
      String targetType = (target['target_type'] ?? 'Other').toString();
      if (!grouped.containsKey(targetType)) {
        grouped[targetType] = [];
      }
      grouped[targetType]!.add(target);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Sales Targets',
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
                child: _buildTargetContent(),
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

  Widget _buildTargetContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: ThemeHelper.loadingColor(context),
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Loading targets...',
              style: ThemeHelper.captionStyle(context),
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
              onPressed: _fetchTargetData,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeHelper.glassBackground(context),
              ),
              child: Text(
                'Retry',
                style: TextStyle(color: ThemeHelper.textColor(context)),
              ),
            ),
          ],
        ),
      );
    }

    if (_targetData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              color: ThemeHelper.subtleTextColor(context),
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No target data available',
              style: ThemeHelper.subtitleStyle(context).copyWith(
                color: ThemeHelper.subtleTextColor(context),
              ),
            ),
          ],
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> groupedTargets = _groupByTargetType();

    return RefreshIndicator(
      onRefresh: _fetchTargetData,
      child: ListView(
        padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 140),
        children: groupedTargets.entries.map((entry) {
          return _buildTargetTypeCard(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildTargetTypeCard(String targetType, List<Map<String, dynamic>> targets) {
    bool isExpanded = _expandedTargetTypes[targetType] ?? false;
    int displayLimit = _displayLimits[targetType] ?? DEFAULT_DISPLAY_LIMIT;
    int totalCount = targets.length;
    bool hasMore = totalCount > displayLimit;

    List<Map<String, dynamic>> displayedTargets = isExpanded
        ? targets
        : targets.take(displayLimit).toList();

    Color color = _getTargetTypeColor(targetType);

    // Calculate total target value
    double totalTarget = 0.0;
    for (var target in targets) {
      var value = target['target'];
      if (value != null) {
        if (value is num) {
          totalTarget += value.toDouble();
        } else if (value is String) {
          totalTarget += double.tryParse(value) ?? 0.0;
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
                _expandedTargetTypes[targetType] = !isExpanded;
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
                      _getTargetTypeIcon(targetType),
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
                          '$targetType TARGET',
                          style: ThemeHelper.titleStyle(context),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$totalCount Items',
                              style: ThemeHelper.captionStyle(context),
                            ),
                            SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 12,
                              color: ThemeHelper.dividerColor(context),
                            ),
                            SizedBox(width: 12),
                            Text(
                              targetType == 'Dealer Count'
                                  ? '${totalTarget.toInt()} Dealers'
                                  : Formatters.formatCurrency(totalTarget),
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
          if (displayedTargets.isNotEmpty) ...[
            Divider(
              color: color.withOpacity(0.2),
              height: 1,
              thickness: 1,
            ),
            _buildTargetTable(targetType, displayedTargets, color),
            if (hasMore && !isExpanded)
              Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _expandedTargetTypes[targetType] = true;
                    });
                  },
                  icon: Icon(Icons.expand_more, color: color, size: 20),
                  label: Text(
                    'Show ${totalCount - displayLimit} more',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Color _getTargetTypeColor(String targetType) {
    switch (targetType.toLowerCase()) {
      case 'value':
        return ThemeHelper.successColor;
      case 'dealer count':
        return ThemeHelper.accentBlue;
      case 'quantity':
        return ThemeHelper.accentOrange;
      case 'points':
        return ThemeHelper.accentPurple;
      default:
        return ThemeHelper.infoColor;
    }
  }

  IconData _getTargetTypeIcon(String targetType) {
    switch (targetType.toLowerCase()) {
      case 'value':
        return Icons.account_balance_wallet;
      case 'dealer count':
        return Icons.people;
      case 'quantity':
        return Icons.inventory_2;
      case 'points':
        return Icons.stars;
      default:
        return Icons.flag;
    }
  }

  Widget _buildTargetTable(String targetType, List<Map<String, dynamic>> targets, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(
                color: ThemeHelper.borderColor(context),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Brand',
                    style: ThemeHelper.subtitleStyle(context).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Sub Group',
                    style: ThemeHelper.subtitleStyle(context).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Target',
                    style: ThemeHelper.subtitleStyle(context).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ...targets.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> target = entry.value;
            bool isLastRow = index == targets.length - 1;

            return Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: ThemeHelper.rowBackground(context, index % 2 == 0),
                borderRadius: isLastRow
                    ? BorderRadius.vertical(bottom: Radius.circular(8))
                    : null,
                border: Border(
                  left: BorderSide(
                    color: ThemeHelper.borderColor(context),
                    width: 1,
                  ),
                  right: BorderSide(
                    color: ThemeHelper.borderColor(context),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: isLastRow
                        ? ThemeHelper.borderColor(context)
                        : ThemeHelper.dividerColor(context),
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
                          target['brand'] ?? '',
                          style: ThemeHelper.bodyStyle(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          target['month'] ?? '',
                          style: ThemeHelper.smallStyle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      _formatSubGroup(target['subgroups']),
                      style: ThemeHelper.bodyStyle(context).copyWith(
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        targetType == 'Dealer Count'
                            ? _parseTarget(target['target']).toInt().toString()
                            : Formatters.formatCurrency(_parseTarget(target['target'])),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.right,
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

  String _formatSubGroup(dynamic subGroup) {
    if (subGroup == null) return '';
    String subGroupStr = subGroup.toString();

    // Split by comma and take first 2 items for brevity
    List<String> parts = subGroupStr.split(',');
    if (parts.length > 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}...';
    }
    return subGroupStr;
  }

  double _parseTarget(dynamic target) {
    if (target == null) return 0.0;
    if (target is num) return target.toDouble();
    if (target is String) return double.tryParse(target) ?? 0.0;
    return 0.0;
  }

  Widget _buildBottomSummaryBar() {
    int totalTargets = _targetData.length;

    double totalValue = 0.0;
    int totalDealerCount = 0;

    for (var target in _targetData) {
      String targetType = target['target_type']?.toString() ?? '';
      var value = target['target'];
      double parsedValue = _parseTarget(value);

      if (targetType == 'Value') {
        totalValue += parsedValue;
      } else if (targetType == 'Dealer Count') {
        totalDealerCount += parsedValue.toInt();
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.cardBackground(context).withOpacity(0.95),
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
                Icon(Icons.flag, color: ThemeHelper.accentBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Total: $totalTargets',
                  style: ThemeHelper.bodyStyle(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 20,
              color: ThemeHelper.dividerColor(context),
            ),
            if (totalValue > 0)
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: ThemeHelper.successColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.formatCurrency(totalValue),
                    style: ThemeHelper.bodyStyle(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (totalDealerCount > 0)
              Row(
                children: [
                  Icon(
                    Icons.people,
                    color: ThemeHelper.accentBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$totalDealerCount Dealers',
                    style: ThemeHelper.bodyStyle(context).copyWith(
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