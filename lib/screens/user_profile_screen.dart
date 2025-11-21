// lib/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/dashboard_layout.dart';
import '../theme/theme_helpers.dart';
import '../widgets/glass_container.dart';
import '../services/user_profile_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // User data
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _securityQuestions = [];
  bool _isLoading = true;
  bool _isEditing = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Password visibility
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _loadUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username == null) {
        _showError('User not logged in');
        return;
      }

      final userProfileService = UserProfileService();
      final response = await userProfileService.getUserProfile(username);

      if (response.isSuccess && response.data != null) {
        setState(() {
          _userData = response.data!['user'];
          _securityQuestions = List<Map<String, dynamic>>.from(
              response.data!['security_questions'] ?? []);

          // Populate controllers
          _fullNameController.text = _userData?['full_name'] ?? '';
          _emailController.text = _userData?['email'] ?? '';
          _mobileController.text = _userData?['mobile'] ?? '';
        });

        _animationController.forward();
      } else {
        _showError(response.error ?? 'Failed to load profile');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username == null) {
        _showError('User not logged in');
        return;
      }

      final userProfileService = UserProfileService();
      final response = await userProfileService.updateUserProfile(
        username: username,
        fullName: _fullNameController.text,
        email: _emailController.text,
        mobile: _mobileController.text,
      );

      if (response.isSuccess) {
        // Update local storage
        await prefs.setString('name', _fullNameController.text);

        _showSuccess('Profile updated successfully');
        setState(() => _isEditing = false);
        await _loadUserProfile();
      } else {
        _showError(response.error ?? 'Failed to update profile');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username == null) {
        _showError('User not logged in');
        return;
      }

      final userProfileService = UserProfileService();
      final response = await userProfileService.changePassword(
        username: username,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (response.isSuccess) {
        _showSuccess('Password changed successfully');
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Navigator.pop(context);
      } else {
        _showError(response.error ?? 'Failed to change password');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: "Profile",
      subtitle: "Manage your account",
      initialIndex: 3,
      showBackButton: true,
      body: _isLoading ? _buildLoadingState() : _buildProfileContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ThemeHelper.loadingColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: ThemeHelper.bodyStyle(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildProfileInfoCard(),
              const SizedBox(height: 16),
              _buildSecuritySection(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userData?['full_name'] ?? 'User',
              style: ThemeHelper.headerStyle(context),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: ThemeHelper.badgeDecoration(
                Theme.of(context).primaryColor,
              ),
              child: Text(
                _userData?['type_name'] ?? 'User',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(_userData?['status'] ?? 'ACTIVE'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'ACTIVE';
    final color = isActive ? ThemeHelper.successColor : ThemeHelper.errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: ThemeHelper.smallBadgeDecoration(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard() {
    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Personal Information',
                    style: ThemeHelper.titleStyle(context),
                  ),
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      color: ThemeHelper.iconColor(context),
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                        if (!_isEditing) {
                          // Reset form
                          _fullNameController.text =
                              _userData?['full_name'] ?? '';
                          _emailController.text = _userData?['email'] ?? '';
                          _mobileController.text = _userData?['mobile'] ?? '';
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoField(
                icon: Icons.person_outline,
                label: 'Username',
                value: _userData?['username'] ?? '',
                enabled: false,
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                icon: Icons.badge_outlined,
                label: 'Full Name',
                controller: _fullNameController,
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                icon: Icons.email_outlined,
                label: 'Email',
                controller: _emailController,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                icon: Icons.phone_outlined,
                label: 'Mobile',
                controller: _mobileController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              if (_isEditing) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required String value,
    bool enabled = true,
  }) {
    return Container(
      decoration: ThemeHelper.inputDecoration(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: ThemeHelper.iconColor(context), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: ThemeHelper.subtleTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: ThemeHelper.bodyStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: ThemeHelper.inputDecoration(context),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        style: ThemeHelper.bodyStyle(context),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: ThemeHelper.hintTextColor(context),
          ),
          prefixIcon: Icon(
            icon,
            color: ThemeHelper.iconColor(context),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return GlassContainer(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security',
              style: ThemeHelper.titleStyle(context),
            ),
            const SizedBox(height: 16),
            _buildSecurityOption(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: _showChangePasswordDialog,
            ),
            const SizedBox(height: 12),
            _buildSecurityOption(
              icon: Icons.help_outline,
              title: 'Security Questions',
              subtitle: '${_securityQuestions.length} questions set',
              onTap: _showSecurityQuestionsDialog,
            ),
            const SizedBox(height: 12),
            _buildSecurityOption(
              icon: Icons.history,
              title: 'Login History',
              subtitle: 'View your login activity',
              onTap: () {
                // TODO: Implement login history
                _showError('Feature coming soon');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ThemeHelper.glassBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ThemeHelper.borderColor(context),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ThemeHelper.bodyStyle(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: ThemeHelper.captionStyle(context),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ThemeHelper.iconColor(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await _loadUserProfile();
              _showSuccess('Profile refreshed');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              side: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeHelper.cardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Change Password',
          style: ThemeHelper.titleStyle(context),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Current Password',
                showPassword: _showCurrentPassword,
                onToggle: () => setState(() {
                  _showCurrentPassword = !_showCurrentPassword;
                }),
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'New Password',
                showPassword: _showNewPassword,
                onToggle: () => setState(() {
                  _showNewPassword = !_showNewPassword;
                }),
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                showPassword: _showConfirmPassword,
                onToggle: () => setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'Password must be at least 8 characters',
                style: ThemeHelper.captionStyle(context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: ThemeHelper.textColor(context)),
            ),
          ),
          ElevatedButton(
            onPressed: _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: ThemeHelper.inputDecoration(context),
      child: TextField(
        controller: controller,
        obscureText: !showPassword,
        style: ThemeHelper.bodyStyle(context),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: ThemeHelper.hintTextColor(context),
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: ThemeHelper.iconColor(context),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              showPassword ? Icons.visibility : Icons.visibility_off,
              color: ThemeHelper.iconColor(context),
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  void _showSecurityQuestionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeHelper.cardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Security Questions',
          style: ThemeHelper.titleStyle(context),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_securityQuestions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No security questions set',
                      style: ThemeHelper.bodyStyle(context),
                    ),
                  ),
                )
              else
                ..._securityQuestions.asMap().entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeHelper.glassBackground(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ThemeHelper.borderColor(context),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Question ${entry.key + 1}',
                                style: ThemeHelper.bodyStyle(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.value['question'] ?? '',
                          style: ThemeHelper.captionStyle(context),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          if (_securityQuestions.length < 3)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to add security question screen
                _showError('Feature coming soon');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Question'),
            ),
        ],
      ),
    );
  }
}