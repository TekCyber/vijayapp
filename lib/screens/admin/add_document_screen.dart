// lib/screens/admin/add_document_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../services/document_service.dart';
import '../../theme/theme_helpers.dart';
import '../../widgets/glass_container.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({Key? key}) : super(key: key);

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DocumentService _documentService = DocumentService();

  final _titleController = TextEditingController();
  final _brandController = TextEditingController(); // Brand as text field
  String? _selectedCategory;
  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;

  List<String> _categories = ["CATALOGUE", "PRICE LIST", "SCHEME POSTER", "DISCOUNT STRUCTURE"]; // Hardcoded categories

  @override
  void initState() {
    super.initState();
    // No need to load brands anymore
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', false);
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      _showSnackBar('Please select a file', false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fileBytes = await _selectedFile!.readAsBytes();
      final fileBase64 = base64Encode(fileBytes);

      // Get brand from text field (can be empty)
      final brand = _brandController.text.trim();

      final result = await _documentService.createDocument(
        categoryName: _selectedCategory!,
        title: _titleController.text.trim(),
        fileDataBase64: fileBase64,
        brand: brand.isEmpty ? null : brand,
      );

      setState(() => _isLoading = false);

      if (result.isSuccess) {
        _showSnackBar('Document added successfully', true);
        Navigator.pop(context, true);
      } else {
        _showSnackBar(result.error ?? 'Failed to add document', false);
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
                      _buildBrandField(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('File Upload'),
                      const SizedBox(height: 16),
                      _buildFilePicker(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
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
                  'Add Document',
                  style: ThemeHelper.titleStyle(context),
                ),
                Text(
                  'Upload new document',
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
        hint: Text('Select Category'),
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

  Widget _buildBrandField() {
    return GlassContainer(
      child: TextFormField(
        controller: _brandController,
        decoration: InputDecoration(
          labelText: 'Brand (Optional)',
          hintText: 'Enter brand name',
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
        style: ThemeHelper.bodyStyle(context),
      ),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
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
                _selectedFile != null
                    ? Icons.check_circle
                    : Icons.cloud_upload_outlined,
                size: 48,
                color: _selectedFile != null
                    ? ThemeHelper.successColor
                    : ThemeHelper.iconColor(context),
              ),
              const SizedBox(height: 12),
              Text(
                _fileName ?? 'Tap to select file',
                style: ThemeHelper.bodyStyle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Supported: PDF, DOC, DOCX, XLS, XLSX, JPG, PNG',
                style: ThemeHelper.captionStyle(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveDocument,
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
            Icon(Icons.save, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Save Document',
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