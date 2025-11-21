// lib/screens/salesman/salesman_target_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/search_filter_models.dart';
import '../../../services/api_service.dart';
import '../../../theme/theme_helpers.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common_dropdowns.dart';
import '../../../widgets/dashboard_layout.dart';
import '../menu_navigator.dart';


class SalesmanTargetScreen extends StatefulWidget {
  final String title;

  SalesmanTargetScreen({required this.title});

  @override
  _SalesmanTargetScreenState createState() => _SalesmanTargetScreenState();
}

class _SalesmanTargetScreenState extends State<SalesmanTargetScreen> {
  List<Map<String, dynamic>> _targetData = [];
  List<Map<String, dynamic>> _filteredTargetData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _selectedBrand;
  String? _selectedTargetType;
  int selectedMenuIndex = 0;

  // Track expanded target types and their item limits
  Map<String, bool> _expandedTargetTypes = {};
  Map<String, int> _displayLimits = {};
  static const int DEFAULT_DISPLAY_LIMIT = 3;

  List<String> _brands = ['All Brands'];
  List<String> _targetTypes = ['All Types'];

  @override
  void initState() {
    super.initState();
    _selectedBrand = _brands.first;
    _selectedTargetType = _targetTypes.first;
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
    _applyFilters();
  }

  void _onBrandChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedBrand = newValue;
        _expandedTargetTypes.clear();
        _displayLimits.clear();
      });
      _applyFilters();
    }
  }

  void _onTargetTypeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedTargetType = newValue;
        _expandedTargetTypes.clear();
        _displayLimits.clear();
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTargetData = _targetData.where((target) {
        bool matchesBrand = _selectedBrand == null ||
            _selectedBrand == 'All Brands' ||
            target['brand'] == _selectedBrand;

        bool matchesTargetType = _selectedTargetType == null ||
            _selectedTargetType == 'All Types' ||
            target['target_type'] == _selectedTargetType;

        return matchesBrand && matchesTargetType;
      }).toList();

      _initializeDisplayLimits();
    });
  }

  void _extractFiltersFromData() {
    Set<String> brandSet = {};
    Set<String> targetTypeSet = {};

    for (var item in _targetData) {
      String brand = item['brand']?.toString() ?? '';
      String targetType = item['target_type']?.toString() ?? '';

      if (brand.isNotEmpty) brandSet.add(brand);
      if (targetType.isNotEmpty) targetTypeSet.add(targetType);
    }

    setState(() {
      _brands = ['All Brands', ...brandSet.toList()..sort()];
      _targetTypes = ['All Types', ...targetTypeSet.toList()..sort()];

      if (_selectedBrand == null || !_brands.contains(_selectedBrand)) {
        _selectedBrand = _brands.first;
      }
      if (_selectedTargetType == null || !_targetTypes.contains(_selectedTargetType)) {
        _selectedTargetType = _targetTypes.first;
      }
    });
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

      Map<String, dynamic> payload = {
        "sqlKey": "GET_SALESMAN_TARGET",
        "executive": username,
        "brand": "%"
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
            'achieved': item['achieved'],
            'balance': item['balance'],
            'incentive': item['incentive'],
            'incentive_achieved': item['incentive_achieved'],
            'incentive_total': item['incentive_total'],
            'incentive_received': item['incentive_received'],
            'percentage_achieved': item['percentage_achieved'],
          });
        }

        setState(() {
          _targetData = fetchedData;
          _extractFiltersFromData();
          _applyFilters();
          _isLoading = false;
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

    for (var target in _filteredTargetData) {
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

    if (_filteredTargetData.isEmpty) {
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

    // Get first row data for percentage_achieved and incentive_received
    Map<String, dynamic> firstRow = targets.isNotEmpty ? targets[0] : {};
    double percentageAchieved = _parseTarget(firstRow['percentage_achieved']);
    double incentiveReceived = _parseTarget(firstRow['incentive_received']);

    // Calculate total target, achieved, and balance values
    double totalTarget = 0.0;
    double totalAchieved = 0.0;
    int itemsCompleted = 0;

    for (var target in targets) {
      var targetValue = target['target'];
      var achievedValue = target['achieved'];

      double parsedTarget = _parseTarget(targetValue);
      double parsedAchieved = _parseTarget(achievedValue);

      totalTarget += parsedTarget;
      totalAchieved += parsedAchieved;

      // Count items that are fully completed
      if (parsedTarget > 0 && parsedAchieved >= parsedTarget) {
        itemsCompleted++;
      }
    }

    // Cap at 100% for display
    double displayPercentage = percentageAchieved > 100 ? 100 : percentageAchieved;

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
          // Non-clickable container - only +/- button is interactive
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Title Row with Icon and Expand/Collapse button
                Row(
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
                            'Target - $targetType',
                            style: ThemeHelper.titleStyle(context),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$totalCount Items',
                            style: ThemeHelper.captionStyle(context),
                          ),
                        ],
                      ),
                    ),
                    // Only this button is clickable for expand/collapse
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedTargetTypes[targetType] = !isExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
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
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Stats and Progress Bar Row
                Row(
                  children: [
                    // Mini stats - forced in single row
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildMiniStat(
                            'Items',
                            '$totalCount',
                            ThemeHelper.infoColor,
                            onTap: null,
                          ),
                          SizedBox(width: 6),
                          _buildMiniStat(
                            'Completed',
                            '$itemsCompleted',
                            ThemeHelper.successColor,
                            onTap: itemsCompleted > 0 ? () {
                              _showCompletedItemsDialog(targetType, targets);
                            } : null,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: _buildMiniStat(
                              'Incentive',
                              Formatters.formatCurrency(incentiveReceived),
                              ThemeHelper.accentBlue,
                              onTap: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // Progress bar with incentive received label
                _buildProgressBar(displayPercentage, percentageAchieved, incentiveReceived, color),
              ],
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

  Widget _buildProgressBar(double displayPercentage, double actualPercentage, double incentiveReceived, Color color) {
    Color progressColor = _getProgressColor(actualPercentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievement',
              style: ThemeHelper.smallStyle(context).copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${actualPercentage.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: progressColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: ThemeHelper.glassBackground(context).withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: ThemeHelper.borderColor(context).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.transparent,
                ),
                FractionallySizedBox(
                  widthFactor: displayPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor.withOpacity(0.8),
                          progressColor,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                if (displayPercentage > 0)
                  FractionallySizedBox(
                    widthFactor: displayPercentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) {
      return ThemeHelper.successColor;
    } else if (percentage >= 80) {
      return ThemeHelper.accentBlue;
    } else if (percentage >= 50) {
      return ThemeHelper.warningColor;
    } else {
      return ThemeHelper.errorColor;
    }
  }

  // Updated _buildMiniStat to support tap interaction
  Widget _buildMiniStat(String label, String value, Color color, {VoidCallback? onTap}) {
    Widget statWidget = Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onTap != null) ...[
            SizedBox(width: 3),
            Icon(
              Icons.visibility,
              color: color,
              size: 11,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: statWidget,
      );
    }

    return statWidget;
  }

// Updated simplified method to show completed items dialog
  void _showCompletedItemsDialog(String targetType, List<Map<String, dynamic>> targets) {
    // Filter completed items
    List<Map<String, dynamic>> completedItems = targets.where((target) {
      double parsedTarget = _parseTarget(target['target']);
      double parsedAchieved = _parseTarget(target['achieved']);
      return parsedTarget > 0 && parsedAchieved >= parsedTarget;
    }).toList();

    if (completedItems.isEmpty) return;

    bool isDealerCount = targetType == 'Dealer Count';
    Color color = _getTargetTypeColor(targetType);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeHelper.cardBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: ThemeHelper.successColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed Items',
                      style: ThemeHelper.titleStyle(context).copyWith(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${completedItems.length} of ${targets.length} completed',
                      style: ThemeHelper.captionStyle(context).copyWith(
                        fontSize: 12,
                        color: ThemeHelper.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: completedItems.length,
              separatorBuilder: (context, index) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                var item = completedItems[index];
                String brandName = item['brand'] ?? '';
                String subGroup = item['subgroups'] ?? '';
                double achievedValue = _parseTarget(item['achieved']);

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: ThemeHelper.glassBackground(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeHelper.borderColor(context).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Brand name
                      Expanded(
                        flex: 2,
                        child: Tooltip(
                          message: brandName,
                          child: Text(
                            brandName,
                            style: ThemeHelper.bodyStyle(context).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      SizedBox(width: 12),

                      // Material Group / Subgroup with Tooltip
                      Expanded(
                        flex: 3,
                        child: Tooltip(
                          message: subGroup.isNotEmpty ? subGroup : 'No subgroup',
                          preferBelow: false,
                          child: Text(
                            subGroup,
                            style: ThemeHelper.captionStyle(context).copyWith(
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      SizedBox(width: 12),

                      // Achieved value
                      Expanded(
                        flex: 2,
                        child: Text(
                          isDealerCount
                              ? '${achievedValue.toInt()}'
                              : Formatters.formatCurrency(achievedValue),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ThemeHelper.successColor,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: ThemeHelper.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: ThemeHelper.borderColor(context),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Sub Group',
                    style: ThemeHelper.subtitleStyle(context).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.flag, color: color, size: 20),
                        SizedBox(height: 4),
                        Text(
                          'Target',
                          style: ThemeHelper.subtitleStyle(context).copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.trending_up, color: ThemeHelper.successColor, size: 20),
                        SizedBox(height: 4),
                        Text(
                          'Achieved',
                          style: ThemeHelper.subtitleStyle(context).copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.pending_actions, color: ThemeHelper.warningColor, size: 20),
                        SizedBox(height: 4),
                        Text(
                          'Balance',
                          style: ThemeHelper.subtitleStyle(context).copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          // Table Rows
          ...targets.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> target = entry.value;

            return _buildTargetRow(
              brandName: target['brand'] ?? '',
              subGroup: target['subgroups'] ?? '',
              month: target['month'] ?? '',
              targetValue: _parseTarget(target['target']),
              achievedValue: _parseTarget(target['achieved']),
              balanceValue: _parseTarget(target['balance']),
              targetType: targetType,
              isLastRow: index == targets.length - 1,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTargetRow({
    required String brandName,
    required String subGroup,
    required String month,
    required double targetValue,
    required double achievedValue,
    required double balanceValue,
    required String targetType,
    bool isLastRow = false,
  }) {
    bool isDealerCount = targetType == 'Dealer Count';

    return Container(
      margin: EdgeInsets.only(bottom: isLastRow ? 0 : 8),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: ThemeHelper.cardBackground(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeHelper.borderColor(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Sub Group Column
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onDoubleTap: () {
                    _showSubGroupDialog(brandName, subGroup);
                  },
                  child: Tooltip(
                    message: 'Double-tap to see full text',
                    child: Text(
                      subGroup.isNotEmpty ? subGroup : 'N/A',
                      style: ThemeHelper.bodyStyle(context).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (month.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    month,
                    style: ThemeHelper.smallStyle(context).copyWith(
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Target Column
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                isDealerCount
                    ? targetValue.toInt().toString()
                    : Formatters.formatCurrency(targetValue),
                style: ThemeHelper.bodyStyle(context).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Achieved Column
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                isDealerCount
                    ? achievedValue.toInt().toString()
                    : Formatters.formatCurrency(achievedValue),
                style: TextStyle(
                  color: ThemeHelper.successColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Balance Column
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                isDealerCount
                    ? balanceValue.toInt().toString()
                    : Formatters.formatCurrencyWithDecimal(balanceValue,2),
                style: TextStyle(
                  color: ThemeHelper.warningColor,
                  fontSize: 13,
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

  void _showSubGroupDialog(String brandName, String subGroup) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeHelper.cardBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.category,
                color: ThemeHelper.accentBlue,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  brandName,
                  style: ThemeHelper.titleStyle(context),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sub Groups:',
                  style: ThemeHelper.subtitleStyle(context).copyWith(
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeHelper.glassBackground(context).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeHelper.borderColor(context),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    subGroup,
                    style: ThemeHelper.bodyStyle(context).copyWith(
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: ThemeHelper.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _parseTarget(dynamic target) {
    if (target == null) return 0.0;
    if (target is num) return target.toDouble();
    if (target is String) return double.tryParse(target) ?? 0.0;
    return 0.0;
  }
}