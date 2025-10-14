// lib/views/dealer/dealer_outstanding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/formatters.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/glass_container.dart';
import '../../services/api_service.dart';
import 'menu_navigator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DealerOutstandingScreen extends StatefulWidget {
  final String title; // dealerName
  final Function(int)? onMenuSelected;

  DealerOutstandingScreen({required this.title, this.onMenuSelected});

  @override
  _DealerOutstandingScreenState createState() => _DealerOutstandingScreenState();
}

class _DealerOutstandingScreenState extends State<DealerOutstandingScreen> {
  late TabController _tabController;
  int selectedMenuIndex = 0;
  int _currentTabIndex = 0;

  // Outstanding data state variables
  List<Map<String, dynamic>> _outstandingData = [];
  bool _isLoadingOutstanding = true;
  String _errorMessageOutstanding = '';

  // Aging data state variables
  List<Map<String, dynamic>> _agingData = [];
  bool _isLoadingAging = true;
  String _errorMessageAging = '';

  @override
  void initState() {
    super.initState();
    // Fetch outstanding data
    _fetchOutstandingData();
    _fetchAgingData();
  }

  Future<void> _downloadPdf() async {
    if (_outstandingData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No Outstanding data to download")),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final domainName = prefs.getString("saved_company") ?? 'Company Name';

      final logoBytes = (await rootBundle.load("assets/images/vijaipipes_logo.png"))
          .buffer
          .asUint8List();

      final rsBytes = (await rootBundle.load("assets/images/rs.png"))
          .buffer
          .asUint8List();

      final ttf = pw.Font.helvetica();
      final ttfBold = pw.Font.helveticaBold();

      final pdf = pw.Document();

      // Get dynamic columns from the first data row, excluding CD/REG column
      final allColumns = _outstandingData.isNotEmpty ? _outstandingData.first.keys.toList() : [];
      final columns = allColumns.where((col) =>
      !col.toLowerCase().contains('cd_reg') &&
          !col.toLowerCase().contains('cd/reg') &&
          col.toLowerCase() != 'cd' &&
          col.toLowerCase() != 'reg'
      ).toList();

      if (columns.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No data columns found")),
        );
        return;
      }

      // Calculate total outstanding
      double totalOutstanding = 0;
      String pendingKey = '';

      // Find the correct pending amount key
      for (var key in columns) {
        if (key.toLowerCase().contains('pending')) {
          pendingKey = key;
          break;
        }
      }

      if (pendingKey.isNotEmpty) {
        for (var row in _outstandingData) {
          final val = row[pendingKey];
          if (val is num) {
            totalOutstanding += val.toDouble();
          } else if (val is String) {
            totalOutstanding += double.tryParse(val.replaceAll(',', '')) ?? 0;
          }
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.only(top: 100, left: 32, right: 32, bottom: 32),

          // HEADER WITH COMPANY INFO AND PAGE NUMBER
          header: (context) {
            return pw.Container(
              padding: pw.EdgeInsets.only(bottom: 16),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.grey400,
                    width: 1,
                  ),
                ),
              ),
              child: pw.Column(
                children: [
                  // First row: Logo + Company name + Page number
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Image(pw.MemoryImage(logoBytes), width: 50, height: 50),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Text(
                          domainName,
                          style: pw.TextStyle(font: ttfBold, fontSize: 20),
                        ),
                      ),
                      pw.Text(
                        'Page ${context.pageNumber}',
                        style: pw.TextStyle(font: ttf, fontSize: 12),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),

                  // Second row: Report title and dealer name
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Outstanding Report - ${widget.title}",
                        style: pw.TextStyle(font: ttfBold, fontSize: 16),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),

                  // Third row: Generation date
                  pw.Row(
                    children: [
                      pw.Text(
                        "Generated on: ${Formatters.formatDate(DateTime.now())}",
                        style: pw.TextStyle(font: ttf, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },

          // FOOTER
          footer: (context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                'Generated by ${domainName}',
                style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600),
              ),
            );
          },

          build: (context) => [
            // Data Table
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.8
              ),
              columnWidths: {
                for (int i = 0; i < columns.length; i++)
                  i: _getColumnWidthForPdf(columns[i])
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: columns.map((col) => pw.Padding(
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text(
                      col,
                      style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 11
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  )).toList(),
                ),

                // Data rows
                ..._outstandingData.map((row) {
                  return pw.TableRow(
                    children: columns.map((col) {
                      final val = row[col];
                      return pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: _buildPdfCellContentForTable(val, rsBytes, ttf),
                      );
                    }).toList(),
                  );
                }).toList(),

                // Total row (if pending column exists)
                if (pendingKey.isNotEmpty && totalOutstanding > 0)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: columns.map((col) {
                      if (col == pendingKey) {
                        return pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Container(
                                width: 12,
                                height: 12,
                                child: pw.Image(
                                  pw.MemoryImage(rsBytes),
                                  fit: pw.BoxFit.contain,
                                ),
                              ),
                              pw.SizedBox(width: 4),
                              pw.Text(
                                Formatters.formatNumber(totalOutstanding),
                                style: pw.TextStyle(font: ttfBold, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      } else if (col == columns.first) {
                        return pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'TOTAL:',
                            style: pw.TextStyle(font: ttfBold, fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        );
                      } else {
                        return pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(''),
                        );
                      }
                    }).toList(),
                  ),
              ],
            ),

