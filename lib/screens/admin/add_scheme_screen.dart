import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/scheme_service.dart';


class AddSchemeScreen extends StatefulWidget {
  const AddSchemeScreen({Key? key}) : super(key: key);

  @override
  State<AddSchemeScreen> createState() => _AddSchemeScreenState();
}

class _AddSchemeScreenState extends State<AddSchemeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schemeService = SchemeService();
  bool _isLoading = false;

  // Scheme Master Fields
  final _schemeIdController = TextEditingController();
  final _schemeNameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _schemeCategory;
  String _status = 'Active';

  // Category-specific data
  final List<Map<String, dynamic>> _schemeDetails = [];
  final List<Map<String, dynamic>> _basketBeneficiaries = [];
  final List<Map<String, dynamic>> _pointBeneficiaries = [];
  final List<Map<String, dynamic>> _pointCalculations = [];
  final List<Map<String, dynamic>> _basketTargets = [];

  final List<String> _categories = ['BASKET', 'VALUE', 'QUANTITY', 'POINTS'];
  final List<String> _statusOptions = ['Active', 'InActive', 'Completed'];

  @override
  void dispose() {
    _schemeIdController.dispose();
    _schemeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Scheme'),
        elevation: 0,
      ),
      body: Form(
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
      bottomNavigationBar: _buildBottomBar(theme),
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

            // Scheme ID
            TextFormField(
              controller: _schemeIdController,
              decoration: const InputDecoration(
                labelText: 'Scheme ID *',
                hintText: 'e.g., SCH001',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter scheme ID';
                }
                if (value.length > 20) {
                  return 'Scheme ID must be 20 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Scheme Name
            TextFormField(
              controller: _schemeNameController,
              decoration: const InputDecoration(
                labelText: 'Scheme Name *',
                hintText: 'e.g., Festival Offer 2025',
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

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _schemeCategory,
              decoration: const InputDecoration(
                labelText: 'Scheme Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _schemeCategory = value;
                  // Clear category-specific data when changing category
                  _schemeDetails.clear();
                  _basketBeneficiaries.clear();
                  _pointBeneficiaries.clear();
                  _pointCalculations.clear();
                  _basketTargets.clear();
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
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
          // Reset end date if it's before start date
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

  // BASKET SCHEME SECTION
  Widget _buildBasketSection(ThemeData theme) {
    return Column(
      children: [
        _buildBasketTargetsCard(theme),
        const SizedBox(height: 16),
        _buildBasketBeneficiariesCard(theme),
      ],
    );
  }

  Widget _buildBasketTargetsCard(ThemeData theme) {
    return Card(
      elevation: 2,
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
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _addBasketTarget(),
                  color: theme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_basketTargets.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No basket targets added yet'),
                ),
              )
            else
              ..._basketTargets.asMap().entries.map((entry) {
                return _buildBasketTargetItem(entry.key, entry.value, theme);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasketTargetItem(int index, Map<String, dynamic> target, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(target['productName'] ?? ''),
        subtitle: Text('Target Amount: ${target['amount']}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _basketTargets.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  void _addBasketTarget() {
    final productController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Basket Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productController,
              decoration: const InputDecoration(
                labelText: 'Product Name/Group',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (productController.text.isNotEmpty &&
                  amountController.text.isNotEmpty) {
                setState(() {
                  _basketTargets.add(<String, dynamic>{
                    'productName': productController.text,
                    'amount': int.parse(amountController.text),
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildBasketBeneficiariesCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Basket Beneficiaries',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _addBasketBeneficiary(),
                  color: theme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_basketBeneficiaries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No beneficiaries added yet'),
                ),
              )
            else
              ..._basketBeneficiaries.asMap().entries.map((entry) {
                return _buildBasketBeneficiaryItem(entry.key, entry.value, theme);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasketBeneficiaryItem(int index, Map<String, dynamic> beneficiary, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Yes Count: ${beneficiary['yesCount']}'),
        subtitle: Text('Benefit: ${beneficiary['cnValue']}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _basketBeneficiaries.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  void _addBasketBeneficiary() {
    final yesCountController = TextEditingController();
    final cnValueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Basket Beneficiary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: yesCountController,
              decoration: const InputDecoration(
                labelText: 'Yes Count (Products to achieve)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cnValueController,
              decoration: const InputDecoration(
                labelText: 'Benefit/CN Value',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (yesCountController.text.isNotEmpty &&
                  cnValueController.text.isNotEmpty) {
                setState(() {
                  _basketBeneficiaries.add(<String, dynamic>{
                    'yesCount': int.parse(yesCountController.text),
                    'cnValue': cnValueController.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // VALUE & QUANTITY SCHEME SECTION
  Widget _buildValueSection(ThemeData theme) {
    return _buildSchemeDetailsCard(theme, 'Value');
  }

  Widget _buildQuantitySection(ThemeData theme) {
    return _buildSchemeDetailsCard(theme, 'Quantity');
  }

  Widget _buildSchemeDetailsCard(ThemeData theme, String type) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$type Scheme Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _addSchemeDetail(type),
                  color: theme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_schemeDetails.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No scheme details added yet'),
                ),
              )
            else
              ..._schemeDetails.asMap().entries.map((entry) {
                return _buildSchemeDetailItem(entry.key, entry.value, theme);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeDetailItem(int index, Map<String, dynamic> detail, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(detail['productName'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Slab: ${detail['slab']}'),
            Text('Achieved Slab: ${detail['achievedSlab']}'),
            Text('Benefit: ${detail['cnValue']}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _schemeDetails.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  void _addSchemeDetail(String type) {
    final productController = TextEditingController();
    final slabController = TextEditingController();
    final achievedSlabController = TextEditingController();
    final cnValueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $type Slab'),
        content: SingleChildScrollView(
          child: Column(
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
                controller: slabController,
                decoration: const InputDecoration(
                  labelText: 'Slab Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: achievedSlabController,
                decoration: InputDecoration(
                  labelText: type == 'Quantity' ? 'Quantity Target' : 'Value Target',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cnValueController,
                decoration: const InputDecoration(
                  labelText: 'Benefit/CN Value',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (productController.text.isNotEmpty &&
                  slabController.text.isNotEmpty &&
                  achievedSlabController.text.isNotEmpty &&
                  cnValueController.text.isNotEmpty) {
                setState(() {
                  _schemeDetails.add(<String, dynamic>{
                    'productName': productController.text,
                    'slab': int.parse(slabController.text),
                    'achievedSlab': int.parse(achievedSlabController.text),
                    'cnValue': cnValueController.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // POINTS SCHEME SECTION
  Widget _buildPointsSection(ThemeData theme) {
    return Column(
      children: [
        _buildPointCalculationsCard(theme),
        const SizedBox(height: 16),
        _buildPointBeneficiariesCard(theme),
      ],
    );
  }

  Widget _buildPointCalculationsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Point Calculations',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _addPointCalculation(),
                  color: theme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_pointCalculations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No point calculations added yet'),
                ),
              )
            else
              ..._pointCalculations.asMap().entries.map((entry) {
                return _buildPointCalculationItem(entry.key, entry.value, theme);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPointCalculationItem(int index, Map<String, dynamic> calc, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(calc['productName'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (calc['brand'] != null) Text('Brand: ${calc['brand']}'),
            Text('Sale Worth: ${calc['saleworth']}'),
            Text('Points: ${calc['point']}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _pointCalculations.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  void _addPointCalculation() {
    final brandController = TextEditingController();
    final productController = TextEditingController();
    final saleworthController = TextEditingController();
    final pointController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Point Calculation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: productController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: saleworthController,
                decoration: const InputDecoration(
                  labelText: 'Sale Worth (Amount for point)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointController,
                decoration: const InputDecoration(
                  labelText: 'Points Earned',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (productController.text.isNotEmpty &&
                  saleworthController.text.isNotEmpty &&
                  pointController.text.isNotEmpty) {
                setState(() {
                  _pointCalculations.add(<String, dynamic>{
                    'brand': brandController.text.isEmpty ? null : brandController.text,
                    'productName': productController.text,
                    'saleworth': int.parse(saleworthController.text),
                    'point': double.parse(pointController.text),
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildPointBeneficiariesCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Point Beneficiaries',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _addPointBeneficiary(),
                  color: theme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_pointBeneficiaries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No beneficiaries added yet'),
                ),
              )
            else
              ..._pointBeneficiaries.asMap().entries.map((entry) {
                return _buildPointBeneficiaryItem(entry.key, entry.value, theme);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPointBeneficiaryItem(int index, Map<String, dynamic> beneficiary, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Points: ${beneficiary['point']}'),
        subtitle: Text('Benefit: ${beneficiary['cnValue']}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _pointBeneficiaries.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  void _addPointBeneficiary() {
    final pointController = TextEditingController();
    final cnValueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Point Beneficiary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pointController,
              decoration: const InputDecoration(
                labelText: 'Points Required',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cnValueController,
              decoration: const InputDecoration(
                labelText: 'Benefit/CN Value',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pointController.text.isNotEmpty &&
                  cnValueController.text.isNotEmpty) {
                setState(() {
                  _pointBeneficiaries.add(<String, dynamic>{
                    'point': double.parse(pointController.text),
                    'cnValue': cnValueController.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
              onPressed: _isLoading ? null : _validateAndSave,
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
                  : const Text('Save Scheme'),
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndSave() async {
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

    // Validate category-specific data
    if (_schemeCategory == 'BASKET') {
      if (_basketTargets.isEmpty || _basketBeneficiaries.isEmpty) {
        _showError('Please add at least one basket target and one beneficiary');
        return;
      }
    } else if (_schemeCategory == 'VALUE' || _schemeCategory == 'QUANTITY') {
      if (_schemeDetails.isEmpty) {
        _showError('Please add at least one scheme detail');
        return;
      }
    } else if (_schemeCategory == 'POINTS') {
      if (_pointCalculations.isEmpty || _pointBeneficiaries.isEmpty) {
        _showError('Please add at least one point calculation and one beneficiary');
        return;
      }
    }

    // Prepare data for API call
    final schemeData = _prepareSchemeData();

    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Call API service
      final result = await _schemeService.createScheme(schemeData);

      if (result.isSuccess) {
        _showSuccess(result.message ?? 'Scheme added successfully!');
      } else {
        _showError(result.error ?? 'Failed to add scheme');
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

  Map<String, dynamic> _prepareSchemeData() {
    final Map<String, dynamic> data = <String, dynamic>{
      'schemeMaster': <String, dynamic>{
        'schemeId': _schemeIdController.text,
        'schemeName': _schemeNameController.text,
        'startDate': DateFormat('yyyy-MM-dd').format(_startDate!),
        'endDate': DateFormat('yyyy-MM-dd').format(_endDate!),
        'schemeCategory': _schemeCategory,
        'status': _status,
      },
    };

    if (_schemeCategory == 'BASKET') {
      data['basketTargets'] = _basketTargets.map((target) {
        final Map<String, dynamic> targetData = Map<String, dynamic>.from(target);
        targetData['schemeId'] = _schemeIdController.text;
        return targetData;
      }).toList();

      data['basketBeneficiaries'] = _basketBeneficiaries.map((beneficiary) {
        final Map<String, dynamic> beneficiaryData = Map<String, dynamic>.from(beneficiary);
        beneficiaryData['schemeId'] = _schemeIdController.text;
        return beneficiaryData;
      }).toList();
    } else if (_schemeCategory == 'VALUE' || _schemeCategory == 'QUANTITY') {
      data['schemeDetails'] = _schemeDetails.map((detail) {
        final Map<String, dynamic> detailData = Map<String, dynamic>.from(detail);
        detailData['schemeId'] = _schemeIdController.text;
        return detailData;
      }).toList();
    } else if (_schemeCategory == 'POINTS') {
      data['pointCalculations'] = _pointCalculations.map((calc) {
        final Map<String, dynamic> calcData = Map<String, dynamic>.from(calc);
        calcData['schemeId'] = _schemeIdController.text;
        return calcData;
      }).toList();

      data['pointBeneficiaries'] = _pointBeneficiaries.map((beneficiary) {
        final Map<String, dynamic> beneficiaryData = Map<String, dynamic>.from(beneficiary);
        beneficiaryData['schemeId'] = _schemeIdController.text;
        return beneficiaryData;
      }).toList();
    }

    return data;
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

    // Navigate back after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context, true);
    });
  }
}