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
  int _currentTabIndex = 0; // 0: All Schemes (Points, Basket, Value & Quantity), 1: Historic
  List<Map<String, dynamic>> _schemeData = [];
  List<Map<String, dynamic>> _pointsSchemeData = [];
  List<Map<String, dynamic>> _basketSchemeData = [];
  List<Map<String, dynamic>> _valueSchemeData = [];
  List<Map<String, dynamic>> _quantitySchemeData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int selectedMenuIndex = 0;
  bool _showAllSchemes = false;
  Key _dashboardKey = UniqueKey();
  Map<String, bool> _expandedYears = {}; // Track which years are expanded

  @override
  void initState() {
    super.initState();
    print("🚀 DealerSchemeScreen initialized");
    _fetchSchemeData();
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  List<SearchFilterOption> _getSearchFilters() {
    // No filters needed for this screen
    return [];
  }

  void _handleFilterChanged(Map<String, dynamic> filters) {
    print('DealerSchemeScreen: Received filters: $filters');
  }

  // Replace ONLY the _fetchSchemeData method in dealer/dealer_scheme_screen.dart

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

      ApiService apiService = ApiService();

      if (_currentTabIndex == 1) {
        // Historic view - keep as is (single call)
        print("📜 Fetching historic schemes for dealer: ${widget.title}");
        Map<String, dynamic> payload = {
          "sqlKey": "GET_ALL_SCHEME_HISTORIC_BY_DEALER",
          "dealername": widget.title,
        };

        final response = await apiService.request(payload: payload);

        if (response.isSuccess && response.data != null) {
          List<Map<String, dynamic>> fetchedData =
          List<Map<String, dynamic>>.from(response.data!);

          setState(() {
            _schemeData = fetchedData;
            _isLoading = false;
          });

          print("✅ Fetched ${fetchedData.length} historic schemes");
        } else {
          throw Exception(response.error ?? 'Failed to fetch historic scheme data');
        }
      } else {
        // All Schemes view - PARALLEL FETCHING 🚀
        print("🚀 Fetching Points, Basket, Value, and Quantity schemes in PARALLEL for dealer: ${widget.title}");

        final startTime = DateTime.now(); // Track performance

        // Create all payloads
        final pointsPayload = {
          "sqlKey": "GET_POINTS_SCHEME_DETAILS_BY_DEALER",
          "dealername": widget.title,
        };

        final basketPayload = {
          "sqlKey": "GET_BASKET_SCHEME_DETAILS_BY_DEALER",
          "dealername": widget.title,
        };

        final valuePayload = {
          "sqlKey": "GET_VALUE_SCHEME_DETAILS_BY_DEALER",
          "dealername": widget.title,
        };

        final quantityPayload = {
          "sqlKey": "GET_QUANTITY_SCHEME_DETAILS_BY_DEALER",
          "dealername": widget.title,
        };

        // 🔥 Execute ALL FOUR API calls in PARALLEL using Future.wait
        final results = await Future.wait([
          apiService.request(payload: pointsPayload),
          apiService.request(payload: basketPayload),
          apiService.request(payload: valuePayload),
          apiService.request(payload: quantityPayload),
        ]);

        final duration = DateTime.now().difference(startTime);
        print("⏱️ All 4 API calls completed in ${duration.inMilliseconds}ms");

        // Extract data from responses
        List<Map<String, dynamic>> pointsData = [];
        List<Map<String, dynamic>> basketData = [];
        List<Map<String, dynamic>> valueData = [];
        List<Map<String, dynamic>> quantityData = [];

        // Process Points response (index 0)
        if (results[0].isSuccess && results[0].data != null) {
          pointsData = List<Map<String, dynamic>>.from(results[0].data!);
          print("✅ Fetched ${pointsData.length} points schemes");
        } else {
          print("⚠️ Points scheme fetch failed: ${results[0].error}");
        }

        // Process Basket response (index 1)
        if (results[1].isSuccess && results[1].data != null) {
          basketData = List<Map<String, dynamic>>.from(results[1].data!);
          print("✅ Fetched ${basketData.length} basket schemes");
        } else {
          print("⚠️ Basket scheme fetch failed: ${results[1].error}");
        }

        // Process Value response (index 2)
        if (results[2].isSuccess && results[2].data != null) {
          valueData = List<Map<String, dynamic>>.from(results[2].data!);
          print("✅ Fetched ${valueData.length} value schemes");
        } else {
          print("⚠️ Value scheme fetch failed: ${results[2].error}");
        }

        // Process Quantity response (index 3)
        if (results[3].isSuccess && results[3].data != null) {
          quantityData = List<Map<String, dynamic>>.from(results[3].data!);
          print("✅ Fetched ${quantityData.length} quantity schemes");
        } else {
          print("⚠️ Quantity scheme fetch failed: ${results[3].error}");
        }

        setState(() {
          _pointsSchemeData = pointsData;
          _basketSchemeData = basketData;
          _valueSchemeData = valueData;
          _quantitySchemeData = quantityData;
          // Combine all four for display
          _schemeData = [...pointsData, ...basketData, ...valueData, ...quantityData];
          _isLoading = false;
        });

        print("✅ Total schemes loaded in PARALLEL: ${_schemeData.length}");
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
    String title = _currentTabIndex == 1 ? 'Historic Schemes' : 'All Schemes';

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
                    _buildTabButton('All Schemes', 0),
                    const SizedBox(width: 8),
                    _buildTabButton('Historic', 1),
                    const Spacer(),
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

          // Fixed bottom summary bar (only for Historic tab)
          if (_currentTabIndex == 1)
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
    // Remove this button for historic tab as we now have expand/collapse per year
    return SizedBox.shrink();
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

  // Get financial year from date (Apr-Mar format)
  String _getFinancialYear(dynamic date) {
    if (date == null) return 'Unknown';

    try {
      String dateStr = date.toString().trim();
      DateTime parsedDate;

      // Parse YYYY-MM-DD format (e.g., "2025-08-01")
      if (dateStr.contains('-') && dateStr.length >= 10 && dateStr.indexOf('-') > 2) {
        parsedDate = DateTime.parse(dateStr.substring(0, 10));
      }
      // Parse DD-MM-YY format (e.g., "01-08-25")
      else if (dateStr.contains('-') && dateStr.length >= 8 && dateStr.length <= 10) {
        List<String> parts = dateStr.split('-');
        if (parts.length >= 3) {
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);

          // Handle 2-digit year (assume 2000s for years 00-99)
          if (year < 100) {
            year += 2000;
          }

          parsedDate = DateTime(year, month, day);
        } else {
          return 'Unknown';
        }
      } else {
        return 'Unknown';
      }

      int year = parsedDate.year;
      int month = parsedDate.month;

      // Financial year runs from April to March
      if (month >= 4) {
        return 'FY ${year}-${(year + 1).toString().substring(2)}';
      } else {
        return 'FY ${year - 1}-${year.toString().substring(2)}';
      }
    } catch (e) {
      print('Error parsing financial year from date: $date, error: $e');
      return 'Unknown';
    }
  }

  // Group historic data by financial year
  Map<String, List<Map<String, dynamic>>> _groupByFinancialYear() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var scheme in _schemeData) {
      String fy = _getFinancialYear(scheme['start_date']);
      if (!grouped.containsKey(fy)) {
        grouped[fy] = [];
      }
      grouped[fy]!.add(scheme);
    }

    // Sort by financial year (descending - most recent first)
    var sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    Map<String, List<Map<String, dynamic>>> sortedGrouped = {};
    for (var key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
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
              _currentTabIndex == 1
                  ? 'No historic data available'
                  : 'No scheme data available',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // For All Schemes tab, display Points, Basket, Value, and Quantity schemes
    if (_currentTabIndex == 0) {
      return RefreshIndicator(
        onRefresh: _fetchSchemeData,
        child: ListView(
          padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 20),
          children: [
            // Points Scheme Section
            if (_pointsSchemeData.isNotEmpty) ...[
              ..._pointsSchemeData.map((data) => _buildPointsSchemeCard(data)),
            ],

            // Basket Scheme Section
            if (_basketSchemeData.isNotEmpty) ...[
              ..._basketSchemeData.map((data) => _buildBasketSchemeCard(data)),
            ],

            // Value Scheme Section
            if (_valueSchemeData.isNotEmpty) ...[
              ..._valueSchemeData.map((data) => _buildValueSchemeCard(data)),
            ],

            // Quantity Scheme Section
            if (_quantitySchemeData.isNotEmpty) ...[
              ..._quantitySchemeData.map((data) => _buildQuantitySchemeCard(data)),
            ],
          ],
        ),
      );
    }

    // For Historic tab, use pagination
    int itemCount = _showAllSchemes
        ? filteredData.length
        : (filteredData.length > 5 ? 5 : filteredData.length);

    return RefreshIndicator(
      onRefresh: _fetchSchemeData,
      child: _buildHistoricGroupedView(),
    );
  }

  // Build historic view grouped by financial year
  Widget _buildHistoricGroupedView() {
    Map<String, List<Map<String, dynamic>>> groupedData = _groupByFinancialYear();

    if (groupedData.isEmpty) {
      return Center(
        child: Text(
          'No historic data available',
          style: TextStyle(color: Colors.white60, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 100),
      itemCount: groupedData.length,
      itemBuilder: (context, index) {
        String financialYear = groupedData.keys.elementAt(index);
        List<Map<String, dynamic>> schemes = groupedData[financialYear]!;
        bool isExpanded = _expandedYears[financialYear] ?? false;

        return _buildFinancialYearCard(financialYear, schemes, isExpanded);
      },
    );
  }

  // Build a card for each financial year
  Widget _buildFinancialYearCard(String financialYear, List<Map<String, dynamic>> schemes, bool isExpanded) {
    // Calculate totals for this financial year
    double yearTotal = 0.0;
    double yearCN = 0.0;

    for (var scheme in schemes) {
      if (scheme['TotalAmount'] != null) {
        if (scheme['TotalAmount'] is num) {
          yearTotal += scheme['TotalAmount'].toDouble();
        } else if (scheme['TotalAmount'] is String) {
          yearTotal += double.tryParse(scheme['TotalAmount']) ?? 0.0;
        }
      }

      if (scheme['CN/VALUE'] != null) {
        if (scheme['CN/VALUE'] is num) {
          yearCN += scheme['CN/VALUE'].toDouble();
        } else if (scheme['CN/VALUE'] is String) {
          yearCN += double.tryParse(scheme['CN/VALUE']) ?? 0.0;
        }
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blueAccent.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Financial Year Header (Clickable)
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedYears[financialYear] = !isExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E3A5F),
                    Color(0xFF2A4A6F),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: isExpanded
                    ? BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                )
                    : BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Expand/Collapse Icon
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                  SizedBox(width: 12),

                  // Financial Year Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          financialYear,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${schemes.length} scheme${schemes.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Year Totals
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.currency_rupee,
                            color: Colors.blue,
                            size: 14,
                          ),
                          SizedBox(width: 2),
                          Text(
                            _formatAmount(yearTotal),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            color: Colors.green,
                            size: 14,
                          ),
                          SizedBox(width: 2),
                          Text(
                            _formatAmount(yearCN),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content - Scheme Cards
          if (isExpanded)
            Container(
              padding: EdgeInsets.all(12),
              child: Column(
                children: schemes.map((scheme) =>
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _buildHistoricSchemeCardCompact(scheme),
                    )
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Compact version of historic scheme card for use inside financial year cards
  Widget _buildHistoricSchemeCardCompact(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1A2F4F).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
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

  // Card for Points scheme
  Widget _buildPointsSchemeCard(Map<String, dynamic> data) {
    double totalEarnedPoints = 0.0;
    double pointsNeeded = 0.0;

    // Parse points values
    if (data['total_earned_points'] != null) {
      if (data['total_earned_points'] is num) {
        totalEarnedPoints = data['total_earned_points'].toDouble();
      } else if (data['total_earned_points'] is String) {
        totalEarnedPoints = double.tryParse(data['total_earned_points']) ?? 0.0;
      }
    }

    if (data['points_needed_for_next_tier'] != null) {
      if (data['points_needed_for_next_tier'] is num) {
        pointsNeeded = data['points_needed_for_next_tier'].toDouble();
      } else if (data['points_needed_for_next_tier'] is String) {
        pointsNeeded = double.tryParse(data['points_needed_for_next_tier']) ?? 0.0;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with scheme name and date range
            Text(
              data['schemeName'] ?? 'Points Scheme',
              style: TextStyle(
                color: Colors.purpleAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              _formatDateRange(data['start_date'], data['end_date']),
              style: TextStyle(
                color: Colors.purpleAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 12),

            // Points and Sales Info - Row 1
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "Total",
                    _formatAmount(data['total_sales']),
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    "Current Points",
                    totalEarnedPoints.toStringAsFixed(2),
                    Colors.orange,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // CN/Value and Balance Info - Row 2
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "CN/Value/Gift",
                    data['current_tier_benefit']?.toString() ?? '0',
                    Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    "Balance to Next",
                    pointsNeeded.toStringAsFixed(2),
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
              data['SCHEME_NAME'] ?? data['schemeName'] ?? 'Basket Scheme',
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

  // Card for Value scheme
  Widget _buildValueSchemeCard(Map<String, dynamic> data) {
    double totalSum = 0.0;
    double currentAchievedSlab = 0.0;
    double amountToNextSlab = 0.0;

    // Parse value scheme data - using correct field names from API
    if (data['total_sum'] != null) {
      if (data['total_sum'] is num) {
        totalSum = data['total_sum'].toDouble();
      } else if (data['total_sum'] is String) {
        totalSum = double.tryParse(data['total_sum']) ?? 0.0;
      }
    }

    if (data['current_achieved_slab'] != null) {
      if (data['current_achieved_slab'] is num) {
        currentAchievedSlab = data['current_achieved_slab'].toDouble();
      } else if (data['current_achieved_slab'] is String) {
        currentAchievedSlab = double.tryParse(data['current_achieved_slab']) ?? 0.0;
      }
    }

    if (data['amount_to_next_slab'] != null) {
      if (data['amount_to_next_slab'] is num) {
        amountToNextSlab = data['amount_to_next_slab'].toDouble();
      } else if (data['amount_to_next_slab'] is String) {
        amountToNextSlab = double.tryParse(data['amount_to_next_slab']) ?? 0.0;
      }
    }

    String currentCnValue = data['current_cnValue']?.toString() ?? '0';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with scheme name and date range
            Text(
              data['schemeName'] ?? 'Value Scheme',
              style: TextStyle(
                color: Colors.tealAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              _formatDateRange(data['start_date'], data['end_date']),
              style: TextStyle(
                color: Colors.tealAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 12),

            // Value Info - Row 1
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "Total",
                    _formatAmount(totalSum),
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    "Current Slab",
                    _formatAmount(currentAchievedSlab),
                    Colors.orange,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // CN/Value and Balance Info - Row 2
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "CN Value",
                    currentCnValue,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    "Balance to Next",
                    _formatAmount(amountToNextSlab),
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

  // Card for Quantity scheme
  Widget _buildQuantitySchemeCard(Map<String, dynamic> data) {
    double totalQty = 0.0;
    double qtyToNextSlab = 0.0;

    // Parse quantity values
    if (data['total_qty'] != null) {
      if (data['total_qty'] is num) {
        totalQty = data['total_qty'].toDouble();
      } else if (data['total_qty'] is String) {
        totalQty = double.tryParse(data['total_qty']) ?? 0.0;
      }
    }

    if (data['qty_to_next_slab'] != null) {
      if (data['qty_to_next_slab'] is num) {
        qtyToNextSlab = data['qty_to_next_slab'].toDouble();
      } else if (data['qty_to_next_slab'] is String) {
        qtyToNextSlab = double.tryParse(data['qty_to_next_slab']) ?? 0.0;
      }
    }

    int currentSlab = data['current_achieved_slab'] ?? 0;
    String currentCnValue = data['current_cnValue']?.toString() ?? '0';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with scheme name and date range
            Text(
              data['schemeName'] ?? 'Quantity Scheme',
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              _formatDateRange(data['start_date'], data['end_date']),
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 12),

            // Quantity Info - Row 1
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "Total Quantity",
                    totalQty.toStringAsFixed(2),
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    "Current Slab",
                    currentSlab.toString(),
                    Colors.orange,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // CN/Value and Balance Info - Row 2
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfo(
                    "CN Value",
                    currentCnValue,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInfo(
                    "Qty to Next",
                    qtyToNextSlab.toStringAsFixed(2),
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
            maxLines: 2,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
    List<Map<String, dynamic>> filteredData = _getFilteredData();

    // For Historic tab, show only amounts (no scheme count)
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
}