            pw.SizedBox(height: 16),

            // Summary section
            pw.Container(
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                color: PdfColors.grey50,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Records: ${_outstandingData.length}',
                    style: pw.TextStyle(font: ttf, fontSize: 12),
                  ),
                  if (totalOutstanding > 0)
                    pw.Row(
                      children: [
                        pw.Text(
                          'Total Outstanding: ',
                          style: pw.TextStyle(font: ttf, fontSize: 12),
                        ),
                        pw.Container(
                          width: 14,
                          height: 14,
                          child: pw.Image(
                            pw.MemoryImage(rsBytes),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          Formatters.formatNumber(totalOutstanding),
                          style: pw.TextStyle(font: ttfBold, fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: "Outstanding_Report_${widget.title}_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PDF generated successfully"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error generating PDF: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Helper method to build PDF cell content for table
  pw.Widget _buildPdfCellContentForTable(dynamic val, Uint8List rsBytes, pw.Font ttf) {
    if (val == null) {
      return pw.Text('', style: pw.TextStyle(font: ttf, fontSize: 10));
    }

    // Check if it's a numeric value (amount)
    if (val is num) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            width: 10,
            height: 10,
            child: pw.Image(
              pw.MemoryImage(rsBytes),
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(width: 3),
          pw.Text(
            Formatters.formatNumber(val.toDouble()),
            style: pw.TextStyle(font: ttf, fontSize: 10),
          ),
        ],
      );
    }

    // Check if it's a string that represents a number
    if (val is String && double.tryParse(val.replaceAll(',', '')) != null) {
      double amount = double.parse(val.replaceAll(',', ''));
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            width: 10,
            height: 10,
            child: pw.Image(
              pw.MemoryImage(rsBytes),
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(width: 3),
          pw.Text(
            Formatters.formatNumber(amount),
            style: pw.TextStyle(font: ttf, fontSize: 10),
          ),
        ],
      );
    }

    // Check if it's a date
    if (val is DateTime) {
      return pw.Text(
        Formatters.formatDate(val),
        style: pw.TextStyle(font: ttf, fontSize: 10),
        textAlign: pw.TextAlign.center,
      );
    }

    // Try to parse string as date
    if (val is String) {
      try {
        final dt = DateTime.parse(val);
        return pw.Text(
          Formatters.formatDate(dt),
          style: pw.TextStyle(font: ttf, fontSize: 10),
          textAlign: pw.TextAlign.center,
        );
      } catch (_) {
        // Not a date, treat as regular string
      }
    }

    // Default: treat as string
    return pw.Text(
      val.toString(),
      style: pw.TextStyle(font: ttf, fontSize: 10),
      textAlign: pw.TextAlign.center,
    );
  }

// Helper method to define individual column width for PDF
  pw.TableColumnWidth _getColumnWidthForPdf(String columnName) {
    String col = columnName.toLowerCase();

    // Adjust column widths based on content type
    if (col.contains('date')) {
      return pw.FixedColumnWidth(80);
    } else if (col.contains('ref') || col.contains('no')) {
      return pw.FixedColumnWidth(70);
    } else if (col.contains('pending') || col.contains('opening') || col.contains('amount')) {
      return pw.FixedColumnWidth(90);
    } else {
      return pw.FlexColumnWidth(1);
    }
  }

  Future<void> _fetchAgingData() async {
    try {
      setState(() {
        _isLoadingAging = true;
        _errorMessageAging = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_AGING_DETAILS_BY_DEALER",
        "dealername": widget.title,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData = List<Map<String, dynamic>>.from(response.data!);

        setState(() {
          _agingData = fetchedData;
          _isLoadingAging = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch aging data');
      }
    } catch (e) {
      setState(() {
        _isLoadingAging = false;
        _errorMessageAging = 'Error loading aging data: ${e.toString()}';
      });
      print('Error fetching aging data: $e');
    }
  }

  double _getAgingValue(Map<String, dynamic> data, String key) {
    return double.tryParse(data[key]?.toString() ?? '0') ?? 0.0;
  }

  double _calculateTotal(Map<String, dynamic> data) {
    double total = 0.0;
    List<String> keys = ['(< 30 days )', '30 to 60 days', '60 to 75 days', '75 to 90 days',  '(> 90 days )'];

    for (String key in keys) {
      total += _getAgingValue(data, key);
    }

    return total;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  // Fetch outstanding data from API
  Future<void> _fetchOutstandingData() async {
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
        "sqlKey": "GET_OUTSTANDING_LIST_BY_DEALER",
        "dealername": widget.title,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData = List<Map<String, dynamic>>.from(response.data!);

        setState(() {
          _outstandingData = fetchedData;
          _isLoadingOutstanding = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch outstanding data');
      }
    } catch (e) {
      setState(() {
        _isLoadingOutstanding = false;
        _errorMessageOutstanding = 'Error loading outstanding data: ${e.toString()}';
      });
      print('Error fetching outstanding data: $e');
    }
  }

  // Calculate total outstanding from dynamic data
  double _calculateTotalOutstanding() {
    if (_outstandingData.isEmpty) return 0.0;

    double total = 0.0;
    for (var row in _outstandingData) {
      double pending = double.tryParse(row['Pending']?.toString() ?? '0') ?? 0.0;
      total += pending;
    }

    return total;
  }

  // Helper method to format amounts
  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    return '${Formatters.formatNumber(amount)}';
    //Formatters.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic title based on current tab
    String currentTitle = _currentTabIndex == 0 ? 'Outstanding Analysis' : 'Aging Analysis';

    return DashboardLayout(
      title: currentTitle, // Dynamic title changes with tab
      subtitle: widget.title, // Dealer name as subtitle
      onTabSelected: _onMenuSelected,
      showBackButton: true,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await Future.wait([_fetchOutstandingData(), _fetchAgingData()]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: _currentTabIndex == 0 ? 100 : 16, // Extra bottom padding for Outstanding tab
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Simple Tab Bar (like DealerSalesView)
                  _buildSimpleTabBar(),
                  const SizedBox(height: 16),

                  // Tab Content (no animation)
                  if (_currentTabIndex == 0)
                    _buildOutstandingTab()
                  else
                    _buildAgingTab(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Fixed bottom summary bar for Outstanding tab only
          if (_currentTabIndex == 0)
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

  Widget _buildSimpleTabBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _currentTabIndex = 0);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _currentTabIndex == 0 ? Colors.blueAccent.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Outstanding',
              style: TextStyle(
                color: _currentTabIndex == 0 ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() => _currentTabIndex = 1);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _currentTabIndex == 1 ? Colors.blueAccent.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Aging',
              style: TextStyle(
                color: _currentTabIndex == 1 ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutstandingTab() {
    return GlassContainer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: _buildOutstandingContent(),
      ),
    );
  }

  Widget _buildOutstandingContent() {
    if (_isLoadingOutstanding) {
      return Container(
        height: 200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(height: 16),
              Text('Loading outstanding data...', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (_errorMessageOutstanding.isNotEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessageOutstanding, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchOutstandingData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_outstandingData.isEmpty) {
      return Container(
        height: 200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, color: Colors.white60, size: 48),
              SizedBox(height: 16),
              Text('No outstanding data available', style: TextStyle(color: Colors.white60, fontSize: 16)),
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
            _buildWideTableHeader(),
            const SizedBox(height: 8),
            ..._buildWideOutstandingData(),
          ],
        ),
      ),
    );
  }

  Widget _buildWideTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.2), // Consistent with DealerSalesView
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildWideHeaderCell('Date', width: 120),
          _buildWideHeaderCell('Ref No', width: 140),
          _buildWideHeaderCell('Opening', width: 120),
          _buildWideHeaderCell('Pending', width: 120),
          _buildWideHeaderCell('Post Dated', width: 120),
          _buildWideHeaderCell('On Account', width: 120),
        ],
      ),
    );
  }

  Widget _buildWideHeaderCell(String title, {required double width}) {
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

  List<Widget> _buildWideOutstandingData() {
    return _outstandingData.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> row = entry.value;
      bool isEven = index % 2 == 0;

      return _buildWideDataRow(row, isEven);
    }).toList();
  }

  Widget _buildWideDataRow(Map<String, dynamic> data, bool isEven) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isEven
            ? Colors.white.withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _buildWideDataCell(data['Date']?.toString() ?? 'N/A', width: 120),
          _buildWideDataCell(data['Ref. No.']?.toString() ?? 'N/A', width: 140),
          _buildWideDataCell(
              _formatAmount(data['Opening']),
              width: 120,
              isAmount: true
          ),
          _buildWideDataCell(
              _formatAmount(data['Pending']),
              width: 120,
              isAmount: true,
              isPending: true
          ),
          _buildWideDataCell(
              _formatAmount(data['PostDated']),
              width: 120,
              isAmount: true
          ),
          _buildWideDataCell(
              _formatAmount(data['OnAccount']),
              width: 120,
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
    bool isPending = false,
    bool isPositive = false,
  }) {
    Color textColor = Colors.white70;

    if (isPending) {
      textColor = Colors.orange;
    } else if (isPositive) {
      textColor = Colors.green;
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
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBottomSummaryBar() {
    double totalAmount = _calculateTotalOutstanding();

    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet,
              color: Colors.blueAccent,
              size: 16,
            ),
            const SizedBox(width: 8),
            const Text(
              'Total Outstanding:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              _isLoadingOutstanding
                  ? '...'
                  : (totalAmount > 0 ? Formatters.formatCurrency(totalAmount) : '₹0.00'),
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            // PDF download icon
            GestureDetector(
              onTap: _downloadPdf,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgingTab() {
    return GlassContainer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: _buildAgingContent(),
      ),
    );
  }

  Widget _buildAgingContent() {
    if (_isLoadingAging) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Loading aging data...',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessageAging.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessageAging,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAgingData,
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
      );
    }

    if (_agingData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No outstanding bills',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'All bills are up to date',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return _buildSimplifiedAgingTable();
  }

  Widget _buildSimplifiedAgingTable() {
    Map<String, dynamic> agingData = _agingData.first;

    return Column(
      children: [
        // Pending Bills - Main row
        _buildSimpleAgingTableRow(
          'Pending Bills',
          _getAgingValue(agingData, 'Pending Bills'),
          null,
          true,
        ),

        const SizedBox(height: 16),

        const Text(
          'Aging Breakdown',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        // Aging breakdown rows
        _buildSimpleAgingTableRow(
          '(< 30 days )',
          _getAgingValue(agingData, '(< 30 days )'),
          Colors.green,
        ),
        _buildSimpleAgingTableRow(
          '30 to 60 days',
          _getAgingValue(agingData, '30 to 60 days'),
          Colors.blue,
        ),
        _buildSimpleAgingTableRow(
          '60 to 75 days',
          _getAgingValue(agingData, '60 to 75 days'),
          Colors.orange,
        ),
        _buildSimpleAgingTableRow(
          '75 to 90 days',
          _getAgingValue(agingData, '75 to 90 days'),
          Colors.deepOrange,
        ),

        _buildSimpleAgingTableRow(
          '(> 90 days )',
          _getAgingValue(agingData, '(> 90 days )'),
          Colors.red,
        ),

        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 1,
          color: Colors.white.withOpacity(0.2),
        ),
        const SizedBox(height: 12),

        // On Account row
        _buildSimpleAgingTableRow(
          'On Account',
          _getAgingValue(agingData, 'On Account'),
          Colors.green,
          true,
        ),
      ],
    );
  }

  Widget _buildSimpleAgingTableRow(String label, double amount, [Color? indicatorColor, bool isMainRow = false]) {
    return Container(
      margin: EdgeInsets.only(bottom: isMainRow ? 12 : 8),
      padding: EdgeInsets.symmetric(vertical: isMainRow ? 12 : 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isMainRow
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: isMainRow
            ? Border.all(color: Colors.white.withOpacity(0.2))
            : null,
      ),
      child: Row(
        children: [
          // Indicator dot for non-main rows
          if (!isMainRow && indicatorColor != null)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: indicatorColor.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
            ),

          // Label
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isMainRow ? Colors.white : Colors.white70,
                fontSize: isMainRow ? 18 : 14,
                fontWeight: isMainRow ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),

          // Amount with credit indicator if negative
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (amount < 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'CR',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                (label == 'Pending Bills') ? Formatters.formatCurrency(amount.abs()) : _formatAmount(amount.abs()),
                style: TextStyle(
                  color: amount < 0
                      ? Colors.red
                      : (isMainRow ? Colors.white : Colors.white),
                  fontSize: isMainRow ? 20 : 16,
                  fontWeight: isMainRow ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}