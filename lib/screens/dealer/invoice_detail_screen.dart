// lib/views/dealer/invoice_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/formatters.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/glass_container.dart';
import '../../services/api_service.dart';
import 'menu_navigator.dart';

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
        "invoiceno":    widget.invoiceNo.split("/" + widget.financialYear )[0]+ "/" + widget.financialYear
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData =
        List<Map<String, dynamic>>.from(response.data!);

        // Extract CGST, SGST, RoundOff, and Charges from the first row
        if (fetchedData.isNotEmpty) {
          _cgst = _parseAmount(fetchedData[0]['CGST']);
          _sgst = _parseAmount(fetchedData[0]['SGST']);
          _roundOff = _parseAmount(fetchedData[0]['RoundOff']);
          _charges = _parseAmount(fetchedData[0]['Charges']);
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
    return subTotal + _cgst + _sgst + _roundOff + _charges;
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

          // Fixed bottom summary bar
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
                const Icon(
                  Icons.receipt_long,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.invoiceNo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Loading invoice details...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
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
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchInvoiceDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, color: Colors.white60, size: 48),
              SizedBox(height: 16),
              Text(
                'N/A',
                style: TextStyle(color: Colors.white60, fontSize: 16),
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
        color: Colors.blueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('ItemName', width: 300),
          _buildHeaderCell('Qty', width: 30),
          _buildHeaderCell('Rate', width: 60),
          _buildHeaderCell('Disc', width: 60),
          _buildHeaderCell('Amount', width: 130),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {required double width}) {
    return Container(
      width: width,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> item, bool isEven) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isEven ? Colors.white.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _buildDataCell(
            item['ItemName']?.toString() ?? 'N/A',
            width: 300,
            textAlign: TextAlign.left, // Add this line
          ),
          _buildDataCell(
            _parseQty(item['Qty']).toString(),
            width: 30,
          ),
          _buildDataCell(
            _formatAmount(item['Rate']),
            width: 60,
            isAmount: true,
          ),
          _buildDataCell(
            _formatAmount(item['Discount']),
            width: 60,
            isAmount: true,
          ),
          _buildDataCell(
            _formatAmount(item['Amount']),
            width: 130,
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
        // Divider
        Container(
          height: 1,
          color: Colors.white.withOpacity(0.2),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        // Subtotal
        _buildSummaryRow('Subtotal', _calculateSubTotal()),
        const SizedBox(height: 4),
        // CGST
        _buildSummaryRow('CGST', _cgst),
        const SizedBox(height: 4),
        // SGST
        _buildSummaryRow('SGST', _sgst),
        const SizedBox(height: 4),
        // Round Off
        if (_roundOff != 0.0) ...[
          _buildSummaryRow('Round Off', _roundOff),
          const SizedBox(height: 4),
        ],
        // Delivery Charge
        if (_charges != 0.0) ...[
          _buildSummaryRow('Delivery Charges', _charges),
          const SizedBox(height: 4),
        ],
        // Divider before grand total
        Container(
          height: 1,
          color: Colors.white.withOpacity(0.2),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        // Grand Total
        _buildSummaryRow('Grand Total', _calculateGrandTotal(), isGrandTotal: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isGrandTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Empty space for ItemName column
          SizedBox(width: 300),
          // Empty space for Qty column
          SizedBox(width: 30),
          // Label spans Rate + Disc columns
          Container(
            width: 120, // 60 (Rate) + 60 (Disc)
            alignment: Alignment.centerRight,
            child: Text(
              '$label:',
              style: TextStyle(
                color: isGrandTotal ? Colors.white : Colors.white70,
                fontSize: isGrandTotal ? 14 : 13,
                fontWeight: isGrandTotal ? FontWeight.w700 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
          // Amount in Amount column
          Container(
            width: 130,
            alignment: Alignment.centerRight,
            child: Text(
              isGrandTotal ? Formatters.formatCurrency(amount) :  _formatAmount(amount),
              style: TextStyle(
                color: isGrandTotal ? Colors.orange : Colors.white,
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
        TextAlign? textAlign, // Add this parameter
      }) {
    return Container(
      width: width,
      child: Text(
        value,
        style: TextStyle(
          color: isTotal
              ? Colors.white
              : (isAmount ? Colors.white70 : Colors.white60),
          fontSize: 13,
          fontWeight: isTotal
              ? FontWeight.w700
              : (isAmount ? FontWeight.w600 : FontWeight.w500),
        ),
        textAlign: textAlign ?? TextAlign.center, // Use provided alignment or default to center
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
            const Icon(
              Icons.shopping_cart,
              color: Colors.blueAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Total Items: ${_invoiceItems.length}',
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
              _isLoading ? '...' : Formatters.formatCurrency(grandTotal),
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