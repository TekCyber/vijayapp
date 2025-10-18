// lib/screens/salesman/data_service.dart
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class DataService {
  final ApiService _apiService = ApiService();

  // Get current executive username
  Future<String?> _getExecutive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // Get material groups by brand
  Future<List<String>> getMaterialGroupsByBrand(String brand) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "GET_ALL_MATERIALGROUP_BY_BRAND",
        "brand": brand,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<String> materialGroups = List<Map<String, dynamic>>.from(response.data!)
            .map((item) => item['materialGroup']?.toString() ?? '')
            .where((group) => group.isNotEmpty)
            .toList();
        return materialGroups;
      }
      return [];
    } catch (e) {
      print('Error fetching material groups: $e');
      return [];
    }
  }

  // Get routes by executive
  Future<List<String>> getRoutesByExecutive() async {
    try {
      String? executive = await _getExecutive();
      if (executive == null) return [];

      Map<String, dynamic> payload = {
        "sqlKey": "ROUTE_LIST_BY_EXECUTIVE_NEW",
        "executive": executive,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<String> routes = List<Map<String, dynamic>>.from(response.data!)
            .map((item) => item['Route']?.toString() ?? '')
            .where((route) => route.isNotEmpty)
            .toList();
        return routes;
      }
      return [];
    } catch (e) {
      print('Error fetching routes: $e');
      return [];
    }
  }

  // Get dealers by executive
  Future<List<Map<String, String>>> getDealersByExecutive() async {
    try {
      String? executive = await _getExecutive();
      if (executive == null) return [];

      Map<String, dynamic> payload = {
        "sqlKey": "GET_ALL_DEALER_BY_EXECUTIVE",
        "executive": executive,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, String>> dealers = List<Map<String, dynamic>>.from(response.data!)
            .map((item) => {
          'name': item['DEALERNAME']?.toString() ?? '',
          'route': item['ROUTE']?.toString() ?? '',
        })
            .where((dealer) => dealer['name']!.isNotEmpty)
            .toList();
        return dealers;
      }
      return [];
    } catch (e) {
      print('Error fetching dealers: $e');
      return [];
    }
  }

  // Get filtered dealers data
  Future<List<Map<String, dynamic>>> getFilteredDealers({
    required String period,
    required String comparison,
    String? brand,
    String? materialGroup,
    String? route,
  }) async {
    try {
      String? executive = await _getExecutive();
      if (executive == null) return [];

      String sqlKey = "GET_ALL_DEALERS_FILTER_BY_${period}_$comparison";

      Map<String, dynamic> payload = {
        "sqlKey": sqlKey,
        "executive": executive,
        "brand": brand ?? "%",
        "material": materialGroup ?? "%",
        "route": route ?? "%",
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data!);
      }
      return [];
    } catch (e) {
      print('Error fetching filtered dealers: $e');
      return [];
    }
  }

  // Get filtered products data
  Future<List<Map<String, dynamic>>> getFilteredProducts({
    required String period,
    required String comparison,
    String? brand,
    String? dealer,
    String? route,
  }) async {
    try {
      String? executive = await _getExecutive();
      if (executive == null) return [];

      String sqlKey = "GET_ALL_PRODUCT_FILTER_BY_${period}_$comparison";

      Map<String, dynamic> payload = {
        "sqlKey": sqlKey,
        "executive": executive,
        "brand": brand ?? "%",
        "dealername": dealer ?? "%",
        "route": route ?? "%"
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data!);
      }
      return [];
    } catch (e) {
      print('Error fetching filtered products: $e');
      return [];
    }
  }

  // Get dealer count data
  Future<List<Map<String, dynamic>>> getDealerCount({
    required String period,
    String? brand,
    String? route,
  }) async {
    try {
      String? executive = await _getExecutive();
      if (executive == null) return [];

      String sqlKey = "GET_DEALER_COUNT_BY_${period}_MOM";

      Map<String, dynamic> payload = {
        "sqlKey": sqlKey,
        "executive": executive,
        "brand": brand ?? "%",
        "route": route ?? "%",
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data!);
      }
      return [];
    } catch (e) {
      print('Error fetching dealer count: $e');
      return [];
    }
  }

  // Get total dealer count data
  Future<List<Map<String, dynamic>>> getTotalDealerCount({
    required String period,
    String? brand,
    String? route,
  }) async {
    try {
      String? executive = await _getExecutive();
      if (executive == null) return [];

      String sqlKey = "GET_TOTAL_DEALER_COUNT_${period}_MOM";

      Map<String, dynamic> payload = {
        "sqlKey": sqlKey,
        "executive": executive,
        "brand": brand ?? "%",
        "route": route ?? "%",
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data!);
      }
      return [];
    } catch (e) {
      print('Error fetching dealer count: $e');
      return [];
    }
  }

  // Get cheque returns by executive
  Future<List<Map<String, dynamic>>> getChequeReturnsByExecutive(String executive) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "GET_ALL_CHEQUE_RETURN_BY_EXECUTIVE",
        "executive": executive,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data!);
      }
      return [];
    } catch (e) {
      print('Error fetching cheque returns: $e');
      return [];
    }
  }

  // Get cheque return summary by executive
  Future<Map<String, dynamic>> getChequeReturnSummaryByExecutive(String executive) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "GET_CHEQUE_RETURN_SUMMARY_BY_EXECUTIVE",
        "executive": executive,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        return Map<String, dynamic>.from(response.data!.first);
      }
      return {};
    } catch (e) {
      print('Error fetching cheque return summary: $e');
      return {};
    }
  }

  // UPDATED: Get schemes by executive and route with scheme name filter
  Future<List<Map<String, dynamic>>> getSchemesByExecutiveAndRoute({
    String? route,
    String? schemeName,
  }) async {
    try {
      String? executive = await _getExecutive();
      if (executive == null) return [];

      Map<String, dynamic> payload = {
        "sqlKey": "GET_SCHEME_DETAILS_BY_EXECUTIVE_AND_ROUTE",
        "executive": executive,
        "route": route ?? "%",
        "schemename": schemeName ?? "%",
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data!);
      }
      return [];
    } catch (e) {
      print('Error fetching schemes by executive and route: $e');
      return [];
    }
  }

  // Get historic schemes by dealer
  Future<List<Map<String, dynamic>>> getHistoricSchemesByDealer({
    required String dealerName,
  }) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "GET_ALL_SCHEME_HISTORIC_BY_DEALER",
        "dealername": dealerName,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data!);
      }
      return [];
    } catch (e) {
      print('Error fetching historic schemes by dealer: $e');
      return [];
    }
  }

  // Get dealers by executive and route
  Future<List<Map<String, String>>> getDealersByExecutiveAndRoute(String route) async {
    try {
      String? executive = await _getExecutive();
      if (executive == null) return [];

      Map<String, dynamic> payload = {
        "sqlKey": "GET_ALL_DEALERS_FOR_EXECUTIVE_ROUTE",
        "executive": executive,
        "route": route,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, String>> dealers = List<Map<String, dynamic>>.from(response.data!)
            .map((item) => {
          'name': item['DEALERNAME']?.toString() ?? '',
          'route': item['ROUTE']?.toString() ?? '',
        })
            .where((dealer) => dealer['name']!.isNotEmpty)
            .toList();
        return dealers;
      }
      return [];
    } catch (e) {
      print('Error fetching dealers by route: $e');
      return [];
    }
  }
}