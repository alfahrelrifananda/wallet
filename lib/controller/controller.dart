import 'package:wallet/onboarding.dart';
import 'package:wallet/widgets/home_widget_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'package:wallet/model.dart';
import 'package:wallet/home.dart';

class AppController extends StatefulWidget {
  const AppController({super.key});

  @override
  State<AppController> createState() => _AppControllerState();
}

class _AppControllerState extends State<AppController> {
  bool _isOnboarded = false;
  String _currency = 'IDR';
  String _currencySymbol = 'Rp';
  double _totalBudget = 0;
  DateTime? _finalDate;
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _biometricEnabled = false;
  bool _isAuthenticated = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  DateTime? _debugCurrentDate;

  void _handleDebugDateChange(DateTime newDate) {
    setState(() {
      _debugCurrentDate = newDate;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isOnboarded = prefs.getBool('isOnboarded') ?? false;
      _currency = prefs.getString('currency') ?? 'IDR';
      _currencySymbol = prefs.getString('currencySymbol') ?? 'Rp';
      _totalBudget = prefs.getDouble('totalBudget') ?? 0;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

      final dateString = prefs.getString('finalDate');
      if (dateString != null) {
        _finalDate = DateTime.parse(dateString);
      }

      final transactionsJson = prefs.getString('transactions');
      if (transactionsJson != null) {
        final List<dynamic> decoded = json.decode(transactionsJson);
        _transactions = decoded.map((e) => Transaction.fromJson(e)).toList();
      }

      final accountsJson = prefs.getString('accounts');
      if (accountsJson != null) {
        final List<dynamic> decoded = json.decode(accountsJson);
        _accounts = decoded.map((e) => Account.fromJson(e)).toList();
      }

      final categoriesJson = prefs.getString('categories');
      if (categoriesJson != null) {
        final List<dynamic> decoded = json.decode(categoriesJson);
        _categories = decoded.map((e) => Category.fromJson(e)).toList();
      } else {
        _categories = _getDefaultCategories();
      }

      _isLoading = false;
    });

    // Trigger authentication if biometric is enabled
    if (_biometricEnabled && _isOnboarded) {
      _authenticateUser();
    } else {
      setState(() => _isAuthenticated = true);
    }
  }

