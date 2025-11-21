// lib/services/user_profile_service.dart
import 'api_service.dart';

class UserProfileService {
  final ApiService _apiService = ApiService();

  /// Get user profile by username
  Future<ApiResponse<Map<String, dynamic>>> getUserProfile(String username) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "GET_USER_PROFILE",
        "username": username,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        // Parse the response data
        final List<Map<String, dynamic>> dataList = response.data!;

        if (dataList.isEmpty) {
          return ApiResponse.error('User not found');
        }

        // Get user data from first item
        Map<String, dynamic> userData = dataList[0];

        // Get security questions if available
        List<Map<String, dynamic>> securityQuestions = await _getSecurityQuestions(username);

        // Combine user data and security questions
        Map<String, dynamic> result = {
          'user': userData,
          'security_questions': securityQuestions,
        };

        return ApiResponse.success(result);
      } else {
        return ApiResponse.error(response.error ?? 'Failed to fetch user profile');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  /// Get security questions for a user
  Future<List<Map<String, dynamic>>> _getSecurityQuestions(String username) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "GET_SECURITY_QUESTIONS",
        "username": username,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        return response.data!;
      }
      return [];
    } catch (e) {
      print('Error fetching security questions: $e');
      return [];
    }
  }

  /// Update user profile
  Future<ApiResponse<String>> updateUserProfile({
    required String username,
    required String fullName,
    required String email,
    String? mobile,
  }) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "UPDATE_USER_PROFILE",
        "username": username,
        "full_name": fullName,
        "email": email,
        "mobile": mobile ?? '',
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess) {
        return ApiResponse.success('Profile updated successfully');
      } else {
        return ApiResponse.error(response.error ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Error updating user profile: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  /// Change user password
  Future<ApiResponse<String>> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "CHANGE_USER_PASSWORD",
        "username": username,
        "current_password": currentPassword,
        "new_password": newPassword,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        // Check if the response indicates success
        final dataList = response.data!;
        if (dataList.isNotEmpty) {
          final result = dataList[0];

          // Check for success indicator
          if (result.containsKey('success') && result['success'] == true) {
            return ApiResponse.success('Password changed successfully');
          } else if (result.containsKey('error')) {
            return ApiResponse.error(result['error'].toString());
          } else if (result.containsKey('message')) {
            // Check if message indicates success or error
            final message = result['message'].toString();
            if (message.toLowerCase().contains('success')) {
              return ApiResponse.success(message);
            } else {
              return ApiResponse.error(message);
            }
          }
        }
        return ApiResponse.success('Password changed successfully');
      } else {
        return ApiResponse.error(response.error ?? 'Failed to change password');
      }
    } catch (e) {
      print('Error changing password: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  /// Add security question
  Future<ApiResponse<String>> addSecurityQuestion({
    required String username,
    required String question,
    required String answer,
  }) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "ADD_SECURITY_QUESTION",
        "username": username,
        "question": question,
        "answer": answer,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess) {
        return ApiResponse.success('Security question added successfully');
      } else {
        return ApiResponse.error(response.error ?? 'Failed to add security question');
      }
    } catch (e) {
      print('Error adding security question: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  /// Update security question
  Future<ApiResponse<String>> updateSecurityQuestion({
    required int questionId,
    required String question,
    required String answer,
  }) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "UPDATE_SECURITY_QUESTION",
        "question_id": questionId,
        "question": question,
        "answer": answer,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess) {
        return ApiResponse.success('Security question updated successfully');
      } else {
        return ApiResponse.error(response.error ?? 'Failed to update security question');
      }
    } catch (e) {
      print('Error updating security question: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  /// Delete security question
  Future<ApiResponse<String>> deleteSecurityQuestion(int questionId) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "DELETE_SECURITY_QUESTION",
        "question_id": questionId,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess) {
        return ApiResponse.success('Security question deleted successfully');
      } else {
        return ApiResponse.error(response.error ?? 'Failed to delete security question');
      }
    } catch (e) {
      print('Error deleting security question: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  /// Get login history (placeholder for future implementation)
  Future<ApiResponse<List<Map<String, dynamic>>>> getLoginHistory(String username) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "GET_LOGIN_HISTORY",
        "username": username,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        return ApiResponse.success(response.data!);
      } else {
        return ApiResponse.error(response.error ?? 'Failed to fetch login history');
      }
    } catch (e) {
      print('Error fetching login history: $e');
      return ApiResponse.error('Error: $e');
    }
  }

  /// Validate current password (helper method)
  Future<bool> validateCurrentPassword({
    required String username,
    required String password,
  }) async {
    try {
      Map<String, dynamic> payload = {
        "sqlKey": "VALIDATE_PASSWORD",
        "username": username,
        "password": password,
      };

      final response = await _apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        final dataList = response.data!;
        if (dataList.isNotEmpty) {
          final result = dataList[0];
          return result['valid'] == true || result['is_valid'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error validating password: $e');
      return false;
    }
  }
}