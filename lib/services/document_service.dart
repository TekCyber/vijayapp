// lib/services/document_service.dart
import 'api_service.dart';

class DocumentService {
  final ApiService _apiService = ApiService();

  // Get all documents with optional filters
  Future<ApiResponse<List<Map<String, dynamic>>>> getAllDocuments({
    String? category,
    String? brand,
    int? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    return await _apiService.request(
      payload: {
        'sqlKey': 'SP_GET_ACTIVE_DOCUMENTS',
      },
    );
  }

  // Get document by ID
  Future<ApiResponse<List<Map<String, dynamic>>>> getDocumentById(int id) async {
    return await _apiService.request(
      payload: {
        'sqlKey': 'sp_get_document_by_id',
        'p_id': id,
      },
    );
  }

  // Create new document
  Future<ApiResponse<List<Map<String, dynamic>>>> createDocument({
    required String categoryName,
    required String title,
    required String fileDataBase64,
    String? brand,
  }) async {
    return await _apiService.request(
      payload: {
        'sqlKey': 'sp_insert_document',
        'category_name': categoryName,
        'title': title,
        'file_data_base64': fileDataBase64,
        'brand': brand,
        'is_active' : 1
      },
    );
  }

  // Update document
  Future<ApiResponse<List<Map<String, dynamic>>>> updateDocument({
    required int id,
    String? categoryName,
    String? title,
    String? fileDataBase64,
    String? brand,
    int? isActive,
  }) async {
    return await _apiService.request(
      payload: {
        'sqlKey': 'sp_update_document',
        'p_id': id,
        'p_category_name': categoryName,
        'p_title': title,
        'p_file_data': fileDataBase64,
        'p_brand': brand,
        'p_is_active': isActive,
      },
    );
  }

  // Delete document
  Future<ApiResponse<List<Map<String, dynamic>>>> deleteDocument(int id) async {
    return await _apiService.request(
      payload: {
        'sqlKey': 'sp_delete_document',
        'p_id': id,
      },
    );
  }

  // Toggle document status
  Future<ApiResponse<List<Map<String, dynamic>>>> toggleDocumentStatus(
      int id, bool isActive) async {
    return await _apiService.request(
      payload: {
        'sqlKey': 'sp_update_document',
        'p_id': id,
        'p_is_active': isActive ? 1 : 0,
      },
    );
  }

  // Get categories with document count
  Future<ApiResponse<List<Map<String, dynamic>>>> getCategories() async {
    return await _apiService.request(
      payload: {
        'sqlKey': 'sp_get_categories',
      },
    );
  }

  // Get brands
  Future<ApiResponse<List<Map<String, dynamic>>>> getBrands() async {
    return await _apiService.request(
      payload: {
        'sqlKey': 'sp_get_brands',
      },
    );
  }

  // Download document
  Future<ApiResponse<List<Map<String, dynamic>>>> downloadDocument(int id) async {
    return await _apiService.request(
      payload: {
        'sqlKey': 'sp_get_document_by_id',
        'p_id': id,
      },
    );
  }
}