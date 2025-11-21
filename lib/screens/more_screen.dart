// lib/screens/more_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:pdfx/pdfx.dart';
import '../services/api_service.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/glass_container.dart';
import '../theme/theme_helpers.dart';
import '../models/search_filter_models.dart';
import 'executive/menu_navigator.dart';

class MoreScreen extends StatefulWidget {
  final String? initialCategory; // NEW: Optional initial category filter
  const MoreScreen({Key? key, this.initialCategory}) : super(key: key);

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _filteredDocuments = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Set<String> _categories = {'All'};
  int selectedMenuIndex = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Set category filter from passed parameter
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
      print('✅ Filter set to: $_selectedCategory');
    }
    _fetchDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.request(
        payload: {
          'sqlKey': 'SP_GET_ACTIVE_DOCUMENTS',
        },
        method: 'POST',
      );

      if (response.isSuccess && response.data != null) {
        print('📦 Received ${response.data!.length} documents');

        // Extract unique categories
        final categories = <String>{'All'};
        for (var doc in response.data!) {
          if (doc['category_name'] != null) {
            categories.add(doc['category_name'].toString());
          }
        }

        setState(() {
          _documents = response.data!;
          _categories = categories;
          _isLoading = false;
          _updateFilteredDocuments();
        });
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load documents';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching documents: $e');
      print('📋 Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _updateFilteredDocuments() {
    var filtered = _documents;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((doc) =>
      doc['category_name']?.toString() == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final searchLower = _searchQuery.toLowerCase();
        final title = doc['title']?.toString().toLowerCase() ?? '';
        final brand = doc['brand']?.toString().toLowerCase() ?? '';
        final category = doc['category_name']?.toString().toLowerCase() ?? '';
        return title.contains(searchLower) ||
            brand.contains(searchLower) ||
            category.contains(searchLower);
      }).toList();
    }

    setState(() {
      _filteredDocuments = filtered;
    });
  }

  // Clean base64 string by removing all whitespace, newlines, and carriage returns
  String _cleanBase64(String base64Data) {
    return base64Data
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '')
        .replaceAll('\t', '')
        .trim();
  }

  // Detect if base64 data is PDF or Image
  String _detectFileType(String base64Data) {
    try {
      final cleanData = _cleanBase64(base64Data);
      if (cleanData.isEmpty) return 'unknown';

      final sampleLength = 200.clamp(0, cleanData.length);
      final bytes = base64.decode(cleanData.substring(0, sampleLength));

      // PDF signature
      if (bytes.length > 4 &&
          bytes[0] == 0x25 && bytes[1] == 0x50 &&
          bytes[2] == 0x44 && bytes[3] == 0x46) {
        return 'pdf';
      }

      // PNG signature
      if (bytes.length > 8 &&
          bytes[0] == 0x89 && bytes[1] == 0x50 &&
          bytes[2] == 0x4E && bytes[3] == 0x47) {
        return 'png';
      }

      // JPEG signature
      if (bytes.length > 3 &&
          bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'jpeg';
      }

      // GIF signature
      if (bytes.length > 6 &&
          bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'gif';
      }

      // WebP signature
      if (bytes.length > 12 &&
          bytes[0] == 0x52 && bytes[1] == 0x49 &&
          bytes[2] == 0x46 && bytes[3] == 0x46 &&
          bytes[8] == 0x57 && bytes[9] == 0x45 &&
          bytes[10] == 0x42 && bytes[11] == 0x50) {
        return 'webp';
      }

      return 'image';
    } catch (e) {
      print('❌ Error detecting file type: $e');
      return 'unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: _selectedCategory != 'All' ? _selectedCategory : 'More',
      subtitle: _selectedCategory != 'All'
          ? '${_filteredDocuments.length} Document${_filteredDocuments.length != 1 ? 's' : ''}'
          : 'Active Documents & Resources',
      initialIndex: 3,
      onTabSelected: _onMenuSelected,
      searchFilters: _getSearchFilters(),
      onFilterChanged: _handleFilterChanged,
      body: _buildBody(),
    );
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  // Build search filters - TWO ROWS
  List<SearchFilterOption> _getSearchFilters() {
    if (_isLoading) return [];

    return [
      // ROW 1: Search box (full width)
      SearchFilterOption(
        key: 'searchRow',
        widget: _buildSearchBox(),
      ),

      // ROW 2: Category dropdown (full width)
      SearchFilterOption(
        key: 'categoryRow',
        widget: _buildCategoryDropdown(),
      ),
    ];
  }

  Widget _buildSearchBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white.withOpacity(0.8) : Colors.black54;
    final iconColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: 'Search Documents',
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 12,
          ),
          hintText: 'Type document name, brand, or category...',
          hintStyle: TextStyle(
            color: hintColor.withOpacity(0.6),
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: iconColor,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: iconColor,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _updateFilteredDocuments();
              });
              HapticFeedback.lightImpact();
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _updateFilteredDocuments();
          });
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white.withOpacity(0.8) : Colors.black54;
    final iconColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: iconColor,
            size: 24,
          ),
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: isDark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 20,
                    color: _getCategoryColor(category),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _selectedCategory) {
              setState(() {
                _selectedCategory = newValue;
                _updateFilteredDocuments();
              });
              HapticFeedback.selectionClick();
            }
          },
          selectedItemBuilder: (BuildContext context) {
            return _categories.map((String category) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Category',
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 18,
                        color: _getCategoryColor(category),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category == 'All') return Icons.dashboard;

    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('scheme') || categoryLower.contains('offer')) {
      return Icons.card_giftcard;
    } else if (categoryLower.contains('report') || categoryLower.contains('analytics')) {
      return Icons.analytics;
    } else if (categoryLower.contains('sales') || categoryLower.contains('revenue')) {
      return Icons.trending_up;
    } else if (categoryLower.contains('invoice') || categoryLower.contains('bill')) {
      return Icons.receipt_long;
    } else if (categoryLower.contains('customer') || categoryLower.contains('client')) {
      return Icons.people;
    } else if (categoryLower.contains('product') || categoryLower.contains('inventory')) {
      return Icons.inventory_2;
    } else if (categoryLower.contains('document') || categoryLower.contains('file')) {
      return Icons.description;
    } else {
      return Icons.article;
    }
  }

  Color _getCategoryColor(String category) {
    if (category == 'All') return Theme.of(context).primaryColor;

    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('scheme') || categoryLower.contains('offer')) {
      return ThemeHelper.accentPink;
    } else if (categoryLower.contains('report') || categoryLower.contains('analytics')) {
      return ThemeHelper.accentBlue;
    } else if (categoryLower.contains('sales') || categoryLower.contains('revenue')) {
      return ThemeHelper.accentGreen;
    } else if (categoryLower.contains('invoice') || categoryLower.contains('bill')) {
      return ThemeHelper.accentOrange;
    } else if (categoryLower.contains('customer') || categoryLower.contains('client')) {
      return ThemeHelper.accentPurple;
    } else if (categoryLower.contains('product') || categoryLower.contains('inventory')) {
      return ThemeHelper.accentTeal;
    } else if (categoryLower.contains('document') || categoryLower.contains('file')) {
      return const Color(0xFF8B5CF6);
    } else {
      return Theme.of(context).primaryColor;
    }
  }

  void _handleFilterChanged(Map<String, dynamic> filters) {
    print('MoreScreen: Received filters: $filters');
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_documents.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredDocuments.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildDocumentsList();
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading documents...',
            style: ThemeHelper.bodyStyle(context).copyWith(
              color: ThemeHelper.subtleTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: ThemeHelper.errorColor.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: ThemeHelper.titleStyle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: ThemeHelper.bodyStyle(context).copyWith(
                color: ThemeHelper.subtleTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchDocuments,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: ThemeHelper.subtleTextColor(context).withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Documents Found',
              style: ThemeHelper.titleStyle(context),
            ),
            const SizedBox(height: 12),
            Text(
              'There are no active documents available at the moment.',
              style: ThemeHelper.bodyStyle(context).copyWith(
                color: ThemeHelper.subtleTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: ThemeHelper.subtleTextColor(context).withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Results Found',
            style: ThemeHelper.titleStyle(context),
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your search or filters',
            style: ThemeHelper.bodyStyle(context).copyWith(
              color: ThemeHelper.subtleTextColor(context),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
                _selectedCategory = 'All';
                _updateFilteredDocuments();
              });
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    return RefreshIndicator(
      onRefresh: _fetchDocuments,
      color: Theme.of(context).primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredDocuments.length,
        itemBuilder: (context, index) {
          return _buildDocumentCard(_filteredDocuments[index], index);
        },
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document, int index) {
    final title = document['title']?.toString() ?? 'Untitled Document';
    final brand = document['brand']?.toString() ?? '';
    final category = document['category_name']?.toString() ?? 'General';
    final documentId = document['id'] as int? ?? document['document_id'] as int?;

    // Detect file type from filename or file_type field
    String fileType = 'unknown';
    final fileName = document['file_name']?.toString() ?? '';
    final fileTypeField = document['file_type']?.toString() ?? '';

    if (fileTypeField.isNotEmpty) {
      fileType = fileTypeField.toLowerCase();
    } else if (fileName.isNotEmpty) {
      final ext = fileName.split('.').last.toLowerCase();
      if (['pdf', 'png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext)) {
        fileType = ext;
      }
    }

    final categoryInfo = _getCategoryInfo(category);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index * 0.1) + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return Transform.translate(
          offset: Offset(0, 50 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          opacity: 0.1,
          blur: 10,
          child: InkWell(
            onTap: () {
              print('🔵 Document card clicked!');
              print('🔵 Document ID: $documentId');
              print('🔵 File type: $fileType');

              HapticFeedback.lightImpact();

              if (documentId != null) {
                print('✅ Calling _viewDocument');
                _viewDocument(document, fileType);
              } else {
                print('❌ Document ID is null');
                _showErrorSnackBar('Document ID not found');
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              categoryInfo['color'] as Color,
                              (categoryInfo['color'] as Color).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: (categoryInfo['color'] as Color).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          categoryInfo['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: ThemeHelper.bodyStyle(context).copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (categoryInfo['color'] as Color).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: (categoryInfo['color'] as Color).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    category,
                                    style: ThemeHelper.captionStyle(context).copyWith(
                                      color: categoryInfo['color'] as Color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (fileType != 'unknown')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getFileTypeColor(fileType).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _getFileTypeColor(fileType).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getFileTypeIcon(fileType),
                                          size: 12,
                                          color: _getFileTypeColor(fileType),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          fileType.toUpperCase(),
                                          style: ThemeHelper.captionStyle(context).copyWith(
                                            color: _getFileTypeColor(fileType),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (brand.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16,
                          color: ThemeHelper.iconColor(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            brand,
                            style: ThemeHelper.bodyStyle(context).copyWith(
                              color: ThemeHelper.subtleTextColor(context),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: ThemeHelper.iconColor(context),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryInfo(String category) {
    final categoryLower = category.toLowerCase();

    if (categoryLower.contains('scheme') || categoryLower.contains('offer')) {
      return {'icon': Icons.card_giftcard, 'color': ThemeHelper.accentPink};
    } else if (categoryLower.contains('report') || categoryLower.contains('analytics')) {
      return {'icon': Icons.analytics, 'color': ThemeHelper.accentBlue};
    } else if (categoryLower.contains('sales') || categoryLower.contains('revenue')) {
      return {'icon': Icons.trending_up, 'color': ThemeHelper.accentGreen};
    } else if (categoryLower.contains('invoice') || categoryLower.contains('bill')) {
      return {'icon': Icons.receipt_long, 'color': ThemeHelper.accentOrange};
    } else if (categoryLower.contains('customer') || categoryLower.contains('client')) {
      return {'icon': Icons.people, 'color': ThemeHelper.accentPurple};
    } else if (categoryLower.contains('product') || categoryLower.contains('inventory')) {
      return {'icon': Icons.inventory_2, 'color': ThemeHelper.accentTeal};
    } else if (categoryLower.contains('document') || categoryLower.contains('file')) {
      return {'icon': Icons.description, 'color': const Color(0xFF8B5CF6)};
    } else {
      return {'icon': Icons.article, 'color': Theme.of(context).primaryColor};
    }
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'png':
      case 'jpeg':
      case 'jpg':
      case 'gif':
      case 'webp':
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFE53935);
      case 'png':
      case 'webp':
        return const Color(0xFF43A047);
      case 'jpeg':
      case 'jpg':
        return const Color(0xFF1976D2);
      case 'gif':
        return const Color(0xFFFF6F00);
      default:
        return ThemeHelper.infoColor;
    }
  }

  // Fetch document by ID to get base64 data
  Future<Map<String, dynamic>?> _fetchDocumentById(int documentId) async {
    try {
      print('🔵 Calling API: SP_GET_DOCUMENT_BY_ID with id: $documentId');

      final response = await _apiService.request(
        payload: {
          'sqlKey': 'SP_GET_DOCUMENT_BY_ID',
          'id': documentId,
        },
        method: 'POST',
      );

      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        print('✅ Fetched document by ID: $documentId');
        return response.data![0];
      } else {
        print('❌ Failed to fetch document: ${response.error}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching document by ID: $e');
      return null;
    }
  }

  // View document - fetches full data including base64 when clicked
  Future<void> _viewDocument(Map<String, dynamic> document, String fileType) async {
    print('🔵 _viewDocument called');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading Document...',
                  style: ThemeHelper.bodyStyle(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Fetch document with base64 data
      final documentId = document['id'] as int? ?? document['document_id'] as int?;
      print('🔵 Document ID from map: $documentId');

      if (documentId == null) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Invalid document ID');
        return;
      }

      final fullDocument = await _fetchDocumentById(documentId);

      // Close loading dialog
      Navigator.pop(context);

      if (fullDocument == null) {
        _showErrorSnackBar('Failed to load document');
        return;
      }

      // Get base64 data
      final rawData = fullDocument['data']?.toString() ??
          fullDocument['file_data']?.toString() ??
          fullDocument['file_data_base64']?.toString() ?? '';
      final base64Data = _cleanBase64(rawData);
      final documentType = _detectFileType(base64Data);
      if (base64Data.isEmpty) {
        _showErrorSnackBar('No document data available');
        return;
      }

      // Decode base64 to bytes
      final bytes = base64.decode(base64Data);

      // Navigate to viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentViewerScreen(
            title: document['title']?.toString() ?? 'Document',
            brand: document['brand']?.toString() ?? '',
            category: document['category_name']?.toString() ?? '',
            fileType: documentType,
            bytes: bytes,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorSnackBar('Error loading document: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ThemeHelper.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================
// DOCUMENT VIEWER SCREEN
// ============================================
class DocumentViewerScreen extends StatefulWidget {
  final String title;
  final String brand;
  final String category;
  final String fileType;
  final Uint8List bytes;

  const DocumentViewerScreen({
    Key? key,
    required this.title,
    this.brand = '',
    this.category = '',
    required this.fileType,
    required this.bytes,
  }) : super(key: key);

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  PdfController? _pdfController;
  bool _isLoadingPdf = false;

  @override
  void initState() {
    super.initState();
    if (widget.fileType == 'pdf') {
      _initPdfController();
    }
  }

  Future<void> _initPdfController() async {
    setState(() => _isLoadingPdf = true);
    try {
      _pdfController = PdfController(
        document: PdfDocument.openData(widget.bytes),
      );
    } catch (e) {
      print('❌ Error loading PDF: $e');
      _pdfController = null;
    }
    if (mounted) {
      setState(() => _isLoadingPdf = false);
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ThemeHelper.iconColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: ThemeHelper.titleStyle(context).copyWith(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.brand.isNotEmpty || widget.category.isNotEmpty)
              Text(
                [widget.brand, widget.category].where((s) => s.isNotEmpty).join(' • '),
                style: ThemeHelper.captionStyle(context).copyWith(fontSize: 11),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: ThemeHelper.iconColor(context)),
            onPressed: () => _shareDocument(context),
            tooltip: 'Share',
          ),
        ],
      ),
      body: SafeArea(child: _buildViewer(context)),
    );
  }

  Future<void> _shareDocument(BuildContext context) async {
    try {
      HapticFeedback.lightImpact();

      final fileExtension = _getFileExtension();
      final fileName = '${_sanitizeFileName(widget.title)}_${widget.brand.replaceAll(' ', '_')}.$fileExtension';

      final shareText = '''
${widget.title}

${widget.brand.isNotEmpty ? 'Brand: ${widget.brand}\n' : ''}${widget.category.isNotEmpty ? 'Category: ${widget.category}\n' : ''}
Shared via Ultra Sales Dashboard
'''.trim();

      await Share.shareXFiles(
        [XFile.fromData(widget.bytes, name: fileName, mimeType: _getMimeType())],
        text: shareText,
        subject: widget.title,
      );
    } catch (e) {
      print('❌ Error sharing: $e');
    }
  }

  String _getMimeType() {
    switch (widget.fileType.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'png': return 'image/png';
      case 'jpeg':
      case 'jpg': return 'image/jpeg';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }

  String _getFileExtension() {
    switch (widget.fileType.toLowerCase()) {
      case 'pdf': return 'pdf';
      case 'png': return 'png';
      case 'jpeg':
      case 'jpg': return 'jpg';
      case 'gif': return 'gif';
      case 'webp': return 'webp';
      default: return 'jpg';
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_').toLowerCase();
  }

  Widget _buildViewer(BuildContext context) {
    if (widget.fileType == 'pdf') {
      return _buildPdfViewer(context);
    } else if (['png', 'jpeg', 'jpg', 'gif', 'webp', 'image'].contains(widget.fileType.toLowerCase())) {
      return _buildImageViewer(context);
    } else {
      return Center(
        child: Text('Unsupported file type: ${widget.fileType}'),
      );
    }
  }

  Widget _buildImageViewer(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.memory(
          widget.bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 80, color: ThemeHelper.errorColor.withOpacity(0.5)),
                  const SizedBox(height: 24),
                  Text('Failed to Display Image', style: ThemeHelper.titleStyle(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPdfViewer(BuildContext context) {
    if (_isLoadingPdf) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
      );
    }

    if (_pdfController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: ThemeHelper.errorColor.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text('Failed to Load PDF', style: ThemeHelper.titleStyle(context)),
          ],
        ),
      );
    }

    return PdfView(
      controller: _pdfController!,
      scrollDirection: Axis.vertical,
      onDocumentLoaded: (document) => print('✅ PDF loaded: ${document.pagesCount} pages'),
      onDocumentError: (error) => print('❌ PDF error: $error'),
    );
  }
}