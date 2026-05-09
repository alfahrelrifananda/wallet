import 'package:wallet/utils/input_formatters.dart';
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';
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

  bool _isSavingsAccount(Transaction transaction) {
    try {
      final account = accounts.firstWhere((a) => a.id == transaction.accountId);
      return account.type == AccountType.savings;
    } catch (_) {
      return false;
    }
  }

  bool _isIncomingFromSavings(Transaction t) {
    if (!_isTransferTransaction(t)) return false;
    if (!t.isIncome) return false;
    if (_isSavingsAccount(t)) return false;
    final baseId = t.id.replaceAll('_in', '');
    final pairedOut = transactions.where(
      (other) => other.id == '${baseId}_out' && _isSavingsAccount(other),
    );
    return pairedOut.isNotEmpty;
  }

  /// The single source of truth for whether a transaction affects the budget.
  ///
  /// Rules:
  ///   - Skip everything whose account is a savings account.
  ///   - For transfer transactions on a normal account:
  ///       • normal→savings _out (isIncome=false): COUNT as expense ✓
  ///       • normal→savings _in  (isIncome=true) : COUNT as income  ✓  (handled by _isIncomingFromSavings)
  ///       • normal→normal either leg            : SKIP              ✗
  bool _shouldCountForBudget(Transaction t) {
    // 1. Always ignore anything sitting on a savings account.
    if (_isSavingsAccount(t)) return false;

    // 2. Only transfer transactions need further inspection.
    if (!_isTransferTransaction(t)) return true;

    // 3. Incoming leg from savings → count as income.
    if (_isIncomingFromSavings(t)) return true;

    // 4. Outgoing leg — figure out where it goes.
    //    Strip suffix to find the paired _in leg.
    final baseId = t.id.replaceAll('_out', '').replaceAll('_in', '');
    final pairedIn = transactions.firstWhere(
      (other) => other.id == '${baseId}_in',
      orElse: () => t, // fallback: treat as same transaction
    );
    final destinationIsSavings = _isSavingsAccount(pairedIn);

    // normal→savings _out: count as expense.
    if (destinationIsSavings) return true;

    // normal→normal (either leg): skip.
    return false;
  }

  // ── Balance helpers ────────────────────────────────────────────────────────

  double get _currentBalance {
    double balance = totalBudget;
    for (var t in transactions) {
      if (!_shouldCountForBudget(t)) continue;
      balance += t.isIncome ? t.amount : -t.amount;
    }
    return balance;
  }

  double get _balanceAtStartOfDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    double balance = totalBudget;
    for (var t in transactions) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      if (!tDate.isBefore(today)) continue;
      if (!_shouldCountForBudget(t)) continue;
      balance += t.isIncome ? t.amount : -t.amount;
    }
    return balance;
  }

  double get _todaySpent {
    final today = DateTime.now();
    return transactions
        .where(
          (t) =>
              !t.isIncome &&
              _shouldCountForBudget(t) &&
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _todayIncome {
    final today = DateTime.now();
    return transactions
        .where(
          (t) =>
              t.isIncome &&
              _shouldCountForBudget(t) &&
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // ── Date / allowance helpers ───────────────────────────────────────────────

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

  double get _baseDailyAllowance {
    if (_isPastFinalDate) return 0;
    return _daysLeft > 0 ? _balanceAtStartOfDay / _daysLeft : 0;
  }

  // ── Surplus / rollover ─────────────────────────────────────────────────────

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

    double totalSurplus = 0;
    DateTime checkDate = startDate;

    while (checkDate.isBefore(today)) {
      final dayTransactions = transactions.where((t) {
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        return tDate.isAtSameMomentAs(checkDate);
      });

      final daySpent = dayTransactions
          .where((t) => !t.isIncome && _shouldCountForBudget(t))
          .fold(0.0, (sum, t) => sum + t.amount);

      final dayIncome = dayTransactions
          .where((t) => t.isIncome && _shouldCountForBudget(t))
          .fold(0.0, (sum, t) => sum + t.amount);

      final daysLeftAtThatTime = finalDate
          .difference(checkDate)
          .inDays
          .clamp(1, 999999);

      final transactionsBeforeThatDay = transactions.where((t) {
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        return tDate.isBefore(checkDate);
      });

      double balanceAtStartOfThatDay = totalBudget;
      for (var t in transactionsBeforeThatDay) {
        if (!_shouldCountForBudget(t)) continue;
        balanceAtStartOfThatDay += t.isIncome ? t.amount : -t.amount;
      }

      final dayAllowance = daysLeftAtThatTime > 0
          ? balanceAtStartOfThatDay / daysLeftAtThatTime
          : 0;
      final daySavings = dayAllowance + dayIncome - daySpent;
      totalSurplus += daySavings;
      if (totalSurplus < 0) totalSurplus = 0;

      checkDate = checkDate.add(const Duration(days: 1));
    }
    return totalSurplus;
  }

  double get _rolloverAmount {
    if (_isPastFinalDate) return 0;
    final total = _totalSurplusBeforeToday;
    if (total < 0) return 0;
    return total.clamp(0, _baseDailyAllowance);
  }

  double get _distributedExcess {
    if (_daysLeft <= 1 || _isPastFinalDate) return 0;
    final total = _totalSurplusBeforeToday;
    if (total <= 0) return 0;
    final excess = total - _baseDailyAllowance;
    return excess > 0 ? excess / (_daysLeft - 1) : 0;
  }

  double get _dailyAllowanceWithRollover =>
      _baseDailyAllowance + _rolloverAmount + _distributedExcess;

  // ── Misc helpers ───────────────────────────────────────────────────────────

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

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showDatePickerDialog(BuildContext context, ThemeData theme) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: finalDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(data: theme, child: child!),
    );
    if (picked != null && picked != finalDate && onUpdateFinalDate != null) {
      onUpdateFinalDate!(picked);
    }
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
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
              const Divider(height: 1),
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
                          borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(10),
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
                    _showEditTransactionDialog(context, transaction);
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

  void _showEditTransactionDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    final amountController = TextEditingController(
      text: transaction.amount
          .toStringAsFixed(0)
          .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ','),
    );
    final noteController = TextEditingController(text: transaction.note);

    bool isTransfer = _isTransferTransaction(transaction);
    String transactionType = isTransfer
        ? 'transfer'
        : (transaction.isIncome ? 'income' : 'expense');
    Account selectedAccount = accounts.firstWhere(
      (a) => a.id == transaction.accountId,
    );
    Account? selectedToAccount;
    Category selectedCategory = _getCategoryById(transaction.categoryId);
    DateTime selectedDate = transaction.date;

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
                    AppStrings.editTransaction,
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
                          selectedCategory = categories.firstWhere(
                            (c) => c.isExpense != (transactionType == 'income'),
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  Material(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.amount,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amountController,
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
                              prefixText: '${currencySymbol} ',
                              prefixStyle: theme.textTheme.displaySmall
                                  ?.copyWith(
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

                  _buildAccountSelector(
                    theme,
                    transactionType,
                    selectedAccount,
                    setDialogState,
                    (account) => selectedAccount = account,
                  ),

                  if (transactionType == 'transfer') ...[
                    const SizedBox(height: 24),
                    _buildToAccountSelector(
                      theme,
                      selectedAccount,
                      selectedToAccount,
                      setDialogState,
                      (a) => selectedToAccount = a,
                    ),
                  ],

                  if (transactionType != 'transfer') ...[
                    const SizedBox(height: 24),
                    _buildCategorySelector(
                      theme,
                      transactionType,
                      selectedCategory,
                      setDialogState,
                      (category) => selectedCategory = category,
                    ),
                  ],
                  const SizedBox(height: 24),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.date,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat(
                                    'EEEE, MMM d, y',
                                  ).format(selectedDate),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: AppStrings.noteOptional,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.note_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    maxLines: 2,
                  ),
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
                            final transferCategory = categories.firstWhere(
                              (c) => c.name == 'Transfer',
                            );
                            if (clean.isEmpty) return;
                            onUpdateTransaction(
                              Transaction(
                                id: transaction.id,
                                amount: double.parse(clean),
                                isIncome: transactionType == 'income',
                                date: selectedDate,
                                accountId: selectedAccount.id,
                                categoryId: transactionType == 'transfer'
                                    ? transferCategory.id
                                    : selectedCategory.id,
                                note: noteController.text,
                              ),
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppStrings.transactionUpdated),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(AppStrings.saveChanges),
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

  // ── Chip selectors ────────────────────────────────────────────────────────

  Widget _buildAccountSelector(
    ThemeData theme,
    String transactionType,
    Account selectedAccount,
    StateSetter setDialogState,
    Function(Account) onChanged,
  ) {
    return Column(
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
          children: accounts.map((account) {
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
              onSelected: (s) {
                if (s) setDialogState(() => onChanged(account));
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.secondaryContainer,
              checkmarkColor: theme.colorScheme.onSecondaryContainer,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildToAccountSelector(
    ThemeData theme,
    Account selectedAccount,
    Account? selectedToAccount,
    StateSetter setDialogState,
    Function(Account?) onChanged,
  ) {
    return Column(
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
          children: accounts.where((a) => a.id != selectedAccount.id).map((
            account,
          ) {
            final isSelected = selectedToAccount?.id == account.id;
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
              onSelected: (s) {
                setDialogState(() => onChanged(s ? account : null));
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.secondaryContainer,
              checkmarkColor: theme.colorScheme.onSecondaryContainer,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
    ThemeData theme,
    String transactionType,
    Category selectedCategory,
    StateSetter setDialogState,
    Function(Category) onChanged,
  ) {
    return Column(
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
          children: categories
              .where(
                (c) =>
                    c.isExpense != (transactionType == 'income') &&
                    c.name != 'Transfer',
              )
              .map((category) {
                final isSelected = selectedCategory.id == category.id;
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        size: 16,
                        color: isSelected
                            ? theme.colorScheme.onSecondaryContainer
                            : category.color,
                      ),
                      const SizedBox(width: 6),
                      Text(category.name),
                    ],
                  ),
                  onSelected: (s) {
                    if (s) setDialogState(() => onChanged(category));
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
              })
              .toList(),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    AppStrings.init(context);
    final theme = Theme.of(context);
    final sortedTransactions = transactions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final latestTransactions = sortedTransactions.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      children: [
        _buildBalanceHeader(theme, context),
        const SizedBox(height: 8),
        _buildDailySpendingCard(theme, context),
        const SizedBox(height: 20),
        _buildSectionHeader(
          theme,
          AppStrings.accounts,
          AppStrings.viewAll,
          onNavigateToAccounts,
        ),
        const SizedBox(height: 8),
        _buildAccountsList(theme),
        const SizedBox(height: 20),
        _buildSectionHeader(
          theme,
          AppStrings.transactions,
          AppStrings.viewAll,
          onNavigateToTransactions,
        ),
        const SizedBox(height: 8),
        _buildTransactionsList(theme, context, latestTransactions),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildBalanceHeader(ThemeData theme, BuildContext context) {
    final progress = totalBudget > 0
        ? (_currentBalance / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.currentBalance,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(_currentBalance),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.format(AppStrings.ofBudget, [
                      _formatCurrency(totalBudget),
                    ]),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onUpdateFinalDate != null
                    ? () => _showDatePickerDialog(context, theme)
                    : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isPastFinalDate
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPastFinalDate
                            ? Icons.event_busy_rounded
                            : Icons.calendar_today_rounded,
                        size: 14,
                        color: _isPastFinalDate
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isPastFinalDate
                            ? 'Ended • ${DateFormat('MMM d').format(finalDate)}'
                            : '$_daysLeft ${_daysLeft == 1 ? AppStrings.day : AppStrings.days}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _isPastFinalDate
                              ? theme.colorScheme.onErrorContainer
                              : theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySpendingCard(ThemeData theme, BuildContext context) {
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
              ? theme.colorScheme.errorContainer.withOpacity(0.3)
              : theme.colorScheme.primaryContainer.withOpacity(0.3),
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

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    String actionLabel,
    VoidCallback onAction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }

  Widget _buildAccountsList(ThemeData theme) {
    if (accounts.isEmpty) {
      return _buildEmptyState(
        theme,
        Icons.account_balance_wallet_outlined,
        AppStrings.noAccountsYet,
      );
    }
    return Column(
      children: accounts.take(3).map((account) {
        final balance = _getAccountBalance(account.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: account.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(account.icon, color: account.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.type.toString().split('.').last.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatCurrency(balance),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionsList(
    ThemeData theme,
    BuildContext context,
    List<Transaction> latestTransactions,
  ) {
    if (latestTransactions.isEmpty) {
      return _buildEmptyState(
        theme,
        Icons.receipt_long_outlined,
        AppStrings.noTransactionsInPeriod,
      );
    }
    return Column(
      children: latestTransactions.map((transaction) {
        final category = _getCategoryById(transaction.categoryId);
        final account = accounts.firstWhere(
          (a) => a.id == transaction.accountId,
        );
        final isTransfer = _isTransferTransaction(transaction);
        final itemColor = isTransfer
            ? theme.colorScheme.primary
            : category.color;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showTransactionOptionsDialog(context, transaction),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: itemColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isTransfer ? Icons.swap_horiz : category.icon,
                        color: itemColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTransfer ? AppStrings.transfer : category.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                account.icon,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                account.name,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                ' • ${DateFormat('MMM d').format(transaction.date)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${transaction.isIncome ? '+' : '-'}${_formatCurrency(transaction.amount)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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
      }).toList(),
    );
  }

  Widget _buildEmptyState(ThemeData theme, IconData icon, String label) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 32,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
