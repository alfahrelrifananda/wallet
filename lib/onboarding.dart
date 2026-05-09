import 'package:wallet/utils/input_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wallet/model.dart';
import 'package:wallet/constants/app_strings.dart';

class OnboardingFlow extends StatefulWidget {
  final Function(String, String, double, DateTime, List<Account>) onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _selectedCurrency = 'GBP';
  String _selectedSymbol = '£';
  DateTime? _selectedDate;
  final List<Account> _accounts = [];

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (_selectedDate != null && _accounts.isNotEmpty) {
        final totalBudget = _accounts.fold<double>(
          0.0,
          (sum, account) => sum + account.initialBalance,
        );

        widget.onComplete(
          _selectedCurrency,
          _selectedSymbol,
          totalBudget,
          _selectedDate!,
          _accounts,
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
      case 1:
        return true;
      case 2:
        return _accounts.isNotEmpty;
      case 3:
        if (_selectedDate == null) return false;

        final totalBudget = _accounts.fold<double>(
          0.0,
          (sum, account) => sum + account.initialBalance,
        );
        final daysRemaining = _selectedDate!.difference(DateTime.now()).inDays;
        final dailyBudget = totalBudget / daysRemaining;

        return dailyBudget >= 1.0;
      default:
        return false;
    }
  }

