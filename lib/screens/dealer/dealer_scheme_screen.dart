// lib/screens/dealer/dealer_scheme_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/common_dropdowns.dart';
import '../../services/api_service.dart';
import '../../models/search_filter_models.dart';
import '../../utils/formatters.dart';
import 'menu_navigator.dart';

class DealerSchemeScreen extends StatefulWidget {
  final String title; // Dealer name

  DealerSchemeScreen({required this.title});

  @override
  _DealerSchemeScreenState createState() => _DealerSchemeScreenState();
}

class _DealerSchemeScreenState extends State<DealerSchemeScreen> {
  int _currentTabIndex = 0; // 0: This Month, 1: Basket, 2: Historic
  List<Map<String, dynamic>> _schemeData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _selectedBrand;
  int selectedMenuIndex = 0;
  bool _showAllSchemes = false;
  Key _dashboardKey = UniqueKey();

  List<String> _brands = [];

  @override
  void initState() {
    super.initState();
    print("🚀 DealerSchemeScreen initialized");
    _fetchBrandList();
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  List<SearchFilterOption> _getSearchFilters() {
    // Hide filters in Basket and Historic view
    if (_currentTabIndex == 1 || _currentTabIndex == 2) {
      return [];
    }

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
    ];
  }

  void _handleFilterChanged(Map<String, dynamic> filters) {
    print('DealerSchemeScreen: Received filters: $filters');
  }

