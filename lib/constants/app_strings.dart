import 'package:flutter/material.dart';
import 'package:wallet/l10n/app_localizations.dart';

class AppStrings {
  static AppLocalizations? _localizations;

  static void init(BuildContext context) {
    _localizations = AppLocalizations.of(context);
  }

  // Onboarding
  static String get welcomeTowallet =>
      _localizations?.translate('welcomeTowallet') ?? 'Welcome to wallet';
  static String get welcomeDescription =>
      _localizations?.translate('welcomeDescription') ??
      'Manage your budget wisely with accounts and categories';
  static String get selectCurrency =>
      _localizations?.translate('selectCurrency') ?? 'Select Currency';
  static String get choosePreferredCurrency =>
      _localizations?.translate('choosePreferredCurrency') ??
      'Choose your preferred currency';
  static String get addAccounts =>
      _localizations?.translate('addAccounts') ?? 'Add Accounts';
  static String get totalBudgetDescription =>
      _localizations?.translate('totalBudgetDescription') ??
      'Your total budget will be the sum of all account balances';
  static String get addAtLeastOneAccount =>
      _localizations?.translate('addAtLeastOneAccount') ??
      'Add at least one account to continue';
  static String get budgetPeriod =>
      _localizations?.translate('budgetPeriod') ?? 'Budget Period';
  static String get whenShouldBudgetEnd =>
      _localizations?.translate('whenShouldBudgetEnd') ??
      'When should this budget end?';
  static String get endDate =>
      _localizations?.translate('endDate') ?? 'End Date';
  static String get selectDate =>
      _localizations?.translate('selectDate') ?? 'Select Date';
  static String get daysFromNow =>
      _localizations?.translate('daysFromNow') ?? '{} days from now';
  static String get back => _localizations?.translate('back') ?? 'Back';
  static String get next => _localizations?.translate('next') ?? 'Next';
  static String get getStarted =>
      _localizations?.translate('getStarted') ?? 'Get Started';
  static String get accountNameHint =>
      _localizations?.translate('accountNameHint') ?? 'e.g., My Wallet';
  static String get deleteAccountNameConfirm =>
      _localizations?.translate('deleteAccountNameConfirm') ??
      'Are you sure you want to delete "{}"?';
  static String get editAccount =>
      _localizations?.translate('editAccount') ?? 'Edit Account';

  // Security
  static String get security =>
      _localizations?.translate('security') ?? 'Security';
  static String get biometricLock =>
      _localizations?.translate('biometricLock') ?? 'Lock';
  static String get appIsLockedWith =>
      _localizations?.translate('appIsLockedWith') ?? 'App is locked with';
  static String get requireToOpenApp =>
      _localizations?.translate('requireToOpenApp') ?? 'Require {} to open app';
  static String get authenticateToEnable =>
      _localizations?.translate('authenticateToEnable') ??
      'Authenticate to enable biometric lock';
  static String get authenticationEnabled =>
      _localizations?.translate('authenticationEnabled') ??
      '{} authentication enabled';
  static String get authenticationDisabled =>
      _localizations?.translate('authenticationDisabled') ??
      '{} authentication disabled';
  static String get authenticationFailed =>
      _localizations?.translate('authenticationFailed') ??
      'Authentication failed: {}';

  // Appearance
  static String get appearance =>
      _localizations?.translate('appearance') ?? 'Appearance';
  static String get theme => _localizations?.translate('theme') ?? 'Theme';
  static String get materialYou =>
      _localizations?.translate('materialYou') ?? 'Material You';
  static String get usingSystemColors =>
      _localizations?.translate('usingSystemColors') ?? 'Using system colors';
  static String get usingDefaultColors =>
      _localizations?.translate('usingDefaultColors') ?? 'Using default colors';
  static String get dynamicColorsEnabled =>
      _localizations?.translate('dynamicColorsEnabled') ??
      'Dynamic colors enabled';
  static String get dynamicColorsDisabled =>
      _localizations?.translate('dynamicColorsDisabled') ??
      'Dynamic colors disabled';
  static String get chooseTheme =>
      _localizations?.translate('chooseTheme') ?? 'Choose Theme';
  static String get light => _localizations?.translate('light') ?? 'Light';
  static String get dark => _localizations?.translate('dark') ?? 'Dark';
  static String get system => _localizations?.translate('system') ?? 'System';
  static String get alwaysUseLightTheme =>
      _localizations?.translate('alwaysUseLightTheme') ??
      'Always use light theme';
  static String get alwaysUseDarkTheme =>
      _localizations?.translate('alwaysUseDarkTheme') ??
      'Always use dark theme';
  static String get followSystemSettings =>
      _localizations?.translate('followSystemSettings') ??
      'Follow system settings';
  static String get themeChangedTo =>
      _localizations?.translate('themeChangedTo') ?? 'Theme changed to {}';

