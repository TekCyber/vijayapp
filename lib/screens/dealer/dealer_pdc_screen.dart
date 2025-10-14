// lib/views/dealer/dealer_pdc_screen.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/formatters.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_container.dart';
import '../../services/api_service.dart';
import 'menu_navigator.dart';

class DealerPDCScreen extends StatefulWidget {
  final String title; // dealerName
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

  // PDC data state variables
  List<Map<String, dynamic>> _pdcData = [];
  bool _isLoadingPDC = true;
  String _errorMessagePDC = '';

  // Cheque return data state variables
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

    // Fetch data
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

  // Fetch PDC data from API
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

  // Fetch cheque return data from API
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

  // Calculate total PDC amount
  double _calculateTotalPDC() {
    if (_pdcData.isEmpty) return 0.0;

    double total = 0.0;
    for (var row in _pdcData) {
      double amount = double.tryParse(row['Amount']?.toString() ?? '0') ?? 0.0;
      total += amount;
    }

    return total;
  }

  // Calculate total cheque return amount
  double _calculateTotalChequeReturn() {
    if (_chequeReturnData.isEmpty) return 0.0;

    double total = 0.0;
    for (var row in _chequeReturnData) {
      double amount = double.tryParse(row['Amount']?.toString() ?? '0') ?? 0.0;
      total += amount;
    }

    return total;
  }

  // Helper method to format amounts
  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    return Formatters.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic title based on current tab
    String currentTitle = _currentTabIndex == 0 ? 'PDC Analysis' : 'Cheque Returns';

    return DashboardLayout(
      title: currentTitle, // Dynamic title changes with tab
      subtitle: widget.title, // Dealer name as subtitle
      onTabSelected: _onMenuSelected,
      showBackButton: true,
      body: SafeArea(
          child: Column(
            children: [
              // Compact Tab Bar
              _buildModernTabBar(),

              // Tab Content with Animation - reduced movement
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
                          physics: NeverScrollableScrollPhysics(), // Disable horizontal swipe
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
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 4), // Minimal margin
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
              color: isSelected ? Colors.white : Colors.white60,
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
              color: Theme.of(context).primaryColor, // Use theme primary color
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
        // Expandable container that grows with content
        Expanded(
          child: SingleChildScrollView( // Only this outer scroll for the whole content
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

        // Bottom summary bar - fixed at bottom
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
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(height: 16),
              Text('Loading PDC data...', style: TextStyle(color: Colors.white60, fontSize: 14)),
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
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(_errorMessagePDC, style: TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPDCData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                child: Text('Retry', style: TextStyle(color: Colors.white)),
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
              Icon(Icons.inbox_outlined, color: Colors.white60, size: 48),
              SizedBox(height: 16),
              Text('No PDC data available', style: TextStyle(color: Colors.white60, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Expandable table - container grows with content
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 600, // Width for 3 columns
        child: Column(
          mainAxisSize: MainAxisSize.min, // Container sizes to content
          children: [
            _buildWidePDCTableHeader(),
            SizedBox(height: 8),
            // All rows directly in column - no height restriction
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
            Theme.of(context).primaryColor.withOpacity(0.2), // Use theme primary
            Theme.of(context).primaryColor.withOpacity(0.1), // Use theme primary
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
          color: Colors.white,
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
        color: isEven
            ? Colors.white.withOpacity(0.05)
            : Colors.transparent,
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
    Color textColor = Colors.white70;

    if (isPositive && isAmount) {
      textColor = Colors.green;
    } else if (isNegative && isAmount) {
      textColor = Colors.red;
    } else if (isAmount) {
      textColor = Colors.white;
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
        maxLines: 2, // Allow up to 2 lines if needed
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
              color: Theme.of(context).primaryColor, // Use theme primary color
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
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Total amount from post-dated cheques',
                    style: TextStyle(
                      color: Colors.white60,
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
                color: Colors.green,
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
        // Expandable container that grows with content
        Expanded(
          child: SingleChildScrollView( // Only this outer scroll for the whole content
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

        // Bottom summary bar - fixed at bottom
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
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(height: 16),
              Text('Loading cheque return data...', style: TextStyle(color: Colors.white60, fontSize: 14)),
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
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(_errorMessageChequeReturn, style: TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchChequeReturnData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                child: Text('Retry', style: TextStyle(color: Colors.white)),
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
              Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text('No cheque returns', style: TextStyle(color: Colors.white60, fontSize: 16)),
              Text('All cheques cleared successfully', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // Expandable table - container grows with content
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 800, // Width for cheque return columns
        child: Column(
          mainAxisSize: MainAxisSize.min, // Container sizes to content
          children: [
            _buildWideChequeReturnTableHeader(),
            SizedBox(height: 8),
            // All rows directly in column - no height restriction
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
            Theme.of(context).primaryColor.withOpacity(0.2), // Use theme primary
            Theme.of(context).primaryColor.withOpacity(0.1), // Use theme primary
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
        color: isEven
            ? Colors.white.withOpacity(0.05)
            : Colors.transparent,
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
              color: Theme.of(context).primaryColor, // Use theme primary color
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
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Total amount of returned cheques',
                    style: TextStyle(
                      color: Colors.white60,
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
                color: Colors.red,
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