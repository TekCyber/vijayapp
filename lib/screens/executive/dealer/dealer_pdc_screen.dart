// lib/views/dealer/dealer_pdc_screen.dart - THEME-AWARE VERSION
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../widgets/glass_container.dart';
import '../../../services/api_service.dart';
import '../../../theme/theme_helpers.dart';
import '../menu_navigator.dart';

class DealerPDCScreen extends StatefulWidget {
  final String title;
  final Function(int)? onMenuSelected;

  DealerPDCScreen({required this.title, this.onMenuSelected});

  @override
  _DealerPDCScreenState createState() => _DealerPDCScreenState();
}

class _DealerPDCScreenState extends State<DealerPDCScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  int selectedMenuIndex = 0;
  int _currentTabIndex = 0;

  List<Map<String, dynamic>> _pdcData = [];
  bool _isLoadingPDC = true;
  String _errorMessagePDC = '';

  List<Map<String, dynamic>> _chequeReturnData = [];
  bool _isLoadingChequeReturn = true;
  String _errorMessageChequeReturn = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        _animationController.reset();
        _animationController.forward();
      }
    });

    _animationController.forward();
    _fetchPDCData();
    _fetchChequeReturnData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  Future<void> _fetchPDCData() async {
    try {
      setState(() {
        _isLoadingPDC = true;
        _errorMessagePDC = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_ALL_PDC_LIST_BY_DEALER",
        "dealername": widget.title,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData = List<Map<String, dynamic>>.from(response.data!);

        setState(() {
          _pdcData = fetchedData;
          _isLoadingPDC = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch PDC data');
      }
    } catch (e) {
      setState(() {
        _isLoadingPDC = false;
        _errorMessagePDC = 'Error loading PDC data: ${e.toString()}';
      });
      print('Error fetching PDC data: $e');
    }
  }

  Future<void> _fetchChequeReturnData() async {
    try {
      setState(() {
        _isLoadingChequeReturn = true;
        _errorMessageChequeReturn = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_ALL_CHEQUE_RETURN_BY_DEALER",
        "dealername": widget.title,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData = List<Map<String, dynamic>>.from(response.data!);

        setState(() {
          _chequeReturnData = fetchedData;
          _isLoadingChequeReturn = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch cheque return data');
      }
    } catch (e) {
      setState(() {
        _isLoadingChequeReturn = false;
        _errorMessageChequeReturn = 'Error loading cheque return data: ${e.toString()}';
      });
      print('Error fetching cheque return data: $e');
    }
  }

  double _calculateTotalPDC() {
    if (_pdcData.isEmpty) return 0.0;

    double total = 0.0;
    for (var row in _pdcData) {
      double amount = double.tryParse(row['Amount']?.toString() ?? '0') ?? 0.0;
      total += amount;
    }

    return total;
  }

  double _calculateTotalChequeReturn() {
    if (_chequeReturnData.isEmpty) return 0.0;

    double total = 0.0;
    for (var row in _chequeReturnData) {
      double amount = double.tryParse(row['Amount']?.toString() ?? '0') ?? 0.0;
      total += amount;
    }

    return total;
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    return Formatters.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    String currentTitle = _currentTabIndex == 0 ? 'PDC Analysis' : 'Cheque Returns';

    return DashboardLayout(
      title: currentTitle,
      subtitle: widget.title,
      onTabSelected: _onMenuSelected,
      showBackButton: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernTabBar(),

            Expanded(
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 10 * (1 - _slideAnimation.value)),
                    child: Opacity(
                      opacity: _slideAnimation.value,
                      child: TabBarView(
                        controller: _tabController,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          _buildPDCTab(),
                          _buildChequeReturnTab(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          _buildMinimalTab(
            index: 0,
            title: 'PDC',
            isSelected: _currentTabIndex == 0,
          ),
          SizedBox(width: 24),
          _buildMinimalTab(
            index: 1,
            title: 'Cheque Returns',
            isSelected: _currentTabIndex == 1,
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildMinimalTab({
    required int index,
    required String title,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        HapticFeedback.lightImpact();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? ThemeHelper.textColor(context)
                  : ThemeHelper.subtleTextColor(context),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: 2,
            width: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDCTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassContainer(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      child: _buildExpandablePDCContent(),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),

        Container(
          margin: EdgeInsets.all(16),
          child: _buildPDCBottomSummaryBar(),
        ),
      ],
    );
  }

  Widget _buildExpandablePDCContent() {
    if (_isLoadingPDC) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  color: ThemeHelper.loadingColor(context),
                  strokeWidth: 2
              ),
              SizedBox(height: 16),
              Text(
                  'Loading PDC data...',
                  style: ThemeHelper.captionStyle(context)
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessagePDC.isNotEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: ThemeHelper.errorColor, size: 48),
              SizedBox(height: 16),
              Text(
                  _errorMessagePDC,
                  style: TextStyle(color: ThemeHelper.errorColor, fontSize: 14),
                  textAlign: TextAlign.center
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPDCData,
                style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeHelper.glassBackground(context)
                ),
                child: Text(
                    'Retry',
                    style: TextStyle(color: ThemeHelper.textColor(context))
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdcData.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  Icons.inbox_outlined,
                  color: ThemeHelper.subtleTextColor(context),
                  size: 48
              ),
              SizedBox(height: 16),
              Text(
                  'No PDC data available',
                  style: ThemeHelper.subtitleStyle(context).copyWith(
                      color: ThemeHelper.subtleTextColor(context)
                  )
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWidePDCTableHeader(),
            SizedBox(height: 8),
            ..._buildWidePDCData(),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildWidePDCTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.2),
            Theme.of(context).primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeHelper.borderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildWideHeaderCell('Date', width: 140),
          _buildWideHeaderCell('Instrument No', width: 180),
          _buildWideHeaderCell('Amount', width: 140),
        ],
      ),
    );
  }

  Widget _buildWideHeaderCell(String title, {required double width}) {
    return Container(
      width: width,
      child: Text(
        title,
        style: TextStyle(
          color: ThemeHelper.textColor(context),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> _buildWidePDCData() {
    return _pdcData.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> row = entry.value;
      bool isEven = index % 2 == 0;

      return _buildWidePDCDataRow(row, isEven);
    }).toList();
  }

  Widget _buildWidePDCDataRow(Map<String, dynamic> data, bool isEven) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: ThemeHelper.rowBackground(context, isEven),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _buildWideDataCell(data['Date']?.toString() ?? 'N/A', width: 140),
          _buildWideDataCell(data['InstrumentNo']?.toString() ?? 'N/A', width: 180),
          _buildWideDataCell(
              '${_formatAmount(data['Amount'])}',
              width: 140,
              isAmount: true,
              isPositive: true
          ),
        ],
      ),
    );
  }

  Widget _buildWideDataCell(String value, {
    required double width,
    bool isAmount = false,
    bool isPositive = false,
    bool isNegative = false,
  }) {
    Color textColor = ThemeHelper.subtleTextColor(context);

    if (isPositive && isAmount) {
      textColor = ThemeHelper.successColor;
    } else if (isNegative && isAmount) {
      textColor = ThemeHelper.errorColor;
    } else if (isAmount) {
      textColor = ThemeHelper.textColor(context);
    }

    return Container(
      width: width,
      child: Text(
        value,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: isAmount ? FontWeight.w600 : FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPDCBottomSummaryBar() {
    double totalAmount = _calculateTotalPDC();

    return GlassContainer(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.payment,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total PDC Amount',
                    style: TextStyle(
                      color: ThemeHelper.textColor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Total amount from post-dated cheques',
                    style: TextStyle(
                      color: ThemeHelper.subtleTextColor(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _isLoadingPDC
                  ? '...'
                  : (totalAmount > 0 ? '${_formatAmount(totalAmount)}' : '₹0'),
              style: TextStyle(
                color: ThemeHelper.successColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChequeReturnTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassContainer(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      child: _buildExpandableChequeReturnContent(),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),

        Container(
          margin: EdgeInsets.all(16),
          child: _buildChequeReturnBottomSummaryBar(),
        ),
      ],
    );
  }

  Widget _buildExpandableChequeReturnContent() {
    if (_isLoadingChequeReturn) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  color: ThemeHelper.loadingColor(context),
                  strokeWidth: 2
              ),
              SizedBox(height: 16),
              Text(
                  'Loading cheque return data...',
                  style: ThemeHelper.captionStyle(context)
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessageChequeReturn.isNotEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: ThemeHelper.errorColor, size: 48),
              SizedBox(height: 16),
              Text(
                  _errorMessageChequeReturn,
                  style: TextStyle(color: ThemeHelper.errorColor, fontSize: 14),
                  textAlign: TextAlign.center
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchChequeReturnData,
                style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeHelper.glassBackground(context)
                ),
                child: Text(
                    'Retry',
                    style: TextStyle(color: ThemeHelper.textColor(context))
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_chequeReturnData.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  Icons.check_circle_outline,
                  color: ThemeHelper.successColor,
                  size: 48
              ),
              SizedBox(height: 16),
              Text(
                  'No cheque returns',
                  style: ThemeHelper.subtitleStyle(context).copyWith(
                      color: ThemeHelper.subtleTextColor(context)
                  )
              ),
              Text(
                  'All cheques cleared successfully',
                  style: ThemeHelper.captionStyle(context)
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWideChequeReturnTableHeader(),
            SizedBox(height: 8),
            ..._buildWideChequeReturnData(),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildWideChequeReturnTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.2),
            Theme.of(context).primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeHelper.borderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildWideHeaderCell('Date', width: 140),
          _buildWideHeaderCell('Instrument No', width: 140),
          _buildWideHeaderCell('Amount', width: 120),
        ],
      ),
    );
  }

  List<Widget> _buildWideChequeReturnData() {
    return _chequeReturnData.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> row = entry.value;
      bool isEven = index % 2 == 0;

      return _buildWideChequeReturnDataRow(row, isEven);
    }).toList();
  }

  Widget _buildWideChequeReturnDataRow(Map<String, dynamic> data, bool isEven) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: ThemeHelper.rowBackground(context, isEven),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _buildWideDataCell(data['Date']?.toString() ?? 'N/A', width: 140),
          _buildWideDataCell(data['InstrumentNo']?.toString() ?? 'N/A', width: 140),
          _buildWideDataCell(
              '${_formatAmount(data['Amount'])}',
              width: 120,
              isAmount: true,
              isNegative: true
          ),
        ],
      ),
    );
  }

  Widget _buildChequeReturnBottomSummaryBar() {
    double totalAmount = _calculateTotalChequeReturn();

    return GlassContainer(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.assignment_return,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Returned Amount',
                    style: TextStyle(
                      color: ThemeHelper.textColor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Total amount of returned cheques',
                    style: TextStyle(
                      color: ThemeHelper.subtleTextColor(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _isLoadingChequeReturn
                  ? '...'
                  : (totalAmount > 0 ? '${_formatAmount(totalAmount)}' : '₹0'),
              style: TextStyle(
                color: ThemeHelper.errorColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}