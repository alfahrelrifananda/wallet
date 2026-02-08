import 'dart:ui';
import 'package:wallet/tab/accounts.dart';
import 'package:wallet/tab/overview.dart';
import 'package:wallet/tab/settings.dart';
import 'package:wallet/tab/transactions.dart';
import 'package:wallet/utils/input_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet/model.dart';
import 'package:wallet/constants/app_strings.dart';

class HomeScreen extends StatefulWidget {
  final String currency;
  final String currencySymbol;
  final double totalBudget;
  final DateTime finalDate;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<Category> categories;
  final Function(Transaction) onAddTransaction;
  final Function(Account) onAddAccount;
  final Function(String) onDeleteTransaction;
  final Function(String) onDeleteAccount;
  final Function(Transaction) onUpdateTransaction;
  final Function(Category) onAddCategory;
  final Function(Category) onUpdateCategory;
  final Function(String) onDeleteCategory;
  final VoidCallback onReset;
  final Future<String> Function() onExportData;
  final Future<void> Function(String) onImportData;
  final bool? biometricEnabled;
  final Function(bool)? onBiometricChanged;
  final Function(DateTime)? onUpdateFinalDate;
  final DateTime? debugCurrentDate;
  final Function(DateTime)? onDebugDateChange;

  const HomeScreen({
    super.key,
    required this.currency,
    required this.currencySymbol,
    required this.totalBudget,
    required this.finalDate,
    required this.transactions,
    required this.accounts,
    required this.categories,
    required this.onAddTransaction,
    required this.onAddAccount,
    required this.onDeleteTransaction,
    required this.onDeleteAccount,
    required this.onUpdateTransaction,
    required this.onAddCategory,
    required this.onUpdateCategory,
    required this.onDeleteCategory,
    required this.onReset,
    required this.onExportData,
    required this.onImportData,
    this.biometricEnabled,
    this.onBiometricChanged,
    this.onUpdateFinalDate,
    this.debugCurrentDate,
    this.onDebugDateChange,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  late PageController _pageController;
  bool _isFabExtended = true;
  double _lastScrollOffset = 0;
  static const double _scrollThreshold = 10.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _navIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onVerticalScroll(bool shouldExtend) {
    if (_isFabExtended != shouldExtend) {
      setState(() {
        _isFabExtended = shouldExtend;
      });
    }
  }

  String get _currentTitle {
    switch (_navIndex) {
      case 0:
        return AppStrings.overview;
      case 1:
        return AppStrings.accounts;
      case 2:
        return AppStrings.transactions;
      case 3:
        return AppStrings.settings;
      default:
        return AppStrings.appName;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkFinalDate();
  }

  void _checkFinalDate() {
    final now = DateTime.now();
    final finalDate = widget.finalDate;
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(finalDate.year, finalDate.month, finalDate.day);

    if (today.isAfter(deadline)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDateExpiredDialog();
      });
    }
  }

  void _showDateExpiredDialog() {
    final formattedDate =
        '${widget.finalDate.day}/${widget.finalDate.month}/${widget.finalDate.year}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          icon: Icon(
            Icons.calendar_today_outlined,
            color: Theme.of(context).colorScheme.error,
            size: 48,
          ),
          title: Text(AppStrings.budgetPeriodEnded),
          content: Text(
            AppStrings.format(AppStrings.budgetEndedOn, [formattedDate]),
          ),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: Text(AppStrings.exitApp),
            ),
            FilledButton(
              onPressed: () => _showUpdateDateDialog(context),
              child: Text(AppStrings.setNewDate),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateDateDialog(BuildContext dialogContext) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (context, setState) {
            final formattedSelected =
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';

            return AlertDialog(
              title: Text(AppStrings.setNewEndDate),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${AppStrings.selected}: $formattedSelected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Text(AppStrings.chooseDate),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    widget.onUpdateFinalDate?.call(selectedDate);
                    Navigator.pop(context);
                    Navigator.pop(dialogContext);
                  },
                  child: Text(AppStrings.confirm),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() => _navIndex = index);
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    AppStrings.init(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _currentTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                expandedTitleScale: 1.5,
              ),
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ];
        },
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  final currentOffset = notification.metrics.pixels;
                  final delta = currentOffset - _lastScrollOffset;

                  if (delta.abs() > _scrollThreshold) {
                    final shouldExtend = delta < 0;
                    _onVerticalScroll(shouldExtend);
                    _lastScrollOffset = currentOffset;
                  }
                }
                return false;
              },
              child: OverviewTab(
                currency: widget.currency,
                currencySymbol: widget.currencySymbol,
                totalBudget: widget.totalBudget,
                finalDate: widget.finalDate,
                transactions: widget.transactions,
                accounts: widget.accounts,
                categories: widget.categories,
                onNavigateToAccounts: () => _onNavTapped(1),
                onNavigateToTransactions: () => _onNavTapped(2),
                onDeleteTransaction: widget.onDeleteTransaction,
                onUpdateTransaction: widget.onUpdateTransaction,
                onUpdateFinalDate: widget.onUpdateFinalDate,
                debugCurrentDate: widget.debugCurrentDate,
                onDebugDateChange: widget.onDebugDateChange,
              ),
            ),
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  final currentOffset = notification.metrics.pixels;
                  final delta = currentOffset - _lastScrollOffset;

                  if (delta.abs() > _scrollThreshold) {
                    final shouldExtend = delta < 0;
                    _onVerticalScroll(shouldExtend);
                    _lastScrollOffset = currentOffset;
                  }
                }
                return false;
              },
              child: AccountsTab(
                currency: widget.currency,
                currencySymbol: widget.currencySymbol,
                transactions: widget.transactions,
                accounts: widget.accounts,
                onAddAccount: widget.onAddAccount,
                onDeleteAccount: widget.onDeleteAccount,
              ),
            ),
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  final currentOffset = notification.metrics.pixels;
                  final delta = currentOffset - _lastScrollOffset;

                  if (delta.abs() > _scrollThreshold) {
                    final shouldExtend = delta < 0;
                    _onVerticalScroll(shouldExtend);
                    _lastScrollOffset = currentOffset;
                  }
                }
                return false;
              },
              child: TransactionsTab(
                currency: widget.currency,
                currencySymbol: widget.currencySymbol,
                transactions: widget.transactions,
                accounts: widget.accounts,
                categories: widget.categories,
                onDeleteTransaction: widget.onDeleteTransaction,
                onUpdateTransaction: widget.onUpdateTransaction,
              ),
            ),
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  final currentOffset = notification.metrics.pixels;
                  final delta = currentOffset - _lastScrollOffset;

                  if (delta.abs() > _scrollThreshold) {
                    final shouldExtend = delta < 0;
                    _onVerticalScroll(shouldExtend);
                    _lastScrollOffset = currentOffset;
                  }
                }
                return false;
              },
              child: SettingsTab(
                onExportData: widget.onExportData,
                onImportData: (jsonData) async =>
                    await widget.onImportData(jsonData),
                onReset: widget.onReset,
                biometricEnabled: widget.biometricEnabled,
                onBiometricChanged: widget.onBiometricChanged,
                categories: widget.categories,
                onAddCategory: widget.onAddCategory,
                onUpdateCategory: widget.onUpdateCategory,
                onDeleteCategory: widget.onDeleteCategory,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context),
        icon: const Icon(Icons.add),
        label: Text(AppStrings.addTransaction),
        isExtended: _isFabExtended,
      ),
      extendBody: true,
      bottomNavigationBar: CustomFloatingNavBar(
        currentIndex: _navIndex,
        onTap: _onNavTapped,
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final amountController = TextEditingController();

    String transactionType = 'expense';
    Account selectedAccount = widget.accounts.first;
    Account? selectedToAccount = widget.accounts.length > 1
        ? widget.accounts[1]
        : null;
    Category selectedCategory = widget.categories.firstWhere(
      (c) => c.isExpense,
    );

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
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
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.4,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    AppStrings.addTransaction,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'expense',
                        label: Text(AppStrings.expense),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      ButtonSegment(
                        value: 'income',
                        label: Text(AppStrings.income),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      ButtonSegment(
                        value: 'transfer',
                        label: Text(AppStrings.transfer),
                        icon: const Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {transactionType},
                    onSelectionChanged: (v) {
                      setDialogState(() {
                        transactionType = v.first;
                        if (transactionType != 'transfer') {
                          selectedCategory = widget.categories.firstWhere(
                            (c) => c.isExpense != (transactionType == 'income'),
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.amount,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: amountController,
                          autofocus: true,
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
                            prefixText: '${widget.currencySymbol} ',
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
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transactionType == 'transfer'
                            ? AppStrings.fromAccount
                            : AppStrings.account,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.accounts.map((account) {
                          final isSelected = selectedAccount.id == account.id;
                          return FilterChip(
                            selected: isSelected,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  account.icon,
                                  size: 16,
                                  color: isSelected
                                      ? theme.colorScheme.onSecondaryContainer
                                      : account.color,
                                ),
                                const SizedBox(width: 6),
                                Text(account.name),
                              ],
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => selectedAccount = account);
                              }
                            },
                            backgroundColor: theme.colorScheme.surface,
                            selectedColor: theme.colorScheme.secondaryContainer,
                            checkmarkColor:
                                theme.colorScheme.onSecondaryContainer,
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.secondary
                                  : account.color.withOpacity(0.5),
                              width: isSelected ? 2 : 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  if (transactionType == 'transfer') ...[
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.toAccount,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.accounts
                              .where((a) => a.id != selectedAccount.id)
                              .map((account) {
                                final isSelected =
                                    selectedToAccount?.id == account.id;
                                return FilterChip(
                                  selected: isSelected,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        account.icon,
                                        size: 16,
                                        color: isSelected
                                            ? theme
                                                  .colorScheme
                                                  .onSecondaryContainer
                                            : account.color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(account.name),
                                    ],
                                  ),
                                  onSelected: (selected) {
                                    setDialogState(() {
                                      selectedToAccount = selected
                                          ? account
                                          : null;
                                    });
                                  },
                                  backgroundColor: theme.colorScheme.surface,
                                  selectedColor:
                                      theme.colorScheme.secondaryContainer,
                                  checkmarkColor:
                                      theme.colorScheme.onSecondaryContainer,
                                  side: BorderSide(
                                    color: isSelected
                                        ? theme.colorScheme.secondary
                                        : account.color.withOpacity(0.5),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                  if (transactionType != 'transfer') ...[
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.category,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.categories
                              .where(
                                (c) =>
                                    c.isExpense !=
                                        (transactionType == 'income') &&
                                    c.name != 'Transfer',
                              )
                              .map((category) {
                                final isSelected =
                                    selectedCategory.id == category.id;
                                return FilterChip(
                                  selected: isSelected,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        category.icon,
                                        size: 16,
                                        color: isSelected
                                            ? theme
                                                  .colorScheme
                                                  .onSecondaryContainer
                                            : category.color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(category.name),
                                    ],
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(
                                        () => selectedCategory = category,
                                      );
                                    }
                                  },
                                  backgroundColor: theme.colorScheme.surface,
                                  selectedColor:
                                      theme.colorScheme.secondaryContainer,
                                  checkmarkColor:
                                      theme.colorScheme.onSecondaryContainer,
                                  side: BorderSide(
                                    color: isSelected
                                        ? theme.colorScheme.secondary
                                        : category.color.withOpacity(0.5),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
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
                            final clean = amountController.text.replaceAll(
                              ',',
                              '',
                            );
                            if (clean.isEmpty) return;

                            if (transactionType == 'transfer') {
                              if (selectedToAccount == null) return;

                              final now = DateTime.now();
                              final transferId = now.millisecondsSinceEpoch
                                  .toString();

                              widget.onAddTransaction(
                                Transaction(
                                  id: '${transferId}_out',
                                  amount: double.parse(clean),
                                  isIncome: false,
                                  date: now,
                                  accountId: selectedAccount.id,
                                  categoryId: widget.categories
                                      .firstWhere((c) => c.name == 'Transfer')
                                      .id,
                                  note: AppStrings.format(
                                    AppStrings.transferToAccount,
                                    [selectedToAccount!.name],
                                  ),
                                ),
                              );

                              widget.onAddTransaction(
                                Transaction(
                                  id: '${transferId}_in',
                                  amount: double.parse(clean),
                                  isIncome: true,
                                  date: now,
                                  accountId: selectedToAccount!.id,
                                  categoryId: widget.categories
                                      .firstWhere((c) => c.name == 'Transfer')
                                      .id,
                                  note: AppStrings.format(
                                    AppStrings.transferFromAccount,
                                    [selectedAccount.name],
                                  ),
                                ),
                              );
                            } else {
                              widget.onAddTransaction(
                                Transaction(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  amount: double.parse(clean),
                                  isIncome: transactionType == 'income',
                                  date: DateTime.now(),
                                  accountId: selectedAccount.id,
                                  categoryId: selectedCategory.id,
                                  note: '',
                                ),
                              );
                            }

                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(AppStrings.addTransaction),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withOpacity(0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              isSelected ? selectedIcon : icon,
              key: ValueKey(isSelected),
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  selectedIcon: Icons.account_balance_wallet,
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
