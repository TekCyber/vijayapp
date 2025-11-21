// lib/screens/salesman/pending_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/theme_helpers.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../models/search_filter_models.dart';
import '../menu_navigator.dart';
import 'data_service.dart';
import 'order_details_screen.dart';

class PendingOrdersScreen extends StatefulWidget {
  final String title;

  PendingOrdersScreen({required this.title});

  @override
  _PendingOrdersScreenState createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  List<Map<String, dynamic>> _orderData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int selectedMenuIndex = 0;
  Set<String> _expandedDealers = {};
  bool _showAll = false; // Toggle for showing all or limited dealers

  // Search functionality
  String _searchText = '';

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

      List<Map<String, dynamic>> fetchedData = await _dataService.getPendingOrders();

      setState(() {
        _orderData = fetchedData;
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

  Map<String, List<Map<String, dynamic>>> _groupByDealer() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var order in _orderData) {
      String dealerName = (order['dealerName'] ?? 'Unknown Dealer').toString();

      // Filter by search query (minimum 2 characters)
      if (_searchText.isNotEmpty && _searchText.length >= 2) {
        if (!dealerName.toLowerCase().contains(_searchText.toLowerCase())) {
          continue; // Skip this dealer if it doesn't match search
        }
      }

      if (!grouped.containsKey(dealerName)) {
        grouped[dealerName] = [];
      }
      grouped[dealerName]!.add(order);
    }

    // Sort dealers by total amount (descending)
    var sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        double totalA = a.value.fold(0.0, (sum, order) => sum + (order['Amount'] ?? 0.0));
        double totalB = b.value.fold(0.0, (sum, order) => sum + (order['Amount'] ?? 0.0));
        return totalB.compareTo(totalA);
      });

    return Map.fromEntries(sortedEntries);
  }

  void _toggleDealerExpansion(String dealerName) {
    setState(() {
      if (_expandedDealers.contains(dealerName)) {
        _expandedDealers.remove(dealerName);
      } else {
        _expandedDealers.add(dealerName);
      }
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

  List<SearchFilterOption> _getSearchFilters() {
    return [
      SearchFilterOption(
        key: 'search',
        widget: SearchTextFilter(
          initialValue: _searchText,
          hint: "Search By Dealer",
          minCharacters: 2,
          onChanged: (value) {
            setState(() {
              _searchText = value;
            });
          },
        ),
      ),
    ];
  }
  Widget build(BuildContext context) {
    Map<String, List<Map<String, dynamic>>> groupedOrders = _groupByDealer();
    bool hasMoreDealers = groupedOrders.length > 5;

    return DashboardLayout(
      title: 'Pending Orders',
      subtitle: widget.title,
      onTabSelected: _onMenuSelected,
      showBackButton: true,
      searchFilters: _getSearchFilters(),
      onFilterChanged: (filters) {
        // Filter changes are handled by the SearchTextFilter onChanged callback
        print('Pending Orders: Filters changed: $filters');
      },
      searchHint: "Search By Dealer",
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 16),
              Expanded(
                child: _buildOrdersContent(),
              ),
            ],
          ),

          // Floating +/- toggle button (top-right, below app bar)
          if (hasMoreDealers)
            Positioned(
              top: 16,
              right: 16,
              child: _buildFloatingToggleButton(),
            ),

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

  Widget _buildFloatingToggleButton() {
    return Material(
      elevation: 4,
      shape: CircleBorder(),
      color: ThemeHelper.cardBackground(context),
      child: InkWell(
        onTap: () {
          setState(() {
            _showAll = !_showAll;

            // When showing all dealers, keep them in collapsed mode
            // When showing only 5 dealers, also keep them collapsed

            if (!_showAll) {
              // When switching to "show 5 only", collapse all
              _expandedDealers.clear();
            }
            // When switching to "show all", do nothing - keep current expansion state
          });
        },
        customBorder: CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ThemeHelper.borderColor(context),
              width: 1,
            ),
          ),
          child: Icon(
            _showAll ? Icons.remove : Icons.add,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
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
            Icon(Icons.check_circle_outline, color: ThemeHelper.successColor, size: 64),
            SizedBox(height: 16),
            Text(
              'No Pending Orders',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
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

    Map<String, List<Map<String, dynamic>>> groupedOrders = _groupByDealer();

    // Limit to 5 dealers if not showing all
    var dealerEntries = groupedOrders.entries.toList();
    var visibleDealers = _showAll ? dealerEntries : dealerEntries.take(5).toList();

    return RefreshIndicator(
      onRefresh: _fetchPendingOrders,
      color: Theme.of(context).primaryColor,
      child: ListView(
        padding: EdgeInsets.only(left: 16, right: 16, top: 72, bottom: 100),
        children: [
          // Search bar
          // Dealer cards
          ...visibleDealers.map((entry) {
            String dealerName = entry.key;
            List<Map<String, dynamic>> orders = entry.value;
            bool isExpanded = _expandedDealers.contains(dealerName);

            return _buildDealerCard(dealerName, orders, isExpanded);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDealerCard(String dealerName, List<Map<String, dynamic>> orders, bool isExpanded) {
    int orderCount = orders.length;
    double totalAmount = orders.fold(0.0, (sum, order) => sum + (order['Amount'] ?? 0.0));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeHelper.cardBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ThemeHelper.borderColor(context).withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dealerName,
                      style: ThemeHelper.titleStyle(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleDealerExpansion(dealerName),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExpanded ? Icons.remove : Icons.add,
                        color: Theme.of(context).primaryColor,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Summary Container (like dealer_sales_view)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    /*Expanded(
                      child: _buildSummaryItem(
                        icon: Icons.receipt_long,
                        label: '$orderCount ${orderCount == 1 ? 'Order' : 'Orders'}',
                        value: '',
                        color: ThemeHelper.accentBlue,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: ThemeHelper.dividerColor(context),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),*/
                    Expanded(
                      child: _buildSummaryItem(

                        label: '',
                        value: 'Total Amount : ' + _formatAmount(totalAmount),
                        color: ThemeHelper.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded Content
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1B2E), // Dark background like in the image
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: [
                        // Table Header
                        _buildOrderTableHeader(),
                        // Orders
                        ...orders.map((order) => _buildOrderRow(order)).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    IconData? icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: ThemeHelper.bodyStyle(context).copyWith(
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (value.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            value,
            style: ThemeHelper.titleStyle(context).copyWith(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderTableHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF252641), // Slightly lighter than the container background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            child: Text(
              'Date',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 170,
            child: Text(
              'Order No',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 8),
          /*Container(
            width: 130,
            child: Text(
              'Invoice No.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 8),*/
          Container(
            width: 85,
            child: Text(
              'Amount',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 80,
            child: Text(
              'Status',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    String orderNumber = order['orderNo']?.toString() ?? 'N/A';
    String invoiceNumber = order['voucherNo']?.toString() ?? 'N/A';
    String status = order['Status']?.toString() ?? 'N/A';
    String dateStr = order['orderDate']?.toString() ?? '';
    double amount = order['Amount'] ?? 0.0;

    // Format date
    String formattedDate = 'N/A-0';
    try {
      if (dateStr.isNotEmpty) {
        DateTime orderDate = DateTime.parse(dateStr);
        formattedDate = DateFormat('dd-MM-yy').format(orderDate);
      }
    } catch (e) {
      formattedDate = 'N/A';
    }

    return InkWell(
      onTap: () => _navigateToOrderDetails(order),
      child: Container(
        margin: EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF2A2B42),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Date column
            Container(
              width: 70,
              child: Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 8),
            // Order Number column (button style)
            Container(
              width: 170,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF5B5FC7), // Blue button color from image
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        orderNumber,
                        style: TextStyle(
                          color: Colors.white,
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
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            /*Container(
              width: 130,
              child: Text(
                invoiceNumber,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),*/
            // Amount column
            Container(
              width: 85,
              child: Text(
                _formatAmount(amount),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 8),
            Container(
              width: 60,
              child: Text(
                status,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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


  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
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
    int totalOrders = _orderData.length;
    int totalDealers = _groupByDealer().length;

    double totalAmount = 0.0;

    for (var order in _orderData) {
      var amount = order['Amount'];
      if (amount != null) {
        if (amount is num) {
          totalAmount += amount.toDouble();
        } else if (amount is String) {
          totalAmount += double.tryParse(amount) ?? 0.0;
        }
      }
    }

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Total Dealers
            Row(
              children: [
                Icon(Icons.people, color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Dealers: $totalDealers',
                  style: TextStyle(
                    color: ThemeHelper.textColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            Container(
              width: 1,
              height: 20,
              color: ThemeHelper.borderColor(context),
            ),

            // Total Orders
            /*Row(
              children: [
                Icon(Icons.receipt_long, color: ThemeHelper.warningColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Orders: $totalOrders',
                  style: TextStyle(
                    color: ThemeHelper.textColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),*/

            Container(
              width: 1,
              height: 20,
              color: ThemeHelper.borderColor(context),
            ),

            // Total Amount
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: ThemeHelper.successColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Total: ' + _formatAmount(totalAmount),
                  style: TextStyle(
                    color: ThemeHelper.textColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
// Search Text Widget
class SearchTextFilter extends StatefulWidget {
  final String? initialValue;
  final String hint;
  final ValueChanged<String> onChanged;
  final int minCharacters;

  const SearchTextFilter({
    Key? key,
    this.initialValue,
    this.hint = "Search...",
    required this.onChanged,
    this.minCharacters = 3,
  }) : super(key: key);

  @override
  State<SearchTextFilter> createState() => _SearchTextFilterState();
}

class _SearchTextFilterState extends State<SearchTextFilter> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ThemeHelper.inputDecoration(context),
      child: TextField(
        controller: _controller,
        style: ThemeHelper.subtitleStyle(context),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: ThemeHelper.hintTextColor(context),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: ThemeHelper.iconColor(context),
            size: 22,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: ThemeHelper.iconColor(context),
              size: 20,
            ),
            onPressed: () {
              _controller.clear();
              widget.onChanged('');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
      ),
    );
  }
}