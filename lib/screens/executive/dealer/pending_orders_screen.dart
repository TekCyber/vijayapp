// lib/screens/executive/dealer/pending_orders_screen.dart - UPDATED WITH HORIZONTAL SCROLL
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/theme_helpers.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/dashboard_layout.dart';
import '../menu_navigator.dart';
import '../salesman/data_service.dart';
import '../salesman/order_details_screen.dart';

class PendingOrdersScreen extends StatefulWidget {
  final String title;

  PendingOrdersScreen({required this.title});

  @override
  _PendingOrdersScreenState createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  List<Map<String, dynamic>> _orderData = [];
  Map<String, List<Map<String, dynamic>>> _groupedOrders = {};
  Map<String, bool> _expandedMonths = {};
  bool _isLoading = true;
  String _errorMessage = '';
  int selectedMenuIndex = 0;
  bool _expandAll = false;

  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _fetchPendingOrders();
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  Future<void> _fetchPendingOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      List<Map<String, dynamic>> fetchedData = await _dataService.getPendingOrders(dealerName: widget.title);

      setState(() {
        _orderData = fetchedData;
        _groupOrdersByMonth(_orderData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading pending orders: ${e.toString()}';
      });
      print('Error fetching pending orders: $e');
    }
  }

  void _groupOrdersByMonth(List<Map<String, dynamic>> orders) {
    _groupedOrders.clear();

    for (var order in orders) {
      DateTime date = _parseDate(order['Date']);
      String monthKey = DateFormat('MMMM yy').format(date);

      if (!_groupedOrders.containsKey(monthKey)) {
        _groupedOrders[monthKey] = [];
        if (!_expandedMonths.containsKey(monthKey)) {
          _expandedMonths[monthKey] = false;
        }
      }

      _groupedOrders[monthKey]!.add(order);
    }

    // Sort months in descending order (most recent first)
    var sortedKeys = _groupedOrders.keys.toList()
      ..sort((a, b) {
        DateTime dateA = DateFormat('MMMM yy').parse(a);
        DateTime dateB = DateFormat('MMMM yy').parse(b);
        return dateB.compareTo(dateA);
      });

    Map<String, List<Map<String, dynamic>>> sortedMap = {};
    for (var key in sortedKeys) {
      sortedMap[key] = _groupedOrders[key]!;
    }

    _groupedOrders = sortedMap;
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
    double total = 0.0;
    for (var order in _orderData) {
      total += _parseAmount(order['Amount']);
    }
    return total;
  }

  double _calculateMonthTotal(String monthKey) {
    double total = 0.0;
    for (var order in _groupedOrders[monthKey]!) {
      total += _parseAmount(order['Amount']);
    }
    return total;
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '₹0';
    return '₹${Formatters.formatNumber(amount)}';
  }

  String _formatDate(dynamic dateValue) {
    DateTime date = _parseDate(dateValue);
    return DateFormat('dd-MM-yy').format(date);
  }

  void _toggleExpandAll() {
    setState(() {
      _expandAll = !_expandAll;
      _expandedMonths.updateAll((key, value) => _expandAll);
    });
  }

  void _navigateToOrderDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          orderNumber: order['orderNo']?.toString() ?? 'N/A',
          orderData: order,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Pending Orders',
      subtitle: widget.title,
      onTabSelected: _onMenuSelected,
      showBackButton: true,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchPendingOrders,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrdersContent(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
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

  Widget _buildOrdersContent() {
    final textColor = ThemeHelper.textColor(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Loading pending orders...',
              style: TextStyle(color: ThemeHelper.subtleTextColor(context), fontSize: 14),
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
            Icon(Icons.error, color: ThemeHelper.errorColor, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: textColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchPendingOrders,
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_orderData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: ThemeHelper.successColor,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'All orders have been processed',
              style: TextStyle(
                color: ThemeHelper.subtleTextColor(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month-wise grouped orders
        ..._groupedOrders.keys.map((monthKey) {
          List<Map<String, dynamic>> orders = _groupedOrders[monthKey]!;
          return _buildMonthCard(monthKey, orders);
        }).toList(),
      ],
    );
  }

  Widget _buildMonthCard(String monthKey, List<Map<String, dynamic>> orders) {
    bool isExpanded = _expandedMonths[monthKey] ?? false;
    double monthTotal = _calculateMonthTotal(monthKey);
    int orderCount = orders.length;

    return Column(
      children: [
        // Wrap the entire table (header + rows) in a horizontal scroll view
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              // Table Header
              Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: ThemeHelper.glassBackground(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      child: Text(
                        'Date',
                        style: ThemeHelper.bodyStyle(context).copyWith(
                          color: ThemeHelper.subtleTextColor(context),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 170,
                      child: Text(
                        'Order No',
                        style: ThemeHelper.bodyStyle(context).copyWith(
                          color: ThemeHelper.subtleTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 8),
                   /* Container(
                      width: 130,
                      child: Text(
                        'Invoice No.',
                        style: ThemeHelper.bodyStyle(context).copyWith(
                          color: ThemeHelper.subtleTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 8),*/
                    Container(
                      width: 85,
                      child: Text(
                        'Amount',
                        style: ThemeHelper.bodyStyle(context).copyWith(
                          color: ThemeHelper.subtleTextColor(context),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 80,
                      child: Text(
                        'Status',
                        style: ThemeHelper.bodyStyle(context).copyWith(
                          color: ThemeHelper.subtleTextColor(context),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              // Order Rows
              ...orders.map((order) => _buildOrderRow(order)).toList(),
            ],
          ),
        ),
        SizedBox(height: 16), // Space between months
      ],
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    String orderNumber = order['orderNo']?.toString() ?? 'N/A';
    String invoiceNumber = order['voucherNo']?.toString() ?? 'N/A';
    String status = order['Status']?.toString() ?? 'N/A';
    String date = _formatDate(order['Date']);
    String amount = _formatAmount(order['Amount']);

    return GestureDetector(
      onTap: () => _navigateToOrderDetails(order),
      child: Container(
        margin: EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: ThemeHelper.glassBackground(context),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              child: Text(
                date,
                style: ThemeHelper.bodyStyle(context).copyWith(
                  color: ThemeHelper.subtleTextColor(context),
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              width: 170,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        orderNumber,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 11,
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
                      color: Theme.of(context).primaryColor,
                      size: 8,
                    ),
                  ],
                ),
              ),
            ),
            /*SizedBox(width: 8),
            Container(
              width: 130,
              child: Text(
                invoiceNumber,
                style: ThemeHelper.bodyStyle(context).copyWith(
                  color: ThemeHelper.subtleTextColor(context),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),*/
            SizedBox(width: 8),
            Container(
              width: 85,
              child: Text(
                amount,
                style: ThemeHelper.bodyStyle(context).copyWith(
                  fontSize: 12,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(width: 8),
            Container(
              width: 80,
              child: Text(
                status,
                style: ThemeHelper.bodyStyle(context).copyWith(
                  fontSize: 11,
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallTotalBar() {
    double totalAmount = _calculateTotal();
    int totalOrders = _orderData.length;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeHelper.borderColor(context),
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
            /*Icon(
              Icons.receipt_long,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Total Orders: $totalOrders',
              style: ThemeHelper.bodyStyle(context),
            ),
            const Spacer(),*/
            Text(
              'Total: ',
              style: ThemeHelper.bodyStyle(context),
            ),
            const SizedBox(width: 4),
            Text(
              _isLoading ? '...' : _formatAmount(totalAmount),
              style: TextStyle(
                color: ThemeHelper.warningColor,
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