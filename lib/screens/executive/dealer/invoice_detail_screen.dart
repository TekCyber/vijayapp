// lib/views/dealer/invoice_detail_screen.dart - THEME-AWARE VERSION
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../widgets/glass_container.dart';
import '../../../services/api_service.dart';
import '../../../theme/theme_helpers.dart';
import '../menu_navigator.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceNo;
  final String dealerName;
  final String financialYear;
  final Function(int)? onMenuSelected;

  InvoiceDetailScreen({
    required this.invoiceNo,
    required this.dealerName,
    required this.financialYear,
    this.onMenuSelected,
  });

  @override
  _InvoiceDetailScreenState createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  int selectedMenuIndex = 0;

  List<Map<String, dynamic>> _invoiceItems = [];
  bool _isLoading = true;
  String _errorMessage = '';
  double _cgst = 0.0;
  double _sgst = 0.0;
  double _roundOff = 0.0;
  double _charges = 0.0;
  double _totalDisc = 0.0;
  String _invoiceDate = '';

  @override
  void initState() {
    super.initState();
    _fetchInvoiceDetails();
  }

  Future<void> _fetchInvoiceDetails() async {
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
        "sqlKey": "GET_INVOICE_DETAILS",
        "invoiceno": widget.invoiceNo.split("/" + widget.financialYear)[0] + "/" + widget.financialYear
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData =
        List<Map<String, dynamic>>.from(response.data!);

        if (fetchedData.isNotEmpty) {
          _cgst = _parseAmount(fetchedData[0]['CGST']);
          _sgst = _parseAmount(fetchedData[0]['SGST']);
          _roundOff = _parseAmount(fetchedData[0]['RoundOff']);
          _charges = _parseAmount(fetchedData[0]['Charges']);
          _totalDisc = _parseAmount(fetchedData[0]['total_disc']);
          _invoiceDate = fetchedData[0]['Date']?.toString() ?? '';
        }

        setState(() {
          _invoiceItems = fetchedData;
          _isLoading = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch invoice details');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading invoice details: ${e.toString()}';
      });
      print('Error fetching invoice details: $e');
    }
  }

  double _parseAmount(dynamic amount) {
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      return double.tryParse(amount.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  int _parseQty(dynamic Qty) {
    if (Qty is num) return Qty.toInt();
    if (Qty is String) {
      return int.tryParse(Qty.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }

  double _calculateSubTotal() {
    double total = 0.0;
    for (var item in _invoiceItems) {
      total += _parseAmount(item['Amount']);
    }
    return total;
  }

  double _calculateGrandTotal() {
    double subTotal = _calculateSubTotal();
    return subTotal + _cgst + _sgst + _roundOff + _charges + _totalDisc;
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    return '${Formatters.formatNumber(amount)}';
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Invoice Details',
      subtitle: widget.dealerName,
      onTabSelected: _onMenuSelected,
      showBackButton: true,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchInvoiceDetails,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInvoiceHeader(),
                  const SizedBox(height: 16),
                  _buildInvoiceItemsContent(),
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

  Widget _buildInvoiceHeader() {
    return GlassContainer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    widget.invoiceNo,
                    style: ThemeHelper.titleStyle(context),
                  ),
                ),
              ],
            ),
            if (_invoiceDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: ThemeHelper.subtleTextColor(context),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Date: $_invoiceDate',
                    style: ThemeHelper.bodyStyle(context).copyWith(
                      color: ThemeHelper.subtleTextColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceItemsContent() {
    return GlassContainer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: _buildContent(),
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
                color: ThemeHelper.loadingColor(context),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Loading invoice details...',
                style: ThemeHelper.captionStyle(context),
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
              Icon(Icons.error_outline, color: ThemeHelper.errorColor, size: 48),
              SizedBox(height: 16),
              Text(
                _errorMessage,
                style: TextStyle(color: ThemeHelper.errorColor, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchInvoiceDetails,
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

    if (_invoiceItems.isEmpty) {
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
                'No items found',
                style: ThemeHelper.subtitleStyle(context).copyWith(
                  color: ThemeHelper.subtleTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 900,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTableHeader(),
            const SizedBox(height: 8),
            ..._invoiceItems.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> item = entry.value;
              bool isEven = index % 2 == 0;
              return _buildDataRow(item, isEven);
            }).toList(),
            const SizedBox(height: 12),
            _buildTaxRows(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeHelper.borderColor(context),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Item Name', width: 350),
          _buildHeaderCell('Qty', width: 80),
          _buildHeaderCell('Rate', width: 100),
          _buildHeaderCell('Disc', width: 100),
          _buildHeaderCell('Amount', width: 150),
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
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        textAlign: title == 'Item Name' ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> item, bool isEven) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: ThemeHelper.rowBackground(context, isEven),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _buildDataCell(
            item['ItemName']?.toString() ?? 'N/A',
            width: 350,
            textAlign: TextAlign.left,
          ),
          _buildDataCell(
            _parseQty(item['Qty']).toString(),
            width: 80,
          ),
          _buildDataCell(
            _formatAmount(item['Rate']),
            width: 100,
            isAmount: true,
          ),
          _buildDataCell(
            _formatAmount(item['Discount']),
            width: 100,
            isAmount: true,
          ),
          _buildDataCell(
            _formatAmount(item['Amount']),
            width: 150,
            isAmount: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRows() {
    return Column(
      children: [
        Container(
          height: 1,
          color: ThemeHelper.borderColor(context),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        _buildSummaryRow('Subtotal', _calculateSubTotal()),
        const SizedBox(height: 4),
        _buildSummaryRow('CGST', _cgst),
        const SizedBox(height: 4),
        _buildSummaryRow('SGST', _sgst),
        const SizedBox(height: 4),
        if (_roundOff != 0.0) ...[
          _buildSummaryRow('Round Off', _roundOff),
          const SizedBox(height: 4),
        ],
        if (_charges != 0.0) ...[
          _buildSummaryRow('Delivery Charges', _charges),
          const SizedBox(height: 4),
        ],
        if (_totalDisc != 0.0) ...[
          _buildSummaryRow('Discount', _totalDisc.abs(), isDiscount: true),
          const SizedBox(height: 4),
        ],
        Container(
          height: 1,
          color: ThemeHelper.borderColor(context),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        _buildSummaryRow('Grand Total', _calculateGrandTotal(), isGrandTotal: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isGrandTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(width: 350),
          SizedBox(width: 80),
          Container(
            width: 200,
            alignment: Alignment.centerRight,
            child: Text(
              '$label:',
              style: TextStyle(
                color: isGrandTotal
                    ? ThemeHelper.textColor(context)
                    : ThemeHelper.subtleTextColor(context),
                fontSize: isGrandTotal ? 14 : 13,
                fontWeight: isGrandTotal ? FontWeight.w700 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
          Container(
            width: 150,
            alignment: Alignment.centerRight,
            child: Text(
              isGrandTotal
                  ? Formatters.formatCurrency(amount)
                  : (isDiscount ? '- ${_formatAmount(amount)}' : _formatAmount(amount)),
              style: TextStyle(
                color: isGrandTotal
                    ? ThemeHelper.warningColor
                    : (isDiscount ? ThemeHelper.errorColor : ThemeHelper.textColor(context)),
                fontSize: isGrandTotal ? 16 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
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
              : (isAmount ? ThemeHelper.subtleTextColor(context) : ThemeHelper.subtleTextColor(context)),
          fontSize: 13,
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
    double grandTotal = _calculateGrandTotal();

    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Total Items: ${_invoiceItems.length}',
              style: ThemeHelper.bodyStyle(context),
            ),
            const Spacer(),
            Text(
              'Total: ',
              style: ThemeHelper.bodyStyle(context),
            ),
            const SizedBox(width: 4),
            Text(
              _isLoading ? '...' : Formatters.formatCurrency(grandTotal),
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