// lib/services/data_services.dart
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';


class DataService {
  final ApiService _apiService = ApiService();

  /// Fetches sales comparison data based on the provided parameters
  ///
  /// Parameters:
  /// - [dealername]: The dealer name
  /// - [brand]: The brand name
  /// - [period]: Selected period (This Month, Last Month, Last Year, YTD)
  /// - [category]: Selected category (Sub Group 2, Grade, Material Group)
  /// - [fromDate]: Start date for YTD date range (optional)
  /// - [toDate]: End date for YTD date range (optional)
  /// - [amount]: Amount value (optional)
  ///
  /// Returns a Map containing:
  /// - success: bool
  /// - data: List<Map<String, dynamic>> or null
  /// - error: String or null
  Future<Map<String, dynamic>> fetchSalesComparisonData({
    required String dealername,
    required String brand,
    required String period,
    required String category,
    DateTime? fromDate,
    DateTime? toDate,
    double? amount,
  }) async {
    try {
      // Get username from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');
      String? salesMan = prefs.getString('salesMan');

      if (username == null || username.isEmpty) {
        return {
          'success': false,
          'data': null,
          'error': 'Username not found in SharedPreferences',
        };
      }

      // Generate combination key and SQL key
      String combinationKey = _generateCombinationKey(period, category);
      String sqlKey = _generateSqlKey(period, category);

      // Build the payload
      Map<String, dynamic> payload = {
        "sqlKey": sqlKey,
        "executive": salesMan != "null" ? salesMan : username,
        "dealername": dealername,
        "period": period,
        "brand": brand,
        "category": category,
        "combination": combinationKey,
      };

      // Add custom date range if YTD and dates are provided
      if (period == 'YTD' && fromDate != null && toDate != null) {
        payload["fromDate"] = "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}";
        payload["toDate"] = "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}";
      }

      // Add amount if provided
      if (amount != null) {
        payload["amount"] = amount;
      }

      print('DataServices - API Payload: $payload');

      // Make the API request
      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData = List<Map<String, dynamic>>.from(response.data!);

        return {
          'success': true,
          'data': fetchedData,
          'error': null,
        };
      } else {
        return {
          'success': false,
          'data': null,
          'error': response.error ?? 'Failed to fetch sales data',
        };
      }
    } catch (e) {
      print('DataServices - Error fetching sales data: $e');
      return {
        'success': false,
        'data': null,
        'error': 'Error loading sales data: ${e.toString()}',
      };
    }
  }

  /// Generates a combination key based on period and category
  String _generateCombinationKey(String period, String category) {
    String combination = '';
    String categoryFormatted = category.replaceAll(' ', '_');

    switch (period) {
      case 'This Month':
        combination = 'This_Month_$categoryFormatted';
        break;

      case 'Last Month':
        combination = 'Last_Month_$categoryFormatted';
        break;

      case 'Last Year':
        combination = 'Last_Year_$categoryFormatted';
        break;

      case 'YTD':
        combination = 'YTD_$categoryFormatted';
        break;

      default:
        combination = 'This_Month_$categoryFormatted';
        break;
    }

    return combination;
  }

  /// Generates SQL key based on period and category
  String _generateSqlKey(String period, String category) {
    String sqlKey = '';

    switch (period) {
      case 'This Month':
        switch (category) {
          case 'Sub Group':
            sqlKey = 'GET_SALES_THIS_MONTH_SUBGROUP2';
            break;
          case 'Grade':
            sqlKey = 'GET_SALES_THIS_MONTH_GRADE';
            break;
          case 'Material Group':
            sqlKey = 'GET_SALES_THIS_MONTH_MATERIAL_GROUP';
            break;
          default:
            sqlKey = 'GET_SALES_THIS_MONTH_SUBGROUP2';
            break;
        }
        break;

      case 'Last Month':
        switch (category) {
          case 'Sub Group':
            sqlKey = 'GET_SALES_LAST_MONTH_SUBGROUP2';
            break;
          case 'Grade':
            sqlKey = 'GET_SALES_LAST_MONTH_GRADE';
            break;
          case 'Material Group':
            sqlKey = 'GET_SALES_LAST_MONTH_MATERIAL_GROUP';
            break;
          default:
            sqlKey = 'GET_SALES_LAST_MONTH_SUBGROUP2';
            break;
        }
        break;

      case 'Last Year':
        switch (category) {
          case 'Sub Group':
            sqlKey = 'GET_SALES_LAST_YEAR_SUBGROUP2';
            break;
          case 'Grade':
            sqlKey = 'GET_SALES_LAST_YEAR_GRADE';
            break;
          case 'Material Group':
            sqlKey = 'GET_SALES_LAST_YEAR_MATERIAL_GROUP';
            break;
          default:
            sqlKey = 'GET_SALES_LAST_YEAR_SUBGROUP2';
            break;
        }
        break;

      case 'YTD':
        switch (category) {
          case 'Sub Group':
            sqlKey = 'GET_SALES_YTD_SUBGROUP2';
            break;
          case 'Grade':
            sqlKey = 'GET_SALES_YTD_GRADE';
            break;
          case 'Material Group':
            sqlKey = 'GET_SALES_YTD_MATERIAL_GROUP';
            break;
          default:
            sqlKey = 'GET_SALES_YTD_SUBGROUP2';
            break;
        }
        break;

      default:
        switch (category) {
          case 'Sub Group':
            sqlKey = 'GET_SALES_THIS_MONTH_SUBGROUP2';
            break;
          case 'Grade':
            sqlKey = 'GET_SALES_THIS_MONTH_GRADE';
            break;
          case 'Material Group':
            sqlKey = 'GET_SALES_THIS_MONTH_MATERIAL_GROUP';
            break;
          default:
            sqlKey = 'GET_THIS_MONTH_SUBGROUP2';
            break;
        }
        break;
    }

    return sqlKey;
  }
}