  Future<void> _authenticateUser() async {
    if (kIsWeb || !_biometricEnabled) {
      setState(() => _isAuthenticated = true);
      return;
    }

    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canAuth || !isDeviceSupported) {
        setState(() => _isAuthenticated = true);
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access wallet',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      setState(() => _isAuthenticated = authenticated);

      if (!authenticated) {
        // If authentication fails, show retry dialog
        _showAuthenticationFailedDialog();
      }
    } catch (e) {
      // On error, allow access but show warning
      setState(() => _isAuthenticated = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showAuthenticationFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_outline, color: Colors.red, size: 48),
        title: const Text('Authentication Failed'),
        content: const Text(
          'You need to authenticate to access wallet. Please try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _authenticateUser();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  List<Category> _getDefaultCategories() {
    return [
      Category(
        id: '1',
        name: 'Food',
        icon: Icons.restaurant,
        color: Colors.orange,
        isExpense: true,
      ),
      Category(
        id: '2',
        name: 'Transport',
        icon: Icons.directions_car,
        color: Colors.blue,
        isExpense: true,
      ),
      Category(
        id: '3',
        name: 'Shopping',
        icon: Icons.shopping_bag,
        color: Colors.purple,
        isExpense: true,
      ),
      Category(
        id: '4',
        name: 'Entertainment',
        icon: Icons.movie,
        color: Colors.pink,
        isExpense: true,
      ),
      Category(
        id: '5',
        name: 'Bills',
        icon: Icons.receipt_long,
        color: Colors.red,
        isExpense: true,
      ),
      Category(
        id: '6',
        name: 'Health',
        icon: Icons.medical_services,
        color: Colors.green,
        isExpense: true,
      ),
      Category(
        id: '7',
        name: 'Salary',
        icon: Icons.payments,
        color: Colors.teal,
        isExpense: false,
      ),
      Category(
        id: '8',
        name: 'Business',
        icon: Icons.business,
        color: Colors.indigo,
        isExpense: false,
      ),
      Category(
        id: '9',
        name: 'Gifts',
        icon: Icons.card_giftcard,
        color: Colors.amber,
        isExpense: false,
      ),
      Category(
        id: '10',
        name: 'Transfer',
        icon: Icons.swap_horiz,
        color: Colors.blueGrey,
        isExpense: true,
      ),
      Category(
        id: '11',
        name: 'Other',
        icon: Icons.more_horiz,
        color: Colors.grey,
        isExpense: false,
      ),
    ];
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isOnboarded', _isOnboarded);
    await prefs.setString('currency', _currency);
    await prefs.setString('currencySymbol', _currencySymbol);
    await prefs.setDouble('totalBudget', _totalBudget);

    if (_finalDate != null) {
      await prefs.setString('finalDate', _finalDate!.toIso8601String());
    }

    if (_isOnboarded && _accounts.isNotEmpty) {
      final currentBalance =
          _totalBudget +
          _transactions.fold<double>(
            0.0,
            (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
          );

      await HomeWidgetHelper.updateBalance(
        balance: currentBalance,
        currencySymbol: _currencySymbol,
      );
    }

    await prefs.setString(
      'transactions',
      json.encode(_transactions.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'accounts',
      json.encode(_accounts.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'categories',
      json.encode(_categories.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveBiometricPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() {
      _biometricEnabled = value;
    });
  }

  void _completeOnboarding(
    String currency,
    String symbol,
    double budget,
    DateTime finalDate,
    List<Account> accounts,
  ) {
    setState(() {
      _isOnboarded = true;
      _currency = currency;
      _currencySymbol = symbol;
      _totalBudget = budget;
      _finalDate = finalDate;
      _accounts = accounts;
    });
    _saveData();
  }

  void _addTransaction(Transaction transaction) {
    setState(() {
      _transactions.add(transaction);
    });
    _saveData();
  }

  void _addAccount(Account account) {
    setState(() {
      _accounts.add(account);
    });
    _saveData();
  }

  void _deleteAccount(String accountId) {
    setState(() {
      // Remove the account
      _accounts.removeWhere((a) => a.id == accountId);

      // Remove all transactions associated with this account
      _transactions.removeWhere((t) => t.accountId == accountId);
    });
    _saveData();
  }

  void _deleteTransaction(String transactionId) {
    setState(() {
      _transactions.removeWhere((t) => t.id == transactionId);
    });
    _saveData();
  }

  void _updateTransaction(Transaction updatedTransaction) {
    setState(() {
      final index = _transactions.indexWhere(
        (t) => t.id == updatedTransaction.id,
      );
      if (index != -1) {
        _transactions[index] = updatedTransaction;
      }
    });
    _saveData();
  }

  void _addCategory(Category category) {
    setState(() {
      _categories.add(category);
    });
    _saveData();
  }

  void _updateCategory(Category updatedCategory) {
    setState(() {
      final index = _categories.indexWhere((c) => c.id == updatedCategory.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }
    });
    _saveData();
  }

  void _deleteCategory(String categoryId) {
    setState(() {
      _categories.removeWhere((c) => c.id == categoryId);
    });
    _saveData();
  }

  // NEW METHOD: Update final date
  void _updateFinalDate(DateTime newDate) {
    setState(() {
      _finalDate = newDate;
    });
    _saveData();
  }

  void _resetApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _isOnboarded = false;
      _currency = 'IDR';
      _currencySymbol = 'Rp';
      _totalBudget = 0;
      _finalDate = null;
      _transactions = [];
      _accounts = [];
      _categories = _getDefaultCategories();
      _biometricEnabled = false;
    });
  }

  Future<String> _exportData() async {
    final data = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'currency': _currency,
      'currencySymbol': _currencySymbol,
      'totalBudget': _totalBudget,
      'finalDate': _finalDate?.toIso8601String(),
      'biometricEnabled': _biometricEnabled,
      'transactions': _transactions.map((e) => e.toJson()).toList(),
      'accounts': _accounts.map((e) => e.toJson()).toList(),
      'categories': _categories.map((e) => e.toJson()).toList(),
    };
    return json.encode(data);
  }

  Future<void> _importData(String jsonString) async {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;

      setState(() {
        _currency = data['currency'] ?? 'IDR';
        _currencySymbol = data['currencySymbol'] ?? 'Rp';
        _totalBudget = (data['totalBudget'] ?? 0).toDouble();
        _biometricEnabled = data['biometricEnabled'] ?? false;

        if (data['finalDate'] != null) {
          _finalDate = DateTime.parse(data['finalDate']);
        }

        if (data['categories'] != null) {
          final List<dynamic> categoriesJson = data['categories'];
          _categories = categoriesJson
              .map((e) => Category.fromJson(e))
              .toList();
        }

        if (data['accounts'] != null) {
          final List<dynamic> accountsJson = data['accounts'];
          _accounts = accountsJson.map((e) => Account.fromJson(e)).toList();
        }

        if (data['transactions'] != null) {
          final List<dynamic> transactionsJson = data['transactions'];
          _transactions = transactionsJson
              .map((e) => Transaction.fromJson(e))
              .toList();
        }
      });

      await _saveData();
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isOnboarded) {
      return OnboardingFlow(onComplete: _completeOnboarding);
    }

    // Show authentication screen if biometric is enabled and not authenticated
    if (_biometricEnabled && !_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Wallet',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authenticate to access your finances',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 64),
                FilledButton.tonalIcon(
                  onPressed: _authenticateUser,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Authenticate'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return HomeScreen(
      currency: _currency,
      currencySymbol: _currencySymbol,
      totalBudget: _totalBudget,
      finalDate: _finalDate!,
      transactions: _transactions,
      accounts: _accounts,
      categories: _categories,
      onAddTransaction: _addTransaction,
      onAddAccount: _addAccount,
      onDeleteTransaction: _deleteTransaction,
      onDeleteAccount: _deleteAccount,
      onUpdateTransaction: _updateTransaction,
      onAddCategory: _addCategory,
      onUpdateCategory: _updateCategory,
      onDeleteCategory: _deleteCategory,
      onUpdateFinalDate: _updateFinalDate,
      onReset: _resetApp,
      onExportData: _exportData,
      onImportData: _importData,
      biometricEnabled: _biometricEnabled,
      onBiometricChanged: _saveBiometricPreference,
      debugCurrentDate: _debugCurrentDate,
      onDebugDateChange: _handleDebugDateChange,
    );
  }
}