  // Language
  static String get language =>
      _localizations?.translate('language') ?? 'Language';
  static String get changeLanguage =>
      _localizations?.translate('changeLanguage') ?? 'Change Language';
  static String get currentLanguage =>
      _localizations?.translate('currentLanguage') ?? 'Current language';
  static String get english =>
      _localizations?.translate('english') ?? 'English';
  static String get indonesian =>
      _localizations?.translate('indonesian') ?? 'Indonesian';
  static String get languageChangedTo =>
      _localizations?.translate('languageChangedTo') ??
      'Language changed to {}';

  // Categories
  static String get categories =>
      _localizations?.translate('categories') ?? 'Categories';
  static String get manageCategories =>
      _localizations?.translate('manageCategories') ?? 'Manage Categories';
  static String get categoriesCount =>
      _localizations?.translate('categoriesCount') ?? '{} categories';
  static String get addCategory =>
      _localizations?.translate('addCategory') ?? 'Add Category';
  static String get editCategory =>
      _localizations?.translate('editCategory') ?? 'Edit Category';
  static String get categoryName =>
      _localizations?.translate('categoryName') ?? 'Category Name';
  static String get type => _localizations?.translate('type') ?? 'Type';
  static String get expense =>
      _localizations?.translate('expense') ?? 'Expense';
  static String get income => _localizations?.translate('income') ?? 'Income';
  static String get icon => _localizations?.translate('icon') ?? 'Icon';
  static String get color => _localizations?.translate('color') ?? 'Color';
  static String get preview =>
      _localizations?.translate('preview') ?? 'Preview';
  static String get defaultCategory =>
      _localizations?.translate('defaultCategory') ?? 'Default category';
  static String get customCategory =>
      _localizations?.translate('customCategory') ?? 'Custom category';
  static String get deleteCategory =>
      _localizations?.translate('deleteCategory') ?? 'Delete Category?';
  static String get deleteCategoryConfirm =>
      _localizations?.translate('deleteCategoryConfirm') ??
      'Are you sure you want to delete "{}"?';
  static String get categoryDeleted =>
      _localizations?.translate('categoryDeleted') ?? 'Category deleted';
  static String get categoryAddedSuccess =>
      _localizations?.translate('categoryAddedSuccess') ??
      'Category added successfully';
  static String get categoryUpdatedSuccess =>
      _localizations?.translate('categoryUpdatedSuccess') ??
      'Category updated successfully';
  static String get pleaseEnterCategoryName =>
      _localizations?.translate('pleaseEnterCategoryName') ??
      'Please enter a category name';
  static String get expenseCategories =>
      _localizations?.translate('expenseCategories') ?? 'EXPENSE CATEGORIES';
  static String get incomeCategories =>
      _localizations?.translate('incomeCategories') ?? 'INCOME CATEGORIES';

  // Actions
  static String get add => _localizations?.translate('add') ?? 'Add';
  static String get update => _localizations?.translate('update') ?? 'Update';
  static String get edit => _localizations?.translate('edit') ?? 'Edit';
  static String get delete => _localizations?.translate('delete') ?? 'Delete';
  static String get cancel => _localizations?.translate('cancel') ?? 'Cancel';
  static String get close => _localizations?.translate('close') ?? 'Close';
  static String get import => _localizations?.translate('import') ?? 'Import';
  static String get reset => _localizations?.translate('reset') ?? 'Reset';

