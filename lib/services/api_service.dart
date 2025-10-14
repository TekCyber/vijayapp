// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://app.shrivijaypipecorporation.com/api/v2/data/get';
  static const Duration timeoutDuration = Duration(seconds: 60);

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Read savedDomain from SharedPreferences
  Future<Map<String, String>> _getHeaders(String tenantId) async {

    return {
      'X-Tenant-ID': tenantId, // use savedDomain here
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }



  /// Generic API method - accepts a full JSON map
  Future<ApiResponse<List<Map<String, dynamic>>>> request({
    required Map<String, dynamic> payload,
    String method = 'POST', // Default to POST
  }) async {
    try {
      // ✅ Extract sqlKey from payload
      if (!payload.containsKey('sqlKey')) {
        return ApiResponse.error('Missing sqlKey in payload');
      }
      final prefs = await SharedPreferences.getInstance();
      final tenantId = prefs.getString('savedDomain') ?? payload['tenantId'] ?? '';
      final sqlKey = payload['sqlKey'];
      final url = Uri.parse('$baseUrl/$sqlKey'); // ✅ baseUrl + sqlKey

      // ✅ Remove sqlKey from body so it's not duplicated
      final bodyMap = Map<String, dynamic>.from(payload)..remove('sqlKey');
      final body = jsonEncode(bodyMap);

      final headers = await _getHeaders(tenantId);

      print('🌐 $method Request to: $url');
      print('📤 Headers: $headers');
      print('📤 Body: $body');

      late http.Response response;

      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(url, headers: headers, body: body)
              .timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: body)
              .timeout(timeoutDuration);
          break;
        case 'GET':
          response = await http.get(url, headers: headers)
              .timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers, body: body)
              .timeout(timeoutDuration);
          break;
        default:
          return ApiResponse.error('Unsupported HTTP method: $method');
      }

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('No internet connection. Please check your network.');
    } on HttpException {
      return ApiResponse.error('Network error occurred. Please try again.');
    } on FormatException {
      return ApiResponse.error('Invalid response format from server.');
    } catch (e) {
      print('❌ API Error: $e');
      return ApiResponse.error('Unexpected error occurred: ${e.toString()}');
    }
  }


  // Handle API response
  ApiResponse<List<Map<String, dynamic>>> _handleResponse(http.Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);

        if (responseData is List) {
          final List<Map<String, dynamic>> data =
          responseData.map((e) => e as Map<String, dynamic>).toList();
          if (data.isNotEmpty && data[0].containsKey('error')) {
            return ApiResponse.error(data[0]['error'].toString());
          }
          return ApiResponse.success(data);
        } else if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('error')) {
            return ApiResponse.error(responseData['error'].toString());
          }
          return ApiResponse.success([responseData]);
        } else {
          return ApiResponse.error('Invalid response format from server');
        }
      } else {
        String errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> && errorData.containsKey('error')) {
            errorMessage = errorData['error'].toString();
          }
        } catch (_) {}
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse server response: ${e.toString()}');
    }
  }
}

// Generic API Response wrapper
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final String? message;

  const ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    this.message,
  });

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse._(isSuccess: true, data: data, message: message);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(isSuccess: false, error: error);
  }

  @override
  String toString() {
    if (isSuccess) return 'ApiResponse.success(data: $data, message: $message)';
    return 'ApiResponse.error(error: $error)';
  }
}
