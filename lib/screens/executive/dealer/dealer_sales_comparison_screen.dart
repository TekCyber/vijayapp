// lib/views/dealer/dealer_sales_comparison_screen.dart - COMPLETE THEME-AWARE VERSION
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/common_dropdowns.dart';
import '../../../theme/theme_helpers.dart';

import '../../../models/search_filter_models.dart';
import 'data_service.dart';
import '../menu_navigator.dart';
import '../../../services/common_data_service.dart';

class DealerSalesComparisonScreen extends StatefulWidget {
  final String title;
  final Function(int)? onMenuSelected;
  final String? dealername;

  DealerSalesComparisonScreen({
    required this.title,
    this.onMenuSelected,
    this.dealername,
  });

  @override
  _DealerSalesComparisonScreenState createState() => _DealerSalesComparisonScreenState();
}


class _DealerSalesComparisonScreenState extends State<DealerSalesComparisonScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  int selectedMenuIndex = 0;

  String selectedPeriod = 'This Month';
  String selectedCategory = 'Sub Group';
  String? selectedBrand;

  DateTime? fromDate;
  DateTime? toDate;
  bool isDatePickerVisible = false;

  final List<String> periodOptions = ['This Month', 'Last Month', 'Last Year', 'YTD'];
  final List<String> categoryOptions = ['Sub Group',  'Material Group'];
  List<String> brandOptions = [];
  bool isLoadingBrands = true;

  List<Map<String, dynamic>> _salesData = [];
  bool _isLoadingSales = true;
  String _errorMessageSales = '';

  final Map<String, bool> _expandedBrands = {};
  final Map<String, String?> _brandIcons = {};

  final DataService _dataServices = DataService();
  final CommonDataService _commonDataService = CommonDataService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _updateButtonStates();
    _loadBrands();
    _fetchSalesData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() {
      isLoadingBrands = true;
    });

    try {
      List<String> brands = await _commonDataService.getBrandsByExecutive();
      setState(() {
        brandOptions = ['All Brands', ...brands];
        isLoadingBrands = false;
        selectedBrand = brandOptions.isNotEmpty ? brandOptions.first : null;
      });
      _fetchSalesData();
    } catch (e) {
      setState(() {
        isLoadingBrands = false;
        brandOptions = ['All Brands'];
        selectedBrand = 'All Brands';
      });
      print('Error loading brands: $e');
    }
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  List<SearchFilterOption> _getSearchFilters() {
    return [
      SearchFilterOption(
        key: 'filterRow1',
        widget: BrandDropdownFilter(
          brands: isLoadingBrands ? ['Loading...'] : brandOptions,
          selectedBrand: selectedBrand,
          label: "Brand",
          onChanged: _onBrandChanged,
        ),
      ),
      SearchFilterOption(
        key: 'filterRow2',
        widget: Row(
          children: [
            Expanded(
              child: PeriodDropdownFilter(
                periods: periodOptions,
                selectedPeriod: selectedPeriod,
                label: "Period",
                onChanged: _onPeriodChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CategoryDropdownFilter(
                categories: categoryOptions,
                selectedCategory: selectedCategory,
                label: "Category",
                onChanged: _onCategoryChanged,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  void _onBrandChanged(String? newValue) {
    if (newValue != null && newValue != 'Loading...') {
      setState(() {
        selectedBrand = newValue;
      });
      _fetchSalesData();
    }
  }

  void _handleFilterChanged(Map<String, dynamic> filters) {
    print('DealerSalesComparisonScreen: Received filters: $filters');
  }

  void _updateButtonStates() {
    setState(() {
      if (selectedPeriod == 'YTD') {
        isDatePickerVisible = true;
      } else {
        isDatePickerVisible = false;
        if (fromDate != null || toDate != null) {
          fromDate = null;
          toDate = null;
        }
      }
    });
  }

  void _onPeriodChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        selectedPeriod = newValue;
      });
      _updateButtonStates();
      _fetchSalesData();
    }
  }

  void _onCategoryChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        selectedCategory = newValue;
      });
      _fetchSalesData();
    }
  }

  Future<void> _fetchSalesData() async {
    if (isLoadingBrands || selectedBrand == null) {
      return;
    }

    if (selectedPeriod == 'YTD' && (fromDate == null || toDate == null)) {
      setState(() {
        _salesData = [];
        _isLoadingSales = false;
        _errorMessageSales = '';
      });
      return;
    }

    setState(() {
      _isLoadingSales = true;
      _errorMessageSales = '';
    });

    try {
      String? brandToFetch = selectedBrand == 'All Brands' ? '%' : selectedBrand;

      final result = await _dataServices.fetchSalesComparisonData(
        dealername: widget.dealername ?? widget.title,
        brand: brandToFetch ?? widget.title,
        period: selectedPeriod,
        category: selectedCategory,
        fromDate: fromDate,
        toDate: toDate,
        amount: null,
      );

      if (result['success']) {
        setState(() {
          _salesData = result['data'] ?? [];
          _isLoadingSales = false;
          _initializeExpandedBrands();
          _loadBrandIcons();
        });
      } else {
        setState(() {
          _isLoadingSales = false;
          _errorMessageSales = result['error'] ?? 'Failed to fetch sales data';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSales = false;
        _errorMessageSales = 'Unexpected error: ${e.toString()}';
      });
      print('Error in _fetchSalesData: $e');
    }
  }

  void _initializeExpandedBrands() {
    _expandedBrands.clear();
    final brands = _salesData
        .map((item) => item['Brand']?.toString() ?? 'Unknown')
        .toSet();

    for (String brand in brands) {
      _expandedBrands[brand] = false;
    }
  }

  Future<void> _loadBrandIcons() async {
    final brands = _salesData
        .map((item) => item['Brand']?.toString() ?? 'Unknown')
        .toSet();

    for (String brand in brands) {
      if (brand != 'Unknown' && !_brandIcons.containsKey(brand)) {
        try {
          String? icon = await _commonDataService.getBrandIconByBrandName(brand);
          if (mounted) {
            setState(() {
              _brandIcons[brand] = icon;
            });
          }
        } catch (e) {
          print('Error loading icon for $brand: $e');
          _brandIcons[brand] = null;
        }
      }
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    double value = double.tryParse(amount.toString()) ?? 0.0;
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {

    return DashboardLayout(
      title: widget.dealername != null ? widget.title : "Sales Analytics",
      subtitle: widget.dealername ?? widget.title,
      onTabSelected: _onMenuSelected,
      showBackButton: true,
      searchFilters: _getSearchFilters(),
      onFilterChanged: _handleFilterChanged,
      body: Stack(
        children: [
          SafeArea(
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _slideAnimation.value)),
                  child: Opacity(
                    opacity: _slideAnimation.value,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 0,
                        bottom: 100,
                      ),
                      child: Column(
                        children: [
                          if (isDatePickerVisible) ...[
                            SizedBox(height: 12),
                            _buildCustomDatePicker(),
                          ],

                          SizedBox(height: 16),
                          _buildSalesContent(),
                          SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_salesData.isNotEmpty && !_isLoadingSales && _errorMessageSales.isEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: _buildBottomTotalsBar(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSalesContent() {
    return _buildSalesDataView();
  }

  Widget _buildSalesDataView() {
    if (_isLoadingSales) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading sales data...',
              style: ThemeHelper.subtitleStyle(context),
            ),
            SizedBox(height: 8),
            Text(
              'Analyzing sales comparison',
              style: ThemeHelper.captionStyle(context),
            ),
          ],
        ),
      );
    }

    if (_errorMessageSales.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeHelper.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeHelper.errorColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.error_outline,
                color: ThemeHelper.errorColor,
                size: 48,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Failed to load sales data',
              style: ThemeHelper.titleStyle(context),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessageSales,
              style: TextStyle(
                color: ThemeHelper.errorColor.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchSalesData,
              icon: Icon(Icons.refresh, color: ThemeHelper.textColor(context)),
              label: Text(
                'Retry',
                style: TextStyle(
                  color: ThemeHelper.textColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_salesData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeHelper.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeHelper.infoColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.analytics_outlined,
                color: ThemeHelper.infoColor,
                size: 48,
              ),
            ),
            SizedBox(height: 20),
            Text(
              selectedPeriod == 'YTD'
                  ? 'Select a date range to view YTD data'
                  : 'No Sales Data Found',
              style: ThemeHelper.titleStyle(context),
            ),
            /*SizedBox(height: 8),
            Text(
              selectedPeriod == 'YTD'
              ? 'Please select a date range to view YTD data'
              : 'No Sales Data Found',
              style: ThemeHelper.captionStyle(context),
              textAlign: TextAlign.center,
            ),*/
          ],
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> groupedByBrand = {};
    for (var item in _salesData) {
      String brand = item['Brand']?.toString() ?? 'Unknown';
      if (!groupedByBrand.containsKey(brand)) {
        groupedByBrand[brand] = [];
      }
      groupedByBrand[brand]!.add(item);
    }

    var brandList = groupedByBrand.entries.toList();
    brandList.sort((a, b) {
      double totalA = a.value.fold(0.0, (sum, item) {
        double current = double.tryParse(item['Current']?.toString() ?? '0') ?? 0.0;
        double previous = double.tryParse(item['Previous']?.toString() ?? '0') ?? 0.0;
        return sum + current + previous;
      });
      double totalB = b.value.fold(0.0, (sum, item) {
        double current = double.tryParse(item['Current']?.toString() ?? '0') ?? 0.0;
        double previous = double.tryParse(item['Previous']?.toString() ?? '0') ?? 0.0;
        return sum + current + previous;
      });
      return totalB.compareTo(totalA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: brandList.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildBrandCard(entry.key, entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildBrandCard(String brandName, List<Map<String, dynamic>> brandData) {
    double brandCurrentTotal = brandData.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item['Current']?.toString() ?? '0') ?? 0.0);
    });

    double brandPreviousTotal = brandData.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item['Previous']?.toString() ?? '0') ?? 0.0);
    });

    bool isExpanded = _expandedBrands[brandName] ?? false;

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
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
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          //ThemeHelper.glassBackground(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildBrandIcon(brandName),
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          //brandName,
                          '',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpanded ? Icons.remove : Icons.add,
                          color: Theme.of(context).primaryColor,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isExpanded) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Total',
                    style: ThemeHelper.bodyStyle(context).copyWith(
                      color: ThemeHelper.subtleTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_getCurrentLabel()}: ₹${_formatAmount(brandCurrentTotal)}',
                          style: ThemeHelper.bodyStyle(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_getPreviousLabel()}: ₹${_formatAmount(brandPreviousTotal)}',
                          style: ThemeHelper.bodyStyle(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            if (isExpanded) ...[
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        "Item",
                        style: ThemeHelper.captionStyle(context),
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _getCurrentLabel(),
                        style: ThemeHelper.captionStyle(context),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _getPreviousLabel(),
                        style: ThemeHelper.captionStyle(context),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(width: 4),
                    Container(
                      width: 60,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: ThemeHelper.successColor,
                            size: 12,
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.arrow_downward,
                            color: ThemeHelper.errorColor,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: ThemeHelper.dividerColor(context), thickness: 1, height: 16),

              ...brandData.map((item) {
                String name = item['Name']?.toString() ?? 'Unknown';
                double current = double.tryParse(item['Current']?.toString() ?? '0') ?? 0.0;
                double previous = double.tryParse(item['Previous']?.toString() ?? '0') ?? 0.0;

                return _buildTableRow(name, current, previous);
              }).toList(),

              const SizedBox(height: 12),
              Divider(color: ThemeHelper.dividerColor(context), thickness: 1, height: 16),

              _buildBrandTotalRow("Grand Total", brandCurrentTotal, brandPreviousTotal),

              const SizedBox(height: 8),
              _buildGrowthIndicator(brandCurrentTotal, brandPreviousTotal),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrandIcon(String brandName) {
    String? base64Icon = _brandIcons[brandName];

    if (base64Icon != null && base64Icon.isNotEmpty) {
      try {
        String base64String = base64Icon.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 150,
          height: 50,
          fit: BoxFit.contain,
        );
      } catch (e) {
        print('Error decoding icon for $brandName: $e');
        return Icon(
          Icons.business_center,
          color: Theme.of(context).primaryColor,
          size: 20,
        );
      }
    }

    return Icon(
      Icons.business_center,
      color: Theme.of(context).primaryColor,
      size: 20,
    );
  }

  Widget _buildTableRow(String label, double currentAmount, double previousAmount) {
    double percentage = _calculatePercentage(currentAmount, previousAmount);
    bool isPositive = percentage >= 0;
    bool hasChange = percentage != 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Tooltip(
              message: label,
              preferBelow: true,
              waitDuration: Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ThemeHelper.isDark(context)
                    ? Color(0xFF1A1A1A)
                    : Color(0xFF575757),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              child: Text(
                label,
                style: ThemeHelper.bodyStyle(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              '₹${_formatAmount(currentAmount)}',
              style: ThemeHelper.bodyStyle(context).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              '₹${_formatAmount(previousAmount)}',
              style: ThemeHelper.bodyStyle(context).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 4),
          Container(
            width: 60,
            alignment: Alignment.centerRight,
            child: Text(
              hasChange ? '${percentage.abs().toStringAsFixed(1)}%' : '-',
              style: TextStyle(
                color: hasChange
                    ? (isPositive ? ThemeHelper.successColor : ThemeHelper.errorColor)
                    : ThemeHelper.subtleTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandTotalRow(String label, double currentAmount, double previousAmount) {
    double percentage = _calculatePercentage(currentAmount, previousAmount);
    bool isPositive = percentage >= 0;
    bool hasChange = percentage != 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: ThemeHelper.subtitleStyle(context),
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              '₹${_formatAmount(currentAmount)}',
              style: ThemeHelper.subtitleStyle(context),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              '₹${_formatAmount(previousAmount)}',
              style: ThemeHelper.subtitleStyle(context),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 4),
          Container(
            width: 60,
            alignment: Alignment.centerRight,
            child: Text(
              hasChange ? '${percentage.abs().toStringAsFixed(1)}%' : '-',
              style: TextStyle(
                color: hasChange
                    ? (isPositive ? ThemeHelper.successColor : ThemeHelper.errorColor)
                    : ThemeHelper.subtleTextColor(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthIndicator(double current, double previous) {
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
            '${isPositive ? '+' : ''}₹${_formatAmount(growthAmount.abs())} (${growthPercentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: isPositive ? ThemeHelper.successColor : ThemeHelper.errorColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'vs ${_getPreviousLabel()}',
            style: ThemeHelper.captionStyle(context),
          ),
        ],
      ),
    );
  }

  String _getCurrentLabel() {
    switch (selectedPeriod) {
      case 'This Month':
        final now = DateTime.now();
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[now.month - 1]}-${now.year.toString().substring(2)}';
      case 'Last Month':
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[lastMonth.month - 1]}-${lastMonth.year.toString().substring(2)}';
      case 'Last Year':
        final now = DateTime.now();
        final lastYear = DateTime(now.year , now.month);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[lastYear.month - 1]}-${lastYear.year.toString().substring(2)}';
      case 'YTD':
        return 'CY';
      default:
        return 'Current';
    }
  }

  String _getPreviousLabel() {
    switch (selectedPeriod) {
      case 'This Month':
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[lastMonth.month - 1]}-${lastMonth.year.toString().substring(2)}';
      case 'Last Month':
        final now = DateTime.now();
        final twoMonthsAgo = DateTime(now.year, now.month - 2);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[twoMonthsAgo.month - 1]}-${twoMonthsAgo.year.toString().substring(2)}';
      case 'Last Year':
        final now = DateTime.now();
        final twoYearsAgo = DateTime(now.year - 1, now.month);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[twoYearsAgo.month - 1]}-${twoYearsAgo.year.toString().substring(2)}';
      case 'YTD':
        return 'LY';
      default:
        return 'Previous';
    }
  }

  Widget _buildCustomDatePicker() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0),
      child: GlassContainer(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Select Date Range for YTD',
                    style: ThemeHelper.bodyStyle(context),
                  ),
                ],
              ),

              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectFromDate(),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ThemeHelper.glassBackground(context),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ThemeHelper.borderColor(context),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: ThemeHelper.subtleTextColor(context),
                              size: 14,
                            ),
                            SizedBox(width: 2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'From',
                                    style: ThemeHelper.smallStyle(context),
                                  ),
                                  Text(
                                    fromDate != null
                                        ? '${fromDate!.day}/${fromDate!.month}/${fromDate!.year}'
                                        : 'Select',
                                    style: TextStyle(
                                      color: fromDate != null
                                          ? ThemeHelper.textColor(context)
                                          : ThemeHelper.subtleTextColor(context),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectToDate(),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ThemeHelper.glassBackground(context),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ThemeHelper.borderColor(context),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: ThemeHelper.subtleTextColor(context),
                              size: 14,
                            ),
                            SizedBox(width: 2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'To',
                                    style: ThemeHelper.smallStyle(context),
                                  ),
                                  Text(
                                    toDate != null
                                        ? '${toDate!.day}/${toDate!.month}/${toDate!.year}'
                                        : 'Select',
                                    style: TextStyle(
                                      color: toDate != null
                                          ? ThemeHelper.textColor(context)
                                          : ThemeHelper.subtleTextColor(context),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  ElevatedButton(
                    onPressed: (fromDate != null && toDate != null) ? _saveDateRange : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (fromDate != null && toDate != null)
                          ? Theme.of(context).primaryColor
                          : ThemeHelper.glassBackground(context),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.save,
                          color: (fromDate != null && toDate != null)
                              ? Colors.white
                              : ThemeHelper.subtleTextColor(context),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Apply',
                          style: TextStyle(
                            color: (fromDate != null && toDate != null)
                                ? Colors.white
                                : ThemeHelper.subtleTextColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (fromDate != null && toDate != null && toDate!.isBefore(fromDate!)) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ThemeHelper.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: ThemeHelper.errorColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: ThemeHelper.errorColor,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'To Date must be after From Date',
                        style: TextStyle(
                          color: ThemeHelper.errorColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: ThemeHelper.surfaceColor(context),
              onSurface: ThemeHelper.textColor(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != fromDate) {
      setState(() {
        fromDate = picked;
        if (toDate != null && toDate!.isBefore(picked)) {
          toDate = null;
        }
      });
    }
  }

  Future<void> _selectToDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? (fromDate ?? DateTime.now()),
      firstDate: fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: ThemeHelper.surfaceColor(context),
              onSurface: ThemeHelper.textColor(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != toDate) {
      setState(() {
        toDate = picked;
      });
    }
  }

  void _saveDateRange() {
    if (fromDate != null && toDate != null && !toDate!.isBefore(fromDate!)) {
      _fetchSalesData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Date range saved: ${fromDate!.day}/${fromDate!.month}/${fromDate!.year} - ${toDate!.day}/${toDate!.month}/${toDate!.year}',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: ThemeHelper.successColor.withOpacity(0.8),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Map<String, double> _calculateComparisonTotals() {
    if (_salesData.isEmpty) return {'current': 0.0, 'previous': 0.0};

    double currentTotal = _salesData.fold(0.0, (sum, item) {
      double current = double.tryParse(item['Current']?.toString() ?? '0') ?? 0.0;
      return sum + current;
    });

    double previousTotal = _salesData.fold(0.0, (sum, item) {
      double previous = double.tryParse(item['Previous']?.toString() ?? '0') ?? 0.0;
      return sum + previous;
    });

    return {'current': currentTotal, 'previous': previousTotal};
  }

  Widget _buildBottomTotalsBar() {
    Map<String, double> totals = _calculateComparisonTotals();
    double currentTotal = totals['current']!;
    double previousTotal = totals['previous']!;
    double totalPercentage = _calculatePercentage(currentTotal, previousTotal);
    bool isPositive = totalPercentage >= 0;

    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.calculate,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Total: ',
              style: ThemeHelper.captionStyle(context),
            ),
            Text(
              '₹${_formatAmount(previousTotal)}',
              style: ThemeHelper.captionStyle(context),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_forward,
              color: ThemeHelper.subtleTextColor(context),
              size: 14,
            ),
            SizedBox(width: 6),
            Text(
              '₹${_formatAmount(currentTotal)}',
              style: ThemeHelper.bodyStyle(context),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPositive
                    ? ThemeHelper.successColor.withOpacity(0.2)
                    : ThemeHelper.errorColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isPositive
                      ? ThemeHelper.successColor.withOpacity(0.4)
                      : ThemeHelper.errorColor.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? ThemeHelper.successColor : ThemeHelper.errorColor,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${totalPercentage.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isPositive ? ThemeHelper.successColor : ThemeHelper.errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculatePercentage(dynamic current, dynamic previous) {
    double currentVal = double.tryParse(current?.toString() ?? '0') ?? 0.0;
    double previousVal = double.tryParse(previous?.toString() ?? '0') ?? 0.0;

    if (previousVal == 0) return 0.0;
    return ((currentVal - previousVal) / previousVal) * 100;
  }
}