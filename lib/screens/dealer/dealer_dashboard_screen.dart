// lib/views/dealer_dashboard_screen.dart - THEME-AWARE VERSION
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/sales_data.dart';
import '../../painters/pie_chart_painter.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchYesterdayData();
    _fetchMonthlyData();
    _fetchMonthlyDealerCount();
    _fetchDealerCount();
    _fetchOutstandingBills();
  }

  String _generateTitleWithYesterday() {
    DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
    String formattedDate = Formatters.formatDate(yesterday);
    return 'Sales by Brand - $formattedDate';
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
        "sqlKey": "PIE_CHART_BY_EXECUTIVE_BY_CM_NEW",
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

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchYesterdayData(),
      _fetchMonthlyData(),
      _fetchDealerCount(),
      _fetchMonthlyDealerCount(),
      _fetchOutstandingBills(),
    ]);
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
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
                  'Sales Summary',
                  style: ThemeHelper.headerStyle(context),
                ),
                SizedBox(height: 16),
                _buildYesterdayChart(),
                SizedBox(height: 32),
                Text(
                  'Monthly Sales Summary',
                  style: ThemeHelper.headerStyle(context),
                ),
                SizedBox(height: 16),
                _buildMonthlyPieChart(),
                SizedBox(height: 32),
                Text(
                  'Outstanding Bills',
                  style: ThemeHelper.headerStyle(context),
                ),
                SizedBox(height: 16),
                _buildOutstandingBills(),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _generateTitleWithYesterday(),
                  style: ThemeHelper.titleStyle(context),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (!_isLoadingYesterday && yesterdayData.isNotEmpty)
              Text(
                'Dealers: $_dealerCount',
                style: ThemeHelper.captionStyle(context),
              ),

            if (!_isLoadingYesterday && yesterdayData.isNotEmpty)
              Text(
                'Total: ${Formatters.formatCurrency(yesterdayData.fold(0.0, (sum, item) => sum + item.amount))}',
                style: ThemeHelper.captionStyle(context),
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

    double maxAmount = yesterdayData.map((e) => e.amount.abs()).reduce(max);

    return Column(
      children: yesterdayData.map((data) => _buildHorizontalBarItem(data, maxAmount)).toList(),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales by Brand',
                  style: ThemeHelper.titleStyle(context),
                ),
                if (!_isLoadingMonthly && monthlyData.isNotEmpty)
                  Text(
                    'Total: ${Formatters.formatCurrency(monthlyData.fold(0.0, (sum, item) => sum + item.value))}',
                    style: ThemeHelper.captionStyle(context),
                  ),
              ],
            ),
            SizedBox(height: 8),
            if (!_isLoadingMonthly && monthlyData.isNotEmpty)
              Text(
                'Dealers: $_monthlydealerCount',
                style: ThemeHelper.captionStyle(context),
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

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 200,
            child: CustomPaint(
              painter: PieChartPainter(monthlyData),
              child: Container(),
            ),
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: Column(
            children: monthlyData
                .map((data) => _buildLegendItem(data))
                .toList(),
          ),
        ),
      ],
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
              'Aging Breakdown',
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
}