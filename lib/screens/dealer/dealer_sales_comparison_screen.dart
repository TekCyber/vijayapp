// lib/views/dealer/dealer_sales_comparison_screen.dart - Refactored with DataServices
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/common_dropdowns.dart';

import '../../models/search_filter_models.dart';
import 'data_service.dart';
import 'menu_navigator.dart';
import '../../services/common_data_service.dart';

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
  String selectedCategory = 'Sub Group 2';
  String? selectedBrand;

  DateTime? fromDate;
  DateTime? toDate;
  bool isDatePickerVisible = false;

  final List<String> periodOptions = ['This Month', 'Last Month', 'Last Year', 'YTD'];
  final List<String> categoryOptions = ['Sub Group 2', 'Grade', 'Material Group'];
  List<String> brandOptions = [];
  bool isLoadingBrands = true;

  List<Map<String, dynamic>> _salesData = [];
  bool _isLoadingSales = true;
  String _errorMessageSales = '';

  final Map<String, bool> _expandedBrands = {};
  final Map<String, String?> _brandIcons = {}; // Cache for brand icons

  // DataServices instance
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

  // Load brands from API
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
      // Fetch sales data after brands are loaded
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
    // Don't fetch if brands are still loading or no brand selected
    if (isLoadingBrands || selectedBrand == null) {
      return;
    }

    // For YTD, don't fetch if dates are not selected
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
      // Pass "%" for brand if "All Brands" is selected
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
          _loadBrandIcons(); // Load icons for all brands
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
      _expandedBrands[brand] = false; // Keep collapsed by default
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
      title: "Sales Analytics",
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

          // Fixed bottom summary bar
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
                color: Color(0xFF4F46E5),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading sales data...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Analyzing sales comparison',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Failed to load sales data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessageSales,
              style: TextStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchSalesData,
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4F46E5),
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
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.analytics_outlined,
                color: Colors.blue,
                size: 48,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'No Sales Data Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              selectedPeriod == 'YTD'
                  ? 'Please select a date range to view YTD data'
                  : 'No data available for the selected filters',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group sales data by Brand
    Map<String, List<Map<String, dynamic>>> groupedByBrand = {};
    for (var item in _salesData) {
      String brand = item['Brand']?.toString() ?? 'Unknown';
      if (!groupedByBrand.containsKey(brand)) {
        groupedByBrand[brand] = [];
      }
      groupedByBrand[brand]!.add(item);
    }

    // Sort brands by total sales (Current + Previous)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleColor = isDark ? Colors.white70 : Colors.black54;

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
                // Top row with icon, brand name and expand button
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    setState(() {
                      _expandedBrands[brandName] = !isExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      // Brand Icon
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildBrandIcon(brandName),
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          brandName,
                          style: TextStyle(
                            color: isDark ? Colors.blueAccent : Colors.blue.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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
                          color: isDark ? Colors.blueAccent : Colors.blue.shade700,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Show totals when collapsed
                if (!isExpanded) ...[
                  const SizedBox(height: 12),
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
                          '${_getCurrentLabel()}: ₹${_formatAmount(brandCurrentTotal)}',
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
                          '${_getPreviousLabel()}: ₹${_formatAmount(brandPreviousTotal)}',
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

            if (isExpanded) ...[
              const SizedBox(height: 16),


              // Header Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        "Item",
                        style: TextStyle(
                          color: subtleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _getCurrentLabel(),
                        style: TextStyle(
                          color: subtleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _getPreviousLabel(),
                        style: TextStyle(
                          color: subtleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
                            color: Colors.green,
                            size: 12,
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.arrow_downward,
                            color: Colors.red,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: isDark ? Colors.white24 : Colors.black26, thickness: 1, height: 16),

              // Items
              ...brandData.map((item) {
                String name = item['Name']?.toString() ?? 'Unknown';
                double current = double.tryParse(item['Current']?.toString() ?? '0') ?? 0.0;
                double previous = double.tryParse(item['Previous']?.toString() ?? '0') ?? 0.0;

                return _buildTableRow(name, current, previous);
              }).toList(),

              const SizedBox(height: 12),
              Divider(color: isDark ? Colors.white24 : Colors.black26, thickness: 1, height: 16),

              // Brand Total Row
              _buildBrandTotalRow("Brand Total", brandCurrentTotal, brandPreviousTotal),

              const SizedBox(height: 8),
              _buildGrowthIndicator(brandCurrentTotal, brandPreviousTotal),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrandIcon(String brandName) {
    // Get brand icon from cache
    String? base64Icon = _brandIcons[brandName];

    if (base64Icon != null && base64Icon.isNotEmpty) {
      try {
        String base64String = base64Icon.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 56,
          height: 20,
          fit: BoxFit.contain,
        );
      } catch (e) {
        print('Error decoding icon for $brandName: $e');
        return Icon(
          Icons.business_center,
          color: Color(0xFF4F46E5),
          size: 20,
        );
      }
    }

    // Show loading indicator while fetching, or default icon
    return Icon(
      Icons.business_center,
      color: Color(0xFF4F46E5),
      size: 20,
    );
  }

  Widget _buildTableRow(String label, double currentAmount, double previousAmount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    double percentage = _calculatePercentage(currentAmount, previousAmount);
    bool isPositive = percentage >= 0;
    bool hasChange = percentage != 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        children: [
          // Name column - with tooltip
          Expanded(
            flex: 5,
            child: Tooltip(
              message: label,
              preferBelow: true,
              waitDuration: Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
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
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          SizedBox(width: 4),
          // Current amount column
          Expanded(
            flex: 2,
            child: Text(
              '₹${_formatAmount(currentAmount)}',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 4),
          // Previous amount column
          Expanded(
            flex: 2,
            child: Text(
              '₹${_formatAmount(previousAmount)}',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 4),
          // Percentage column - NO ARROW, just colored text
          Container(
            width: 60,
            alignment: Alignment.centerRight,
            child: Text(
              hasChange ? '${percentage.abs().toStringAsFixed(1)}%' : '-',
              style: TextStyle(
                color: hasChange
                    ? (isPositive ? Colors.green : Colors.red)
                    : Colors.grey,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    double percentage = _calculatePercentage(currentAmount, previousAmount);
    bool isPositive = percentage >= 0;
    bool hasChange = percentage != 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              '₹${_formatAmount(currentAmount)}',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              '₹${_formatAmount(previousAmount)}',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 4),
          // Percentage column - NO ARROW, just colored text
          Container(
            width: 60,
            alignment: Alignment.centerRight,
            child: Text(
              hasChange ? '${percentage.abs().toStringAsFixed(1)}%' : '-',
              style: TextStyle(
                color: hasChange
                    ? (isPositive ? Colors.green : Colors.red)
                    : Colors.grey,
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
            '${isPositive ? '+' : ''}₹${_formatAmount(growthAmount.abs())} (${growthPercentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'vs ${_getPreviousLabel()}',
            style: TextStyle(
              color: subtleColor,
              fontSize: 12,
            ),
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
      // Show current month from last year (e.g., Jun-24)
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
      // Show same month from 2 years ago (e.g., Jun-23)
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
                    color: Color(0xFF4F46E5),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Select Date Range for YTD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                              size: 14,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'From',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    fromDate != null
                                        ? '${fromDate!.day}/${fromDate!.month}/${fromDate!.year}'
                                        : 'Select',
                                    style: TextStyle(
                                      color: fromDate != null ? Colors.white : Colors.white60,
                                      fontSize: 12,
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
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                              size: 14,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'To',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    toDate != null
                                        ? '${toDate!.day}/${toDate!.month}/${toDate!.year}'
                                        : 'Select',
                                    style: TextStyle(
                                      color: toDate != null ? Colors.white : Colors.white60,
                                      fontSize: 12,
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
                          ? Color(0xFF4F46E5)
                          : Colors.grey.withOpacity(0.3),
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
                          color: (fromDate != null && toDate != null) ? Colors.white : Colors.grey,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Apply',
                          style: TextStyle(
                            color: (fromDate != null && toDate != null) ? Colors.white : Colors.grey,
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'To Date must be after From Date',
                        style: TextStyle(
                          color: Colors.red,
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
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              surface: Color(0xFF1F2937),
              onSurface: Colors.white,
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
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              surface: Color(0xFF1F2937),
              onSurface: Colors.white,
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
          backgroundColor: Colors.green.withOpacity(0.8),
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
              color: Color(0xFF4F46E5),
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Total: ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '₹${_formatAmount(previousTotal)}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_forward,
              color: Colors.white60,
              size: 14,
            ),
            SizedBox(width: 6),
            Text(
              '₹${_formatAmount(currentTotal)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPositive
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isPositive
                      ? Colors.green.withOpacity(0.4)
                      : Colors.red.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${totalPercentage.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
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