  void _onBrandChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedBrand = newValue;
      });
      _fetchSchemeData();
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
        "sqlKey": "GET_ALL_BRANDS_BY_EXC",
        "executive": username
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData =
        List<Map<String, dynamic>>.from(response.data!);

        List<String> brandList = fetchedData
            .map((e) => e['Brand']?.toString() ?? '')
            .where((brand) => brand.isNotEmpty)
            .toSet()
            .toList();

        setState(() {
          _brands = ['All Brands', ...brandList];
          _selectedBrand = _brands.isNotEmpty ? _brands.first : null;
        });

        _fetchSchemeData();
      } else {
        print('Failed to fetch brand list: ${response.error}');
      }
    } catch (e) {
      print('Error fetching brand list: $e');
    }
  }

  Future<void> _fetchSchemeData() async {
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

      Map<String, dynamic> payload;

      if (_currentTabIndex == 2) {
        // Historic view
        print("📜 Fetching historic schemes for dealer: ${widget.title}");
        payload = {
          "sqlKey": "GET_ALL_SCHEME_HISTORIC_BY_DEALER",
          "dealername": widget.title,
        };
      } else if (_currentTabIndex == 1) {
        // Basket view
        print("🧺 Fetching basket scheme for dealer: ${widget.title}");
        payload = {
          "sqlKey": "GET_BASKET_SCHEME_DETAILS",
          "dealername": widget.title,
        };
      } else {
        // This Month view
        print("📅 Fetching current month schemes");
        payload = {
          "sqlKey": "GET_ALL_SCHEME_BY_DEALER",
          "dealername": widget.title,
          "brand": (_selectedBrand == null || _selectedBrand == 'All Brands')
              ? '%'
              : _selectedBrand,
        };
      }

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData =
        List<Map<String, dynamic>>.from(response.data!);

        setState(() {
          _schemeData = fetchedData;
          _isLoading = false;
        });

        print("✅ Fetched ${fetchedData.length} schemes");
      } else {
        throw Exception(response.error ?? 'Failed to fetch scheme data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading scheme data: ${e.toString()}';
      });
      print('❌ Error fetching scheme data: $e');
    }
  }

  void _onTabChanged(int index) {
    print("👆 Tab changed to index: $index");
    setState(() {
      _currentTabIndex = index;
      _showAllSchemes = false;
      _dashboardKey = UniqueKey();
    });
    _fetchSchemeData();
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Schemes';
    if (_currentTabIndex == 1) {
      title = 'Basket Scheme';
    } else if (_currentTabIndex == 2) {
      title = 'Historic Schemes';
    }

    return DashboardLayout(
      key: _dashboardKey,
      title: title,
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

              // Compact Modern Tab Bar with Show All/Hide button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTabButton('This Month', 0),
                    const SizedBox(width: 8),
                    _buildTabButton('Basket', 1),
                    const SizedBox(width: 8),
                    _buildTabButton('Historic', 2),
                    const Spacer(),
                    if (_currentTabIndex != 1) _buildShowAllButton(),
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
          if (_currentTabIndex != 1)
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

    if (totalSchemes <= 5) {
      return SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        print("🔄 Toggle show all schemes: ${!_showAllSchemes}");
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

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () {
        print("🎯 Tab tapped: $label (index: $index)");
        _onTabChanged(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredData() {
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
              _currentTabIndex == 2
                  ? 'No historic data available'
                  : _currentTabIndex == 1
                  ? 'No basket data available'
                  : 'No scheme data available',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // For Basket tab, always show single card (no pagination)
    if (_currentTabIndex == 1) {
      return RefreshIndicator(
        onRefresh: _fetchSchemeData,
        child: ListView(
          padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 20),
          children: [
            _buildBasketSchemeCard(filteredData[0]),
          ],
        ),
      );
    }

    // For other tabs, use pagination
    int itemCount = _showAllSchemes
        ? filteredData.length
        : (filteredData.length > 5 ? 5 : filteredData.length);

    return RefreshIndicator(
      onRefresh: _fetchSchemeData,
      child: ListView.builder(
        padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 100),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return _currentTabIndex == 2
              ? _buildHistoricSchemeCard(filteredData[index])
              : _buildSchemeCard(filteredData[index]);
        },
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    String dateStr = date.toString().trim();

    try {
      // Handle format like "2025-08-01" (YYYY-MM-DD)
      if (dateStr.contains('-') && dateStr.length >= 10) {
        List<String> parts = dateStr.split('-');
        if (parts.length >= 3) {
          int year = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int day = int.parse(parts[2]);

          const monthNames = [
            '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];

          if (month >= 1 && month <= 12) {
            return '${monthNames[month]} $day';
          }
        }
      }

      // Handle format like "01-08-25" (DD-MM-YY)
      if (dateStr.contains('-') && dateStr.length >= 8 && dateStr.length < 10) {
        List<String> parts = dateStr.split('-');
        if (parts.length >= 3) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);

          const monthNames = [
            '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];

          if (month >= 1 && month <= 12) {
            return '${monthNames[month]} $day';
          }
        }
      }
    } catch (e) {
      print('Error formatting date: $e');
    }

    return dateStr;
  }

  String _formatDateRange(dynamic startDate, dynamic endDate) {
    String start = _formatDate(startDate);
    String end = _formatDate(endDate);

    if (start.isEmpty || end.isEmpty) return '';

    List<String> startParts = start.split(' ');
    List<String> endParts = end.split(' ');

    if (startParts.length == 2 && endParts.length == 2) {
      String startMonth = startParts[0];
      String startDay = startParts[1];
      String endMonth = endParts[0];
      String endDay = endParts[1];

      if (startMonth == endMonth) {
        return '[$startMonth $startDay to $endDay]';
      } else {
        return '[$start to $end]';
      }
    }

    return '[$start to $end]';
  }

  // Card for Basket scheme
  Widget _buildBasketSchemeCard(Map<String, dynamic> data) {
    int currentYesCount = data['current_yes_count'] ?? 0;
    int nextYesCount = data['next_yes_count'] ?? 0;
    int balanceToNext = nextYesCount - currentYesCount;

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
            // Header with date range
            Text(
              _formatDateRange(data['start_date'], data['end_date']),
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 12),

            // Compact Info Grid - Row 1
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "Total",
                    _formatAmount(data['total_sum']),
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    "Current Yes Count",
                    currentYesCount.toString(),
                    Colors.orange,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Compact Info Grid - Row 2
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "Yes Value / CN",
                    _formatAmount(data['current_yes_CN']),
                    Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    "Balance to Next",
                    balanceToNext.toString(),
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

  // Card for current month schemes
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  _formatDateRange(data['start_date'], data['end_date']),
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),

            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "Total",
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

  // Card for historic schemes
  Widget _buildHistoricSchemeCard(Map<String, dynamic> data) {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  _formatDateRange(data['start_date'], data['end_date']),
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),

            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "Amount",
                    _formatAmount(data['TotalAmount']),
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    "Gift/CN",
                    _formatAmount(data['CN/VALUE']),
                    Colors.green,
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
    List<Map<String, dynamic>> filteredData = _getFilteredData();

    // For Historic tab, show only amounts (no scheme count)
    if (_currentTabIndex == 2) {
      double totalAmount = 0.0;
      double totalCNValue = 0.0;

      for (var scheme in filteredData) {
        if (scheme['TotalAmount'] != null) {
          if (scheme['TotalAmount'] is num) {
            totalAmount += scheme['TotalAmount'].toDouble();
          } else if (scheme['TotalAmount'] is String) {
            totalAmount += double.tryParse(scheme['TotalAmount']) ?? 0.0;
          }
        }

        if (scheme['CN/VALUE'] != null) {
          if (scheme['CN/VALUE'] is num) {
            totalCNValue += scheme['CN/VALUE'].toDouble();
          } else if (scheme['CN/VALUE'] is String) {
            totalCNValue += double.tryParse(scheme['CN/VALUE']) ?? 0.0;
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
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.currency_rupee,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Total Amount: ${_formatAmount(totalAmount)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Total Gift/CN: ${_formatAmount(totalCNValue)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
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

    // For other tabs, show full summary with scheme count
    int totalSchemes = filteredData.length;
    double totalAmount = 0.0;

    for (var scheme in filteredData) {
      if (scheme['TotalAmount'] != null) {
        if (scheme['TotalAmount'] is num) {
          totalAmount += scheme['TotalAmount'].toDouble();
        } else if (scheme['TotalAmount'] is String) {
          totalAmount += double.tryParse(scheme['TotalAmount']) ?? 0.0;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.currency_rupee,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Total Amount: ${_formatAmount(totalAmount)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
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