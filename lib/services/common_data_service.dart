// lib/services/common_data_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class CommonDataService {
  final ApiService _apiService = ApiService();

  // Get current executive username
  Future<String?> _getExecutive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // Get all brands by executive
  Future<List<String>> getBrandsByExecutive() async {
    try {
      String? executive = await _getExecutive();
      if (executive == null) return [];

      Map<String, dynamic> payload = {
        "sqlKey": "GET_ALL_BRANDS_BY_EXC",
        "executive": executive,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<String> brands = List<Map<String, dynamic>>.from(response.data!)
            .map((item) => item['Brand']?.toString() ?? '')
            .where((brand) => brand.isNotEmpty)
            .toList();
        return brands;
      }
      return [];
    } catch (e) {
      print('Error fetching brands: $e');
      return [];
    }
  }

  // Get brand icon by brand name
  Future<String?> getBrandIconByBrandName(String brandName) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "GET_BRAND_ICON_BY_BRAND_NAME",
        "brand": brandName,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        // Assuming the response returns a list with one item containing the icon
        List<dynamic> dataList = response.data as List<dynamic>;
        if (dataList.isNotEmpty) {
          var firstItem = dataList[0] as Map<String, dynamic>;
          // Try different possible key names for the icon field
          String? icon = firstItem['icon']?.toString() ??
              firstItem['Icon']?.toString() ??
              firstItem['brand_icon']?.toString() ??
              firstItem['brandIcon']?.toString() ??
              firstItem['base64Icon']?.toString();
          return icon;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching brand icon for $brandName: $e');
      return null;
    }
  }
}