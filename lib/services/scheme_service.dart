import 'api_service.dart';

class SchemeService {
  final ApiService _apiService = ApiService();

  // ==================== CREATE Operations ====================

  /// Insert complete scheme data (master + category-specific tables)
  Future<ApiResponse<List<Map<String, dynamic>>>> createScheme(
      Map<String, dynamic> schemeData) async {
    try {
      final payload = {
        'sqlKey': 'SP_CREATE_SCHEMES_FOR_ADMIN',
        'schemeData': schemeData,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error creating scheme: ${e.toString()}');
    }
  }

  /// Insert scheme master only
  Future<ApiResponse<List<Map<String, dynamic>>>> createSchemeMaster(
      Map<String, dynamic> masterData) async {
    try {
      final payload = {
        'sqlKey': 'createSchemeMaster',
        ...masterData,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error creating scheme master: ${e.toString()}');
    }
  }

  /// Insert basket targets (composite key: schemeId + productName)
  Future<ApiResponse<List<Map<String, dynamic>>>> createBasketTargets(
      List<Map<String, dynamic>> targets) async {
    try {
      final payload = {
        'sqlKey': 'createBasketTargets',
        'targets': targets,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error creating basket targets: ${e.toString()}');
    }
  }

  /// Insert basket beneficiaries
  Future<ApiResponse<List<Map<String, dynamic>>>> createBasketBeneficiaries(
      List<Map<String, dynamic>> beneficiaries) async {
    try {
      final payload = {
        'sqlKey': 'createBasketBeneficiaries',
        'beneficiaries': beneficiaries,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error creating basket beneficiaries: ${e.toString()}');
    }
  }

  /// Insert scheme details (for VALUE and QUANTITY schemes)
  Future<ApiResponse<List<Map<String, dynamic>>>> createSchemeDetails(
      List<Map<String, dynamic>> details) async {
    try {
      final payload = {
        'sqlKey': 'createSchemeDetails',
        'details': details,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error creating scheme details: ${e.toString()}');
    }
  }

  /// Insert point calculations
  Future<ApiResponse<List<Map<String, dynamic>>>> createPointCalculations(
      List<Map<String, dynamic>> calculations) async {
    try {
      final payload = {
        'sqlKey': 'createPointCalculations',
        'calculations': calculations,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error creating point calculations: ${e.toString()}');
    }
  }

  /// Insert point beneficiaries
  Future<ApiResponse<List<Map<String, dynamic>>>> createPointBeneficiaries(
      List<Map<String, dynamic>> beneficiaries) async {
    try {
      final payload = {
        'sqlKey': 'createPointBeneficiaries',
        'beneficiaries': beneficiaries,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error creating point beneficiaries: ${e.toString()}');
    }
  }

  // ==================== READ Operations ====================

  /// Get all schemes
  Future<ApiResponse<List<Map<String, dynamic>>>> getAllSchemes() async {
    try {
      final payload = {
        'sqlKey': 'SP_GET_ALL_SCHEMES_FOR_ADMIN',
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error fetching schemes: ${e.toString()}');
    }
  }

  /// Get scheme by ID with all related data
  Future<ApiResponse<List<Map<String, dynamic>>>> getSchemeById(
      String schemeId) async {
    try {
      final payload = {
        'sqlKey': 'SP_GET_SCHEMES_BY_ID_FOR_ADMIN',
        'schemeId': schemeId,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error fetching scheme: ${e.toString()}');
    }
  }

  /// Get schemes by category
  Future<ApiResponse<List<Map<String, dynamic>>>> getSchemesByCategory(
      String category) async {
    try {
      final payload = {
        'sqlKey': 'getSchemesByCategory',
        'category': category,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error fetching schemes: ${e.toString()}');
    }
  }

  /// Get active schemes
  Future<ApiResponse<List<Map<String, dynamic>>>> getActiveSchemes() async {
    try {
      final payload = {
        'sqlKey': 'getActiveSchemes',
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error fetching active schemes: ${e.toString()}');
    }
  }

  /// Get basket scheme details
  Future<ApiResponse<List<Map<String, dynamic>>>> getBasketSchemeDetails(
      String schemeId) async {
    try {
      final payload = {
        'sqlKey': 'SP_GET_BASKET_SCHEMES_DETAILS_BY_ID_FOR_ADMIN',
        'schemeId': schemeId,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error fetching basket scheme details: ${e.toString()}');
    }
  }

  /// Get value scheme details
  Future<ApiResponse<List<Map<String, dynamic>>>> getValueSchemeDetails(
      String schemeId) async {
    try {
      final payload = {
        'sqlKey': 'SP_GET_VALUE_SCHEME_DETAILS_BY_ID_FOR_ADMIN',
        'schemeId': schemeId,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error fetching value scheme details: ${e.toString()}');
    }
  }

  /// Get quantity scheme details
  Future<ApiResponse<List<Map<String, dynamic>>>> getQuantitySchemeDetails(
      String schemeId) async {
    try {
      final payload = {
        'sqlKey': 'SP_GET_QUANTITY_SCHEME_DETAILS_BY_ID_FOR_ADMIN',
        'schemeId': schemeId,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error fetching quantity scheme details: ${e.toString()}');
    }
  }

  /// Get points scheme details
  Future<ApiResponse<List<Map<String, dynamic>>>> getPointsSchemeDetails(
      String schemeId) async {
    try {
      final payload = {
        'sqlKey': 'SP_GET_POINTS_SCHEME_DETAILS_BY_ID_FOR_ADMIN',
        'schemeId': schemeId,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error fetching points scheme details: ${e.toString()}');
    }
  }

  // ==================== UPDATE Operations ====================

  /// Update scheme master
  Future<ApiResponse<List<Map<String, dynamic>>>> updateSchemeMaster(
      String schemeId, Map<String, dynamic> updates) async {
    try {
      final payload = {
        'sqlKey': 'updateSchemeMaster',
        'schemeId': schemeId,
        ...updates,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error updating scheme: ${e.toString()}');
    }
  }

  /// Update scheme status
  Future<ApiResponse<List<Map<String, dynamic>>>> updateSchemeStatus(
      String schemeId, String status) async {
    try {
      final payload = {
        'sqlKey': 'updateSchemeStatus',
        'schemeId': schemeId,
        'status': status,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error updating scheme status: ${e.toString()}');
    }
  }

  /// Update basket target (using composite key: schemeId + productName)
  Future<ApiResponse<List<Map<String, dynamic>>>> updateBasketTarget(
      String schemeId, String productName, Map<String, dynamic> updates) async {
    try {
      final payload = {
        'sqlKey': 'updateBasketTarget',
        'schemeId': schemeId,
        'productName': productName,
        ...updates,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error updating basket target: ${e.toString()}');
    }
  }

  /// Update basket beneficiary
  Future<ApiResponse<List<Map<String, dynamic>>>> updateBasketBeneficiary(
      int id, Map<String, dynamic> updates) async {
    try {
      final payload = {
        'sqlKey': 'updateBasketBeneficiary',
        'id': id,
        ...updates,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error updating basket beneficiary: ${e.toString()}');
    }
  }

  /// Update scheme detail
  Future<ApiResponse<List<Map<String, dynamic>>>> updateSchemeDetail(
      int id, Map<String, dynamic> updates) async {
    try {
      final payload = {
        'sqlKey': 'updateSchemeDetail',
        'id': id,
        ...updates,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error updating scheme detail: ${e.toString()}');
    }
  }

  /// Update point calculation
  Future<ApiResponse<List<Map<String, dynamic>>>> updatePointCalculation(
      int id, Map<String, dynamic> updates) async {
    try {
      final payload = {
        'sqlKey': 'updatePointCalculation',
        'id': id,
        ...updates,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error updating point calculation: ${e.toString()}');
    }
  }

  /// Update point beneficiary
  Future<ApiResponse<List<Map<String, dynamic>>>> updatePointBeneficiary(
      int id, Map<String, dynamic> updates) async {
    try {
      final payload = {
        'sqlKey': 'updatePointBeneficiary',
        'id': id,
        ...updates,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error updating point beneficiary: ${e.toString()}');
    }
  }

  // ==================== DELETE Operations ====================

  /// Delete scheme (will cascade delete all related records)
  Future<ApiResponse<List<Map<String, dynamic>>>> deleteScheme(
      String schemeId) async {
    try {
      final payload = {
        'sqlKey': 'SP_DELETE_SCHEME_FOR_ADMIN',
        'schemeId': schemeId,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error deleting scheme: ${e.toString()}');
    }
  }

  /// Delete basket target (using composite key: schemeId + productName)
  Future<ApiResponse<List<Map<String, dynamic>>>> deleteBasketTarget(
      String schemeId, String productName) async {
    try {
      final payload = {
        'sqlKey': 'deleteBasketTarget',
        'schemeId': schemeId,
        'productName': productName,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error deleting basket target: ${e.toString()}');
    }
  }

  /// Delete basket beneficiary
  Future<ApiResponse<List<Map<String, dynamic>>>> deleteBasketBeneficiary(
      int id) async {
    try {
      final payload = {
        'sqlKey': 'deleteBasketBeneficiary',
        'id': id,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error deleting basket beneficiary: ${e.toString()}');
    }
  }

  /// Delete scheme detail
  Future<ApiResponse<List<Map<String, dynamic>>>> deleteSchemeDetail(
      int id) async {
    try {
      final payload = {
        'sqlKey': 'deleteSchemeDetail',
        'id': id,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error('Error deleting scheme detail: ${e.toString()}');
    }
  }

  /// Delete point calculation
  Future<ApiResponse<List<Map<String, dynamic>>>> deletePointCalculation(
      int id) async {
    try {
      final payload = {
        'sqlKey': 'deletePointCalculation',
        'id': id,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error deleting point calculation: ${e.toString()}');
    }
  }

  /// Delete point beneficiary
  Future<ApiResponse<List<Map<String, dynamic>>>> deletePointBeneficiary(
      int id) async {
    try {
      final payload = {
        'sqlKey': 'deletePointBeneficiary',
        'id': id,
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error deleting point beneficiary: ${e.toString()}');
    }
  }

  // ==================== UTILITY Operations ====================

  /// Load basket scheme data (calls stored procedure)
  Future<ApiResponse<List<Map<String, dynamic>>>> loadBasketSchemeData() async {
    try {
      final payload = {
        'sqlKey': 'loadBasketSchemeData',
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error loading basket scheme data: ${e.toString()}');
    }
  }

  /// Load points scheme data (calls stored procedure)
  Future<ApiResponse<List<Map<String, dynamic>>>> loadPointsSchemeData() async {
    try {
      final payload = {
        'sqlKey': 'loadPointsSchemeData',
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error loading points scheme data: ${e.toString()}');
    }
  }

  /// Load value scheme data (calls stored procedure)
  Future<ApiResponse<List<Map<String, dynamic>>>> loadValueSchemeData() async {
    try {
      final payload = {
        'sqlKey': 'loadValueSchemeData',
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error loading value scheme data: ${e.toString()}');
    }
  }

  /// Load quantity scheme data (calls stored procedure)
  Future<ApiResponse<List<Map<String, dynamic>>>> loadQuantitySchemeData() async {
    try {
      final payload = {
        'sqlKey': 'loadQuantitySchemeData',
      };

      return await _apiService.request(payload: payload, method: 'POST');
    } catch (e) {
      return ApiResponse.error(
          'Error loading quantity scheme data: ${e.toString()}');
    }
  }
}