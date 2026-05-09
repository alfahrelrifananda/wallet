import 'package:wallet/utils/input_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wallet/model.dart';
import 'package:wallet/constants/app_strings.dart';

class AccountsTab extends StatelessWidget {
  final String currency;
  final String currencySymbol;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final Function(Account) onAddAccount;
  final Function(String) onDeleteAccount;
  final Function(int oldIndex, int newIndex) onReorderAccounts;

  const AccountsTab({
    super.key,
    required this.currency,
    required this.currencySymbol,
    required this.transactions,
    required this.accounts,
    required this.onAddAccount,
    required this.onDeleteAccount,
    required this.onReorderAccounts,
  });

  double _getAccountBalance(String accountId) {
    final account = accounts.firstWhere((a) => a.id == accountId);
    double balance = account.initialBalance;
    for (var t in transactions.where((t) => t.accountId == accountId)) {
      balance += t.isIncome ? t.amount : -t.amount;
    }
    return balance;
  }

  int _getTransactionCount(String accountId) {
    return transactions.where((t) => t.accountId == accountId).length;
  }

  double _getAccountIncome(String accountId) {
    return transactions
        .where((t) => t.accountId == accountId && t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _getAccountExpenses(String accountId) {
    return transactions
        .where((t) => t.accountId == accountId && !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalBalance {
    return accounts.fold(
      0.0,
      (sum, account) => sum + _getAccountBalance(account.id),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
      locale: currency == 'IDR' ? 'id_ID' : 'en_US',
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    AppStrings.init(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      children: [
        if (accounts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 40,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.noAccountsYet,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.addFirstAccount,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else ...[
          _buildTotalOverviewCard(theme),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: accounts.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              onReorderAccounts(oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: child,
            ),
            itemBuilder: (context, index) {
              final account = accounts[index];
              final balance = _getAccountBalance(account.id);
              final transactionCount = _getTransactionCount(account.id);
              final income = _getAccountIncome(account.id);
              final expenses = _getAccountExpenses(account.id);

              return Padding(
                key: ValueKey(account.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: _AccountCard(
                  account: account,
                  balance: balance,
                  transactionCount: transactionCount,
                  income: income,
                  expenses: expenses,
                  index: index,
                  formatCurrency: _formatCurrency,
                  onTap: () => _showAccountDetailsDialog(
                    context,
                    account,
                    balance,
                    transactionCount,
                    income,
                    expenses,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => _showAddAccountDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: Text(AppStrings.addAccount),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildTotalOverviewCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.totalNetWorth,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(_totalBalance),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.format(AppStrings.acrossAccounts, [
              accounts.length.toString(),
            ]),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Account details bottom sheet ──────────────────────────────────────────

  void _showAccountDetailsDialog(
    BuildContext context,
    Account account,
    double balance,
    int transactionCount,
    double income,
    double expenses,
  ) {
    final theme = Theme.of(context);
    final netChange = income - expenses;
    final canDelete = accounts.length > 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
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

                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: account.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          account.icon,
                          color: account.color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              account.type
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: balance >= 0
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.currentBalance,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatCurrency(balance),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          theme,
                          icon: Icons.swap_vert,
                          label: AppStrings.transactions,
                          value: transactionCount.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          theme,
                          icon: Icons.account_balance_wallet_outlined,
                          label: AppStrings.initial,
                          value: _formatCurrency(account.initialBalance),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildIncomeExpenseCol(
                                theme,
                                icon: Icons.arrow_downward,
                                iconColor: Colors.green,
                                label: AppStrings.income,
                                value: _formatCurrency(income),
                                valueColor: Colors.green,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildIncomeExpenseCol(
                                theme,
                                icon: Icons.arrow_upward,
                                iconColor: Colors.red,
                                label: AppStrings.expenses,
                                value: _formatCurrency(expenses),
                                valueColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: theme.colorScheme.outlineVariant,
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.netChange,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${netChange >= 0 ? '+' : ''}${_formatCurrency(netChange)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: netChange >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (canDelete)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmationDialog(
                            context,
                            account,
                            transactionCount,
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(AppStrings.deleteAccount),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withOpacity(
                          0.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.mustHaveOneAccount,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseCol(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Delete confirmation ───────────────────────────────────────────────────

  void _showDeleteConfirmationDialog(
    BuildContext context,
    Account account,
    int transactionCount,
  ) {
    final theme = Theme.of(context);
    final balance = _getAccountBalance(account.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_rounded,
          color: theme.colorScheme.error,
          size: 48,
        ),
        title: Text(AppStrings.deleteAccountQuestion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transactionCount > 0
                  ? AppStrings.format(
                      AppStrings.deleteAccountWithTransactionsWarning,
                      [transactionCount.toString()],
                    )
                  : AppStrings.deleteAccountConfirm,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: account.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          account.type.toString().split('.').last.toUpperCase(),
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
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            if (transactionCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                AppStrings.actionCannotBeUndone,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              onDeleteAccount(account.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    transactionCount > 0
                        ? AppStrings.format(
                            AppStrings.accountAndTransactionsDeleted,
                            [transactionCount.toString()],
                          )
                        : AppStrings.accountDeleted,
                  ),
                  duration: const Duration(seconds: 3),
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

  // ── Add account ───────────────────────────────────────────────────────────

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    AccountType selectedType = AccountType.wallet;
    IconData selectedIcon = Icons.account_balance_wallet;
    Color selectedColor = Colors.teal;

    final typeIcons = {
      AccountType.wallet: Icons.account_balance_wallet,
      AccountType.bank: Icons.account_balance,
      AccountType.card: Icons.credit_card,
      AccountType.savings: Icons.savings,
      AccountType.investment: Icons.trending_up,
    };

    final colors = [
      Colors.teal,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.pink,
      Colors.red,
      Colors.indigo,
    ];

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isSavings = selectedType == AccountType.savings;

          // Clear and lock balance field when savings is selected
          if (isSavings) balanceController.text = '';

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                      AppStrings.addAccount,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.accountName,
                        filled: true,
                        fillColor: theme.colorScheme.secondaryContainer
                            .withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Initial balance — hidden for savings ──
                    if (!isSavings) ...[
                      TextField(
                        controller: balanceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppStrings.initialBalance,
                          prefixText: '$currencySymbol ',
                          filled: true,
                          fillColor: theme.colorScheme.secondaryContainer
                              .withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ThousandsSeparatorInputFormatter(),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Savings notice
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withOpacity(0.5),
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
                      const SizedBox(height: 20),
                    ],

                    Text(
                      AppStrings.accountType,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AccountType.values.map((type) {
                        final isSelected = selectedType == type;
                        return ChoiceChip(
                          label: Text(
                            type.toString().split('.').last.toUpperCase(),
                          ),
                          avatar: Icon(typeIcons[type], size: 18),
                          selected: isSelected,
                          onSelected: (_) {
                            setDialogState(() {
                              selectedType = type;
                              selectedIcon = typeIcons[type]!;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.color,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: colors.map((color) {
                        final isSelected = selectedColor == color;
                        return InkWell(
                          onTap: () =>
                              setDialogState(() => selectedColor = color),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: theme.colorScheme.primary,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
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
                                borderRadius: BorderRadius.circular(14),
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
                              if (nameController.text.isEmpty) return;
                              // Savings always gets 0; others need a value
                              if (!isSavings && balanceController.text.isEmpty)
                                return;
                              final initialBalance = isSavings
                                  ? 0.0
                                  : double.parse(
                                      balanceController.text.replaceAll(
                                        ',',
                                        '',
                                      ),
                                    );
                              onAddAccount(
                                Account(
                                  id: DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                                  name: nameController.text,
                                  type: selectedType,
                                  initialBalance: initialBalance,
                                  icon: selectedIcon,
                                  color: selectedColor,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(AppStrings.addAccount),
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
        },
      ),
    );
  }
}

// ── Account card widget ───────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final Account account;
  final double balance;
  final int transactionCount;
  final double income;
  final double expenses;
  final int index;
  final String Function(double) formatCurrency;
  final VoidCallback onTap;

  const _AccountCard({
    required this.account,
    required this.balance,
    required this.transactionCount,
    required this.income,
    required this.expenses,
    required this.index,
    required this.formatCurrency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.drag_indicator,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(balance),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.format(AppStrings.transactionCount, [
                      transactionCount.toString(),
                    ]),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
