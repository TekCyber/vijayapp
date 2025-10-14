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
  String? _selectedScheme;
  int selectedMenuIndex = 0;
  bool _showAllSchemes = false; // Track if showing all schemes

  List<String> _routes = [];
  List<String> _schemes = [];
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _fetchRouteList();
    _fetchSchemeList();
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
        key: 'schemeFilter',
        widget: BrandDropdownFilter(
          brands: _schemes,
          selectedBrand: _selectedScheme,
          label: "Filter by Scheme",
          onChanged: _onSchemeChanged,
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
      });
      _fetchSchemeData();
    }
  }

  void _onSchemeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedScheme = newValue;
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

  Future<void> _fetchSchemeList() async {
    try {
      List<String> schemeList = await _dataService.getAllSchemeNames();

      setState(() {
        _schemes = ['All Schemes', ...schemeList];
        _selectedScheme = _schemes.isNotEmpty ? _schemes.first : null;
      });
    } catch (e) {
      print('Error fetching scheme list: $e');
    }
  }

  Future<void> _fetchSchemeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Determine route and scheme parameters
      String routeParam = (_selectedRoute == null || _selectedRoute == 'All Routes')
          ? '%'
          : _selectedRoute!;

      String schemeParam = (_selectedScheme == null || _selectedScheme == 'All Schemes')
          ? '%'
          : _selectedScheme!;

      List<Map<String, dynamic>> fetchedData = await _dataService.getSchemesByExecutive(
        route: routeParam,
        schemeName: schemeParam,
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

              // Show All/Hide button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Spacer(),
                    _buildShowAllButton(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: _buildSchemeContent(),
              ),
            ],
          ),

          // Fixed bottom summary bar
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

  Widget _buildShowAllButton() {
    List<Map<String, dynamic>> filteredData = _getFilteredData();
    int totalSchemes = filteredData.length;

    // Only show button if there are more than 5 schemes
    if (totalSchemes <= 5) {
      return SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showAllSchemes = !_showAllSchemes;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blueAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          _showAllSchemes ? Icons.remove : Icons.add,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredData() {
    // Data is already filtered by API call based on dropdowns
    return _schemeData;
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

    List<Map<String, dynamic>> filteredData = _getFilteredData();

    if (filteredData.isEmpty) {
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

    // Determine how many schemes to show
    int itemCount = _showAllSchemes ? filteredData.length : (filteredData.length > 5 ? 5 : filteredData.length);

    return RefreshIndicator(
      onRefresh: _fetchSchemeData,
      child: ListView.builder(
        padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 100),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return _buildSchemeCard(filteredData[index]);
        },
      ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with dealer name and scheme name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['dealername'] ?? '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  data['SCHEME_NAME'] ?? '',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '${_formatDate(data['start_date'])} - ${_formatDate(data['end_date'])}',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Compact Info Grid
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "Total Amount",
                    _formatAmount(data['TotalAmount']),
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    "Current Slab",
                    data['Current_Slab'] ?? '-',
                    Colors.orange,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "Eligible CN/Value",
                    _formatAmount(data['CN/VALUE']),
                    Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    "Balance to Next",
                    _formatAmount(data['Amount_To_Next_Slab']),
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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

    // Use the Formatters utility class
    return Formatters.formatCurrency(value.abs());
  }

  Widget _buildBottomSummaryBar() {
    List<Map<String, dynamic>> filteredData = _getFilteredData();
    int totalSchemes = filteredData.length;

    // Calculate total amount
    double totalAmount = 0.0;
    for (var scheme in filteredData) {
      var amount = scheme['TotalAmount'];
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: Colors.blueAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Total Schemes: $totalSchemes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 20,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.account_balance_wallet,
              color: Colors.green,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Amount: ${_formatAmount(totalAmount)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}