  // Data Management
  static String get dataManagement =>
      _localizations?.translate('dataManagement') ?? 'Data Management';
  static String get exportData =>
      _localizations?.translate('exportData') ?? 'Export Data';
  static String get importData =>
      _localizations?.translate('importData') ?? 'Import Data';
  static String get saveDataBackup =>
      _localizations?.translate('saveDataBackup') ??
      'Save your data as a backup file';
  static String get restoreFromBackup =>
      _localizations?.translate('restoreFromBackup') ??
      'Restore from a backup file';
  static String get dataExportedSuccess =>
      _localizations?.translate('dataExportedSuccess') ??
      'Data exported successfully';
  static String get dataImportedSuccess =>
      _localizations?.translate('dataImportedSuccess') ??
      'Data imported successfully';
  static String get exportFailed =>
      _localizations?.translate('exportFailed') ?? 'Failed to export data: {}';
  static String get importFailed =>
      _localizations?.translate('importFailed') ?? 'Failed to import data: {}';
  static String get invalidBackupFile =>
      _localizations?.translate('invalidBackupFile') ??
      'Invalid backup file format';
  static String get importDataQuestion =>
      _localizations?.translate('importDataQuestion') ?? 'Import Data?';
  static String get importWarning =>
      _localizations?.translate('importWarning') ??
      'This will replace all your current data';
  static String get exportFunctionNotAvailable =>
      _localizations?.translate('exportFunctionNotAvailable') ??
      'Export function not available';

  // App Information
  static String get appInformation =>
      _localizations?.translate('appInformation') ?? 'App Information';
  static String get about => _localizations?.translate('about') ?? 'About';
  static String get appVersionInfo =>
      _localizations?.translate('appVersionInfo') ??
      'App version and information';
  static String get appName => _localizations?.translate('appName') ?? 'Wallet';
  static String get appVersion =>
      _localizations?.translate('appVersion') ?? '1.0.0';
  static String get appDescription =>
      _localizations?.translate('appDescription') ??
      'A simple and beautiful budget tracking app';
  static String get privacyPolicy =>
      _localizations?.translate('privacyPolicy') ?? 'Privacy Policy';
  static String get howWeHandleData =>
      _localizations?.translate('howWeHandleData') ?? 'How we handle your data';
  static String get privacyMessage =>
      _localizations?.translate('privacyMessage') ??
      'All your financial data is stored locally';
  static String get sourceCode =>
      _localizations?.translate('sourceCode') ?? 'Source Code';
  static String get viewOnGitHub =>
      _localizations?.translate('viewOnGitHub') ?? 'View on GitHub';

  // Danger Zone
  static String get dangerZone =>
      _localizations?.translate('dangerZone') ?? 'Danger Zone';
  static String get resetAllData =>
      _localizations?.translate('resetAllData') ?? 'Reset All Data';
  static String get deleteAllTransactions =>
      _localizations?.translate('deleteAllTransactions') ??
      'Delete all transactions and accounts';
  static String get resetDataQuestion =>
      _localizations?.translate('resetDataQuestion') ?? 'Reset All Data?';
  static String get resetWarning =>
      _localizations?.translate('resetWarning') ??
      'Are you sure you want to delete all data?';

