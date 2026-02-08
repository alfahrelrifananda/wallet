import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import 'package:wallet/model.dart';
import 'package:wallet/constants/app_strings.dart';

class OverviewTab extends StatelessWidget {
  final String currency;
  final String currencySymbol;
  final double totalBudget;
  final DateTime finalDate;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<Category> categories;
  final VoidCallback onNavigateToAccounts;
  final VoidCallback onNavigateToTransactions;
  final Function(String) onDeleteTransaction;
  final Function(Transaction) onUpdateTransaction;
  final Function(DateTime)? onUpdateFinalDate;
  final DateTime? debugCurrentDate;
  final Function(DateTime)? onDebugDateChange;

  const OverviewTab({
    super.key,
    required this.currency,
    required this.currencySymbol,
    required this.totalBudget,
    required this.finalDate,
    required this.transactions,
    required this.accounts,
    required this.categories,
    required this.onNavigateToAccounts,
    required this.onNavigateToTransactions,
    required this.onDeleteTransaction,
    required this.onUpdateTransaction,
    this.onUpdateFinalDate,
    this.debugCurrentDate,
    this.onDebugDateChange,
  });

  Category _getCategoryById(String categoryId) {
    try {
      return categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return Category(
        id: 'unknown',
        name: AppStrings.unknownCategory,
        icon: Icons.help_outline,
        color: Colors.grey,
        isExpense: true,
      );
    }
  }

  bool _isTransferTransaction(Transaction transaction) {
    final category = _getCategoryById(transaction.categoryId);
    return category.name == 'Transfer';
  }

  double get _currentBalance {
    double balance = totalBudget;
    for (var t in transactions) {
      balance += t.isIncome ? t.amount : -t.amount;
    }
    return balance;
  }

