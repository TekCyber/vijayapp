// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glass_container.dart';
import '../widgets/theme_selector.dart';
import '../services/api_service.dart';
import 'dealer/dealer_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _selectedCompany;

  // Company options
  final Map<String, String> _companies = {
    'Shri Vijay Pipes Corporation': 'svpc',
    'Test': 'tenantB',
  };

  // SharedPreferences keys
  static const String _keyRememberMe = 'remember_me';
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';
  static const String _keyCompany = 'saved_company';
  static const String _keyUsername = 'username';
  static const String _keyName = 'name';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();

    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool rememberMe = prefs.getBool(_keyRememberMe) ?? false;

      if (rememberMe) {
        String? savedEmail = prefs.getString(_keyEmail);
        String? savedPassword = prefs.getString(_keyPassword);
        String? savedCompany = prefs.getString(_keyCompany);

        setState(() {
          _rememberMe = rememberMe;
          if (savedEmail != null) _emailController.text = savedEmail;
          if (savedPassword != null) _passwordController.text = savedPassword;
          if (savedCompany != null) _selectedCompany = savedCompany;
        });
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        await prefs.setBool(_keyRememberMe, true);
        await prefs.setString(_keyEmail, _emailController.text);
        await prefs.setString(_keyPassword, _passwordController.text);
        if (_selectedCompany != null) {
          await prefs.setString(_keyCompany, _selectedCompany!);
        }
      } else {
        await prefs.setBool(_keyRememberMe, false);
        await prefs.remove(_keyEmail);
        await prefs.remove(_keyPassword);
        await prefs.remove(_keyCompany);
      }
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  Future<void> _clearSavedCredentials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyPassword);
      await prefs.remove(_keyCompany);
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      if (_selectedCompany == null) {
        setState(() => _isLoading = false);
        _showSnackBar('Please select a company', Colors.red);
        return;
      }

      if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
        setState(() => _isLoading = false);
        _showSnackBar('Please enter both email and password', Colors.red);
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String tenantId = _companies[_selectedCompany] ?? '';
      await prefs.setString('savedDomain', tenantId);

      Map<String, dynamic> loginPayload = {
        "sqlKey": "LOGIN_BY_USER",
        "username": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: loginPayload);

      // Check if response is successful AND has non-empty data
      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        final userData = response.data!.first;

        SharedPreferences prefs = await SharedPreferences.getInstance();

        if (userData.containsKey('username')) {
          await prefs.setString(_keyUsername, userData['username'].toString());
        }
        if (userData.containsKey('full_name')) {
          await prefs.setString(_keyName, userData['full_name'].toString());
        }

        await _saveCredentials();
        _showSnackBar('Login successful!', Colors.green);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => DealerDashboardScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: Duration(milliseconds: 800),
            ),
          );
        }
      } else {
        // Treat empty data or unsuccessful response as login failure
        setState(() => _isLoading = false);

        // Show appropriate error message
        String errorMessage = 'Invalid username or password';

        // If there's a specific error from the API, use that instead
        if (response.error != null && response.error!.isNotEmpty) {
          errorMessage = response.error!;
        }
        // If response was successful but data is empty/null
        else if (response.isSuccess && (response.data == null || response.data!.isEmpty)) {
          errorMessage = 'Invalid username or password';
        }

        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Network error. Please check your connection.', Colors.red);
      print('Login error: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _handleForgotPassword() {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter your username/email first', Colors.orange);
      return;
    }

    if (_selectedCompany == null) {
      _showSnackBar('Please select a company first', Colors.orange);
      return;
    }

    _fetchSecurityQuestions();
  }

  Future<void> _fetchSecurityQuestions() async {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      ),
    );

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String tenantId = _companies[_selectedCompany] ?? '';
      await prefs.setString('savedDomain', tenantId);

      Map<String, dynamic> payload = {
        "sqlKey": "GET_USER_SECURITY_QUESTIONS",
        "username": _emailController.text.trim(),
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (mounted) Navigator.of(context).pop();

      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        _showSecurityQuestionsDialog(response.data!);
      } else {
        _showSnackBar(
          response.error ?? 'Unable to retrieve security questions. Please contact support.',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showSnackBar('Network error. Please check your connection.', Colors.red);
      print('Error fetching security questions: $e');
    }
  }

  void _showSecurityQuestionsDialog(List<dynamic> questions) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black54;

    List<TextEditingController> answerControllers =
    List.generate(questions.length, (index) => TextEditingController());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                child: Container(
                  padding: EdgeInsets.all(24),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Security Questions',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: hintColor),
                            onPressed: () {
                              for (var controller in answerControllers) {
                                controller.dispose();
                              }
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Answer the following security questions to reset your password',
                        style: TextStyle(
                          fontSize: 14,
                          color: hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: List.generate(questions.length, (index) {
                              final question = questions[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Question ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.primaryColor,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      question['question'] ?? '',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    TextField(
                                      controller: answerControllers[index],
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        hintText: 'Your answer',
                                        hintStyle: TextStyle(color: hintColor),
                                        prefixIcon: Icon(
                                          Icons.question_answer,
                                          color: theme.primaryColor,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.3)
                                                : Colors.black.withOpacity(0.3),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.3)
                                                : Colors.black.withOpacity(0.3),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            bool allAnswered = answerControllers.every(
                                  (controller) => controller.text.trim().isNotEmpty,
                            );

                            if (!allAnswered) {
                              _showSnackBar(
                                'Please answer all security questions',
                                Colors.orange,
                              );
                              return;
                            }

                            await _verifySecurityAnswers(
                              questions,
                              answerControllers,
                              context,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Verify & Reset Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _verifySecurityAnswers(
      List<dynamic> questions,
      List<TextEditingController> answerControllers,
      BuildContext dialogContext,
      ) async {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      ),
    );

    try {
      Map<String, dynamic> payload = {
        "sqlKey": "VERIFY_THREE_SECURITY_ANSWERS",
        "username": _emailController.text.trim(),
      };

      // Add questions and answers dynamically
      for (int i = 0; i < questions.length && i < 3; i++) {
        payload["question${i + 1}"] = questions[i]['question'] ?? '';
        payload["answer${i + 1}"] = answerControllers[i].text.trim();
      }

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (mounted) Navigator.of(context).pop();

      if (response.isSuccess &&
          response.data != null &&
          response.data!.isNotEmpty) {
        final responseData = response.data!.first;

        if (responseData['status'] == 'VERIFIED') {
          if (mounted) Navigator.of(dialogContext).pop();

          for (var controller in answerControllers) {
            controller.dispose();
          }

          _showResetPasswordDialog();
        } else {
          _showSnackBar(
            'Incorrect answers. Please try again with new questions.',
            Colors.red,
          );

          if (mounted) Navigator.of(dialogContext).pop();

          for (var controller in answerControllers) {
            controller.dispose();
          }

          await Future.delayed(Duration(milliseconds: 500));
          _fetchSecurityQuestions();
        }
      } else {
        _showSnackBar(
          'Verification failed. Please try again.',
          Colors.red,
        );

        if (mounted) Navigator.of(dialogContext).pop();

        for (var controller in answerControllers) {
          controller.dispose();
        }

        await Future.delayed(Duration(milliseconds: 500));
        _fetchSecurityQuestions();
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showSnackBar('Network error. Please check your connection.', Colors.red);
      print('Error verifying security answers: $e');
    }
  }

  void _showResetPasswordDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black54;

    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                child: Container(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: hintColor),
                            onPressed: () {
                              newPasswordController.dispose();
                              confirmPasswordController.dispose();
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enter your new password',
                        style: TextStyle(
                          fontSize: 14,
                          color: hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      TextField(
                        controller: newPasswordController,
                        obscureText: obscureNewPassword,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'New Password',
                          hintStyle: TextStyle(color: hintColor),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: theme.primaryColor,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: hintColor,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureNewPassword = !obscureNewPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          hintStyle: TextStyle(color: hintColor),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: theme.primaryColor,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: hintColor,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirmPassword = !obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (newPasswordController.text.trim().isEmpty ||
                                confirmPasswordController.text.trim().isEmpty) {
                              _showSnackBar(
                                'Please fill in both password fields',
                                Colors.orange,
                              );
                              return;
                            }

                            if (newPasswordController.text !=
                                confirmPasswordController.text) {
                              _showSnackBar(
                                'Passwords do not match',
                                Colors.red,
                              );
                              return;
                            }

                            if (newPasswordController.text.length < 6) {
                              _showSnackBar(
                                'Password must be at least 6 characters',
                                Colors.orange,
                              );
                              return;
                            }

                            await _submitNewPassword(
                              newPasswordController,
                              confirmPasswordController,
                              dialogContext,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitNewPassword(
      TextEditingController newPasswordController,
      TextEditingController confirmPasswordController,
      BuildContext dialogContext,
      ) async {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      ),
    );

    try {
      Map<String, dynamic> payload = {
        "sqlKey": "UPDATE_USER_PASSWORD",
        "username": _emailController.text.trim(),
        "newPassword": newPasswordController.text.trim(),
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (mounted) Navigator.of(context).pop(); // Close loading dialog

      if (response.isSuccess &&
          response.data != null &&
          response.data!.isNotEmpty) {

        final responseData = response.data!.first;

        if (responseData['status'] == 'SUCCESS') {
          // Dispose controllers first
          newPasswordController.dispose();
          confirmPasswordController.dispose();

          // Close Reset Password dialog
          if (mounted) {
            Navigator.of(dialogContext).pop();
          }

          // Wait a moment for dialog to close
          await Future.delayed(Duration(milliseconds: 300));

          // Clear the password field and update UI
          if (mounted) {
            setState(() {
              _passwordController.clear();
              if (_rememberMe) {
                _rememberMe = false;
              }
            });

            // Clear saved credentials
            await _clearSavedCredentials();

            // Show success message
            _showSnackBar(
              'Password reset successfully! Please login with your new password.',
              Colors.green,
            );
          }
        } else {
          _showSnackBar(
            'Failed to reset password. Please try again.',
            Colors.red,
          );
        }
      } else {
        _showSnackBar(
          response.error ?? 'Failed to reset password. Please try again.',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showSnackBar('Network error. Please check your connection.', Colors.red);
      print('Error resetting password: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      SizedBox(height: 80),
                      _buildLogo(),
                      SizedBox(height: 60),
                      _buildLoginForm(),
                      SizedBox(height: 40),
                      _buildLoginButton(),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const FloatingThemeButton(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/vijaipipes_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.analytics,
                    size: 60,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor,
              theme.primaryColor.withOpacity(0.8),
            ],
          ).createShader(bounds),
          child: Text(
            'Vijay Groups',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Advanced Analytics Platform',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white60 : Colors.black54,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black54;

    return GlassContainer(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sign in to continue to your dashboard',
              style: TextStyle(
                fontSize: 16,
                color: hintColor,
              ),
            ),
            SizedBox(height: 32),
            _buildCompanyDropdown(),
            SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              hintText: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            _buildTextField(
              controller: _passwordController,
              hintText: 'Password',
              icon: Icons.lock_outlined,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: hintColor,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            SizedBox(height: 16),
            _buildRememberMeAndForgotPassword(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02)
          ]
              : [
            Colors.black.withOpacity(0.03),
            Colors.black.withOpacity(0.01)
          ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCompany,
        hint: Text(
          'Select Company',
          style: TextStyle(color: hintColor),
        ),
        icon: Icon(Icons.arrow_drop_down, color: hintColor),
        dropdownColor: isDark ? Color(0xFF2A2D3A) : Colors.white,
        style: TextStyle(color: textColor, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.business, color: theme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        items: _companies.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.key,
              style: TextStyle(color: textColor),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedCompany = newValue;
          });
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor =
    isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (bool? value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                  HapticFeedback.lightImpact();
                },
                activeColor: theme.primaryColor,
                checkColor: Colors.white,
                side: BorderSide(
                  color: borderColor,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
                HapticFeedback.lightImpact();
              },
              child: Text(
                'Remember Me',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _handleForgotPassword,
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02)
          ]
              : [
            Colors.black.withOpacity(0.03),
            Colors.black.withOpacity(0.01)
          ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(color: textColor, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor),
          prefixIcon: Icon(icon, color: theme.primaryColor),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text(
          'SIGN IN',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}