  void _onCurrencySelected(String code, String symbol) {
    setState(() {
      _selectedCurrency = code;
      _selectedSymbol = symbol;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _onAccountsChanged(List<Account> accounts) {
    setState(() {
      _accounts.clear();
      _accounts.addAll(accounts);
    });
  }

  @override
  Widget build(BuildContext context) {
    AppStrings.init(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  const WelcomePage(),
                  CurrencyPage(
                    selectedCurrency: _selectedCurrency,
                    selectedSymbol: _selectedSymbol,
                    onCurrencySelected: _onCurrencySelected,
                  ),
                  AccountsPage(
                    accounts: _accounts,
                    selectedSymbol: _selectedSymbol,
                    onAccountsChanged: _onAccountsChanged,
                  ),
                  DatePage(
                    selectedDate: _selectedDate,
                    onDateSelected: _onDateSelected,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(AppStrings.back),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: _currentPage > 0 ? 1 : 1,
                    child: FilledButton(
                      onPressed: _canProceed ? _nextPage : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == 3
                            ? AppStrings.getStarted
                            : AppStrings.next,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.welcomeTowallet,
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.welcomeDescription,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}

class CurrencyPage extends StatelessWidget {
  final String selectedCurrency;
  final String selectedSymbol;
  final Function(String, String) onCurrencySelected;

  const CurrencyPage({
    super.key,
    required this.selectedCurrency,
    required this.selectedSymbol,
    required this.onCurrencySelected,
  });

  static final List<Map<String, String>> _currencies = [
    {'symbol': '£', 'name': 'British Pound', 'code': 'GBP'},
    {'symbol': '€', 'name': 'Euro', 'code': 'EUR'},
    {'symbol': 'Rp', 'name': 'Indonesian Rupiah', 'code': 'IDR'},
    {'symbol': '¥', 'name': 'Japanese Yen', 'code': 'JPY'},
    {'symbol': '\$', 'name': 'US Dollar', 'code': 'USD'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.selectCurrency,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.choosePreferredCurrency,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _currencies.length,
              itemBuilder: (context, index) {
                final currency = _currencies[index];
                final isSelected = selectedCurrency == currency['code'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: isSelected
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.5,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onCurrencySelected(
                        currency['code']!,
                        currency['symbol']!,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.onSecondaryContainer
                                          .withOpacity(0.1)
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  currency['symbol']!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? theme.colorScheme.onSecondaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currency['name']!,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    currency['code']!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.onSecondaryContainer,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AccountsPage extends StatefulWidget {
  final List<Account> accounts;
  final String selectedSymbol;
  final Function(List<Account>) onAccountsChanged;

  const AccountsPage({
    super.key,
    required this.accounts,
    required this.selectedSymbol,
    required this.onAccountsChanged,
  });

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  late List<Account> _localAccounts;

  @override
  void initState() {
    super.initState();
    _localAccounts = List.from(widget.accounts);
  }

  void _updateParent() {
    widget.onAccountsChanged(_localAccounts);
  }

  void _showAddAccountDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditAccountDialog(
        selectedSymbol: widget.selectedSymbol,
        onSave: (account) {
          setState(() {
            _localAccounts.add(account);
          });
          _updateParent();
        },
      ),
    );
  }

  void _showEditAccountDialog(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditAccountDialog(
        selectedSymbol: widget.selectedSymbol,
        account: _localAccounts[index],
        onSave: (account) {
          setState(() {
            _localAccounts[index] = account;
          });
          _updateParent();
        },
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(AppStrings.deleteAccount),
        content: Text(
          AppStrings.format(AppStrings.deleteAccountNameConfirm, [
            _localAccounts[index].name,
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _localAccounts.removeAt(index);
              });
              _updateParent();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.addAccounts,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.totalBudgetDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _localAccounts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.noAccountsYet,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.addAtLeastOneAccount,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _localAccounts.length,
                    itemBuilder: (context, index) {
                      final account = _localAccounts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: theme.colorScheme.secondaryContainer
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _showEditAccountDialog(index),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: account.color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      account.icon,
                                      color: account.color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          account.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          account.type
                                              .toString()
                                              .split('.')
                                              .last
                                              .toUpperCase(),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${widget.selectedSymbol}${NumberFormat('#,##0').format(account.initialBalance)}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: theme.colorScheme.error,
                                    ),
                                    onPressed: () =>
                                        _showDeleteConfirmation(index),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showAddAccountDialog,
              icon: const Icon(Icons.add),
              label: Text(AppStrings.addAccount),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEditAccountDialog extends StatefulWidget {
  final String selectedSymbol;
  final Account? account;
  final Function(Account) onSave;

  const _AddEditAccountDialog({
    required this.selectedSymbol,
    this.account,
    required this.onSave,
  });

  @override
  State<_AddEditAccountDialog> createState() => _AddEditAccountDialogState();
}

class _AddEditAccountDialogState extends State<_AddEditAccountDialog> {
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late AccountType _selectedType;
  late IconData _selectedIcon;
  late Color _selectedColor;

  static final Map<AccountType, IconData> _typeIcons = {
    AccountType.wallet: Icons.account_balance_wallet,
    AccountType.bank: Icons.account_balance,
    AccountType.card: Icons.credit_card,
    AccountType.savings: Icons.savings,
    AccountType.investment: Icons.trending_up,
  };

  static final List<Color> _colors = [
    Colors.teal,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.green,
    Colors.pink,
    Colors.red,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _selectedType = widget.account?.type ?? AccountType.wallet;
    _selectedIcon = widget.account?.icon ?? Icons.account_balance_wallet;
    _selectedColor = widget.account?.color ?? Colors.teal;

    // For a savings account (new or existing), balance is always 0
    final isSavings = _selectedType == AccountType.savings;
    _balanceController = TextEditingController(
      text: isSavings
          ? ''
          : (widget.account != null
                ? NumberFormat('#,##0').format(widget.account!.initialBalance)
                : ''),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.account != null;
    final isSavings = _selectedType == AccountType.savings;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                isEditing ? AppStrings.editAccount : AppStrings.addAccount,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // ── Account name ──
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppStrings.accountName,
                  hintText: AppStrings.accountNameHint,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),

              // ── Initial balance — hidden for savings ──
              if (!isSavings) ...[
                Material(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.initialBalance,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _balanceController,
                          keyboardType: TextInputType.number,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.3),
                            ),
                            prefixText: '${widget.selectedSymbol} ',
                            prefixStyle: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ThousandsSeparatorInputFormatter(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                // Savings notice
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(
                      0.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.savingsAccountInfo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Account type chips ──
              Text(
                AppStrings.accountType,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AccountType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return FilterChip(
                    label: Text(type.toString().split('.').last.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedType = type;
                          _selectedIcon = _typeIcons[type]!;
                          // Clear balance when switching to savings
                          if (type == AccountType.savings) {
                            _balanceController.text = '';
                          }
                        });
                      }
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.secondaryContainer,
                    checkmarkColor: theme.colorScheme.onSecondaryContainer,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Color picker ──
              Text(
                AppStrings.color,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Actions ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        if (_nameController.text.isEmpty) return;
                        // Non-savings accounts require a balance entry
                        if (!isSavings && _balanceController.text.isEmpty)
                          return;

                        final initialBalance = isSavings
                            ? 0.0
                            : double.parse(
                                _balanceController.text.replaceAll(',', ''),
                              );

                        widget.onSave(
                          Account(
                            id:
                                widget.account?.id ??
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            name: _nameController.text,
                            type: _selectedType,
                            initialBalance: initialBalance,
                            icon: _selectedIcon,
                            color: _selectedColor,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEditing ? AppStrings.update : AppStrings.addAccount,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class DatePage extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const DatePage({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    AppStrings.init(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.budgetPeriod,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.whenShouldBudgetEnd,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 60),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    color: selectedDate != null
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.5,
                          ),
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedDate ??
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          onDateSelected(date);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: selectedDate != null
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.endDate,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: selectedDate != null
                                        ? theme.colorScheme.onSecondaryContainer
                                              .withOpacity(0.7)
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedDate == null
                                      ? AppStrings.selectDate
                                      : DateFormat(
                                          'EEEE, MMM d, y',
                                        ).format(selectedDate!),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: selectedDate != null
                                        ? theme.colorScheme.onSecondaryContainer
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (selectedDate != null) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 20,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.format(AppStrings.daysFromNow, [
                                selectedDate!
                                    .difference(DateTime.now())
                                    .inDays
                                    .toString(),
                              ]),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
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
          ),
        ],
      ),
    );
  }
}