  // Calculate balance at the start of today (before today's transactions)
  double get _balanceAtStartOfDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    double balance = totalBudget;
    for (var t in transactions) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      // Only include transactions BEFORE today
      if (tDate.isBefore(today)) {
        balance += t.isIncome ? t.amount : -t.amount;
      }
    }
    return balance;
  }

  double get _todaySpent {
    final today = DateTime.now();
    final transferCategoryId = categories
        .firstWhere((c) => c.name == 'Transfer')
        .id;

    return transactions
        .where(
          (t) =>
              !t.isIncome &&
              t.categoryId != transferCategoryId &&
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // NEW: Check if date has passed
  bool get _isPastFinalDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final finalDay = DateTime(finalDate.year, finalDate.month, finalDate.day);
    return today.isAfter(finalDay);
  }

  int get _daysLeft {
    if (_isPastFinalDate) return 0;
    return finalDate.difference(DateTime.now()).inDays.clamp(1, 999999);
  }

  // FIXED: Use balance at start of day instead of current balance
  double get _baseDailyAllowance {
    if (_isPastFinalDate) return 0; // NEW: No allowance if date passed
    return _daysLeft > 0 ? _balanceAtStartOfDay / _daysLeft : 0;
  }

  double get _todayIncome {
    final today = DateTime.now();
    final transferCategoryId = categories
        .firstWhere((c) => c.name == 'Transfer')
        .id;

    return transactions
        .where(
          (t) =>
              t.isIncome &&
              t.categoryId != transferCategoryId &&
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // NEW: Calculate accumulated surplus from all previous days
  double get _totalSurplusBeforeToday {
    if (transactions.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final transactionsBeforeToday = transactions.where((t) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      return tDate.isBefore(today);
    });

    if (transactionsBeforeToday.isEmpty) return 0;

    final earliestTransaction = transactionsBeforeToday
        .reduce((a, b) => a.date.isBefore(b.date) ? a : b)
        .date;

    final startDate = DateTime(
      earliestTransaction.year,
      earliestTransaction.month,
      earliestTransaction.day,
    );

    final transferCategoryId = categories
        .firstWhere((c) => c.name == 'Transfer')
        .id;

    double totalSurplus = 0;
    DateTime checkDate = startDate;

    while (checkDate.isBefore(today)) {
      final dayTransactions = transactions.where((t) {
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        return tDate.isAtSameMomentAs(checkDate);
      });

      final daySpent = dayTransactions
          .where((t) => !t.isIncome && t.categoryId != transferCategoryId)
          .fold(0.0, (sum, t) => sum + t.amount);

      final dayIncome = dayTransactions
          .where((t) => t.isIncome && t.categoryId != transferCategoryId)
          .fold(0.0, (sum, t) => sum + t.amount);

      // Calculate what the daily allowance was on that specific day
      final daysLeftAtThatTime = finalDate
          .difference(checkDate)
          .inDays
          .clamp(1, 999999);

      // Calculate balance at the start of that day
      final transactionsBeforeThatDay = transactions.where((t) {
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        return tDate.isBefore(checkDate);
      });

      double balanceAtStartOfThatDay = totalBudget;
      for (var t in transactionsBeforeThatDay) {
        balanceAtStartOfThatDay += t.isIncome ? t.amount : -t.amount;
      }

      final dayAllowance = daysLeftAtThatTime > 0
          ? balanceAtStartOfThatDay / daysLeftAtThatTime
          : 0;

      final daySavings = dayAllowance + dayIncome - daySpent;

      totalSurplus += daySavings;

      // Reset surplus to 0 if it goes negative (can't carry over debt)
      if (totalSurplus < 0) {
        totalSurplus = 0;
      }

      checkDate = checkDate.add(const Duration(days: 1));
    }

    return totalSurplus;
  }

  double get _rolloverAmount {
    if (_isPastFinalDate) return 0; // NEW
    final total = _totalSurplusBeforeToday;
    if (total < 0) return 0;
    return total.clamp(0, _baseDailyAllowance);
  }

  double get _distributedExcess {
    if (_daysLeft <= 1 || _isPastFinalDate) return 0; // NEW

    // Only distribute if we have EXTRA savings beyond rollover cap
    final total = _totalSurplusBeforeToday;
    if (total <= 0) return 0; // No surplus at all

    // Calculate excess only if surplus exceeds the rollover cap
    final excess = total - _baseDailyAllowance;

    // Only distribute positive excess (true savings beyond cap)
    return excess > 0 ? excess / (_daysLeft - 1) : 0;
  }

  double get _dailyAllowanceWithRollover =>
      _baseDailyAllowance + _rolloverAmount + _distributedExcess;

  Widget _buildDailySpendingFocusCard(ThemeData theme, BuildContext context) {
    // Handle past final date
    if (_isPastFinalDate) {
      return GestureDetector(
        onTap: () => _showBudgetExplanationBottomSheet(context, theme),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: _currentBalance >= 0
                ? Colors.blue.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Period Ended',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatCurrency(_currentBalance),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentBalance >= 0
                      ? AppStrings.stayedWithinBudget
                      : AppStrings.overspent,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final remainingBudget =
        _dailyAllowanceWithRollover + _todayIncome - _todaySpent;
    final isOverBudget = remainingBudget < 0;

    return GestureDetector(
      onTap: () => _showBudgetExplanationBottomSheet(context, theme),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isOverBudget
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.todaysBudgetRemaining,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _formatCurrency(remainingBudget),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetExplanationBottomSheet(
    BuildContext context,
    ThemeData theme,
  ) {
    final remainingBudget =
        _dailyAllowanceWithRollover + _todayIncome - _todaySpent;
    final isOverBudget = remainingBudget < 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.budgetBreakdown,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isPastFinalDate) ...[
                      _buildExplanationRow(
                        theme,
                        AppStrings.baseDailyAllowance,
                        _baseDailyAllowance,
                        Icons.calendar_today,
                        theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      _buildExplanationRow(
                        theme,
                        AppStrings.rolloverFromPreviousDays,
                        _rolloverAmount,
                        Icons.trending_up,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildExplanationRow(
                        theme,
                        AppStrings.todaysIncome,
                        _todayIncome,
                        Icons.add_circle,
                        Colors.teal,
                      ),
                      const SizedBox(height: 12),
                      _buildExplanationRow(
                        theme,
                        AppStrings.todaysSpending,
                        -_todaySpent,
                        Icons.remove_circle,
                        Colors.red,
                      ),
                      const Divider(height: 24),
                      _buildExplanationRow(
                        theme,
                        AppStrings.remainingBudget,
                        remainingBudget,
                        Icons.account_balance_wallet,
                        isOverBudget ? Colors.red : Colors.green,
                        isBold: true,
                      ),
                    ] else ...[
                      _buildExplanationRow(
                        theme,
                        AppStrings.finalBalance,
                        _currentBalance,
                        Icons.account_balance_wallet,
                        _currentBalance >= 0 ? Colors.green : Colors.red,
                        isBold: true,
                      ),
                      const SizedBox(height: 12),
                      _buildExplanationRow(
                        theme,
                        AppStrings.startingBudget,
                        totalBudget,
                        Icons.monetization_on,
                        theme.colorScheme.primary,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isPastFinalDate
                                    ? AppStrings.periodSummary
                                    : AppStrings.howItWorks,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isPastFinalDate
                                ? (_currentBalance >= 0
                                      ? AppStrings.periodEndedSuccess
                                      : AppStrings.periodEndedOverspent)
                                : AppStrings.budgetExplanationText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationRow(
    ThemeData theme,
    String label,
    double amount,
    IconData icon,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: amount < 0 ? Colors.red : color,
          ),
        ),
      ],
    );
  }

  double _getAccountBalance(String accountId) {
    final account = accounts.firstWhere((a) => a.id == accountId);
    double balance = account.initialBalance;
    for (var t in transactions.where((t) => t.accountId == accountId)) {
      balance += t.isIncome ? t.amount : -t.amount;
    }
    return balance;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
      locale: currency == 'IDR' ? 'id_ID' : 'en_US',
    );
    return formatter.format(amount);
  }

  // NEW: Show date picker dialog
  void _showDatePickerDialog(BuildContext context, ThemeData theme) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: finalDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
      builder: (context, child) {
        return Theme(data: theme, child: child!);
      },
    );

    if (picked != null && picked != finalDate && onUpdateFinalDate != null) {
      onUpdateFinalDate!(picked);
    }
  }

  void _showTransactionOptionsDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                  title: Text(AppStrings.editTransaction),
                  onTap: () {
                    Navigator.pop(context);
                    // You'll need to implement this method similar to the transactions tab
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: theme.colorScheme.error),
                  title: Text(AppStrings.deleteTransaction),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(context, transaction);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: Text(AppStrings.cancel),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    final theme = Theme.of(context);
    final category = _getCategoryById(transaction.categoryId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deleteTransaction),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.deleteTransactionConfirm),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(category.icon, color: category.color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, y').format(transaction.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatCurrency(transaction.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: transaction.isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              onDeleteTransaction(transaction.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.transactionDeleted),
                  duration: const Duration(seconds: 2),
                ),
              );
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
    AppStrings.init(context);
    final theme = Theme.of(context);
    final sortedTransactions = transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final latestTransactions = sortedTransactions.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildBalanceGraphCard(theme, context),
        const SizedBox(height: 16),
        _buildDailySpendingFocusCard(theme, context),
        const SizedBox(height: 24),
        _buildAccountsOverviewCard(theme),
        const SizedBox(height: 24),

        // Transaction list header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.transactions,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onNavigateToTransactions,
              child: Text(AppStrings.viewAll),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Transactions list (latest 5)
        if (latestTransactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noTransactionsInPeriod,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...latestTransactions.map((transaction) {
            final category = _getCategoryById(transaction.categoryId);
            final account = accounts.firstWhere(
              (a) => a.id == transaction.accountId,
            );
            final isTransfer = _isTransferTransaction(transaction);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surface,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      _showTransactionOptionsDialog(context, transaction),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isTransfer
                                  ? theme.colorScheme.primary
                                  : category.color,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isTransfer ? Icons.swap_horiz : category.icon,
                            color: isTransfer
                                ? theme.colorScheme.primary
                                : category.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTransfer
                                    ? AppStrings.transfer
                                    : category.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    account.icon,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    account.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (transaction.note.isNotEmpty) ...[
                                    const Text(' • '),
                                    Flexible(
                                      child: Text(
                                        transaction.note,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                DateFormat('MMM d, y').format(transaction.date),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${transaction.isIncome ? '+' : '-'}${_formatCurrency(transaction.amount)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isTransfer
                                ? theme.colorScheme.primary
                                : (transaction.isIncome
                                      ? Colors.green
                                      : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildBalanceGraphCard(ThemeData theme, BuildContext context) {
    final progress = totalBudget > 0
        ? (_currentBalance / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        color: theme.colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.currentBalance,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                InkWell(
                  onTap: onUpdateFinalDate != null
                      ? () {
                          _showDatePickerDialog(context, theme);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _isPastFinalDate
                          ? theme.colorScheme.errorContainer.withOpacity(0.5)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPastFinalDate
                              ? Icons.event_busy_rounded
                              : Icons.calendar_today_rounded,
                          size: 16,
                          color: _isPastFinalDate
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPastFinalDate
                              ? 'Ended • ${DateFormat('MMM d').format(finalDate)}'
                              : '$_daysLeft ${_daysLeft == 1 ? AppStrings.day : AppStrings.days} • ${DateFormat('MMM d').format(finalDate)}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _isPastFinalDate
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _formatCurrency(_currentBalance),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.format(AppStrings.ofBudget, [
                _formatCurrency(totalBudget),
              ]),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsOverviewCard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.accounts,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onNavigateToAccounts,
              child: Text(AppStrings.viewAll),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...accounts.take(3).map((account) {
          final balance = _getAccountBalance(account.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: account.color, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(account.icon, color: account.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            account.type
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(balance),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