  // Transactions
  static String get transactions =>
      _localizations?.translate('transactions') ?? 'Transactions';
  static String get totalTransactions =>
      _localizations?.translate('totalTransactions') ?? '{} total';
  static String get noTransactionsInPeriod =>
      _localizations?.translate('noTransactionsInPeriod') ??
      'No transactions in this period';
  static String get unknownCategory =>
      _localizations?.translate('unknownCategory') ?? 'Unknown Category';
  static String get week => _localizations?.translate('week') ?? 'Week';
  static String get month => _localizations?.translate('month') ?? 'Month';
  static String get allTime =>
      _localizations?.translate('allTime') ?? 'All Time';
  static String get spent => _localizations?.translate('spent') ?? 'Spent';
  static String get expenses =>
      _localizations?.translate('expenses') ?? 'Expenses';
  static String get weeklyTrend =>
      _localizations?.translate('weeklyTrend') ?? 'Weekly Trend';
  static String get topCategories =>
      _localizations?.translate('topCategories') ?? 'Top Categories';
  static String get editTransaction =>
      _localizations?.translate('editTransaction') ?? 'Edit Transaction';
  static String get deleteTransaction =>
      _localizations?.translate('deleteTransaction') ?? 'Delete Transaction';
  static String get deleteTransactionConfirm =>
      _localizations?.translate('deleteTransactionConfirm') ??
      'Are you sure you want to delete this transaction?';
  static String get transactionDeleted =>
      _localizations?.translate('transactionDeleted') ?? 'Transaction deleted';
  static String get transactionUpdated =>
      _localizations?.translate('transactionUpdated') ?? 'Transaction updated';
  static String get amount => _localizations?.translate('amount') ?? 'Amount';
  static String get account =>
      _localizations?.translate('account') ?? 'Account';
  static String get fromAccount =>
      _localizations?.translate('fromAccount') ?? 'From Account';
  static String get toAccount =>
      _localizations?.translate('toAccount') ?? 'To Account';
  static String get noteOptional =>
      _localizations?.translate('noteOptional') ?? 'Note (optional)';
  static String get saveChanges =>
      _localizations?.translate('saveChanges') ?? 'Save Changes';
  static String get transfer =>
      _localizations?.translate('transfer') ?? 'Transfer';
  static String get date => _localizations?.translate('date') ?? 'Date';
  static String get totalCount =>
      _localizations?.translate('totalCount') ?? '{} total';
  static String get category =>
      _localizations?.translate('category') ?? 'Category';
  static String get transactionCount =>
      _localizations?.translate('transactionCount') ?? '{} Transaction{}';

  // Accounts
  static String get accounts =>
      _localizations?.translate('accounts') ?? 'Accounts';
  static String get noAccountsYet =>
      _localizations?.translate('noAccountsYet') ?? 'No accounts yet';
  static String get addFirstAccount =>
      _localizations?.translate('addFirstAccount') ??
      'Add your first account to start tracking';
  static String get totalNetWorth =>
      _localizations?.translate('totalNetWorth') ?? 'Total Net Worth';
  static String get acrossAccounts =>
      _localizations?.translate('acrossAccounts') ?? 'across {} account{}';
  static String get addAccount =>
      _localizations?.translate('addAccount') ?? 'Add Account';
  static String get deleteAccount =>
      _localizations?.translate('deleteAccount') ?? 'Delete Account';
  static String get deleteAccountQuestion =>
      _localizations?.translate('deleteAccountQuestion') ?? 'Delete Account?';
  static String get deleteAccountConfirm =>
      _localizations?.translate('deleteAccountConfirm') ??
      'Are you sure you want to delete this account?';
  static String get deleteAccountWithTransactionsWarning =>
      _localizations?.translate('deleteAccountWithTransactionsWarning') ??
      'This account has {} transaction{}. Deleting this account will also delete all associated transactions.';
  static String get mustHaveOneAccount =>
      _localizations?.translate('mustHaveOneAccount') ??
      'You must have at least one account';
  static String get cannotDeleteLastAccount =>
      _localizations?.translate('cannotDeleteLastAccount') ??
      'Cannot delete last account';
  static String get accountDeleted =>
      _localizations?.translate('accountDeleted') ?? 'Account deleted';
  static String get accountAndTransactionsDeleted =>
      _localizations?.translate('accountAndTransactionsDeleted') ??
      'Account and {} transaction{} deleted';
  static String get accountName =>
      _localizations?.translate('accountName') ?? 'Account Name';
  static String get initialBalance =>
      _localizations?.translate('initialBalance') ?? 'Initial Balance';
  static String get accountType =>
      _localizations?.translate('accountType') ?? 'Account Type';
  static String get currentBalance =>
      _localizations?.translate('currentBalance') ?? 'Current Balance';
  static String get initial =>
      _localizations?.translate('initial') ?? 'Initial';
  static String get netChange =>
      _localizations?.translate('netChange') ?? 'Net Change';
  static String get actionCannotBeUndone =>
      _localizations?.translate('actionCannotBeUndone') ??
      'This action cannot be undone.';

