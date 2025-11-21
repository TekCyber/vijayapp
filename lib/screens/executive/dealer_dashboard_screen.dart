// lib/views/dealer_dashboard_screen.dart - THEME-AWARE VERSION
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/sales_data.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/glass_container.dart';
import '../../theme/theme_helpers.dart';
import 'menu_navigator.dart';


class DealerDashboardScreen extends StatefulWidget {
  @override
  _DealerDashboardScreenState createState() => _DealerDashboardScreenState();
}

class _DealerDashboardScreenState extends State<DealerDashboardScreen> {
  List<SalesData> yesterdayData = [];
  List<MonthlyData> monthlyData = [];
  bool _isLoadingYesterday = true;
  bool _isLoadingMonthly = true;
  bool _isLoadingDealerCount = true;
  bool _isLoadingMonthlyDealerCount = true;
  String _errorMessageYesterday = '';
  String _errorMessageMonthly = '';
  int _dealerCount = 0;
  int _monthlydealerCount = 0;
  String _username = 'Dealer Dashboard';
  String? _name = "Salesman";
  int selectedMenuIndex = 0;

  // Predefined 20 bright colors (top to bottom order) - kept as semantic colors
  final List<Color> _predefinedColors = ThemeHelper.chartColors;

  List<OutstandingBill> outstandingBills = [];
  bool _isLoadingOutstanding = true;
  String _errorMessageOutstanding = '';
  // Dealer counts summary
  Map<String, dynamic>? _dealerCountsSummary;
  bool _isLoadingDealerSummary = true;
  String _errorMessageDealerSummary = '';

  // Monthly financial year sales data
  List<Map<String, dynamic>> _monthlySalesFY = [];
  bool _isLoadingMonthlySalesFY = true;
  String _errorMessageMonthlySalesFY = '';

