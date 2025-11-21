import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/scheme_service.dart';

import 'add_scheme_screen.dart';
import 'edit_scheme_screen.dart';

class SchemeListScreen extends StatefulWidget {
  const SchemeListScreen({Key? key}) : super(key: key);

  @override
  State<SchemeListScreen> createState() => _SchemeListScreenState();
}

class _SchemeListScreenState extends State<SchemeListScreen> {
  final _schemeService = SchemeService();
  List<Map<String, dynamic>> _schemes = [];
  List<Map<String, dynamic>> _filteredSchemes = [];
  bool _isLoading = false;
  String? _selectedCategory;
  String _searchQuery = '';

  final List<String> _categories = ['ALL', 'BASKET', 'VALUE', 'QUANTITY', 'POINTS'];

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  Future<void> _loadSchemes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _schemeService.getAllSchemes();

      if (result.isSuccess && result.data != null) {
        setState(() {
          _schemes = result.data!;
          _filterSchemes();
        });
      } else {
        _showError(result.error ?? 'Failed to load schemes');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterSchemes() {
    setState(() {
      _filteredSchemes = _schemes.where((scheme) {
        final matchesCategory = _selectedCategory == null ||
            _selectedCategory == 'ALL' ||
            scheme['schemeCategory'] == _selectedCategory;

        final matchesSearch = _searchQuery.isEmpty ||
            (scheme['schemeName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (scheme['schemeId']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchemes,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSchemes.isEmpty
                ? _buildEmptyState(theme)
                : _buildSchemeList(theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddScheme(),
        icon: const Icon(Icons.add),
        label: const Text('Add Scheme'),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search schemes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterSchemes();
                });
              },
            ),
            const SizedBox(height: 12),

            // Category filter chips
            Wrap(
              spacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category ||
                    (_selectedCategory == null && category == 'ALL');

                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? (category == 'ALL' ? null : category) : null;
                      _filterSchemes();
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Schemes Found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != null
                ? 'Try adjusting your filters'
                : 'Tap the button below to add a scheme',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadSchemes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredSchemes.length,
        itemBuilder: (context, index) {
          final scheme = _filteredSchemes[index];
          return _buildSchemeCard(scheme, theme);
        },
      ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme, ThemeData theme) {
    final schemeId = scheme['schemeId']?.toString() ?? '';
    final schemeName = scheme['schemeName']?.toString() ?? '';
    final category = scheme['schemeCategory']?.toString() ?? '';
    final status = scheme['status']?.toString() ?? '';
    final startDate = scheme['startDate']?.toString() ?? '';
    final endDate = scheme['endDate']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewSchemeDetails(schemeId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schemeName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          schemeId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCategoryChip(category, theme),
                  const SizedBox(width: 8),
                  _buildStatusChip(status, theme),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.disabledColor),
                  const SizedBox(width: 4),
                  Text(
                    '$startDate to $endDate',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _viewSchemeDetails(schemeId),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                  ),
                  TextButton.icon(
                    onPressed: () => _editScheme(scheme),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(schemeId, schemeName),
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, ThemeData theme) {
    Color color;
    switch (category) {
      case 'BASKET':
        color = Colors.purple;
        break;
      case 'VALUE':
        color = Colors.blue;
        break;
      case 'QUANTITY':
        color = Colors.green;
        break;
      case 'POINTS':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        category,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'inactive':
        color = Colors.orange;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Future<void> _navigateToAddScheme() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSchemeScreen()),
    );

    if (result == true) {
      _loadSchemes();
    }
  }

  void _viewSchemeDetails(String schemeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SchemeDetailScreen(schemeId: schemeId),
      ),
    );
  }

  void _editScheme(Map<String, dynamic> scheme) {
    final schemeId = scheme['schemeId']?.toString() ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSchemeScreen(schemeId: schemeId),
      ),
    ).then((result) {
      if (result == true) {
        _loadSchemes();
      }
    });
  }

  Future<void> _confirmDelete(String schemeId, String schemeName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scheme'),
        content: Text(
          'Are you sure you want to delete "$schemeName"?\n\nThis will also delete all related records (targets, beneficiaries, etc.)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteScheme(schemeId);
    }
  }

  Future<void> _deleteScheme(String schemeId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _schemeService.deleteScheme(schemeId);

      if (result.isSuccess) {
        _showSuccess('Scheme deleted successfully');
        _loadSchemes();
      } else {
        _showError(result.error ?? 'Failed to delete scheme');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// Scheme Detail Screen
class SchemeDetailScreen extends StatefulWidget {
  final String schemeId;

  const SchemeDetailScreen({Key? key, required this.schemeId}) : super(key: key);

  @override
  State<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends State<SchemeDetailScreen> {
  final _schemeService = SchemeService();
  Map<String, dynamic>? _schemeData;
  List<Map<String, dynamic>> _categoryDetails = [];
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _detailsError;

  @override
  void initState() {
    super.initState();
    _loadSchemeDetails();
  }

  Future<void> _loadSchemeDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _schemeService.getSchemeById(widget.schemeId);

      if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
        setState(() {
          _schemeData = result.data!.first;
        });

        // Load category-specific details
        await _loadCategorySpecificDetails();
      } else {
        _showError(result.error ?? 'Failed to load scheme details');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategorySpecificDetails() async {
    if (_schemeData == null) {
      print('DEBUG: _schemeData is null');
      return;
    }

    setState(() {
      _isLoadingDetails = true;
      _detailsError = null;
    });

    final category = _schemeData!['schemeCategory']?.toString();
    print('DEBUG: Loading category details for: $category');

    try {
      switch (category) {
        case 'BASKET':
          final result = await _schemeService.getBasketSchemeDetails(widget.schemeId);
          print('DEBUG: Basket result - isSuccess: ${result.isSuccess}, data: ${result.data}');

          if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
            print('DEBUG: Setting category details with ${result.data!.length} items');
            print('DEBUG: First item structure: ${result.data!.first.keys}');
            setState(() {
              _categoryDetails = result.data!;
              _isLoadingDetails = false;
            });
          } else {
            print('DEBUG: No basket data - error: ${result.error}');
            setState(() {
              _detailsError = result.error ?? 'Failed to load basket scheme details';
              _isLoadingDetails = false;
            });
          }
          break;

        case 'VALUE':
          final result = await _schemeService.getValueSchemeDetails(widget.schemeId);
          if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
            setState(() {
              _categoryDetails = result.data!;
              _isLoadingDetails = false;
            });
          } else {
            setState(() {
              _detailsError = result.error ?? 'Failed to load value scheme details';
              _isLoadingDetails = false;
            });
          }
          break;

        case 'QUANTITY':
          final result = await _schemeService.getQuantitySchemeDetails(widget.schemeId);
          if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
            setState(() {
              _categoryDetails = result.data!;
              _isLoadingDetails = false;
            });
          } else {
            setState(() {
              _detailsError = result.error ?? 'Failed to load quantity scheme details';
              _isLoadingDetails = false;
            });
          }
          break;

        case 'POINTS':
          final result = await _schemeService.getPointsSchemeDetails(widget.schemeId);
          if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
            setState(() {
              _categoryDetails = result.data!;
              _isLoadingDetails = false;
            });
          } else {
            setState(() {
              _detailsError = result.error ?? 'Failed to load points scheme details';
              _isLoadingDetails = false;
            });
          }
          break;

        default:
          setState(() {
            _detailsError = 'Unknown scheme category: $category';
            _isLoadingDetails = false;
          });
      }
    } catch (e) {
      print('DEBUG: Exception in _loadCategorySpecificDetails: $e');
      setState(() {
        _detailsError = 'Error loading category details: ${e.toString()}';
        _isLoadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme Details'),
        elevation: 0,
        actions: [
          if (_schemeData != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'active') {
                  _updateStatus('Active');
                } else if (value == 'inactive') {
                  _updateStatus('Inactive');
                } else if (value == 'completed') {
                  _updateStatus('Completed');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'active',
                  child: Text('Mark as Active'),
                ),
                const PopupMenuItem(
                  value: 'inactive',
                  child: Text('Mark as Inactive'),
                ),
                const PopupMenuItem(
                  value: 'completed',
                  child: Text('Mark as Completed'),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schemeData == null
          ? const Center(child: Text('No data available'))
          : _buildSchemeDetails(theme),
    );
  }

  Widget _buildSchemeDetails(ThemeData theme) {
    final schemeName = _schemeData!['schemeName']?.toString() ?? '';
    final schemeId = _schemeData!['schemeId']?.toString() ?? '';
    final category = _schemeData!['schemeCategory']?.toString() ?? '';
    final status = _schemeData!['status']?.toString() ?? '';
    final startDate = _schemeData!['startDate']?.toString() ?? '';
    final endDate = _schemeData!['endDate']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Basic Information Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schemeName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Scheme ID', schemeId, theme),
                _buildDetailRow('Category', category, theme),
                _buildDetailRow('Status', status, theme),
                _buildDetailRow('Start Date', startDate, theme),
                _buildDetailRow('End Date', endDate, theme),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Category-specific details
        Text(
          '${category} Scheme Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        if (_isLoadingDetails)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else if (_detailsError != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _detailsError!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadCategorySpecificDetails,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_categoryDetails.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No additional details available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              ),
            )
          else
            _buildCategorySpecificSection(category, theme),
      ],
    );
  }

  Widget _buildCategorySpecificSection(String category, ThemeData theme) {
    switch (category) {
      case 'BASKET':
        return _buildBasketDetails(theme);
      case 'VALUE':
        return _buildValueDetails(theme);
      case 'QUANTITY':
        return _buildQuantityDetails(theme);
      case 'POINTS':
        return _buildPointsDetails(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasketDetails(ThemeData theme) {
    print('DEBUG: _buildBasketDetails called with ${_categoryDetails.length} items');

    if (_categoryDetails.isEmpty) {
      print('DEBUG: _categoryDetails is empty');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No basket details available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ),
      );
    }

    final data = _categoryDetails.first;
    print('DEBUG: First item keys: ${data.keys.toList()}');

    // The API returns schemeDetails as a JSON string, we need to decode it
    Map<String, dynamic> schemeDetails;
    if (data['schemeDetails'] is String) {
      print('DEBUG: schemeDetails is a String, parsing JSON...');
      try {
        schemeDetails = json.decode(data['schemeDetails'] as String);
      } catch (e) {
        print('DEBUG: Error parsing JSON: $e');
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error parsing scheme details',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        );
      }
    } else if (data['schemeDetails'] is Map) {
      schemeDetails = data['schemeDetails'] as Map<String, dynamic>;
    } else {
      schemeDetails = data;
    }

    print('DEBUG: Parsed schemeDetails keys: ${schemeDetails.keys.toList()}');

    final targets = (schemeDetails['baskettarget'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final beneficiaries = (schemeDetails['basketbeneficiary'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    print('DEBUG: Extracted ${targets.length} targets and ${beneficiaries.length} beneficiaries');

    if (targets.isEmpty && beneficiaries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No basket targets or beneficiaries found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (targets.isNotEmpty) ...[
          Text(
            'Basket Targets',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...targets.map((target) {
            final productName = target['productName']?.toString() ?? '';
            final amount = target['amount']?.toString() ?? '0';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.shopping_basket, color: Colors.purple),
                title: Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '₹$amount',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        if (beneficiaries.isNotEmpty) ...[
          Text(
            'Beneficiaries',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...beneficiaries.map((ben) {
            final yesCount = ben['yesCount']?.toString() ?? '0';
            final cnValue = ben['cnValue']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.card_giftcard, color: Colors.green),
                title: Text(
                  'Achieve $yesCount out of ${targets.length} targets',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'CN: ₹$cnValue',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildValueDetails(ThemeData theme) {
    if (_categoryDetails.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No value scheme details available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ),
      );
    }

    final data = _categoryDetails.first;

    // Parse schemeDetails if it's a JSON string
    Map<String, dynamic> schemeDetails;
    if (data['schemeDetails'] is String) {
      try {
        schemeDetails = json.decode(data['schemeDetails'] as String);
      } catch (e) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error parsing scheme details',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          ),
        );
      }
    } else if (data['schemeDetails'] is Map) {
      schemeDetails = data['schemeDetails'] as Map<String, dynamic>;
    } else {
      schemeDetails = data;
    }

    final details = (schemeDetails['schemedetails'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    if (details.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No value slabs found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ),
      );
    }

    // Group by product name
    final Map<String, List<Map<String, dynamic>>> productGroups = {};
    for (var detail in details) {
      final productName = detail['productName']?.toString() ?? '';
      if (!productGroups.containsKey(productName)) {
        productGroups[productName] = [];
      }
      productGroups[productName]!.add(detail);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: productGroups.entries.map((entry) {
        final productName = entry.key;
        final slabs = entry.value;

        // Sort slabs by slab number
        slabs.sort((a, b) => (a['slab'] as num).compareTo(b['slab'] as num));

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: const Icon(Icons.category, color: Colors.blue),
            title: Text(
              productName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text('${slabs.length} slabs'),
            children: slabs.map((slab) {
              final slabNo = slab['slab']?.toString() ?? '';
              final achievedSlab = slab['achievedSlab']?.toString() ?? '0';
              final cnValue = slab['cnValue']?.toString() ?? '';

              // Skip slab 0 (no benefit)
              if (slabNo == '0') return const SizedBox.shrink();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 18,
                  child: Text(
                    slabNo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  achievedSlab != '0'
                      ? 'Achieve: ₹$achievedSlab'
                      : 'No minimum',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    cnValue,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantityDetails(ThemeData theme) {
    if (_categoryDetails.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No quantity scheme details available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ),
      );
    }

    final data = _categoryDetails.first;

    // Parse schemeDetails if it's a JSON string
    Map<String, dynamic> schemeDetails;
    if (data['schemeDetails'] is String) {
      try {
        schemeDetails = json.decode(data['schemeDetails'] as String);
      } catch (e) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error parsing scheme details',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          ),
        );
      }
    } else if (data['schemeDetails'] is Map) {
      schemeDetails = data['schemeDetails'] as Map<String, dynamic>;
    } else {
      schemeDetails = data;
    }

    final details = (schemeDetails['schemedetails'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    if (details.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No quantity slabs found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ),
      );
    }

    // Group by product name
    final Map<String, List<Map<String, dynamic>>> productGroups = {};
    for (var detail in details) {
      final productName = detail['productName']?.toString() ?? '';
      if (!productGroups.containsKey(productName)) {
        productGroups[productName] = [];
      }
      productGroups[productName]!.add(detail);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: productGroups.entries.map((entry) {
        final productName = entry.key;
        final slabs = entry.value;

        // Sort slabs by slab number
        slabs.sort((a, b) => (a['slab'] as num).compareTo(b['slab'] as num));

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: const Icon(Icons.inventory_2, color: Colors.green),
            title: Text(
              productName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text('${slabs.length} slabs'),
            children: slabs.map((slab) {
              final slabNo = slab['slab']?.toString() ?? '';
              final achievedSlab = slab['achievedSlab']?.toString() ?? '0';
              final cnValue = slab['cnValue']?.toString() ?? '';

              // Skip slab 0 (no benefit)
              if (slabNo == '0') return const SizedBox.shrink();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 18,
                  child: Text(
                    slabNo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  achievedSlab != '0'
                      ? 'Achieve: $achievedSlab Qty'
                      : 'No minimum',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '₹$cnValue',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPointsDetails(ThemeData theme) {
    if (_categoryDetails.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No points scheme details available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ),
      );
    }

    final data = _categoryDetails.first;

    // Parse schemeDetails if it's a JSON string
    Map<String, dynamic> schemeDetails;
    if (data['schemeDetails'] is String) {
      try {
        schemeDetails = json.decode(data['schemeDetails'] as String);
      } catch (e) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error parsing scheme details',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          ),
        );
      }
    } else if (data['schemeDetails'] is Map) {
      schemeDetails = data['schemeDetails'] as Map<String, dynamic>;
    } else {
      schemeDetails = data;
    }

    final calculations = (schemeDetails['pointcalculation'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final beneficiaries = (schemeDetails['pointbeneficiary'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    if (calculations.isEmpty && beneficiaries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No point calculations or beneficiaries found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calculations.isNotEmpty) ...[
          Text(
            'How to Earn Points',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Group by brand
          ...(() {
            final Map<String, List<Map<String, dynamic>>> brandGroups = {};
            for (var calc in calculations) {
              final brand = calc['Brand']?.toString() ?? 'Unknown';
              if (!brandGroups.containsKey(brand)) {
                brandGroups[brand] = [];
              }
              brandGroups[brand]!.add(calc);
            }

            return brandGroups.entries.map((entry) {
              final brand = entry.key;
              final products = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calculate, color: Colors.orange),
                  ),
                  title: Text(
                    brand,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text('${products.length} product categories'),
                  children: products.map((calc) {
                    final productName = calc['ProductName']?.toString() ?? '';
                    final saleworth = calc['saleworth']?.toString() ?? '0';
                    final points = calc['point']?.toString() ?? '0';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        productName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('Sale worth: ₹$saleworth = $points point${points != '1' ? 's' : ''}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              points,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList();
          })(),

          const SizedBox(height: 24),
        ],

        if (beneficiaries.isNotEmpty) ...[
          Text(
            'Redeem Your Points',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Sort beneficiaries by points (ascending)
          ...(() {
            final sortedBeneficiaries = List<Map<String, dynamic>>.from(beneficiaries);
            sortedBeneficiaries.sort((a, b) {
              final pointA = double.tryParse(a['point']?.toString() ?? '0') ?? 0;
              final pointB = double.tryParse(b['point']?.toString() ?? '0') ?? 0;
              return pointA.compareTo(pointB);
            });

            return sortedBeneficiaries.map((ben) {
              final point = ben['point']?.toString() ?? '';
              final cnValue = ben['cnValue']?.toString() ?? '';

              // Format point value (remove .00 if whole number)
              final pointValue = double.tryParse(point) ?? 0;
              final pointDisplay = pointValue % 1 == 0
                  ? pointValue.toInt().toString()
                  : point;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.orange.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 20),
                        const SizedBox(height: 2),
                        Text(
                          pointDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    cnValue,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Required: $pointDisplay points',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            }).toList();
          })(),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.disabledColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final result = await _schemeService.updateSchemeStatus(
        widget.schemeId,
        newStatus,
      );

      if (result.isSuccess) {
        _showSuccess('Status updated successfully');
        _loadSchemeDetails();
      } else {
        _showError(result.error ?? 'Failed to update status');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}