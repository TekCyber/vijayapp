// lib/views/dealer/dealer_outstanding_screen.dart - THEME-AWARE VERSION WITH CHECKBOXES
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/dashboard_layout.dart';
import '../../../widgets/glass_container.dart';
import '../../../services/api_service.dart';
import '../../../theme/theme_helpers.dart';
import '../menu_navigator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DealerOutstandingScreen extends StatefulWidget {
  final String title;
  final Function(int)? onMenuSelected;

  DealerOutstandingScreen({required this.title, this.onMenuSelected});

  @override
  _DealerOutstandingScreenState createState() => _DealerOutstandingScreenState();
}

class _DealerOutstandingScreenState extends State<DealerOutstandingScreen> {
  late TabController _tabController;
  int selectedMenuIndex = 0;
  int _currentTabIndex = 0;

  List<Map<String, dynamic>> _outstandingData = [];
  bool _isLoadingOutstanding = true;
  String _errorMessageOutstanding = '';

  List<Map<String, dynamic>> _agingData = [];
  bool _isLoadingAging = true;
  String _errorMessageAging = '';

  // CHECKBOX SELECTION - NEW ADDITION
  Set<int> _selectedRows = {};
  double _selectedTotal = 0.0;

  // PDF Summary Box Colors - Customize these as needed
  static const PdfColor _pdfSummaryBackground = PdfColors.red50;
  static const PdfColor _pdfSummaryBorder = PdfColors.red700;
  static const PdfColor _pdfSummaryText = PdfColors.red900;

  // Rupee symbol color in hex format (should match _pdfSummaryText)
  // Red900 = #7f1d1d, Blue900 = #1e3a8a, etc.
  static const String _pdfRupeeSymbolColor = '#7f1d1d';  // Matches red900

  @override
  void initState() {
    super.initState();
    _fetchOutstandingData();
    _fetchAgingData();
  }

  // NEW METHODS FOR CHECKBOX FUNCTIONALITY
  void _calculateSelectedTotal() {
    double total = 0.0;

    for (int index in _selectedRows) {
      if (index < _outstandingData.length) {
        final row = _outstandingData[index];
        double pending = double.tryParse(row['Pending']?.toString() ?? '0') ?? 0.0;
        total += pending;
      }
    }

    setState(() {
      _selectedTotal = total;
    });
  }

  void _toggleRowSelection(int index) {
    setState(() {
      if (_selectedRows.contains(index)) {
        _selectedRows.remove(index);
      } else {
        _selectedRows.add(index);
      }
      _calculateSelectedTotal();
    });
  }