  // PageView controller and current page index
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadUsername();
    _fetchYesterdayData();
    _fetchMonthlyData();
    _fetchMonthlyDealerCount();
    _fetchDealerCount();
    _fetchOutstandingBills();
    _fetchDealerCountsSummary();
    _fetchMonthlySalesFY();
  }

  String _generateTitleWithYesterday() {
    DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
    String formattedDate = Formatters.formatDate(yesterday);
    return 'Sales by Brand - $formattedDate';
  }

  String _generateCurrentMonthYear() {
    DateTime now = DateTime.now();
    List<String> months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  String _generateYesterdayDate() {
    DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
    List<String> months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return '${months[yesterday.month - 1]} ${yesterday.day}, ${yesterday.year}';
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? name = prefs.getString('name');

    if (username != null && username.isNotEmpty) {
      setState(() {
        _username = username;
        _name = name;
      });
    }
  }

  Future<void> _fetchYesterdayData() async {
    try {
      setState(() {
        _isLoadingYesterday = true;
        _errorMessageYesterday = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "HBAR_CHART_BY_EXECUTIVE_BY_YD",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<SalesData> fetchedData = [];

        for (int i = 0; i < response.data!.length; i++) {
          final item = response.data![i];
          final brand = item['Brand']?.toString() ?? 'Unknown';
          final amount = double.tryParse(item['Amount']?.toString() ?? '0') ?? 0.0;

          final colorIndex = i % _predefinedColors.length;
          final color = _predefinedColors[colorIndex];

          fetchedData.add(SalesData(brand, amount, color));
        }

        setState(() {
          yesterdayData = fetchedData;
          _isLoadingYesterday = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch yesterday data');
      }
    } catch (e) {
      setState(() {
        _isLoadingYesterday = false;
        _errorMessageYesterday = 'Error loading yesterday data: ${e.toString()}';
      });
      print('Error fetching yesterday data: $e');
    }
  }

  Future<void> _fetchMonthlyData() async {
    try {
      setState(() {
        _isLoadingMonthly = true;
        _errorMessageMonthly = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "PIE_CHART_BY_EXECUTIVE_BY_CM",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<MonthlyData> fetchedData = [];

        double totalAmount = response.data!.fold(0.0, (sum, item) {
          return sum + (double.tryParse(item['Amount']?.toString() ?? '0') ?? 0.0);
        });

        for (int i = 0; i < response.data!.length; i++) {
          final item = response.data![i];
          final brand = item['Brand']?.toString() ?? 'Unknown';
          final amount = double.tryParse(item['Amount']?.toString() ?? '0') ?? 0.0;
          final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;

          final colorIndex = i % _predefinedColors.length;
          final color = _predefinedColors[colorIndex];

          fetchedData.add(MonthlyData(brand, amount, percentage, color));
        }

        setState(() {
          monthlyData = fetchedData;
          _isLoadingMonthly = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch monthly data');
      }
    } catch (e) {
      setState(() {
        _isLoadingMonthly = false;
        _errorMessageMonthly = 'Error loading monthly data: ${e.toString()}';
      });
      print('Error fetching monthly data: $e');
    }
  }

  Future<void> _fetchDealerCount() async {
    try {
      setState(() {
        _isLoadingDealerCount = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_DEALER_COUNT_YD",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        final dealerCountData = response.data!.first;
        final count = int.tryParse(dealerCountData['DealerCount']?.toString() ?? '0') ?? 0;

        setState(() {
          _dealerCount = count;
          _isLoadingDealerCount = false;
        });
      } else {
        throw Exception('Failed to fetch dealer count');
      }
    } catch (e) {
      setState(() {
        _isLoadingDealerCount = false;
        _dealerCount = 0;
      });
      print('Error fetching dealer count: $e');
    }
  }

  Future<void> _fetchMonthlyDealerCount() async {
    try {
      setState(() {
        _isLoadingMonthlyDealerCount = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_DEALER_COUNT",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        final dealerCountData = response.data!.first;
        final count = int.tryParse(dealerCountData['DealerCount']?.toString() ?? '0') ?? 0;

        setState(() {
          _monthlydealerCount = count;
          _isLoadingMonthlyDealerCount = false;
        });
      } else {
        throw Exception('Failed to fetch dealer count');
      }
    } catch (e) {
      setState(() {
        _isLoadingMonthlyDealerCount = false;
        _monthlydealerCount = 0;
      });
      print('Error fetching Monthly dealer count: $e');
    }
  }

  Future<void> _fetchOutstandingBills() async {
    try {
      setState(() {
        _isLoadingOutstanding = true;
        _errorMessageOutstanding = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_AGING_BY_EXECUTIVE",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<OutstandingBill> fetchedData = [];

        for (final item in response.data!) {
          fetchedData.add(OutstandingBill.fromJson(item));
        }

        setState(() {
          outstandingBills = fetchedData;
          _isLoadingOutstanding = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch outstanding bills');
      }
    } catch (e) {
      setState(() {
        _isLoadingOutstanding = false;
        _errorMessageOutstanding = 'Error loading outstanding bills: ${e.toString()}';
      });
      print('Error fetching outstanding bills: $e');
    }
  }


  Future<void> _fetchDealerCountsSummary() async {
    try {
      setState(() {
        _isLoadingDealerSummary = true;
        _errorMessageDealerSummary = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_DEALER_COUNTS_SUMMARY_BY_EXECUTIVE",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _dealerCountsSummary = response.data!.first;
          _isLoadingDealerSummary = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch dealer counts summary');
      }
    } catch (e) {
      setState(() {
        _isLoadingDealerSummary = false;
        _errorMessageDealerSummary = 'Error loading dealer counts: ${e.toString()}';
      });
      print('Error fetching dealer counts summary: $e');
    }
  }

  Future<void> _fetchMonthlySalesFY() async {
    try {
      setState(() {
        _isLoadingMonthlySalesFY = true;
        _errorMessageMonthlySalesFY = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_MONTHLY_SALES_FINANCIAL_YEAR",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        setState(() {
          _monthlySalesFY = List<Map<String, dynamic>>.from(response.data!);
          _isLoadingMonthlySalesFY = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch monthly sales data');
      }
    } catch (e) {
      setState(() {
        _isLoadingMonthlySalesFY = false;
        _errorMessageMonthlySalesFY = 'Error loading monthly sales: ${e.toString()}';
      });
      print('Error fetching monthly sales FY: $e');
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchYesterdayData(),
      _fetchMonthlyData(),
      _fetchDealerCount(),
      _fetchMonthlyDealerCount(),
      _fetchOutstandingBills(),
      _fetchDealerCountsSummary(),
      _fetchMonthlySalesFY(),
    ]);
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DashboardLayout(
          title: _name ?? 'Dealer Dashboard',
          showGreeting: true,
          initialIndex: 0,
          onTabSelected: _onMenuSelected,
          body: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outstanding Bills',
                  style: ThemeHelper.headerStyle(context),
                ),
                SizedBox(height: 16),
                _buildOutstandingBills(),


                SizedBox(height: 32),
                Text(
                  'Sales Overview',
                  style: ThemeHelper.headerStyle(context),
                ),
                SizedBox(height: 16),

                // Horizontal scrollable cards for Monthly Sales and Sales Summary
                Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: PageView(
                        controller: _pageController,
                        padEnds: false,
                        onPageChanged: (int page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: _buildMonthlyPieChart(),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: _buildYesterdayChart(),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: _buildDealerCountsCard(),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: _buildMonthlySalesFYChart(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Page indicator dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 12 : 8,
                          height: _currentPage == index ? 12 : 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? ThemeHelper.accentBlue
                                : ThemeHelper.subtleTextColor(context).withOpacity(0.3),
                          ),
                        );
                      }),
                    ),
                  ],
                ),


                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYesterdayChart() {
    return GlassContainer(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'DAILY SALES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 24),
            _buildYesterdayChartContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildYesterdayChartContent() {
    if (_isLoadingYesterday) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: ThemeHelper.loadingColor(context),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Loading sales data...',
                style: ThemeHelper.captionStyle(context),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessageYesterday.isNotEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: ThemeHelper.errorColor,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessageYesterday,
                style: TextStyle(
                  color: ThemeHelper.errorColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchYesterdayData,
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
        ),
      );
    }

    if (yesterdayData.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                color: ThemeHelper.subtleTextColor(context),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'No sales data available',
                style: ThemeHelper.subtitleStyle(context).copyWith(
                  color: ThemeHelper.subtleTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate total
    double totalAmount = yesterdayData.fold(0.0, (sum, item) => sum + item.amount);

    return Column(
      children: [
        // Date header
        Text(
          _generateYesterdayDate(),
          style: TextStyle(
            color: ThemeHelper.accentBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 20),

        // Main content: Total box on left, brand list on right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Total amount box
            Container(
              width: 120,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  Formatters.formatCurrency(totalAmount),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            SizedBox(width: 20),

            // Right side - Brand list
            Expanded(
              child: Column(
                children: yesterdayData.map((data) => _buildDailyBrandListItem(data)).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyBrandListItem(SalesData data) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: data.color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    data.period.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.formatCurrency(data.amount),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalBarItem(SalesData data, double maxAmount) {
    double percentage = maxAmount > 0 ? data.amount.abs() / maxAmount : 0.0;
    bool isNegative = data.amount < 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    data.period,
                    style: ThemeHelper.subtitleStyle(context),
                  ),
                  if (isNegative)
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: ThemeHelper.smallBadgeDecoration(ThemeHelper.errorColor),
                      child: Text(
                        'NEG',
                        style: TextStyle(
                          color: ThemeHelper.errorColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                Formatters.formatCurrency(data.amount.abs()),
                style: TextStyle(
                  color: isNegative ? ThemeHelper.errorColor : ThemeHelper.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: ThemeHelper.glassBackground(context),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isNegative
                        ? [ThemeHelper.errorColor, ThemeHelper.errorColor.withOpacity(0.7)]
                        : [data.color, data.color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: (isNegative ? ThemeHelper.errorColor : data.color).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyPieChart() {
    return GlassContainer(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'MONTHLY SALES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 24),
            _buildMonthlyChartContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChartContent() {
    if (_isLoadingMonthly) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: ThemeHelper.loadingColor(context),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Loading monthly data...',
                style: ThemeHelper.captionStyle(context),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessageMonthly.isNotEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: ThemeHelper.errorColor,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessageMonthly,
                style: TextStyle(
                  color: ThemeHelper.errorColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMonthlyData,
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
        ),
      );
    }

    if (monthlyData.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                color: ThemeHelper.subtleTextColor(context),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'No monthly data available',
                style: ThemeHelper.subtitleStyle(context).copyWith(
                  color: ThemeHelper.subtleTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate total
    double totalAmount = monthlyData.fold(0.0, (sum, item) => sum + item.value);

    return Column(
      children: [
        // Month and Year subheading
        Text(
          _generateCurrentMonthYear(),
          style: TextStyle(
            color: ThemeHelper.accentBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 20),

        // Main content: Total box on left, brand list on right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Total amount box
            Container(
              width: 120,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  Formatters.formatCurrency(totalAmount),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            SizedBox(width: 20),

            // Right side - Brand list
            Expanded(
              child: Column(
                children: monthlyData.map((data) => _buildBrandListItem(data)).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrandListItem(MonthlyData data) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: data.color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    data.category.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.formatCurrency(data.value),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(MonthlyData data) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.category,
                  style: ThemeHelper.bodyStyle(context),
                ),
                Text(
                  '${Formatters.formatCurrency(data.value)} (${data.percentage.toStringAsFixed(1)}%)',
                  style: ThemeHelper.captionStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarItem(MonthlyData data, double maxAmount) {
    double percentage = maxAmount > 0 ? data.value.abs() / maxAmount : 0.0;
    bool isNegative = data.value < 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    data.category,
                    style: ThemeHelper.subtitleStyle(context),
                  ),
                  if (isNegative)
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: ThemeHelper.smallBadgeDecoration(ThemeHelper.errorColor),
                      child: Text(
                        'NEG',
                        style: TextStyle(
                          color: ThemeHelper.errorColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                Formatters.formatCurrency(data.value.abs()),
                style: TextStyle(
                  color: isNegative ? ThemeHelper.errorColor : ThemeHelper.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: ThemeHelper.glassBackground(context),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isNegative
                        ? [ThemeHelper.errorColor, ThemeHelper.errorColor.withOpacity(0.7)]
                        : [data.color, data.color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: (isNegative ? ThemeHelper.errorColor : data.color).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingBills() {
    if (_isLoadingOutstanding) {
      return Container(
        height: 200,
        child: GlassContainer(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: ThemeHelper.loadingColor(context),
                  strokeWidth: 2,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading outstanding bills...',
                  style: ThemeHelper.captionStyle(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessageOutstanding.isNotEmpty) {
      return GlassContainer(
        child: Container(
          height: 200,
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: ThemeHelper.errorColor,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  _errorMessageOutstanding,
                  style: TextStyle(
                    color: ThemeHelper.errorColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchOutstandingBills,
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
          ),
        ),
      );
    }

    if (outstandingBills.isEmpty) {
      return GlassContainer(
        child: Container(
          height: 200,
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: ThemeHelper.successColor,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'No outstanding bills',
                  style: ThemeHelper.titleStyle(context),
                ),
                Text(
                  'All bills are up to date',
                  style: ThemeHelper.captionStyle(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildComparisonTable();
  }

  Widget _buildComparisonTable() {
    OutstandingBill? cdData = outstandingBills.firstWhere(
          (bill) => bill.cdReg == 'CD',
      orElse: () => OutstandingBill(
        cdReg: 'CD',
        pendingBills: 0,
        lessThan30Days: 0,
        days30To60: 0,
        days60To75: 0,
        days75To90: 0,
        moreThan90Days: 0,
        onAccount: 0,
      ),
    );

    OutstandingBill? regData = outstandingBills.firstWhere(
          (bill) => bill.cdReg == 'REG',
      orElse: () => OutstandingBill(
        cdReg: 'REG',
        pendingBills: 0,
        lessThan30Days: 0,
        days30To60: 0,
        days60To75: 0,
        days75To90: 0,
        moreThan90Days: 0,
        onAccount: 0,
      ),
    );

    return GlassContainer(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
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
                    flex: 3,
                    child: Text(
                      '',
                      style: TextStyle(color: Colors.transparent),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.credit_card, color: ThemeHelper.accentBlue, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'CD',
                            style: ThemeHelper.titleStyle(context),
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
                          Icon(Icons.receipt_long, color: ThemeHelper.accentOrange, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'REG',
                            style: ThemeHelper.titleStyle(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            _buildTableRow('Pending Bills', cdData.pendingBills, regData.pendingBills, null, true),
            SizedBox(height: 12),

            Text(
              'Ageing Breakdown',
              style: ThemeHelper.bodyStyle(context).copyWith(
                color: ThemeHelper.subtleTextColor(context),
              ),
            ),
            SizedBox(height: 12),

            _buildTableRow('(< 30 days )', cdData.lessThan30Days, regData.lessThan30Days, ThemeHelper.successColor),
            _buildTableRow('30 to 60 days', cdData.days30To60, regData.days30To60, ThemeHelper.infoColor),
            _buildTableRow('60 to 75 days', cdData.days60To75, regData.days60To75, ThemeHelper.warningColor),
            _buildTableRow('75 to 90 days', cdData.days75To90, regData.days75To90, Color(0xFFFF5722)),
            _buildTableRow('(> 90 days )', cdData.moreThan90Days, regData.moreThan90Days, ThemeHelper.errorColor),

            SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 1,
              color: ThemeHelper.borderColor(context),
            ),
            SizedBox(height: 12),

            _buildTableRow('On Account', cdData.onAccount, regData.onAccount, ThemeHelper.successColor, true),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, double cdAmount, double regAmount, [Color? indicatorColor, bool isMainRow = false]) {
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
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: indicatorColor.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    label,
                    style: isMainRow
                        ? ThemeHelper.subtitleStyle(context)
                        : ThemeHelper.bodyStyle(context).copyWith(
                      color: ThemeHelper.subtleTextColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (cdAmount < 0)
                    Container(
                      margin: EdgeInsets.only(right: 4),
                      padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: ThemeHelper.smallBadgeDecoration(ThemeHelper.errorColor),
                      child: Text(
                        'CR',
                        style: TextStyle(
                          color: ThemeHelper.errorColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      Formatters.formatCurrency(cdAmount.abs()),
                      style: TextStyle(
                        color: cdAmount < 0
                            ? ThemeHelper.errorColor
                            : (isMainRow ? ThemeHelper.textColor(context) : ThemeHelper.subtleTextColor(context)),
                        fontSize: isMainRow ? 16 : 13,
                        fontWeight: isMainRow ? FontWeight.w700 : FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (regAmount < 0)
                    Container(
                      margin: EdgeInsets.only(right: 4),
                      padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: ThemeHelper.smallBadgeDecoration(ThemeHelper.errorColor),
                      child: Text(
                        'CR',
                        style: TextStyle(
                          color: ThemeHelper.errorColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      Formatters.formatCurrency(regAmount.abs()),
                      style: TextStyle(
                        color: regAmount < 0
                            ? ThemeHelper.errorColor
                            : (isMainRow ? ThemeHelper.textColor(context) : ThemeHelper.subtleTextColor(context)),
                        fontSize: isMainRow ? 16 : 13,
                        fontWeight: isMainRow ? FontWeight.w700 : FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerCountsCard() {
    return GlassContainer(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'BILLED COUNT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 24),
            _buildDealerCountsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildDealerCountsContent() {
    if (_isLoadingDealerSummary) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: ThemeHelper.loadingColor(context),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Loading dealer counts...',
                style: ThemeHelper.captionStyle(context),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessageDealerSummary.isNotEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: ThemeHelper.errorColor,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessageDealerSummary,
                style: TextStyle(
                  color: ThemeHelper.errorColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDealerCountsSummary,
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
        ),
      );
    }

    if (_dealerCountsSummary == null) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                color: ThemeHelper.subtleTextColor(context),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'No dealer counts available',
                style: ThemeHelper.subtitleStyle(context).copyWith(
                  color: ThemeHelper.subtleTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    int totalDealers = int.tryParse(_dealerCountsSummary!['TotalDealers']?.toString() ?? '0') ?? 0;
    int monthlyDealers = int.tryParse(_dealerCountsSummary!['MonthlyDealers']?.toString() ?? '0') ?? 0;
    int yesterdayDealers = int.tryParse(_dealerCountsSummary!['YesterdayDealers']?.toString() ?? '0') ?? 0;
    int fyDealers = int.tryParse(_dealerCountsSummary!['FinancialYearDealers']?.toString() ?? '0') ?? 0;

    return Column(
      children: [
        SizedBox(height: 8),
        // Grid of 4 boxes (2x2)
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // First row
              Row(
                children: [
                  Expanded(
                    child: _buildCountBox(
                      'Total Dealers',
                      totalDealers,
                      ThemeHelper.accentBlue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildCountBox(
                      'Monthly Dealers',
                      monthlyDealers,
                      ThemeHelper.accentBlue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Second row
              Row(
                children: [
                  Expanded(
                    child: _buildCountBox(
                      'Yesterday\'s Dealer',
                      yesterdayDealers,
                      ThemeHelper.accentBlue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildCountBox(
                      'FY New Dealers',
                      fyDealers,
                      ThemeHelper.accentBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountBox(String label, int count, Color accentColor) {
    return Container(
      height: 100, // Fixed height for all cards
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(height: 4),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySalesFYChart() {
    return GlassContainer(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'SALES 25-26',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 24),
            _buildMonthlySalesFYContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySalesFYContent() {
    if (_isLoadingMonthlySalesFY) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: ThemeHelper.loadingColor(context),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Loading sales data...',
                style: ThemeHelper.captionStyle(context),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessageMonthlySalesFY.isNotEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: ThemeHelper.errorColor,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessageMonthlySalesFY,
                style: TextStyle(
                  color: ThemeHelper.errorColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMonthlySalesFY,
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
        ),
      );
    }

    if (_monthlySalesFY.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                color: ThemeHelper.subtleTextColor(context),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'No sales data available',
                style: ThemeHelper.subtitleStyle(context).copyWith(
                  color: ThemeHelper.subtleTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }


    // Get current month to determine FY position
    DateTime now = DateTime.now();
    int currentMonth = now.month; // 1-12

    // Financial Year: April (4) to March (3)
    // Calculate how many months have passed in current FY
    int monthsInCurrentFY;
    if (currentMonth >= 4) {
      // Apr to Dec: months since April
      monthsInCurrentFY = currentMonth - 3; // Apr=1, May=2, Jun=3, etc.
    } else {
      // Jan to Mar: months since last April
      monthsInCurrentFY = currentMonth + 9; // Jan=10, Feb=11, Mar=12
    }

    // Get last 6 months or available months in current FY (whichever is smaller)
    int monthsToShow = monthsInCurrentFY < 6 ? monthsInCurrentFY : 6;

    // Get the data for display
    List<Map<String, dynamic>> displayMonths = _monthlySalesFY.length >= monthsToShow
        ? _monthlySalesFY.sublist(_monthlySalesFY.length - monthsToShow)
        : _monthlySalesFY;

    // Reverse the order to show most recent month first
    displayMonths = displayMonths.reversed.toList();

    // Calculate total and max for chart
    double totalAmount = displayMonths.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item['TotalAmount']?.toString() ?? '0') ?? 0.0);
    });

    double maxAmount = displayMonths.fold(0.0, (max, item) {
      double amount = double.tryParse(item['TotalAmount']?.toString() ?? '0') ?? 0.0;
      return amount > max ? amount : max;
    });

    return Column(
      children: [
        // Horizontal Bar chart
        Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: displayMonths.map((data) {
              String monthName = data['MonthName'] ?? '';
              double amount = double.tryParse(data['TotalAmount']?.toString() ?? '0') ?? 0.0;
              double widthPercentage = maxAmount > 0 ? (amount / maxAmount) : 0.0;

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    // Month label on the left
                    SizedBox(
                      width: 55,
                      child: Text(
                        monthName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(width: 6),
                    // Horizontal bar
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: widthPercentage,
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    ThemeHelper.accentBlue,
                                    ThemeHelper.accentBlue.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: ThemeHelper.accentBlue.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: amount > (maxAmount * 0.2) // Show amount inside if bar is wide enough
                                  ? Text(
                                Formatters.formatCurrency(amount),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )
                                  : SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amount label on the right (for small bars)
                    SizedBox(width: 5),
                    SizedBox(
                      width: 65,
                      child: amount <= (maxAmount * 0.2)
                          ? Text(
                        Formatters.formatCurrency(amount),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                      )
                          : SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}