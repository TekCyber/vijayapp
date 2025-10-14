// lib/views/dealer/invoice_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../utils/formatters.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_container.dart';
import '../../services/api_service.dart';
import 'menu_navigator.dart';
import 'invoice_detail_screen.dart';

class InvoiceScreen extends StatefulWidget {
  final String dealerName;
  final Function(int)? onMenuSelected;

  InvoiceScreen({required this.dealerName, this.onMenuSelected});

  @override
  _InvoiceScreenState createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  int selectedMenuIndex = 0;
  int _currentTabIndex = 0; // 0: All, 1: Outstanding, 2: Overdue

  // Invoice data state variables
  List<Map<String, dynamic>> _allInvoices = [];
  Map<String, List<Map<String, dynamic>>> _groupedInvoices = {};
  Map<String, bool> _expandedMonths = {};
  bool _isLoading = true;
  String _errorMessage = '';
  bool _expandAll = false;

  @override
  void initState() {
    super.initState();
    _fetchInvoiceData();
  }

  Future<void> _fetchInvoiceData() async {
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

      // Determine which API to call based on selected tab
      String sqlKey;
      if (_currentTabIndex == 0) {
        sqlKey = "GET_ALL_INVOICES_BY_DEALER";
      } else if (_currentTabIndex == 1) {
        sqlKey = "GET_ALL_OUTSTANDING_INVOICES";
      } else {
        // Overdue - not yet implemented
        setState(() {
          _allInvoices = [];
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> payload = {
        "sqlKey": sqlKey,
        "dealername": widget.dealerName,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData =
        List<Map<String, dynamic>>.from(response.data!);

        setState(() {
          _allInvoices = fetchedData;
          _isLoading = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch invoice data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading invoice data: ${e.toString()}';
      });
      print('Error fetching invoice data: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredInvoices() {
    _groupInvoicesByMonth(_allInvoices);
    return _allInvoices;
  }

  void _groupInvoicesByMonth(List<Map<String, dynamic>> invoices) {
    _groupedInvoices.clear();

    for (var invoice in invoices) {
      DateTime date = _parseDate(invoice['Date']);
      String monthKey = DateFormat('MMMM yy').format(date);

      if (!_groupedInvoices.containsKey(monthKey)) {
        _groupedInvoices[monthKey] = [];
        if (!_expandedMonths.containsKey(monthKey)) {
          _expandedMonths[monthKey] = false;
        }
      }

      _groupedInvoices[monthKey]!.add(invoice);
    }

    var sortedKeys = _groupedInvoices.keys.toList()
      ..sort((a, b) {
        DateTime dateA = DateFormat('MMMM yy').parse(a);
        DateTime dateB = DateFormat('MMMM yy').parse(b);
        return dateB.compareTo(dateA);
      });

    Map<String, List<Map<String, dynamic>>> sortedMap = {};
    for (var key in sortedKeys) {
      sortedMap[key] = _groupedInvoices[key]!;
    }

    _groupedInvoices = sortedMap;
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      try {
        List<String> parts = dateValue.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          } else {
            return DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
        return DateTime.parse(dateValue);
      } catch (e) {
        print('Error parsing date: $dateValue - $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  double _parseAmount(dynamic amount) {
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      return double.tryParse(amount.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  double _calculateTotal() {
    List<Map<String, dynamic>> invoices = _getFilteredInvoices();
    double total = 0.0;
    for (var invoice in invoices) {
      total += _parseAmount(invoice['Amount']);
    }
    return total;
  }

  double _calculateMonthTotal(String monthKey) {
    double total = 0.0;
    for (var invoice in _groupedInvoices[monthKey]!) {
      total += _parseAmount(invoice['Amount']);
    }
    return total;
  }

  void _toggleExpandAll() {
    setState(() {
      _expandAll = !_expandAll;
      for (var key in _expandedMonths.keys) {
        _expandedMonths[key] = _expandAll;
      }
    });
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '₹0';
    return '₹${Formatters.formatNumber(amount)}';
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  @override
  Widget build(BuildContext context) {
    String tabName = _currentTabIndex == 0
        ? 'All Invoices'
        : (_currentTabIndex == 1 ? 'Outstanding Invoices' : 'Overdue Invoices');

    return DashboardLayout(
      title: tabName,
      subtitle: widget.dealerName,
      onTabSelected: _onMenuSelected,
      showBackButton: true,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchInvoiceData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabBar(),
                  const SizedBox(height: 16),
                  _buildInvoiceContent(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Fixed bottom total bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildOverallTotalBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTabButton('All', 0),
        const SizedBox(width: 8),
        _buildTabButton('Outstanding', 1),
        const SizedBox(width: 8),
        _buildTabButton('Overdue', 2),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentTabIndex = index);
        _fetchInvoiceData(); // Refetch data when tab changes
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildInvoiceContent() {
    // Show "Coming Soon" for Overdue tab
    if (_currentTabIndex == 2) {
      return _buildComingSoonCard();
    }

    return _buildContent();
  }

  Widget _buildComingSoonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.schedule, color: Colors.blueAccent, size: 64),
            SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Overdue invoices feature is under development',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorCard();
    }

    List<Map<String, dynamic>> invoices = _getFilteredInvoices();

    if (invoices.isEmpty) {
      return _buildEmptyCard();
    }

    return Column(
      children: _groupedInvoices.keys.map((monthKey) {
        return _buildMonthCard(monthKey);
      }).toList(),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Colors.blueAccent,
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Loading invoice data...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchInvoiceData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    String emptyMessage = _currentTabIndex == 0
        ? 'No invoices found'
        : (_currentTabIndex == 1
        ? 'No outstanding invoices found'
        : 'No overdue invoices found');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, color: Colors.white60, size: 48),
            SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(String monthKey) {
    List<Map<String, dynamic>> invoices = _groupedInvoices[monthKey]!;
    bool isExpanded = _expandedMonths[monthKey] ?? false;
    double monthTotal = _calculateMonthTotal(monthKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF2A3F5F).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedMonths[monthKey] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          monthKey,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Total Invoices: ${invoices.length}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
                ],
              ),
            ),
          ),

          // Invoice List
          if (isExpanded) ...[
            Divider(
              color: Colors.white.withOpacity(0.1),
              height: 1,
              thickness: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Date',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Invoice No',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Amount',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  // Invoice Rows
                  ...invoices.map((invoice) => _buildInvoiceRow(invoice)).toList(),
                ],
              ),
            ),
            Divider(
              color: Colors.white.withOpacity(0.1),
              height: 1,
              thickness: 1,
            ),
          ],

          // Footer - Total
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Sales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatAmount(monthTotal),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(Map<String, dynamic> invoice) {
    String invoiceNo = invoice['InvoiceNo']?.toString() ?? 'N/A';
    String date = invoice['Date']?.toString() ?? 'N/A';
    String amount = _formatAmount(invoice['Amount']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceDetailScreen(
              invoiceNo: invoiceNo,
              dealerName: widget.dealerName,
              financialYear: Formatters.getFYFromDateString(date),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                date,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        invoiceNo,
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.lightBlueAccent,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                amount,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallTotalBar() {
    double totalAmount = _calculateTotal();
    List<Map<String, dynamic>> invoices = _getFilteredInvoices();

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.receipt_long,
              color: Colors.blueAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Total Invoices: ${invoices.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Text(
              'Total: ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _isLoading ? '...' : _formatAmount(totalAmount),
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}