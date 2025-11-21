// lib/screens/salesman/cheque_return_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/theme_helpers.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../widgets/glass_container.dart';
import '../menu_navigator.dart';
import '../salesman/data_service.dart';

class ChequeReturnScreen extends StatefulWidget {
  final Function(int)? onMenuSelected;

  ChequeReturnScreen({this.onMenuSelected});

  @override
  _ChequeReturnScreenState createState() => _ChequeReturnScreenState();
}

class _ChequeReturnScreenState extends State<ChequeReturnScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  int selectedMenuIndex = 0;

  final DataService _dataService = DataService();

  String _executive = '';
  bool _isLoadingExecutive = true;
  List<Map<String, dynamic>> _chequeReturnData = [];
  bool _isLoadingChequeReturn = true;
  String _errorMessageChequeReturn = '';

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
    _loadExecutiveInfo();
  }

  Future<void> _loadExecutiveInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username != null && username.isNotEmpty) {
        setState(() {
          _executive = username;
          _isLoadingExecutive = false;
        });
        _fetchChequeReturnData();
      } else {
        setState(() {
          _isLoadingExecutive = false;
          _errorMessageChequeReturn = 'Executive information not found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingExecutive = false;
        _errorMessageChequeReturn = 'Error loading executive info: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  Future<void> _fetchChequeReturnData() async {
    if (_executive.isEmpty) return;

    try {
      setState(() {
        _isLoadingChequeReturn = true;
        _errorMessageChequeReturn = '';
      });

      List<Map<String, dynamic>> fetchedData = await _dataService.getChequeReturnsByExecutive(_executive);

      setState(() {
        _chequeReturnData = fetchedData;
        _isLoadingChequeReturn = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingChequeReturn = false;
        _errorMessageChequeReturn = 'Error loading cheque return data: ${e.toString()}';
      });
      print('Error fetching cheque return data: $e');
    }
  }

  double _calculateTotalReturnedAmount() {
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
    return DashboardLayout(
      title: 'Cheque Return',
      subtitle: _executive.isNotEmpty ? _executive : 'Loading...',
      onTabSelected: _onMenuSelected,
      showBackButton: true,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 10 * (1 - _slideAnimation.value)),
              child: Opacity(
                opacity: _slideAnimation.value,
                child: _buildChequeReturnContent(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChequeReturnContent() {
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
          child: _buildBottomSummaryBar(),
        ),
      ],
    );
  }

  Widget _buildExpandableChequeReturnContent() {
    final textColor = ThemeHelper.textColor(context);
    final subtleColor = ThemeHelper.subtleTextColor(context);

    if (_isLoadingChequeReturn) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Loading cheque return data...',
                style: TextStyle(color: subtleColor, fontSize: 14),
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
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchChequeReturnData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeHelper.glassBackground(context),
                ),
                child: Text('Retry', style: TextStyle(color: textColor)),
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
              Icon(Icons.check_circle_outline, color: ThemeHelper.successColor, size: 48),
              SizedBox(height: 16),
              Text('No cheque returns', style: TextStyle(color: subtleColor, fontSize: 16)),
              Text('All cheques cleared successfully', style: TextStyle(color: subtleColor, fontSize: 12)),
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
            _buildWideTableHeader(),
            SizedBox(height: 8),
            ..._buildWideChequeReturnData(),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildWideTableHeader() {
    final textColor = ThemeHelper.textColor(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: ThemeHelper.tableHeaderDecoration(context),
      child: Row(
        children: [
          _buildWideHeaderCell('Date', width: 120, textColor: textColor),
          _buildWideHeaderCell('Dealer Name', width: 200, textColor: textColor),
          _buildWideHeaderCell('Instrument No', width: 140, textColor: textColor),
          _buildWideHeaderCell('Amount', width: 120, textColor: textColor),
        ],
      ),
    );
  }

  Widget _buildWideHeaderCell(String title, {required double width, required Color textColor}) {
    return Container(
      width: width,
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> _buildWideChequeReturnData() {
    return _chequeReturnData.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> row = entry.value;
      bool isEven = index % 2 == 0;

      return _buildWideDataRow(row, isEven);
    }).toList();
  }

  Widget _buildWideDataRow(Map<String, dynamic> data, bool isEven) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: ThemeHelper.rowBackground(context, isEven),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _buildWideDataCell(data['Date']?.toString() ?? 'N/A', width: 120),
          _buildWideDataCell(data['Dealername']?.toString() ?? 'N/A', width: 200),
          _buildWideDataCell(data['InstrumentNo']?.toString() ?? 'N/A', width: 140),
          _buildWideDataCell(
              '${_formatAmount(double.parse(data['Amount'].toString()))}',
              width: 120,
              isAmount: true,
              isNegative: true
          ),
        ],
      ),
    );
  }

  Widget _buildWideDataCell(String value, {
    required double width,
    bool isAmount = false,
    bool isNegative = false,
  }) {
    Color textColor = ThemeHelper.textColor(context);

    if (isNegative && isAmount) {
      textColor = ThemeHelper.errorColor;
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

  Widget _buildBottomSummaryBar() {
    double totalAmount = _calculateTotalReturnedAmount();
    final textColor = ThemeHelper.textColor(context);
    final subtleColor = ThemeHelper.subtleTextColor(context);

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
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Total amount of returned cheques',
                    style: TextStyle(
                      color: subtleColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _isLoadingChequeReturn
                  ? '...'
                  : (totalAmount != 0 ? '${_formatAmount(totalAmount)}' : '₹0'),
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