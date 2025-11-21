// lib/screens/admin/edit_document_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../services/document_service.dart';
import '../../theme/theme_helpers.dart';
import '../../widgets/glass_container.dart';

class EditDocumentScreen extends StatefulWidget {
  final Map<String, dynamic> document;

  const EditDocumentScreen({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  State<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends State<EditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DocumentService _documentService = DocumentService();

  late TextEditingController _titleController;
  String? _selectedCategory;
  String? _selectedBrand;
  File? _newFile;
  String? _newFileName;
  bool _isLoading = false;
  bool _fileChanged = false;

  List<String> _categories = ["CATALOGUE", "PRICE LIST", "SCHEME POSTER", "DISCOUNT STRUCTURE"]; // Hardcoded categories
  List<String> _brands = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: widget.document['title']?.toString() ?? ''
    );
    _selectedCategory = widget.document['category_name']?.toString();
    _selectedBrand = widget.document['brand']?.toString();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    // Load all documents to extract brands only (categories are hardcoded)
    final result = await _documentService.getAllDocuments();

    if (result.isSuccess && result.data != null) {
      // Extract distinct brands
      final brandSet = <String>{};
      for (var doc in result.data!) {
        final brand = doc['brand']?.toString();
        if (brand != null && brand.isNotEmpty) {
          brandSet.add(brand);
        }
      }

      setState(() {
        _brands = brandSet.toList()..sort();
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _newFile = File(result.files.single.path!);
          _newFileName = result.files.single.name;
          _fileChanged = true;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', false);
    }
  }

  Future<void> _updateDocument() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? fileBase64;
      if (_fileChanged && _newFile != null) {
        final fileBytes = await _newFile!.readAsBytes();
        fileBase64 = base64Encode(fileBytes);
      }

      final id = widget.document['id'] as int;

      final result = await _documentService.updateDocument(
        id: id,
        categoryName: _selectedCategory,
        title: _titleController.text.trim(),
        fileDataBase64: fileBase64,
        brand: _selectedBrand,
      );

      setState(() => _isLoading = false);

      if (result.isSuccess) {
        _showSnackBar('Document updated successfully', true);
        Navigator.pop(context, true);
      } else {
        _showSnackBar(result.error ?? 'Failed to update document', false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error: $e', false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Document Information'),
                      const SizedBox(height: 16),
                      _buildTitleField(),
                      const SizedBox(height: 16),
                      _buildCategoryDropdown(),
                      const SizedBox(height: 16),
                      _buildBrandDropdown(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('File'),
                      const SizedBox(height: 16),
                      _buildFilePicker(),
                      const SizedBox(height: 32),
                      _buildUpdateButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
                  'Edit Document',
                  style: ThemeHelper.titleStyle(context),
                ),
                Text(
                  'Update document details',
                  style: ThemeHelper.captionStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: ThemeHelper.subtitleStyle(context),
    );
  }

  Widget _buildTitleField() {
    return GlassContainer(
      child: TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: 'Document Title',
          hintText: 'Enter document title',
          prefixIcon: Icon(
            Icons.title,
            color: ThemeHelper.iconColor(context),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        style: ThemeHelper.bodyStyle(context),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter document title';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return GlassContainer(
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(
            Icons.category,
            color: ThemeHelper.iconColor(context),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        items: _categories.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedCategory = value);
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a category';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildBrandDropdown() {
    return GlassContainer(
      child: DropdownButtonFormField<String>(
        value: _selectedBrand,
        decoration: InputDecoration(
          labelText: 'Brand (Optional)',
          prefixIcon: Icon(
            Icons.branding_watermark,
            color: ThemeHelper.iconColor(context),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('None'),
          ),
          ..._brands.map((brand) {
            return DropdownMenuItem(
              value: brand,
              child: Text(brand),
            );
          }),
        ],
        onChanged: (value) {
          setState(() => _selectedBrand = value);
        },
      ),
    );
  }

  Widget _buildFilePicker() {
    final currentTitle = widget.document['title']?.toString() ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassContainer(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.description,
                  color: ThemeHelper.iconColor(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current File',
                        style: ThemeHelper.captionStyle(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _newFileName ?? currentTitle,
                        style: ThemeHelper.bodyStyle(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickFile,
          child: GlassContainer(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ThemeHelper.borderColor(context),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _fileChanged
                        ? Icons.check_circle
                        : Icons.cloud_upload_outlined,
                    size: 40,
                    color: _fileChanged
                        ? ThemeHelper.successColor
                        : ThemeHelper.iconColor(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _fileChanged
                        ? 'New file selected'
                        : 'Tap to replace file',
                    style: ThemeHelper.bodyStyle(context),
                    textAlign: TextAlign.center,
                  ),
                  if (!_fileChanged) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Supported: PDF, DOC, DOCX, XLS, XLSX, JPG, PNG',
                      style: ThemeHelper.captionStyle(context),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateDocument,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.update, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Update Document',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}