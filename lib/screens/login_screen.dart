// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glass_container.dart';
import '../widgets/theme_selector.dart';
import '../services/api_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'executive/dealer_dashboard_screen.dart';
import 'dealer/dealer_dashboard_screen.dart' as dealer_screen;

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
    'Shri Vijay Pipe Corporation': 'svpc',
    'Test': 'tenantB',
  };

  // SharedPreferences keys
  static const String _keyRememberMe = 'remember_me';
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';
  static const String _keyCompany = 'saved_company';
  static const String _keyUsername = 'username';
  static const String _keyName = 'name';
  static const String _keyTypeName = 'typeName';
  static const String _keySalesman = 'salesMan';

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
        await prefs.remove(_keyTypeName);
        await prefs.remove(_keySalesman);
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
      await prefs.remove(_keyTypeName);
      await prefs.remove(_keySalesman);
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
        if (userData.containsKey('type_name')) {
          await prefs.setString(_keyTypeName, userData['type_name'].toString());
        }
        if (userData.containsKey('salesman')) {
          await prefs.setString(_keySalesman, userData['salesman'].toString());
        }

        // Check for security questions requirement
        int seqQCount = 0;
        if (userData.containsKey('seqQCount')) {
          seqQCount = int.tryParse(userData['seqQCount'].toString()) ?? 0;
        }

        setState(() => _isLoading = false);

        // If seqQCount is 0, show security questions dialog
        if (seqQCount == 0) {
          await _showSecurityQuestionsDialog(userData['username'].toString(), userData);
        } else {
          // Proceed with normal login
          await _saveCredentials();
          _showSnackBar('Login successful!', Colors.green);
          _navigateToDashboard(userData);
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

  Future<void> _showSecurityQuestionsDialog(String username, Map<String, dynamic> userData) async {
    final List<String> questions = [
      'What is your mothers maiden name?',
      'What was the name of your first pet?',
      'What city were you born in?',
      'What is your favorite book?',
      'What was your first car model?',
    ];

    final List<TextEditingController> answerControllers = List.generate(
      questions.length,
          (index) => TextEditingController(),
    );

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: Theme.of(context).primaryColor,
                                size: 32,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Security Questions',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please answer these security questions to secure your account',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 24),
                          ...List.generate(questions.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${index + 1}. ${questions[index]}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextFormField(
                                    controller: answerControllers[index],
                                    decoration: InputDecoration(
                                      hintText: 'Enter your answer',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please provide an answer';
                                      }
                                      if (value.trim().length < 2) {
                                        return 'Answer must be at least 2 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                          SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  // Clear controllers
                                  for (var controller in answerControllers) {
                                    controller.dispose();
                                  }
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    await _saveSecurityQuestions(
                                      username,
                                      questions,
                                      answerControllers,
                                      userData,
                                    );
                                    // Clear controllers
                                    for (var controller in answerControllers) {
                                      controller.dispose();
                                    }
                                    Navigator.of(context).pop();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Submit',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _saveSecurityQuestions(
      String username,
      List<String> questions,
      List<TextEditingController> answerControllers,
      Map<String, dynamic> userData,
      ) async {
    try {
      setState(() => _isLoading = true);

      // Prepare the payload for saving security questions
      Map<String, dynamic> securityQuestionsPayload = {
        "sqlKey": "SAVE_SECURITY_QUESTIONS_BY_USERNAME",
        "username": username,
        "question1": questions[0],
        "answer1": answerControllers[0].text.trim(),
        "question2": questions[1],
        "answer2": answerControllers[1].text.trim(),
        "question3": questions[2],
        "answer3": answerControllers[2].text.trim(),
        "question4": questions[3],
        "answer4": answerControllers[3].text.trim(),
        "question5": questions[4],
        "answer5": answerControllers[4].text.trim(),
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: securityQuestionsPayload);

      setState(() => _isLoading = false);

      if (response.isSuccess) {
        _showSnackBar('Security questions saved successfully!', Colors.green);

        // Now proceed with login
        await _saveCredentials();

        // Navigate to dashboard using the userData passed from login
        if (mounted) {
          _navigateToDashboard(userData);
        }
      } else {
        _showSnackBar(
          response.error ?? 'Failed to save security questions',
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error saving security questions: $e', Colors.red);
      print('Security questions error: $e');
    }
  }

  void _navigateToDashboard(Map<String, dynamic> userData) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          (userData['type_name'] == 'SALESMAN')
              ? DealerDashboardScreen()
              : (userData['type_name'] == 'DEALER')
              ? dealer_screen.DealerDashboardScreen()
              : (userData['type_name'] == 'ADMIN')
              ? AdminDashboardScreen()
              :DealerDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 800),
        ),
      );
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


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  Color(0xFF1A1D2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ]
                    : [
                  Color(0xFFE8F5E9),
                  Color(0xFFC8E6C9),
                  Color(0xFFA5D6A7),
                ],
              ),
            ),
          ),
          // Floating orbs animation
          ..._buildFloatingOrbs(isDark),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 32,
                    vertical: 24,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(isSmallScreen),
                          SizedBox(height: 40),
                          _buildLoginForm(isSmallScreen),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Theme selector
          Positioned(
            top: 16,
            right: 16,
            child: ThemeSelector(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingOrbs(bool isDark) {
    return List.generate(3, (index) {
      return Positioned(
        top: 100.0 * index + 50,
        left: index.isEven ? -50 : null,
        right: index.isOdd ? -50 : null,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(seconds: 3 + index),
          curve: Curves.easeInOut,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (value - 0.5)),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                      Colors.blue.withOpacity(0.15),
                      Colors.transparent,
                    ]
                        : [
                      Colors.green.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildHeader(bool isSmallScreen) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.8),
                theme.primaryColor,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.lock_outline_rounded,
            size: isSmallScreen ? 50 : 60,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: isSmallScreen ? 32 : 40,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? double.infinity : 450,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCompanyDropdown(),
              SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                hintText: 'Username',
                icon: Icons.person_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Password',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
              SizedBox(height: 20),
              _buildLoginButton(),
              SizedBox(height: 16),
              _buildRememberMeAndForgotPassword(),
            ],
          ),
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

  // Forgot Password Implementation
  void _handleForgotPassword() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(
                Icons.lock_reset,
                color: theme.primaryColor,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'Forgot Password',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter your username to reset password',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.person, color: theme.primaryColor),
            ),
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_emailController.text.trim().isEmpty) {
                  _showSnackBar('Please enter your username', Colors.orange);
                  return;
                }
                Navigator.of(context).pop();
                _fetchSecurityQuestions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
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
      ApiService apiService = ApiService();
      final response = await apiService.request(
        payload: {
          "sqlKey": "GET_USER_SECURITY_QUESTIONS",
          "username": _emailController.text.trim(),
        },
      );

      if (mounted) Navigator.of(context).pop();

      if (response.isSuccess &&
          response.data != null &&
          response.data!.isNotEmpty) {
        _showSecurityAnswersDialog(response.data!);
      } else {
        _showSnackBar(
          response.message ?? 'No security questions found for this user',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showSnackBar(
        'Network error. Please check your connection.',
        Colors.red,
      );
      print('Error fetching security questions: $e');
    }
  }

  void _showSecurityAnswersDialog(List<dynamic> questions) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final List<TextEditingController> answerControllers =
    List.generate(questions.length, (_) => TextEditingController());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(
                Icons.help_outline,
                color: theme.primaryColor,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'Answer Security Questions',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please answer the following questions',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                questions.length,
                    (index) => Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questions[index]['question'] ?? '',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: answerControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Your answer',
                          hintStyle: TextStyle(
                            color: textColor.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                for (var controller in answerControllers) {
                  controller.dispose();
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                bool allFilled = answerControllers.every(
                      (controller) => controller.text.trim().isNotEmpty,
                );

                if (!allFilled) {
                  _showSnackBar(
                    'Please answer all questions',
                    Colors.orange,
                  );
                  return;
                }

                await _verifySecurityAnswers(
                  questions,
                  answerControllers,
                  dialogContext,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          ],
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
            'Incorrect answers. Please try again.',
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
      _showSnackBar(
        'Network error. Please check your connection.',
        Colors.red,
      );
      print('Error verifying security answers: $e');
    }
  }

  void _showResetPasswordDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  Icon(
                    Icons.lock_open,
                    color: theme.primaryColor,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enter your new password',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.lock, color: theme.primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureNewPassword = !obscureNewPassword;
                          });
                        },
                      ),
                    ),
                    style: TextStyle(color: textColor),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.lock_outline, color: theme.primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    newPasswordController.dispose();
                    confirmPasswordController.dispose();
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (newPasswordController.text.trim().isEmpty ||
                        confirmPasswordController.text.trim().isEmpty) {
                      _showSnackBar(
                        'Please fill in both password fields',
                        Colors.orange,
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

                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      _showSnackBar(
                        'Passwords do not match',
                        Colors.red,
                      );
                      return;
                    }

                    await _submitNewPassword(
                      newPasswordController.text,
                      dialogContext,
                    );

                    newPasswordController.dispose();
                    confirmPasswordController.dispose();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitNewPassword(
      String newPassword,
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
      ApiService apiService = ApiService();
      final response = await apiService.request(
        payload: {
          "sqlKey": "UPDATE_USER_PASSWORD",
          "username": _emailController.text.trim(),
          "newPassword": newPassword,
        },
      );

      if (mounted) Navigator.of(context).pop(); // Close loading dialog

      if (response.isSuccess) {
        if (mounted) Navigator.of(dialogContext).pop(); // Close reset dialog

        _showSnackBar(
          'Password reset successfully! Please login with your new password.',
          Colors.green,
        );

        // Clear password field
        _passwordController.clear();
      } else {
        _showSnackBar(
          response.message ?? 'Failed to reset password',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showSnackBar(
        'Network error. Please try again.',
        Colors.red,
      );
      print('Error resetting password: $e');
    }
  }
}