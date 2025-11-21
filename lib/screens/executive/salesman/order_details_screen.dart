// lib/screens/salesman/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/theme_helpers.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../widgets/glass_container.dart';
import '../../../services/api_service.dart';
import '../menu_navigator.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderNumber;
  final Map<String, dynamic>? orderData;

  OrderDetailsScreen({
    required this.orderNumber,
    this.orderData,
  });

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  int selectedMenuIndex = 0;

  List<Map<String, dynamic>> _orderItems = [];
  Map<String, List<Map<String, dynamic>>> _groupedOrders = {};
  String _partyName = '';
  String _orderDate = '';

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.orderData != null) {
      _partyName = widget.orderData!['Party Name']?.toString() ?? '';
      _orderDate = widget.orderData!['Date']?.toString() ?? '';
    }
    _fetchOrderDetails();
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  Future<void> _fetchOrderDetails() async {
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

      Map<String, dynamic> payload = {
        "sqlKey": "GET_DEALER_PENDING_SALES_ORDERS_DETAILS",
        "order_no": widget.orderNumber,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData =
        List<Map<String, dynamic>>.from(response.data!);

        if (fetchedData.isNotEmpty) {
          // Get party name and date from first item if not already set
          if (_partyName.isEmpty) {
            _partyName = fetchedData[0]['Party Name']?.toString() ?? '';
          }
          if (_orderDate.isEmpty) {
            _orderDate = fetchedData[0]['Date']?.toString() ?? '';
          }
        }

        // Group orders by Order Number
        Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var item in fetchedData) {
          String orderNo = item['Order Number']?.toString() ?? '';
          if (orderNo.isNotEmpty) {
            if (!grouped.containsKey(orderNo)) {
              grouped[orderNo] = [];
            }
            grouped[orderNo]!.add(item);
          }
        }

        setState(() {
          _orderItems = fetchedData;
          _groupedOrders = grouped;
          _isLoading = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch order details');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading order details: ${e.toString()}';
      });
      print('Error fetching order details: $e');
    }
  }

  double _parseAmount(dynamic amount) {
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      return double.tryParse(amount.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  String _parseQuantity(dynamic qty) {
    if (qty == null) return 'N/A';
    return qty.toString();
  }

  double _calculateTotalValue() {
    double total = 0.0;
    for (var item in _orderItems) {
      total += _parseAmount(item['Value']);
    }
    return total;
  }

  double _calculateOrderTotal(List<Map<String, dynamic>> items) {
    double total = 0.0;
    for (var item in items) {
      total += _parseAmount(item['Value']);
    }
    return total;
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    return '${Formatters.formatNumber(amount)}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Order Details',
      subtitle: _partyName.isNotEmpty ? _partyName : widget.orderNumber,
      onTabSelected: _onMenuSelected,
      showBackButton: true,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchOrderDetails,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContent(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: _buildBottomSummaryBar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Loading order details...',
                style: ThemeHelper.bodyStyle(context).copyWith(
                  color: ThemeHelper.subtleTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
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
                _errorMessage,
                style: ThemeHelper.bodyStyle(context).copyWith(
                  color: ThemeHelper.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchOrderDetails,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_groupedOrders.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: ThemeHelper.subtleTextColor(context),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'No orders found',
                style: ThemeHelper.subtitleStyle(context).copyWith(
                  color: ThemeHelper.subtleTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _groupedOrders.entries.map((entry) {
        String orderNo = entry.key;
        List<Map<String, dynamic>> items = entry.value;
        return _buildOrderCard(orderNo, items);
      }).toList(),
    );
  }

  Widget _buildOrderCard(String orderNo, List<Map<String, dynamic>> items) {
    double orderTotal = _calculateOrderTotal(items);
    String orderDate = items.isNotEmpty ? items[0]['Date']?.toString() ?? '' : '';
    String partyName = items.isNotEmpty ? items[0]['Party Name']?.toString() ?? '' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      orderNo,
                      style: ThemeHelper.titleStyle(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date and Party Info
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: ThemeHelper.subtleTextColor(context),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(orderDate),
                    style: ThemeHelper.bodyStyle(context).copyWith(
                      fontSize: 15,
                      color: ThemeHelper.subtleTextColor(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  /*Icon(
                    Icons.store,
                    color: ThemeHelper.subtleTextColor(context),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      partyName.split(',')[0], // Show only first part before comma
                      style: ThemeHelper.bodyStyle(context).copyWith(
                        fontSize: 12,
                        color: ThemeHelper.subtleTextColor(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),*/
                ],
              ),

              const SizedBox(height: 12),

              // Divider
              Container(
                height: 1,
                color: ThemeHelper.borderColor(context),
              ),

              const SizedBox(height: 12),

              // Items List
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: MediaQuery.of(context).size.width < 800
                      ? 1000
                      : MediaQuery.of(context).size.width - 64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTableHeader(),
                      const SizedBox(height: 8),
                      ...items.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> item = entry.value;
                        bool isEven = index % 2 == 0;
                        return _buildDataRow(item, isEven);
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Order Total
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          color: Theme.of(context).primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order Items: ${items.length}',
                          style: ThemeHelper.bodyStyle(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Order Total: ',
                          style: ThemeHelper.bodyStyle(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(orderTotal),
                          style: TextStyle(
                            color: ThemeHelper.warningColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Item Name', width: 350),
          _buildHeaderCell('Ordered Qty', width: 110),
          _buildHeaderCell('Balance Qty', width: 110),
          _buildHeaderCell('Rate', width: 100),
          _buildHeaderCell('Disc %', width: 80),
          _buildHeaderCell('Value', width: 150),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {required double width}) {
    return Container(
      width: width,
      child: Text(
        title,
        style: TextStyle(
          color: ThemeHelper.textColor(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        textAlign: title == 'Item Name' ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> item, bool isEven) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: ThemeHelper.rowBackground(context, isEven),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          _buildDataCell(
            item['Name of Item']?.toString() ?? 'N/A',
            width: 350,
            textAlign: TextAlign.left,
          ),
          _buildDataCell(
            _parseQuantity(item['Ordered Quantity']),
            width: 110,
          ),
          _buildDataCell(
            _parseQuantity(item['Balance Quantity']),
            width: 110,
          ),
          _buildDataCell(
            _formatAmount(item['Rate']),
            width: 100,
            isAmount: true,
          ),
          _buildDataCell(
            _formatAmount(item['Discount']),
            width: 80,
            isAmount: true,
          ),
          _buildDataCell(
            _formatAmount(item['Value']),
            width: 150,
            isAmount: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(
      String value, {
        required double width,
        bool isAmount = false,
        bool isTotal = false,
        TextAlign? textAlign,
      }) {
    return Container(
      width: width,
      child: Text(
        value,
        style: TextStyle(
          color: isTotal
              ? ThemeHelper.textColor(context)
              : ThemeHelper.subtleTextColor(context),
          fontSize: 12,
          fontWeight: isTotal
              ? FontWeight.w700
              : (isAmount ? FontWeight.w600 : FontWeight.w500),
        ),
        textAlign: textAlign ?? TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBottomSummaryBar() {
    double totalValue = _calculateTotalValue();
    int totalOrders = _groupedOrders.length;
    int totalItems = _orderItems.length;

    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            /*Icon(
              Icons.receipt,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Orders: $totalOrders',
              style: ThemeHelper.bodyStyle(context).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 20,
              color: ThemeHelper.borderColor(context),
            ),*/
            const SizedBox(width: 16),
            Icon(
              Icons.inventory_2,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),

            Text(
              'Grand Total: ',
              style: ThemeHelper.bodyStyle(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _isLoading ? '...' : Formatters.formatCurrency(totalValue),
              style: TextStyle(
                color: ThemeHelper.warningColor,
                fontSize: 16,
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