  void _clearSelections() {
    setState(() {
      _selectedRows.clear();
      _selectedTotal = 0.0;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedRows.length == _outstandingData.length) {
        _selectedRows.clear();
      } else {
        _selectedRows = Set.from(List.generate(_outstandingData.length, (index) => index));
      }
      _calculateSelectedTotal();
    });
  }
  // END OF NEW CHECKBOX METHODS

  Future<void> _downloadPdf() async {

    print('===== PDF GENERATION DEBUG =====');
    print('_outstandingData.length: ${_outstandingData.length}');
    print('_selectedRows.length: ${_selectedRows.length}');
    print('================================');


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

      // **DEFINE SPECIFIC COLUMNS TO SHOW IN PDF**
      // Display names for PDF headers
      final columnHeaders = [
        'Date',
        'Invoice No.',  // Changed from 'Ref. No.'
        'Opening',
        'Pending',
        'PostDated',
        'OnAccount',
      ];

      // Actual data keys in the data map
      final dataKeys = [
        'Date',
        'Ref. No.',  // This is the actual key in the data
        'Opening',
        'Pending',
        'PostDated',
        'OnAccount',
      ];

      // **DETERMINE DATA TO USE - SELECTED OR ALL**
      List<Map<String, dynamic>> dataToExport;
      double totalOutstanding;

      if (_selectedRows.isNotEmpty) {
        // Use only selected rows
        dataToExport = _selectedRows.map((index) => _outstandingData[index]).toList();

        // Calculate total from selected items' Pending values
        totalOutstanding = 0.0;
        for (var row in dataToExport) {
          double pending = double.tryParse(row['Pending']?.toString() ?? '0') ?? 0.0;
          totalOutstanding += pending;
        }
      } else {
        // Use all data
        dataToExport = _outstandingData;
        totalOutstanding = _calculateTotalOutstanding(); // Use full total
      }

      // Verify that these columns exist in the data
      if (dataToExport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No data available")),
        );
        return;
      }

      // **Split data into chunks to avoid too many pages**
      const int rowsPerPage = 15; // Adjusted for fewer columns
      final int totalPages = (dataToExport.length / rowsPerPage).ceil();

      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final startIndex = pageIndex * rowsPerPage;
        final endIndex = (startIndex + rowsPerPage).clamp(0, dataToExport.length);
        final pageData = dataToExport.sublist(startIndex, endIndex);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(32),
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Container(
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
                              'Page ${pageIndex + 1} of $totalPages',
                              style: pw.TextStyle(font: ttf, fontSize: 12),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),
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
                  ),

                  pw.SizedBox(height: 16),

                  // Total Outstanding Summary Box (only on first page)
                  if (pageIndex == 0 && totalOutstanding != 0)
                    pw.Container(
                      margin: pw.EdgeInsets.only(bottom: 16),
                      padding: pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: _pdfSummaryBackground,
                        border: pw.Border.all(
                          color: _pdfSummaryBorder,
                          width: 2,
                        ),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL OUTSTANDING',
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 16,
                              color: _pdfSummaryText,
                            ),
                          ),
                          pw.Row(
                            children: [
                              pw.SvgImage(
                                svg: '''
                                <svg width="16" height="16" viewBox="0 0 320 512" xmlns="http://www.w3.org/2000/svg">
                                  <path fill="$_pdfRupeeSymbolColor" d="M308 96c6.627 0 12-5.373 12-12V44c0-6.627-5.373-12-12-12H12C5.373 32 0 37.373 0 44v40c0 6.627 5.373 12 12 12h85.28c27.308 0 48.261 9.958 60.97 27.252H12c-6.627 0-12 5.373-12 12v40c0 6.627 5.373 12 12 12h158.757c-6.217 36.086-32.961 58.632-74.757 58.632H12c-6.627 0-12 5.373-12 12v53.012c0 3.349 1.4 6.546 3.861 8.818l165.052 152.356a12.001 12.001 0 0 0 8.139 3.182h82.562c10.924 0 16.166-13.408 8.139-20.818L116.871 319.906c76.499-2.34 131.144-53.395 138.318-127.906H308c6.627 0 12-5.373 12-12v-40c0-6.627-5.373-12-12-12h-58.69c-3.486-11.541-8.28-22.246-14.252-32H308z"/>
                                </svg>
                              ''',
                                width: 16,
                                height: 16,
                              ),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                Formatters.formatNumber(totalOutstanding),
                                style: pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 18,
                                  color: _pdfSummaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Data Table for this page
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      columnWidths: {
                        0: pw.FixedColumnWidth(70),   // Date
                        1: pw.FixedColumnWidth(90),   // Invoice No.
                        2: pw.FixedColumnWidth(85),   // Opening
                        3: pw.FixedColumnWidth(85),   // Pending
                        4: pw.FixedColumnWidth(85),   // PostDated
                        5: pw.FixedColumnWidth(85),   // OnAccount
                      },
                      children: [
                        // Header row - using columnHeaders for display
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: PdfColors.grey200),
                          children: columnHeaders.map((col) {
                            return pw.Container(
                              padding: pw.EdgeInsets.all(8),
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                col,
                                style: pw.TextStyle(font: ttfBold, fontSize: 10),
                                textAlign: pw.TextAlign.center,
                              ),
                            );
                          }).toList(),
                        ),
                        // Data rows for this page - using dataKeys to access data
                        for (var row in pageData)
                          pw.TableRow(
                            children: dataKeys.map((key) {
                              return pw.Container(
                                padding: pw.EdgeInsets.all(6),
                                child: _buildPdfCellContent(row[key], ttf),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  // Footer
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    margin: pw.EdgeInsets.only(top: 8),
                    child: pw.Text(
                      'Generated by ${domainName}',
                      style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey600),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }


      // Direct download instead of print dialog
      final pdfBytes = await pdf.save();
      await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'outstanding_${_selectedRows.isNotEmpty ? "selected_" : ""}${DateTime.now().millisecondsSinceEpoch}.pdf'
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF downloaded successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating PDF: $e")),
      );
      print("PDF Error Details: $e");
    }
  }

  pw.Widget _buildPdfCellContent(dynamic val, pw.Font ttf) {
    if (val == null) {
      return pw.Text(
        '',
        style: pw.TextStyle(font: ttf, fontSize: 10),
        textAlign: pw.TextAlign.center,
      );
    }

    if (val is num) {
      return pw.Text(
        Formatters.formatNumber(val.toDouble()),
        style: pw.TextStyle(font: ttf, fontSize: 10),
        textAlign: pw.TextAlign.center,
      );
    }

    if (val is String) {
      try {
        final dt = DateTime.parse(val);
        return pw.Text(
          Formatters.formatDate(dt),
          style: pw.TextStyle(font: ttf, fontSize: 10),
          textAlign: pw.TextAlign.center,
        );
      } catch (_) {}
    }

    return pw.Text(
      val.toString(),
      style: pw.TextStyle(font: ttf, fontSize: 10),
      textAlign: pw.TextAlign.center,
    );
  }

  pw.TableColumnWidth _getColumnWidthForPdf(String columnName) {
    String col = columnName.toLowerCase();

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

  @override
  void dispose() {
    super.dispose();
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  Future<void> _fetchOutstandingData() async {
    try {
      setState(() {
        _isLoadingOutstanding = true;
        _errorMessageOutstanding = '';
        // Clear selections when refreshing data
        _selectedRows.clear();
        _selectedTotal = 0.0;
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


  double _calculateTotalOutstanding() {
    if (_outstandingData.isEmpty) return 0.0;

    // Get TotalOutstanding from the first row (same value in all rows)
    double totalOutstanding = double.tryParse(_outstandingData.first['TotalOutstanding']?.toString() ?? '0') ?? 0.0;

    return totalOutstanding;
  }
  double _calculateTotalOutstanding_old() {
    if (_outstandingData.isEmpty) return 0.0;

    double total = 0.0;
    for (var row in _outstandingData) {
      double pending = double.tryParse(row['Pending']?.toString() ?? '0') ?? 0.0;
      total += pending;
    }

    return total;
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    return '${Formatters.formatNumber(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    String currentTitle = _currentTabIndex == 0 ? 'Outstanding Analysis' : 'Aging Analysis';

    return DashboardLayout(
      title: currentTitle,
      subtitle: widget.title,
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
                bottom: _currentTabIndex == 0 ? 100 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSimpleTabBar(),
                  const SizedBox(height: 16),

                  if (_currentTabIndex == 0)
                    _buildOutstandingTab()
                  else
                    _buildAgingTab(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

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
              color: _currentTabIndex == 0
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Outstanding',
              style: TextStyle(
                color: _currentTabIndex == 0
                    ? ThemeHelper.textColor(context)
                    : ThemeHelper.subtleTextColor(context),
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
              color: _currentTabIndex == 1
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Ageing',
              style: TextStyle(
                color: _currentTabIndex == 1
                    ? ThemeHelper.textColor(context)
                    : ThemeHelper.subtleTextColor(context),
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
                  'Loading outstanding data...',
                  style: ThemeHelper.captionStyle(context)
              ),
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
              Icon(Icons.error_outline, color: ThemeHelper.errorColor, size: 48),
              SizedBox(height: 16),
              Text(
                  _errorMessageOutstanding,
                  style: TextStyle(color: ThemeHelper.errorColor, fontSize: 14),
                  textAlign: TextAlign.center
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchOutstandingData,
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

    if (_outstandingData.isEmpty) {
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
                  'No outstanding data available',
                  style: ThemeHelper.subtitleStyle(context).copyWith(
                      color: ThemeHelper.subtleTextColor(context)
                  )
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: 840, // Added extra width for checkbox column
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWideTableHeader(),
                const SizedBox(height: 8),
                ..._buildWideOutstandingData(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideTableHeader() {
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
          // CHECKBOX HEADER - NEW ADDITION
          Container(
            width: 40,
            child: Checkbox(
              value: _selectedRows.length == _outstandingData.length && _outstandingData.isNotEmpty,
              onChanged: (bool? value) {
                _toggleSelectAll();
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
          // END OF NEW HEADER
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
        style: TextStyle(
          color: ThemeHelper.textColor(context),
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
      bool isSelected = _selectedRows.contains(index); // NEW

      return _buildWideDataRow(row, isEven, index, isSelected); // MODIFIED
    }).toList();
  }

  Widget _buildWideDataRow(Map<String, dynamic> data, bool isEven, int index, bool isSelected) { // MODIFIED SIGNATURE
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected // NEW - Highlight selected rows
            ? Theme.of(context).primaryColor.withOpacity(0.15)
            : ThemeHelper.rowBackground(context, isEven),
        borderRadius: BorderRadius.circular(6),
        border: isSelected // NEW - Border for selected rows
            ? Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // CHECKBOX CELL - NEW ADDITION
          Container(
            width: 40,
            child: Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                _toggleRowSelection(index);
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
          // END OF NEW CELL
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

  Widget _buildWideDataCell(
      String value, {
        required double width,
        bool isAmount = false,
        bool isPending = false,
        bool isPositive = false,
      }) {
    Color textColor = ThemeHelper.subtleTextColor(context);

    if (isPending) {
      textColor = ThemeHelper.warningColor;
    } else if (isPositive) {
      textColor = ThemeHelper.successColor;
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

  Widget _buildBottomSummaryBar() {
    double totalAmount = _calculateTotalOutstanding();

    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              _selectedRows.isNotEmpty ? Icons.check_circle : Icons.account_balance_wallet,
              color: _selectedRows.isNotEmpty
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _selectedRows.isNotEmpty ? 'Selected Bills:' : 'Total Outstanding:',
              style: TextStyle(
                color: ThemeHelper.textColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              _isLoadingOutstanding
                  ? '...'
                  : (_selectedRows.isNotEmpty
                  ? '₹' + Formatters.formatNumber   (_selectedTotal)
                  : (totalAmount > 0 ? ( '₹' + Formatters.formatNumber(totalAmount) ) : '₹0.00')),
              style: TextStyle(
                color: _selectedRows.isNotEmpty
                    ? Theme.of(context).primaryColor
                    : ThemeHelper.errorColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            if (_selectedRows.isNotEmpty)
              GestureDetector(
                onTap: _clearSelections,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ThemeHelper.glassBackground(context),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: ThemeHelper.borderColor(context),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: ThemeHelper.textColor(context),
                    size: 14,
                  ),
                ),
              ),
            GestureDetector(
              onTap: _downloadPdf,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ThemeHelper.glassBackground(context),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: ThemeHelper.borderColor(context),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: ThemeHelper.textColor(context),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: ThemeHelper.loadingColor(context),
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Loading aging data...',
              style: ThemeHelper.captionStyle(context),
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
            Icon(
              Icons.error_outline,
              color: ThemeHelper.errorColor,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessageAging,
              style: TextStyle(
                color: ThemeHelper.errorColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAgingData,
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
      );
    }

    if (_agingData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: ThemeHelper.successColor,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No outstanding bills',
              style: ThemeHelper.titleStyle(context),
            ),
            Text(
              'All bills are up to date',
              style: ThemeHelper.captionStyle(context),
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
        _buildSimpleAgingTableRow(
          'Pending Bills',
          _getAgingValue(agingData, 'Pending Bills'),
          null,
          true,
        ),

        const SizedBox(height: 16),

        Text(
          'Ageing Breakdown',
          style: ThemeHelper.bodyStyle(context).copyWith(
            color: ThemeHelper.subtleTextColor(context),
          ),
        ),

        const SizedBox(height: 12),

        _buildSimpleAgingTableRow(
          '(< 30 days )',
          _getAgingValue(agingData, '(< 30 days )'),
          ThemeHelper.successColor,
        ),
        _buildSimpleAgingTableRow(
          '30 to 60 days',
          _getAgingValue(agingData, '30 to 60 days'),
          ThemeHelper.infoColor,
        ),
        _buildSimpleAgingTableRow(
          '60 to 75 days',
          _getAgingValue(agingData, '60 to 75 days'),
          ThemeHelper.warningColor,
        ),
        _buildSimpleAgingTableRow(
          '75 to 90 days',
          _getAgingValue(agingData, '75 to 90 days'),
          Color(0xFFFF5722),
        ),

        _buildSimpleAgingTableRow(
          '(> 90 days )',
          _getAgingValue(agingData, '(> 90 days )'),
          ThemeHelper.errorColor,
        ),

        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 1,
          color: ThemeHelper.borderColor(context),
        ),
        const SizedBox(height: 12),

        _buildSimpleAgingTableRow(
          'On Account',
          _getAgingValue(agingData, 'On Account'),
          ThemeHelper.successColor,
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
            ? ThemeHelper.glassBackground(context)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isMainRow
            ? Border.all(color: ThemeHelper.borderColor(context))
            : null,
      ),
      child: Row(
        children: [
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

          Expanded(
            child: Text(
              label,
              style: isMainRow
                  ? ThemeHelper.titleStyle(context)
                  : ThemeHelper.bodyStyle(context).copyWith(
                color: ThemeHelper.subtleTextColor(context),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (amount < 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: ThemeHelper.smallBadgeDecoration(ThemeHelper.errorColor),
                  child: Text(
                    'CR',
                    style: TextStyle(
                      color: ThemeHelper.errorColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                (label == 'Pending Bills')
                    ? Formatters.formatCurrency(amount.abs())
                    : _formatAmount(amount.abs()),
                style: TextStyle(
                  color: amount < 0
                      ? ThemeHelper.errorColor
                      : (isMainRow ? ThemeHelper.textColor(context) : ThemeHelper.textColor(context)),
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