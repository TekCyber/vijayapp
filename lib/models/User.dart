// lib/models/user.dart
class User {
  final String userId;
  final String username;
  final String email;
  final String mobile;
  final String fullName;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.mobile,
    required this.fullName,
  });

  // Factory constructor to create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'mobile': mobile,
      'full_name': fullName,
    };
  }

  // Create a copy of User with updated fields
  User copyWith({
    String? userId,
    String? username,
    String? email,
    String? mobile,
    String? fullName,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      fullName: fullName ?? this.fullName,
    );
  }

  @override
  String toString() {
    return 'User(userId: $userId, username: $username, email: $email, mobile: $mobile, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.userId == userId &&
        other.username == username &&
        other.email == email &&
        other.mobile == mobile &&
        other.fullName == fullName;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
    username.hashCode ^
    email.hashCode ^
    mobile.hashCode ^
    fullName.hashCode;
  }
}