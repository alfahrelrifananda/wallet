import 'package:wallet/utils/input_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wallet/model.dart';
import 'package:wallet/constants/app_strings.dart';

class TransactionsTab extends StatefulWidget {
  final String currency;
  final String currencySymbol;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<Category> categories;
  final Function(String) onDeleteTransaction;
  final Function(Transaction) onUpdateTransaction;

  const TransactionsTab({
    super.key,
    required this.currency,
    required this.currencySymbol,
    required this.transactions,
    required this.accounts,
    required this.categories,
    required this.onDeleteTransaction,
    required this.onUpdateTransaction,
  });

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  String _selectedPeriod = 'week'; // week, month, all

  Category _getCategoryById(String categoryId) {
    try {
      return widget.categories.firstWhere((c) => c.id == categoryId);
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: widget.currencySymbol,
      decimalDigits: 0,
      locale: widget.currency == 'IDR' ? 'id_ID' : 'en_US',
    );
    return formatter.format(amount);
  }

  bool _isTransferTransaction(Transaction transaction) {
    final category = _getCategoryById(transaction.categoryId);
    return category.name == 'Transfer';
  }

  List<Transaction> _getFilteredTransactions() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return widget.transactions
            .where((t) => t.date.isAfter(weekAgo))
            .toList();
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return widget.transactions
            .where((t) => t.date.isAfter(monthAgo))
            .toList();
      default:
        return widget.transactions;
    }
  }

  Map<String, double> _getCategoryBreakdown() {
    final filtered = _getFilteredTransactions();
    final breakdown = <String, double>{};

    for (var t in filtered.where((t) => !t.isIncome)) {
      breakdown[t.categoryId] = (breakdown[t.categoryId] ?? 0) + t.amount;
    }

    return breakdown;
  }

  List<Map<String, dynamic>> _getWeeklyData() {
    final now = DateTime.now();
    final weeklyData = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayTransactions = widget.transactions.where(
        (t) => t.date.isAfter(dayStart) && t.date.isBefore(dayEnd),
      );

      final expenses = dayTransactions
          .where((t) => !t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);

      final income = dayTransactions
          .where((t) => t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);

      weeklyData.add({
        'day': DateFormat('E').format(date),
        'date': date,
        'expenses': expenses,
        'income': income,
      });
    }

    return weeklyData;
  }

  double get _periodSpent {
    return _getFilteredTransactions()
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _periodIncome {
    return _getFilteredTransactions()
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    AppStrings.init(context);
    final theme = Theme.of(context);
    final sortedTransactions = _getFilteredTransactions()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Period selector
        _buildPeriodSelector(theme),
        const SizedBox(height: 16),

        // Summary cards
        _buildSummaryCards(theme),
        const SizedBox(height: 16),

        // Weekly trend graph
        if (_selectedPeriod == 'week') ...[
          _buildWeeklyTrendCard(theme),
          const SizedBox(height: 16),
        ],

        if (sortedTransactions.isNotEmpty) ...[
          Text(
            AppStrings.topCategories,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Category breakdown
        if (_getCategoryBreakdown().isNotEmpty) ...[
          _buildCategoryBreakdownCard(theme),
          const SizedBox(height: 24),
        ],

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
            Text(
              AppStrings.format(AppStrings.totalCount, [
                sortedTransactions.length.toString(),
              ]),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Transactions list
        if (sortedTransactions.isEmpty)
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
          ...sortedTransactions.map((transaction) {
            final category = _getCategoryById(transaction.categoryId);
            final account = widget.accounts.firstWhere(
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

  Widget _buildPeriodSelector(ThemeData theme) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'week',
          label: Text(AppStrings.week),
          icon: const Icon(Icons.calendar_view_week),
        ),
        ButtonSegment(
          value: 'month',
          label: Text(AppStrings.month),
          icon: const Icon(Icons.calendar_month),
        ),
        ButtonSegment(
          value: 'all',
          label: Text(AppStrings.allTime),
          icon: const Icon(Icons.calendar_today),
        ),
      ],
      selected: {_selectedPeriod},
      onSelectionChanged: (v) {
        setState(() => _selectedPeriod = v.first);
      },
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surface,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trending_down,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.spent,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(_periodSpent),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surface,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.income,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(_periodIncome),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyTrendCard(ThemeData theme) {
    final weeklyData = _getWeeklyData();
    final maxAmount = weeklyData.fold<double>(
      0,
      (max, day) => [
        max,
        day['expenses'] as double,
        day['income'] as double,
      ].reduce((a, b) => a > b ? a : b),
    );

    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.weeklyTrend,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weeklyData.map((day) {
                  final expenses = day['expenses'] as double;
                  final income = day['income'] as double;
                  final expenseHeight = maxAmount > 0
                      ? (expenses / maxAmount * 140).clamp(4.0, 140.0)
                      : 4.0;
                  final incomeHeight = maxAmount > 0
                      ? (income / maxAmount * 140).clamp(4.0, 140.0)
                      : 4.0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Income bar
                              Expanded(
                                child: Container(
                                  height: incomeHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              // Expense bar
                              Expanded(
                                child: Container(
                                  height: expenseHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            day['day'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(theme, Colors.green, AppStrings.income),
                const SizedBox(width: 24),
                _buildLegendItem(theme, Colors.red, AppStrings.expenses),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(ThemeData theme, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdownCard(ThemeData theme) {
    final breakdown = _getCategoryBreakdown();
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalSpent = breakdown.values.fold(0.0, (sum, val) => sum + val);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sortedEntries.take(5).map((entry) {
              final category = _getCategoryById(entry.key);
              final percentage = totalSpent > 0
                  ? (entry.value / totalSpent * 100)
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: category.color, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(entry.value),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: category.color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
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
              widget.onDeleteTransaction(transaction.id);
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
    Account selectedAccount = widget.accounts.firstWhere(
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
                          autofocus: false,
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
                                    (transactionType == 'income'),
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
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: AppStrings.noteOptional,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                            if (clean.isEmpty) return;

                            widget.onUpdateTransaction(
                              Transaction(
                                id: transaction.id,
                                amount: double.parse(clean),
                                isIncome: transactionType == 'income',
                                date: selectedDate,
                                accountId: selectedAccount.id,
                                categoryId: selectedCategory.id,
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
}
