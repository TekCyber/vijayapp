import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/scheme_service.dart';

class EditSchemeScreen extends StatefulWidget {
  final String schemeId;

  const EditSchemeScreen({Key? key, required this.schemeId}) : super(key: key);

  @override
  State<EditSchemeScreen> createState() => _EditSchemeScreenState();
}

class _EditSchemeScreenState extends State<EditSchemeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schemeService = SchemeService();
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Scheme Master Fields
  final _schemeIdController = TextEditingController();
  final _schemeNameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _schemeCategory;
  String _status = 'Active';

  // Category-specific data
  Map<String, dynamic>? _originalSchemeData;
  List<Map<String, dynamic>> _basketTargets = [];
  List<Map<String, dynamic>> _basketBeneficiaries = [];
  List<Map<String, dynamic>> _valueSlabs = [];
  List<Map<String, dynamic>> _quantitySlabs = [];
  List<Map<String, dynamic>> _pointCalculations = [];
  List<Map<String, dynamic>> _pointBeneficiaries = [];

  final List<String> _statusOptions = ['Active', 'Inactive', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadSchemeData();
  }

  @override
  void dispose() {
    _schemeIdController.dispose();
    _schemeNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSchemeData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load master details
      final masterResult = await _schemeService.getSchemeById(widget.schemeId);

      if (masterResult.isSuccess && masterResult.data != null && masterResult.data!.isNotEmpty) {
        final masterData = masterResult.data!.first;

        setState(() {
          _schemeIdController.text = masterData['schemeId']?.toString() ?? '';
          _schemeNameController.text = masterData['schemeName']?.toString() ?? '';
          _schemeCategory = masterData['schemeCategory']?.toString();

          // Normalize status to match dropdown options (handle case variations)
          final dbStatus = masterData['status']?.toString() ?? 'Active';
          if (dbStatus.toLowerCase() == 'active') {
            _status = 'Active';
          } else if (dbStatus.toLowerCase() == 'inactive') {
            _status = 'Inactive';
          } else if (dbStatus.toLowerCase() == 'completed') {
            _status = 'Completed';
          } else {
            _status = 'Active';
          }

          // Parse dates
          final startDateStr = masterData['startDate']?.toString();
          final endDateStr = masterData['endDate']?.toString();

          if (startDateStr != null) {
            _startDate = DateTime.tryParse(startDateStr);
          }
          if (endDateStr != null) {
            _endDate = DateTime.tryParse(endDateStr);
          }

          _originalSchemeData = masterData;
        });

        // Load category-specific details
        await _loadCategoryDetails();
      } else {
        _showError('Failed to load scheme data');
      }
    } catch (e) {
      _showError('Error loading scheme: ${e.toString()}');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadCategoryDetails() async {
    if (_schemeCategory == null) return;

    try {
      switch (_schemeCategory) {
        case 'BASKET':
          final result = await _schemeService.getBasketSchemeDetails(widget.schemeId);
          if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
            final data = result.data!.first;
            Map<String, dynamic> schemeDetails;

            if (data['schemeDetails'] is String) {
              schemeDetails = json.decode(data['schemeDetails'] as String);
            } else {
              schemeDetails = data;
            }

            setState(() {
              _basketTargets = (schemeDetails['baskettarget'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ?? [];
              _basketBeneficiaries = (schemeDetails['basketbeneficiary'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ?? [];
            });
          }
          break;

        case 'VALUE':
          final result = await _schemeService.getValueSchemeDetails(widget.schemeId);
          if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
            final data = result.data!.first;
            Map<String, dynamic> schemeDetails;

            if (data['schemeDetails'] is String) {
              schemeDetails = json.decode(data['schemeDetails'] as String);
            } else {
              schemeDetails = data;
            }

            setState(() {
              _valueSlabs = (schemeDetails['schemedetails'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ?? [];
            });
          }
          break;

        case 'QUANTITY':
          final result = await _schemeService.getQuantitySchemeDetails(widget.schemeId);
          if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
            final data = result.data!.first;
            Map<String, dynamic> schemeDetails;

            if (data['schemeDetails'] is String) {
              schemeDetails = json.decode(data['schemeDetails'] as String);
            } else {
              schemeDetails = data;
            }

            setState(() {
              _quantitySlabs = (schemeDetails['schemedetails'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ?? [];
            });
          }
          break;

        case 'POINTS':
          final result = await _schemeService.getPointsSchemeDetails(widget.schemeId);
          if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
            final data = result.data!.first;
            Map<String, dynamic> schemeDetails;

            if (data['schemeDetails'] is String) {
              schemeDetails = json.decode(data['schemeDetails'] as String);
            } else {
              schemeDetails = data;
            }

            setState(() {
              _pointCalculations = (schemeDetails['pointcalculation'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ?? [];
              _pointBeneficiaries = (schemeDetails['pointbeneficiary'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ?? [];
            });
          }
          break;
      }
    } catch (e) {
      print('Error loading category details: $e');
      _showError('Error loading category details: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Scheme'),
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSchemeMasterSection(theme),
            const SizedBox(height: 24),
            if (_schemeCategory != null) ...[
              _buildCategorySpecificSection(theme),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _isLoadingData ? null : _buildBottomBar(theme),
    );
  }

  Widget _buildSchemeMasterSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheme Master Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Scheme ID (Read-only)
            TextFormField(
              controller: _schemeIdController,
              decoration: const InputDecoration(
                labelText: 'Scheme ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Scheme Name
            TextFormField(
              controller: _schemeNameController,
              decoration: const InputDecoration(
                labelText: 'Scheme Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter scheme name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category (Read-only)
            DropdownButtonFormField<String>(
              value: _schemeCategory,
              decoration: const InputDecoration(
                labelText: 'Scheme Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: [_schemeCategory].map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category ?? ''),
                );
              }).toList(),
              onChanged: null, // Read-only
            ),
            const SizedBox(height: 16),

            // Status Dropdown
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _status = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Date Range
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'Start Date *',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'End Date *',
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? DateFormat('dd-MMM-yyyy').format(date) : 'Select Date',
          style: TextStyle(
            color: date != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildCategorySpecificSection(ThemeData theme) {
    switch (_schemeCategory) {
      case 'BASKET':
        return _buildBasketSection(theme);
      case 'VALUE':
        return _buildValueSection(theme);
      case 'QUANTITY':
        return _buildQuantitySection(theme);
      case 'POINTS':
        return _buildPointsSection(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasketSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basket Targets
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Basket Targets',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${_basketTargets.length} products',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: Colors.purple,
                          onPressed: _addBasketTarget,
                          tooltip: 'Add Target',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_basketTargets.isEmpty)
                  const Text('No targets defined')
                else
                  ..._basketTargets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final target = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.purple.withOpacity(0.05),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_basket, color: Colors.purple),
                        title: Text(target['productName']?.toString() ?? ''),
                        subtitle: Text('Target: ₹${target['amount']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: Colors.purple,
                              onPressed: () => _editBasketTarget(index, target),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              onPressed: () => _deleteBasketTarget(index),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Basket Beneficiaries
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Beneficiaries',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${_basketBeneficiaries.length} tiers',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: Colors.green,
                          onPressed: _addBasketBeneficiary,
                          tooltip: 'Add Beneficiary',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_basketBeneficiaries.isEmpty)
                  const Text('No beneficiaries defined')
                else
                  ..._basketBeneficiaries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ben = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.green.withOpacity(0.05),
                      child: ListTile(
                        leading: const Icon(Icons.card_giftcard, color: Colors.green),
                        title: Text('Achieve ${ben['yesCount']} targets'),
                        subtitle: Text('Benefit: ₹${ben['cnValue']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: Colors.green,
                              onPressed: () => _editBasketBeneficiary(index, ben),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              onPressed: () => _deleteBasketBeneficiary(index),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addBasketTarget() async {
    final productController = TextEditingController();
    final amountController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Basket Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (productController.text.isEmpty || amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _basketTargets.add({
          'productName': productController.text,
          'amount': double.tryParse(amountController.text) ?? 0,
          'schemeId': widget.schemeId,
        });
      });
      _showInfo('Target added. Click "Save Changes" to apply.');
    }
  }

  Future<void> _addBasketBeneficiary() async {
    final yesCountController = TextEditingController();
    final cnValueController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Beneficiary Tier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: yesCountController,
              decoration: const InputDecoration(
                labelText: 'Number of Targets to Achieve',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cnValueController,
              decoration: const InputDecoration(
                labelText: 'Benefit Amount',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (yesCountController.text.isEmpty || cnValueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _basketBeneficiaries.add({
          'yesCount': int.tryParse(yesCountController.text) ?? 0,
          'cnValue': cnValueController.text,
          'schemeId': widget.schemeId,
        });
      });
      _showInfo('Beneficiary added. Click "Save Changes" to apply.');
    }
  }

  Future<void> _editBasketTarget(int index, Map<String, dynamic> target) async {
    final amountController = TextEditingController(
        text: target['amount']?.toString() ?? '0'
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${target['productName']}'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(
            labelText: 'Target Amount',
            border: OutlineInputBorder(),
            prefixText: '₹',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter amount')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _basketTargets[index]['amount'] = double.tryParse(amountController.text) ?? 0;
      });
      _showInfo('Target updated. Click "Save Changes" to apply.');
    }
  }

  Future<void> _deleteBasketTarget(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Basket Target'),
        content: const Text('Are you sure you want to delete this target?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _basketTargets.removeAt(index);
      });
      _showInfo('Target marked for deletion. Click "Save Changes" to apply.');
    }
  }

  Future<void> _editBasketBeneficiary(int index, Map<String, dynamic> ben) async {
    final yesCountController = TextEditingController(
        text: ben['yesCount']?.toString() ?? '0'
    );
    final cnValueController = TextEditingController(
        text: ben['cnValue']?.toString() ?? ''
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Beneficiary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: yesCountController,
              decoration: const InputDecoration(
                labelText: 'Number of Targets to Achieve',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cnValueController,
              decoration: const InputDecoration(
                labelText: 'Benefit Amount',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (yesCountController.text.isEmpty || cnValueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _basketBeneficiaries[index]['yesCount'] = int.tryParse(yesCountController.text) ?? 0;
        _basketBeneficiaries[index]['cnValue'] = cnValueController.text;
      });
      _showInfo('Beneficiary updated. Click "Save Changes" to apply.');
    }
  }

  Future<void> _deleteBasketBeneficiary(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Beneficiary'),
        content: const Text('Are you sure you want to delete this beneficiary tier?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _basketBeneficiaries.removeAt(index);
      });
      _showInfo('Beneficiary marked for deletion. Click "Save Changes" to apply.');
    }
  }

  Widget _buildValueSection(ThemeData theme) {
    // Group by product
    final Map<String, List<Map<String, dynamic>>> productGroups = {};
    final Map<String, List<int>> productIndexes = {}; // Track original indexes

    for (int i = 0; i < _valueSlabs.length; i++) {
      final slab = _valueSlabs[i];
      final productName = slab['productName']?.toString() ?? '';
      if (!productGroups.containsKey(productName)) {
        productGroups[productName] = [];
        productIndexes[productName] = [];
      }
      productGroups[productName]!.add(slab);
      productIndexes[productName]!.add(i);
    }

    // Get unique product names for adding new slabs
    final Set<String> existingProducts = productGroups.keys.toSet();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Value Scheme Slabs',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${productGroups.length} products',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Colors.blue,
                      onPressed: () => _addValueSlab(existingProducts.toList()),
                      tooltip: 'Add New Slab',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (productGroups.isEmpty)
              const Text('No value slabs defined')
            else
              ...productGroups.entries.map((entry) {
                final productName = entry.key;
                final slabs = entry.value;
                final indexes = productIndexes[productName];

                if (indexes == null || indexes.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Sort both slabs and indexes together
                final combined = List.generate(slabs.length, (i) => {'slab': slabs[i], 'index': indexes[i]});
                combined.sort((a, b) {
                  final slabA = a['slab'] as Map<String, dynamic>?;
                  final slabB = b['slab'] as Map<String, dynamic>?;
                  if (slabA == null || slabB == null) return 0;
                  return (slabA['slab'] as num).compareTo(slabB['slab'] as num);
                });

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.blue.withOpacity(0.05),
                  child: ExpansionTile(
                    title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${slabs.length} slabs'),
                    children: combined.map((item) {
                      final slab = item['slab'] as Map<String, dynamic>;
                      final index = item['index'] as int;
                      final slabNo = slab['slab']?.toString() ?? '';
                      final achievedSlab = slab['achievedSlab']?.toString() ?? '0';
                      final cnValue = slab['cnValue']?.toString() ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 16,
                          child: Text(
                            slabNo,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        title: Text('Achieve: ₹$achievedSlab'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cnValue,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: Colors.blue,
                              onPressed: () => _editValueSlab(index, slab),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              onPressed: () => _deleteValueSlab(index, productName, slabNo),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _addValueSlab(List<String> existingProducts) async {
    final productController = TextEditingController();
    final slabNoController = TextEditingController();
    final achievedSlabController = TextEditingController();
    final cnValueController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Value Slab'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existingProducts.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Product',
                    border: OutlineInputBorder(),
                  ),
                  items: existingProducts.map((prod) => DropdownMenuItem(
                    value: prod,
                    child: Text(prod),
                  )).toList(),
                  onChanged: (value) {
                    productController.text = value ?? '';
                  },
                ),
              const SizedBox(height: 8),
              const Text('OR enter new product name:'),
              const SizedBox(height: 8),
              TextField(
                controller: productController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: slabNoController,
                decoration: const InputDecoration(
                  labelText: 'Slab Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: achievedSlabController,
                decoration: const InputDecoration(
                  labelText: 'Achievement Value',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cnValueController,
                decoration: const InputDecoration(
                  labelText: 'Benefit (CN Value)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 1.75%',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (productController.text.isEmpty || slabNoController.text.isEmpty ||
                  achievedSlabController.text.isEmpty || cnValueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _valueSlabs.add({
          'productName': productController.text,
          'slab': int.tryParse(slabNoController.text) ?? 0,
          'achievedSlab': double.tryParse(achievedSlabController.text) ?? 0,
          'cnValue': cnValueController.text,
          'schemeId': widget.schemeId,
          // Note: ID will be null for new items, will be created on save
        });
      });
      _showInfo('Slab added. Click "Save Changes" to apply.');
    }
  }

  Future<void> _editValueSlab(int index, Map<String, dynamic> slab) async {
    final achievedSlabController = TextEditingController(
        text: slab['achievedSlab']?.toString() ?? '0'
    );
    final cnValueController = TextEditingController(
        text: slab['cnValue']?.toString() ?? ''
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Slab ${slab['slab']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: achievedSlabController,
              decoration: const InputDecoration(
                labelText: 'Achievement Value',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cnValueController,
              decoration: const InputDecoration(
                labelText: 'Benefit (CN Value)',
                border: OutlineInputBorder(),
                hintText: 'e.g., 1.75%',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (achievedSlabController.text.isEmpty || cnValueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _valueSlabs[index]['achievedSlab'] = double.tryParse(achievedSlabController.text) ?? 0;
        _valueSlabs[index]['cnValue'] = cnValueController.text;
      });
      _showInfo('Slab updated. Click "Save Changes" to apply.');
    }
  }

  Future<void> _deleteValueSlab(int index, String productName, String slabNo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slab'),
        content: Text('Are you sure you want to delete slab $slabNo for $productName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _valueSlabs.removeAt(index);
      });
      _showInfo('Slab marked for deletion. Click "Save Changes" to apply.');
    }
  }

  Widget _buildQuantitySection(ThemeData theme) {
    // Group by product
    final Map<String, List<Map<String, dynamic>>> productGroups = {};
    final Map<String, List<int>> productIndexes = {}; // Track original indexes

    for (int i = 0; i < _quantitySlabs.length; i++) {
      final slab = _quantitySlabs[i];
      final productName = slab['productName']?.toString() ?? '';
      if (!productGroups.containsKey(productName)) {
        productGroups[productName] = [];
        productIndexes[productName] = [];
      }
      productGroups[productName]!.add(slab);
      productIndexes[productName]!.add(i);
    }

    // Get unique product names for adding new slabs
    final Set<String> existingProducts = productGroups.keys.toSet();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantity Scheme Slabs',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${productGroups.length} products',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Colors.green,
                      onPressed: () => _addQuantitySlab(existingProducts.toList()),
                      tooltip: 'Add New Slab',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (productGroups.isEmpty)
              const Text('No quantity slabs defined')
            else
              ...productGroups.entries.map((entry) {
                final productName = entry.key;
                final slabs = entry.value;
                final indexes = productIndexes[productName];

                if (indexes == null || indexes.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Sort both slabs and indexes together
                final combined = List.generate(slabs.length, (i) => {'slab': slabs[i], 'index': indexes[i]});
                combined.sort((a, b) {
                  final slabA = a['slab'] as Map<String, dynamic>?;
                  final slabB = b['slab'] as Map<String, dynamic>?;
                  if (slabA == null || slabB == null) return 0;
                  return (slabA['slab'] as num).compareTo(slabB['slab'] as num);
                });

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.green.withOpacity(0.05),
                  child: ExpansionTile(
                    title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${slabs.length} slabs'),
                    children: combined.map((item) {
                      final slab = item['slab'] as Map<String, dynamic>;
                      final index = item['index'] as int;
                      final slabNo = slab['slab']?.toString() ?? '';
                      final achievedSlab = slab['achievedSlab']?.toString() ?? '0';
                      final cnValue = slab['cnValue']?.toString() ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 16,
                          child: Text(
                            slabNo,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        title: Text('Achieve: $achievedSlab Qty'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹$cnValue',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: Colors.green,
                              onPressed: () => _editQuantitySlab(index, slab),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              onPressed: () => _deleteQuantitySlab(index, productName, slabNo),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _addQuantitySlab(List<String> existingProducts) async {
    final productController = TextEditingController();
    final slabNoController = TextEditingController();
    final achievedSlabController = TextEditingController();
    final cnValueController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Quantity Slab'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existingProducts.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Product',
                    border: OutlineInputBorder(),
                  ),
                  items: existingProducts.map((prod) => DropdownMenuItem(
                    value: prod,
                    child: Text(prod),
                  )).toList(),
                  onChanged: (value) {
                    productController.text = value ?? '';
                  },
                ),
              const SizedBox(height: 8),
              const Text('OR enter new product name:'),
              const SizedBox(height: 8),
              TextField(
                controller: productController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: slabNoController,
                decoration: const InputDecoration(
                  labelText: 'Slab Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: achievedSlabController,
                decoration: const InputDecoration(
                  labelText: 'Quantity to Achieve',
                  border: OutlineInputBorder(),
                  suffixText: 'Qty',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cnValueController,
                decoration: const InputDecoration(
                  labelText: 'Benefit Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (productController.text.isEmpty || slabNoController.text.isEmpty ||
                  achievedSlabController.text.isEmpty || cnValueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _quantitySlabs.add({
          'productName': productController.text,
          'slab': int.tryParse(slabNoController.text) ?? 0,
          'achievedSlab': double.tryParse(achievedSlabController.text) ?? 0,
          'cnValue': cnValueController.text,
          'schemeId': widget.schemeId,
        });
      });
      _showInfo('Slab added. Click "Save Changes" to apply.');
    }
  }

  Future<void> _editQuantitySlab(int index, Map<String, dynamic> slab) async {
    final achievedSlabController = TextEditingController(
        text: slab['achievedSlab']?.toString() ?? '0'
    );
    final cnValueController = TextEditingController(
        text: slab['cnValue']?.toString() ?? ''
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Slab ${slab['slab']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: achievedSlabController,
              decoration: const InputDecoration(
                labelText: 'Quantity to Achieve',
                border: OutlineInputBorder(),
                suffixText: 'Qty',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cnValueController,
              decoration: const InputDecoration(
                labelText: 'Benefit Amount',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (achievedSlabController.text.isEmpty || cnValueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _quantitySlabs[index]['achievedSlab'] = double.tryParse(achievedSlabController.text) ?? 0;
        _quantitySlabs[index]['cnValue'] = cnValueController.text;
      });
      _showInfo('Slab updated. Click "Save Changes" to apply.');
    }
  }

  Future<void> _deleteQuantitySlab(int index, String productName, String slabNo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slab'),
        content: Text('Are you sure you want to delete slab $slabNo for $productName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _quantitySlabs.removeAt(index);
      });
      _showInfo('Slab marked for deletion. Click "Save Changes" to apply.');
    }
  }

  Widget _buildPointsSection(ThemeData theme) {
    // Group calculations by brand
    final Map<String, List<Map<String, dynamic>>> brandGroups = {};
    final Map<String, List<int>> brandIndexes = {};

    for (int i = 0; i < _pointCalculations.length; i++) {
      final calc = _pointCalculations[i];
      final brand = calc['Brand']?.toString() ?? 'Unknown';
      if (!brandGroups.containsKey(brand)) {
        brandGroups[brand] = [];
        brandIndexes[brand] = [];
      }
      brandGroups[brand]!.add(calc);
      brandIndexes[brand]!.add(i);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Point Calculations
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Point Calculation Rules',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_pointCalculations.length} rules',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (brandGroups.isEmpty)
                  const Text('No point calculation rules defined')
                else
                  ...brandGroups.entries.map((entry) {
                    final brand = entry.key;
                    final products = entry.value;
                    final indexes = brandIndexes[brand];

                    if (indexes == null || indexes.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.orange.withOpacity(0.05),
                      child: ExpansionTile(
                        title: Text(brand, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${products.length} products'),
                        children: List.generate(products.length, (i) {
                          final calc = products[i];
                          final index = indexes[i];

                          return ListTile(
                            dense: true,
                            title: Text(calc['ProductName']?.toString() ?? ''),
                            subtitle: Text('₹${calc['saleworth']} = ${calc['point']} pt'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  color: Colors.orange,
                                  onPressed: () => _editPointCalculation(index, calc),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: Colors.red,
                                  onPressed: () => _deletePointCalculation(index),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Point Beneficiaries
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Redemption Options',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_pointBeneficiaries.length} rewards',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_pointBeneficiaries.isEmpty)
                  const Text('No redemption options defined')
                else
                  ..._pointBeneficiaries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ben = entry.value;
                    final point = ben['point']?.toString() ?? '';
                    final pointValue = double.tryParse(point) ?? 0;
                    final pointDisplay = pointValue % 1 == 0
                        ? pointValue.toInt().toString()
                        : point;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.orange.withOpacity(0.05),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 16),
                              Text(
                                pointDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: Text(
                          ben['cnValue']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('$pointDisplay points required'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: Colors.orange,
                              onPressed: () => _editPointBeneficiary(index, ben),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              onPressed: () => _deletePointBeneficiary(index),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editPointCalculation(int index, Map<String, dynamic> calc) async {
    final saleworthController = TextEditingController(
        text: calc['saleworth']?.toString() ?? '0'
    );
    final pointController = TextEditingController(
        text: calc['point']?.toString() ?? '1'
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${calc['ProductName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: saleworthController,
              decoration: const InputDecoration(
                labelText: 'Sale Worth',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointController,
              decoration: const InputDecoration(
                labelText: 'Points Earned',
                border: OutlineInputBorder(),
                suffixText: 'pts',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (saleworthController.text.isEmpty || pointController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _pointCalculations[index]['saleworth'] = double.tryParse(saleworthController.text) ?? 0;
        _pointCalculations[index]['point'] = double.tryParse(pointController.text) ?? 1;
      });
      _showInfo('Point rule updated. Click "Save Changes" to apply.');
    }
  }

  Future<void> _editPointBeneficiary(int index, Map<String, dynamic> ben) async {
    final pointController = TextEditingController(
        text: ben['point']?.toString() ?? '0'
    );
    final cnValueController = TextEditingController(
        text: ben['cnValue']?.toString() ?? ''
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Redemption Option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pointController,
              decoration: const InputDecoration(
                labelText: 'Points Required',
                border: OutlineInputBorder(),
                suffixText: 'pts',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cnValueController,
              decoration: const InputDecoration(
                labelText: 'Reward/Benefit',
                border: OutlineInputBorder(),
                hintText: 'e.g., 2N/3D @COORG',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pointController.text.isEmpty || cnValueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _pointBeneficiaries[index]['point'] = double.tryParse(pointController.text) ?? 0;
        _pointBeneficiaries[index]['cnValue'] = cnValueController.text;
      });
      _showInfo('Redemption option updated. Click "Save Changes" to apply.');
    }
  }

  Future<void> _deletePointCalculation(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Point Calculation'),
        content: const Text('Are you sure you want to delete this point calculation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _pointCalculations.removeAt(index);
      });
      _showInfo('Point calculation marked for deletion. Click "Save Changes" to apply.');
    }
  }

  Future<void> _deletePointBeneficiary(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Redemption Option'),
        content: const Text('Are you sure you want to delete this redemption option?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _pointBeneficiaries.removeAt(index);
      });
      _showInfo('Redemption option marked for deletion. Click "Save Changes" to apply.');
    }
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showError('Please select both start and end dates');
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showError('End date must be after start date');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare scheme data for createScheme API (same structure as add_scheme_screen)
      final Map<String, dynamic> schemeData = {
        'schemeMaster': {
          'schemeId': _schemeIdController.text,
          'schemeName': _schemeNameController.text,
          'startDate': DateFormat('yyyy-MM-dd').format(_startDate!),
          'endDate': DateFormat('yyyy-MM-dd').format(_endDate!),
          'schemeCategory': _schemeCategory,
          'status': _status,
        },
      };

      // Add category-specific data based on scheme type
      if (_schemeCategory == 'BASKET') {
        schemeData['basketTargets'] = _basketTargets.map((target) {
          final Map<String, dynamic> targetData = Map<String, dynamic>.from(target);
          targetData['schemeId'] = _schemeIdController.text;
          return targetData;
        }).toList();

        schemeData['basketBeneficiaries'] = _basketBeneficiaries.map((beneficiary) {
          final Map<String, dynamic> beneficiaryData = Map<String, dynamic>.from(beneficiary);
          beneficiaryData['schemeId'] = _schemeIdController.text;
          return beneficiaryData;
        }).toList();
      } else if (_schemeCategory == 'VALUE' || _schemeCategory == 'QUANTITY') {
        final sourceList = _schemeCategory == 'VALUE' ? _valueSlabs : _quantitySlabs;
        schemeData['schemeDetails'] = sourceList.map((detail) {
          final Map<String, dynamic> detailData = Map<String, dynamic>.from(detail);
          detailData['schemeId'] = _schemeIdController.text;
          return detailData;
        }).toList();
      } else if (_schemeCategory == 'POINTS') {
        schemeData['pointCalculations'] = _pointCalculations.map((calc) {
          final Map<String, dynamic> calcData = Map<String, dynamic>.from(calc);
          calcData['schemeId'] = _schemeIdController.text;
          return calcData;
        }).toList();

        schemeData['pointBeneficiaries'] = _pointBeneficiaries.map((beneficiary) {
          final Map<String, dynamic> beneficiaryData = Map<String, dynamic>.from(beneficiary);
          beneficiaryData['schemeId'] = _schemeIdController.text;
          return beneficiaryData;
        }).toList();
      }

      // Call createScheme API
      final result = await _schemeService.createScheme(schemeData);

      if (!result.isSuccess) {
        _showError(result.error ?? 'Failed to save changes');
        return;
      }

      // Clear all memory after successful save
      _clearMemory();

      _showSuccess('All changes saved successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearMemory() {
    // Clear all controllers
    _schemeIdController.clear();
    _schemeNameController.clear();

    // Reset dates
    _startDate = null;
    _endDate = null;

    // Reset category and status
    _schemeCategory = null;
    _status = 'Active';

    // Clear all category-specific data
    _originalSchemeData = null;
    _basketTargets.clear();
    _basketBeneficiaries.clear();
    _valueSlabs.clear();
    _quantitySlabs.clear();
    _pointCalculations.clear();
    _pointBeneficiaries.clear();
  }
}