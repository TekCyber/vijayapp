// lib/screens/admin/document_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/document_service.dart';
import '../../theme/theme_helpers.dart';
import '../../widgets/glass_container.dart';
import 'add_document_screen.dart';
import 'edit_document_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({Key? key}) : super(key: key);

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final DocumentService _documentService = DocumentService();

  List<Map<String, dynamic>> _allDocuments = []; // Store all documents
  List<Map<String, dynamic>> _documents = []; // Filtered documents
  List<String> _categories = ["CATALOGUE", "PRICE LIST", "SCHEME POSTER", "DISCOUNT STRUCTURE"]; // Hardcoded categories
  List<String> _brands = [];

  bool _isLoading = true;
  String? _selectedCategory;
  String? _selectedBrand;
  int? _selectedStatus;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadDocuments();
  }

  void _extractFiltersFromDocuments() {
    if (_allDocuments.isEmpty) return;

    // Categories are hardcoded, only extract brands
    final brandSet = <String>{};
    for (var doc in _allDocuments) {
      final brand = doc['brand']?.toString();
      if (brand != null && brand.isNotEmpty) {
        brandSet.add(brand);
      }
    }
    _brands = brandSet.toList()..sort();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allDocuments);

    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered.where((doc) {
        return doc['category_name']?.toString() == _selectedCategory;
      }).toList();
    }

    // Filter by brand
    if (_selectedBrand != null) {
      filtered = filtered.where((doc) {
        return doc['brand']?.toString() == _selectedBrand;
      }).toList();
    }

    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered.where((doc) {
        final isActive = doc['is_active'] is int
            ? doc['is_active'] as int
            : int.tryParse(doc['is_active']?.toString() ?? '0') ?? 0;
        return isActive == _selectedStatus;
      }).toList();
    }

    setState(() {
      _documents = filtered;
    });
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    final result = await _documentService.getAllDocuments(
      category: _selectedCategory,
      brand: _selectedBrand,
      isActive: _selectedStatus,
      page: _currentPage,
    );

    if (result.isSuccess && mounted) {
      setState(() {
        _allDocuments = result.data ?? []; // Store all documents
        _extractFiltersFromDocuments(); // Extract categories and brands from response
        _applyFilters(); // Apply current filters
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar(result.error ?? 'Failed to load documents', false);
      }
    }
  }

  Future<void> _deleteDocument(int id) async {
    final confirm = await _showConfirmDialog(
      'Delete Document',
      'Are you sure you want to delete this document?',
    );

    if (confirm == true) {
      final result = await _documentService.deleteDocument(id);

      if (result.isSuccess) {
        _showSnackBar('Document deleted successfully', true);
        _loadDocuments();
      } else {
        _showSnackBar(result.error ?? 'Failed to delete document', false);
      }
    }
  }

  Future<void> _toggleStatus(int id, int currentStatus) async {
    final result = await _documentService.toggleDocumentStatus(
        id, currentStatus == 0);

    if (result.isSuccess) {
      _showSnackBar('Status updated successfully', true);
      _loadDocuments();
    } else {
      _showSnackBar(result.error ?? 'Failed to update status', false);
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? ThemeHelper.successColor
            : ThemeHelper.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildFilters(context),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _documents.isEmpty
                  ? _buildEmptyState()
                  : _buildDocumentList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: ThemeHelper.borderColor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: ThemeHelper.iconColor(context),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Management',
                  style: ThemeHelper.titleStyle(context),
                ),
                Text(
                  '${_documents.length} Documents',
                  style: ThemeHelper.captionStyle(context),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: ThemeHelper.iconColor(context),
            ),
            onPressed: _loadDocuments,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildCategoryFilter()),
              const SizedBox(width: 12),
              Expanded(child: _buildBrandFilter()),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusFilter(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ThemeHelper.inputDecoration(context),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: Text('All Categories', style: ThemeHelper.bodyStyle(context)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: ThemeHelper.iconColor(context)),
          items: [
            DropdownMenuItem<String>(value: null, child: Text('All Categories')),
            ..._categories.map((category) => DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
              _currentPage = 1;
            });
            _applyFilters(); // Apply filters locally without API call
          },
        ),
      ),
    );
  }

  Widget _buildBrandFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ThemeHelper.inputDecoration(context),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBrand,
          hint: Text('All Brands', style: ThemeHelper.bodyStyle(context)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: ThemeHelper.iconColor(context)),
          items: [
            DropdownMenuItem<String>(value: null, child: Text('All Brands')),
            ..._brands.map((brand) => DropdownMenuItem<String>(
              value: brand,
              child: Text(brand),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedBrand = value;
              _currentPage = 1;
            });
            _applyFilters(); // Apply filters locally without API call
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ThemeHelper.inputDecoration(context),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedStatus,
          hint: Text('All Status', style: ThemeHelper.bodyStyle(context)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: ThemeHelper.iconColor(context)),
          items: const [
            DropdownMenuItem<int?>(value: null, child: Text('All Status')),
            DropdownMenuItem<int?>(value: 1, child: Text('Active')),
            DropdownMenuItem<int?>(value: 0, child: Text('Inactive')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedStatus = value;
              _currentPage = 1;
            });
            _applyFilters(); // Apply filters locally without API call
          },
        ),
      ),
    );
  }

  Widget _buildDocumentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        return _buildDocumentCard(_documents[index]);
      },
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    final theme = Theme.of(context);
    final id = document['id'] is int ? document['id'] as int : int.tryParse(document['id']?.toString() ?? '0') ?? 0;
    final title = document['title']?.toString() ?? '';
    final categoryName = document['category_name']?.toString() ?? '';
    final brand = document['brand']?.toString();
    final isActive = document['is_active'] is int ? document['is_active'] as int : int.tryParse(document['is_active']?.toString() ?? '0') ?? 0;

    return GlassContainer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description, color: theme.primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: ThemeHelper.subtitleStyle(context),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(categoryName, style: ThemeHelper.captionStyle(context)),
                    ],
                  ),
                ),
                _buildStatusBadge(isActive == 1),
              ],
            ),
            if (brand != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.branding_watermark, size: 14,
                      color: ThemeHelper.subtleTextColor(context)),
                  const SizedBox(width: 6),
                  Text(brand, style: ThemeHelper.captionStyle(context)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  color: ThemeHelper.infoColor,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditDocumentScreen(document: document),
                      ),
                    );
                    if (result == true) _loadDocuments();
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: isActive == 1 ? Icons.visibility_off : Icons.visibility,
                  color: ThemeHelper.warningColor,
                  onTap: () => _toggleStatus(id, isActive),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.delete,
                  color: ThemeHelper.errorColor,
                  onTap: () => _deleteDocument(id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ThemeHelper.smallBadgeDecoration(
        isActive ? ThemeHelper.successColor : ThemeHelper.errorColor,
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: ThemeHelper.smallStyle(context).copyWith(
          color: isActive ? ThemeHelper.successColor : ThemeHelper.errorColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: ThemeHelper.loadingColor(context)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80,
              color: ThemeHelper.subtleTextColor(context)),
          const SizedBox(height: 16),
          Text('No Documents Found', style: ThemeHelper.titleStyle(context)),
          const SizedBox(height: 8),
          Text('Add your first document to get started',
            style: ThemeHelper.bodyStyle(context).copyWith(
              color: ThemeHelper.subtleTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddDocumentScreen()),
        );
        if (result == true) _loadDocuments();
      },
      backgroundColor: theme.primaryColor,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Add Document', style: TextStyle(color: Colors.white)),
    );
  }
}