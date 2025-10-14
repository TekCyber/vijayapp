// lib/screens/salesman/salesman_scheme_screen.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_container.dart';
import '../../services/api_service.dart';
import '../dealer/menu_navigator.dart';

class SchemeScreen extends StatefulWidget {
  final String title;
  final Function(int)? onMenuSelected;

  SchemeScreen({
    required this.title,
    this.onMenuSelected,
  });

  @override
  _SchemeScreenState createState() => _SchemeScreenState();
}

class _SchemeScreenState extends State<SchemeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  int selectedMenuIndex = 0;

  // Dropdown values
  String? selectedScheme;
  String? selectedRoute;

  // Data lists
  List<Map<String, dynamic>> _schemes = [];
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _schemeTransactions = [];
  List<Map<String, dynamic>> _slabThresholds = []; // Add slab thresholds data

  // Loading states
  bool _isLoadingSchemes = true;
  bool _isLoadingRoutes = true;
  bool _isLoadingTransactions = true;

  // Error states
  String _errorMessageSchemes = '';
  String _errorMessageRoutes = '';
  String _errorMessageTransactions = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _fetchSchemes();
    _fetchRoutes(); // Load routes immediately
    _fetchAllSchemeTransactions(); // Load all transactions by default
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onMenuSelected(int index) {
    setState(() => selectedMenuIndex = index);
    MenuNavigator.handleMenuSelection(context, index);
  }

  // Fetch schemes from API
  Future<void> _fetchSchemes() async {
    try {
      setState(() {
        _isLoadingSchemes = true;
        _errorMessageSchemes = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_SCHEME_MASTER",
        "executive": username,
      };

      print('Fetching Schemes API Payload: $payload');

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData = List<Map<String, dynamic>>.from(response.data!);

        setState(() {
          _schemes = fetchedData;
          _isLoadingSchemes = false;
        });

        print('Schemes state updated. Total schemes: ${_schemes.length}');
      } else {
        throw Exception(response.error ?? 'Failed to fetch schemes');
      }
    } catch (e) {
      setState(() {
        _isLoadingSchemes = false;
        _errorMessageSchemes = 'Error loading schemes: ${e.toString()}';
      });
      print('Error fetching schemes: $e');
    }
  }

  // Fetch routes based on executive
  Future<void> _fetchRoutes() async {
    try {
      setState(() {
        _isLoadingRoutes = true;
        _errorMessageRoutes = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_ROUTES_BY_EXECUTIVE",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData = List<Map<String, dynamic>>.from(response.data!);

        setState(() {
          _routes = fetchedData;
          _isLoadingRoutes = false;
        });

        print('Routes state updated. Total routes: ${_routes.length}');
      } else {
        throw Exception(response.error ?? 'Failed to fetch routes');
      }
    } catch (e) {
      setState(() {
        _isLoadingRoutes = false;
        _errorMessageRoutes = 'Error loading routes: ${e.toString()}';
      });
      print('Error fetching routes: $e');
    }
  }

  // Fetch slab thresholds for a specific scheme
  Future<void> _fetchSlabThresholds(String schemeName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        print('Username not found for slab thresholds');
        return;
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_SLAB_THRESHOLDS_BY_SCHEME",
        "scheme_name": schemeName,
        "executive": username,
      };

      print('Fetching Slab Thresholds API Payload: $payload');

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData = List<Map<String, dynamic>>.from(response.data!);

        setState(() {
          _slabThresholds = fetchedData;
        });

        print('Slab thresholds loaded: ${_slabThresholds.length} slabs for scheme: $schemeName');
      } else {
        print('Failed to fetch slab thresholds: ${response.error}');
      }
    } catch (e) {
      print('Error fetching slab thresholds: $e');
    }
  }

  // Fetch all scheme transactions for the executive (default view)
  Future<void> _fetchAllSchemeTransactions() async {
    try {
      setState(() {
        _isLoadingTransactions = true;
        _errorMessageTransactions = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "sqlKey": "GET_ALL_SCHEME_TRANSACTIONS_BY_EXECUTIVE",
        "executive": username,
      };

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData = List<Map<String, dynamic>>.from(response.data!);

        setState(() {
          _schemeTransactions = fetchedData;
          _isLoadingTransactions = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch all scheme transactions');
      }
    } catch (e) {
      setState(() {
        _isLoadingTransactions = false;
        _errorMessageTransactions = 'Error loading all scheme transactions: ${e.toString()}';
      });
    }
  }

  // Fetch scheme transactions (handles different filtering scenarios)
  Future<void> _fetchSchemeTransactions() async {
    if (selectedScheme == null && selectedRoute == null) {
      _fetchAllSchemeTransactions();
      return;
    }

    try {
      setState(() {
        _isLoadingTransactions = true;
        _errorMessageTransactions = '';
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found in SharedPreferences');
      }

      Map<String, dynamic> payload = {
        "executive": username,
      };

      String sqlKey = '';

      if (selectedScheme != null && selectedRoute != null) {
        sqlKey = "GET_SCHEME_TRANSACTIONS";
        payload["scheme_name"] = selectedScheme;
        payload["route_name"] = selectedRoute;
      } else if (selectedScheme != null) {
        sqlKey = "GET_SCHEME_TRANSACTIONS_BY_SCHEME";
        payload["scheme_name"] = selectedScheme;
      } else if (selectedRoute != null) {
        sqlKey = "GET_SCHEME_TRANSACTIONS_BY_ROUTE";
        payload["route_name"] = selectedRoute;
      }

      payload["sqlKey"] = sqlKey;

      ApiService apiService = ApiService();
      final response = await apiService.request(payload: payload);

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> fetchedData = List<Map<String, dynamic>>.from(response.data!);

        setState(() {
          _schemeTransactions = fetchedData;
          _isLoadingTransactions = false;
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch scheme transactions');
      }
    } catch (e) {
      setState(() {
        _isLoadingTransactions = false;
        _errorMessageTransactions = 'Error loading scheme transactions: ${e.toString()}';
      });
    }
  }

  void _onSchemeChanged(String? newValue) {
    if (newValue != null && newValue != selectedScheme) {
      setState(() {
        selectedScheme = newValue;
      });
      _fetchSlabThresholds(newValue);
      _fetchSchemeTransactions();
    }
  }

  void _onRouteChanged(String? newValue) {
    if (newValue != null && newValue != selectedRoute) {
      setState(() {
        selectedRoute = newValue;
      });
      _fetchSchemeTransactions();
    }
  }

  // Calculate next slab requirement using Method 1: Historical Achievement Analysis
  Map<String, dynamic> _calculateNextSlabRequirement(double currentAmount, int currentSlabValue, String currentSlab, String schemeName) {
    if (_slabThresholds.isEmpty) {
      return {
        'target': 0.0,
        'needed': 0.0,
        'name': 'Next Slab',
        'reward': '',
      };
    }

    List<Map<String, dynamic>> sortedSlabs = List.from(_slabThresholds);
    sortedSlabs.sort((a, b) {
      int aValue = int.tryParse(a['slab_value']?.toString() ?? '0') ?? 0;
      int bValue = int.tryParse(b['slab_value']?.toString() ?? '0') ?? 0;
      return aValue.compareTo(bValue);
    });

    for (var slab in sortedSlabs) {
      int slabValue = int.tryParse(slab['slab_value']?.toString() ?? '0') ?? 0;

      if (slabValue > currentSlabValue) {
        String nextSlabName = slab['SLAB']?.toString() ?? 'Next Slab';
        String cnGift = slab['cn_gift']?.toString() ?? '';

        double estimatedTarget = _analyzeTransactionDataForTarget(schemeName, slabValue, currentAmount);
        double amountNeeded = estimatedTarget > currentAmount ? (estimatedTarget - currentAmount) : 0.0;

        return {
          'target': estimatedTarget,
          'needed': amountNeeded,
          'name': nextSlabName,
          'reward': cnGift,
          'slab_value': slabValue,
        };
      }
    }

    return {
      'target': 0.0,
      'needed': 0.0,
      'name': 'Max Slab Achieved',
      'reward': 'Maximum rewards',
      'slab_value': currentSlabValue,
    };
  }

  // Method 1: Historical Achievement Analysis
  double _analyzeTransactionDataForTarget(String schemeName, int targetSlabValue, double currentAmount) {
    if (_schemeTransactions.isEmpty) {
      return currentAmount > 0 ? currentAmount * 1.3 : 100000.0;
    }

    List<double> achievedAmountsAtTargetSlab = [];

    for (var transaction in _schemeTransactions) {
      String transactionScheme = transaction['SCHEME_NAME']?.toString() ?? '';
      int transactionSlabValue = int.tryParse(transaction['slab_value']?.toString() ?? '0') ?? 0;
      String achievement = transaction['scheme_achievement']?.toString().toLowerCase() ?? '';
      double amount = double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;

      if (transactionScheme == schemeName &&
          transactionSlabValue == targetSlabValue &&
          (achievement.contains('achieved') ||
              achievement.contains('qualified') ||
              achievement.contains('completed') ||
              achievement == 'achieved') &&
          amount > currentAmount) {
        achievedAmountsAtTargetSlab.add(amount);
      }
    }

    if (achievedAmountsAtTargetSlab.isNotEmpty) {
      achievedAmountsAtTargetSlab.sort();
      double minAchievedTarget = achievedAmountsAtTargetSlab.first;

      print('Found ${achievedAmountsAtTargetSlab.length} achieved amounts for $schemeName slab $targetSlabValue');
      print('Minimum achieved amount: $minAchievedTarget');

      return minAchievedTarget;
    }

    return currentAmount > 0 ? currentAmount * 1.3 : 100000.0;
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    double value = double.tryParse(amount.toString()) ?? 0.0;
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: widget.title,
      onTabSelected: _onMenuSelected,
      showBackButton: true,

        body: SafeArea(
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _slideAnimation.value)),
                child: Opacity(
                  opacity: _slideAnimation.value,
                  child: Column(
                    children: [
                      _buildTopRow(),
                      SizedBox(height: 12),
                      _buildDropdownRow(),
                      SizedBox(height: 16),
                      Expanded(child: _buildSchemeContent()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

    );
  }

  Widget _buildTopRow() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        child: Container(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4F46E5).withOpacity(0.3),
                      Color(0xFF7C3AED).withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.card_giftcard,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Schemes',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownRow() {
    List<String> schemeItems = [];
    if (_schemes.isNotEmpty) {
      for (var scheme in _schemes) {
        String schemeName = scheme['scheme_name']?.toString() ?? '';
        if (schemeName.isNotEmpty) {
          schemeItems.add(schemeName);
        }
      }
    }

    List<String> routeItems = [];
    if (_routes.isNotEmpty) {
      for (var route in _routes) {
        String routeName = route['route_name']?.toString() ?? '';
        if (routeName.isNotEmpty) {
          routeItems.add(routeName);
        }
      }
    }

    bool schemeEnabled = !_isLoadingSchemes && schemeItems.isNotEmpty;
    bool routeEnabled = !_isLoadingRoutes && routeItems.isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              label: 'Select Scheme',
              value: selectedScheme,
              items: schemeItems,
              onChanged: _onSchemeChanged,
              icon: Icons.card_giftcard,
              isLoading: _isLoadingSchemes,
              errorMessage: _errorMessageSchemes,
              enabled: schemeEnabled,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildDropdown(
              label: 'Select Route',
              value: selectedRoute,
              items: routeItems,
              onChanged: _onRouteChanged,
              icon: Icons.route,
              isLoading: _isLoadingRoutes,
              errorMessage: _errorMessageRoutes,
              enabled: routeEnabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    bool isLoading = false,
    String errorMessage = '',
    bool enabled = true,
  }) {
    return GlassContainer(
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: enabled ? Color(0xFF4F46E5) : Colors.grey,
                  size: 14,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: enabled ? Colors.white70 : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 10),
              )
            else if (isLoading)
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (!enabled)
                Text(
                  'Not available',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                )
              else if (items.isEmpty)
                  Text(
                    'No options found',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  )
                else
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: items.contains(value) ? value : null,
                      hint: Text(
                        'Select ${label.replaceAll('Select ', '')}',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      isExpanded: true,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      dropdownColor: Color(0xFF1F2937),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 18,
                      ),
                      items: items.map<DropdownMenuItem<String>>((String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: TextStyle(color: Colors.white, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: onChanged,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeContent() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          child: _buildSchemeTransactionsView(),
        ),
      ),
    );
  }

  Widget _buildSchemeTransactionsView() {
    if (_isLoadingTransactions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading scheme transactions...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessageTransactions.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(Icons.error_outline, color: Colors.red, size: 48),
            ),
            SizedBox(height: 20),
            Text(
              'Failed to load transactions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessageTransactions,
              style: TextStyle(color: Colors.red.withOpacity(0.8), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: selectedScheme != null && selectedRoute != null
                  ? _fetchSchemeTransactions
                  : _fetchAllSchemeTransactions,
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4F46E5),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_schemeTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(Icons.receipt_long, color: Colors.blue, size: 48),
            ),
            SizedBox(height: 20),
            Text(
              'No Transactions Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4F46E5).withOpacity(0.2),
                      Color(0xFF7C3AED).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long, color: Color(0xFF4F46E5), size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scheme Transactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      selectedScheme != null && selectedRoute != null
                          ? '$selectedScheme - $selectedRoute'
                          : 'All your scheme transactions',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (selectedScheme != null || selectedRoute != null) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedScheme = null;
                      selectedRoute = null;
                    });
                    _fetchAllSchemeTransactions();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear, color: Colors.orange, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _schemeTransactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionRow(_schemeTransactions[index], index);
            },
          ),
        ),
        _buildTotalSummary(),
      ],
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> transaction, int index) {
    bool isEven = index % 2 == 0;

    String customerName = transaction['customer_name']?.toString() ?? 'N/A';
    String brand = transaction['BRAND']?.toString() ?? 'N/A';
    String slab = transaction['SLAB']?.toString() ?? 'N/A';
    String schemeName = transaction['SCHEME_NAME']?.toString() ?? '';
    double amount = double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
    String startDate = transaction['start_date']?.toString() ?? 'N/A';
    String endDate = transaction['end_date']?.toString() ?? 'N/A';
    String schemeAchievement = transaction['scheme_achievement']?.toString() ?? 'Pending';
    String finalGift = transaction['final_gift']?.toString() ?? 'N/A';
    int finalCn = int.tryParse(transaction['final_cn']?.toString() ?? '0') ?? 0;
    int slabValue = int.tryParse(transaction['slab_value']?.toString() ?? '0') ?? 0;

    Map<String, dynamic> nextSlabInfo = _calculateNextSlabRequirement(amount, slabValue, slab, schemeName);
    double amountNeeded = nextSlabInfo['needed'];
    String nextSlabName = nextSlabInfo['name'];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: isEven ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.01),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  customerName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(schemeAchievement).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getStatusColor(schemeAchievement).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  schemeAchievement,
                  style: TextStyle(
                    color: _getStatusColor(schemeAchievement),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Brand: $brand | Current Slab: $slab',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Period: $startDate to $endDate',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Sales',
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.2),
                            Colors.blue.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        '₹${_formatAmount(amount)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              if (amountNeeded > 0) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Next: ${nextSlabName}',
                        style: TextStyle(
                          color: Colors.orange.withOpacity(0.9),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withOpacity(0.2),
                              Colors.orange.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.trending_up, color: Colors.orange, size: 8),
                                SizedBox(width: 2),
                                Text(
                                  '₹${_formatAmount(amountNeeded)}',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (nextSlabInfo['reward'] != null && nextSlabInfo['reward'].toString().isNotEmpty) ...[
                              SizedBox(height: 2),
                              Text(
                                nextSlabInfo['reward'].toString(),
                                style: TextStyle(
                                  color: Colors.orange.withOpacity(0.8),
                                  fontSize: 7,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withOpacity(0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 10),
                        SizedBox(width: 4),
                        Text(
                          'Achieved',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (finalCn > 0) ...[
                      Text(
                        'Final CN: $finalCn',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                    ],
                    if (finalGift != 'N/A' && finalGift.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Gift: $finalGift',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String achievement) {
    switch (achievement.toLowerCase()) {
      case 'achieved':
      case 'completed':
        return Colors.green;
      case 'partial':
      case 'in progress':
        return Colors.orange;
      case 'not achieved':
      case 'failed':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildTotalSummary() {
    double totalAmount = _schemeTransactions.fold(0.0, (sum, item) {
      double amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
      return sum + amount;
    });

    int totalFinalCn = _schemeTransactions.fold(0, (sum, item) {
      int finalCn = int.tryParse(item['final_cn']?.toString() ?? '0') ?? 0;
      return sum + finalCn;
    });

    int achievedCount = _schemeTransactions.where((item) {
      String achievement = item['scheme_achievement']?.toString().toLowerCase() ?? '';
      return achievement == 'achieved' || achievement == 'completed';
    }).length;

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4F46E5).withOpacity(0.2),
            Color(0xFF7C3AED).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 8),
              Text(
                'Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Transactions: ${_schemeTransactions.length}',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Achieved: $achievedCount',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (totalFinalCn > 0) ...[
                      SizedBox(height: 4),
                      Text(
                        'Total CN: $totalFinalCn',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '₹${_formatAmount(totalAmount)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}