  // Overview
  static String get overview =>
      _localizations?.translate('overview') ?? 'Overview';
  static String get balanceTrend =>
      _localizations?.translate('balanceTrend') ?? 'Balance Trend';
  static String get viewAll =>
      _localizations?.translate('viewAll') ?? 'View All';
  static String get daysLeft =>
      _localizations?.translate('daysLeft') ?? '{} days left';
  static String get ofBudget =>
      _localizations?.translate('ofBudget') ?? 'of {} budget';
  static String get todaysBudgetRemaining =>
      _localizations?.translate('todaysBudgetRemaining') ??
      'Today\'s Budget Remaining';
  static String get spendingByCategory =>
      _localizations?.translate('spendingByCategory') ?? 'Spending by Category';
  static String get budgetBreakdown =>
      _localizations?.translate('budgetBreakdown') ?? 'Budget Breakdown';
  static String get baseDailyAllowance =>
      _localizations?.translate('baseDailyAllowance') ?? 'Base Daily Allowance';
  static String get rolloverFromPreviousDays =>
      _localizations?.translate('rolloverFromPreviousDays') ??
      'Rollover from Previous Days';
  static String get todaysIncome =>
      _localizations?.translate('todaysIncome') ?? 'Today\'s Income';
  static String get todaysSpending =>
      _localizations?.translate('todaysSpending') ?? 'Today\'s Spending';
  static String get remainingBudget =>
      _localizations?.translate('remainingBudget') ?? 'Remaining Budget';
  static String get howItWorks =>
      _localizations?.translate('howItWorks') ?? 'How it works';
  static String get budgetExplanationText =>
      _localizations?.translate('budgetExplanationText') ??
      'Your base daily allowance is calculated from your remaining balance divided by days left.\n\n'
          'When you spend less than your allowance, the savings roll over to the next day as a bonus.\n\n'
          'If you overspend, your rollover resets to zero, but your base allowance adjusts automatically based on your new balance.\n\n'
          'Today\'s income immediately increases your available budget for today.\n\n'
          'Transfers between accounts don\'t affect your budget.';
  static String get gotIt => _localizations?.translate('gotIt') ?? 'Got it';

  // Home & Navigation
  static String get settings =>
      _localizations?.translate('settings') ?? 'Settings';
  static String get addTransaction =>
      _localizations?.translate('addTransaction') ?? 'Add Transaction';
  static String get transferToAccount =>
      _localizations?.translate('transferToAccount') ?? 'Transfer to {}';
  static String get transferFromAccount =>
      _localizations?.translate('transferFromAccount') ?? 'Transfer from {}';
  static String get budgetPeriodEnded =>
      _localizations?.translate('budgetPeriodEnded') ?? 'Budget Period Ended';
  static String get budgetEndedOn =>
      _localizations?.translate('budgetEndedOn') ??
      'Your budget period ended on {}. Please set a new end date to continue using the app.';
  static String get exitApp =>
      _localizations?.translate('exitApp') ?? 'Exit App';
  static String get setNewDate =>
      _localizations?.translate('setNewDate') ?? 'Set New Date';
  static String get setNewEndDate =>
      _localizations?.translate('setNewEndDate') ?? 'Set New End Date';
  static String get selected =>
      _localizations?.translate('selected') ?? 'Selected';
  static String get chooseDate =>
      _localizations?.translate('chooseDate') ?? 'Choose Date';
  static String get confirm =>
      _localizations?.translate('confirm') ?? 'Confirm';

  static String get day => _localizations?.translate('day') ?? 'day';
  static String get days => _localizations?.translate('days') ?? 'days';

  static String get finalBalance =>
      _localizations?.translate('finalBalance') ?? 'Final Balance';
  static String get startingBudget =>
      _localizations?.translate('startingBudget') ?? 'Starting Budget';
  static String get periodSummary =>
      _localizations?.translate('periodSummary') ?? 'Period Summary';
  static String get stayedWithinBudget =>
      _localizations?.translate('stayedWithinBudget') ??
      'Final balance (you stayed within budget!)';
  static String get overspent =>
      _localizations?.translate('overspent') ?? 'Final balance (overspent)';
  static String get periodEndedSuccess =>
      _localizations?.translate('periodEndedSuccess') ??
      'Your budget period has ended. Great job staying within budget!';
  static String get periodEndedOverspent =>
      _localizations?.translate('periodEndedOverspent') ??
      'Your budget period has ended. You went over budget, but that\'s okay - use this as learning for next time.';

  static String format(String template, List<String> args) {
    String result = template;
    for (var arg in args) {
      result = result.replaceFirst('{}', arg);
    }
    return result;
  }
}
