import 'package:wallet/manager/language_manager.dart';
import 'package:wallet/manager/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io';
import 'package:wallet/model.dart';
import 'package:wallet/constants/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsTab extends StatefulWidget {
  final Future<void> Function(String)? onImportData;
  final Future<String> Function()? onExportData;
  final VoidCallback? onReset;
  final bool? biometricEnabled;
  final Function(bool)? onBiometricChanged;
  final List<Category>? categories;
  final Function(Category)? onAddCategory;
  final Function(Category)? onUpdateCategory;
  final Function(String)? onDeleteCategory;

  const SettingsTab({
    super.key,
    this.onImportData,
    this.onExportData,
    this.onReset,
    this.biometricEnabled,
    this.onBiometricChanged,
    this.categories,
    this.onAddCategory,
    this.onUpdateCategory,
    this.onDeleteCategory,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  String _biometricType = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      if (kIsWeb) {
        setState(() {
          _biometricAvailable = false;
        });
        return;
      }

      final canAuth = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canAuth && isDeviceSupported) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        String type = 'Biometric';

        if (availableBiometrics.contains(BiometricType.face)) {
          type = 'Face ID';
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          type = 'Fingerprint';
        } else if (availableBiometrics.contains(BiometricType.iris)) {
          type = 'Iris';
        }

        setState(() {
          _biometricAvailable = true;
          _biometricType = type;
        });
      } else {
        setState(() {
          _biometricAvailable = false;
        });
      }
    } catch (e) {
      setState(() {
        _biometricAvailable = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: AppStrings.authenticateToEnable,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (authenticated && mounted) {
          widget.onBiometricChanged?.call(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.format(AppStrings.authenticationEnabled, [
                  _biometricType,
                ]),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.format(AppStrings.authenticationFailed, [
                  e.toString(),
                ]),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      widget.onBiometricChanged?.call(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.format(AppStrings.authenticationDisabled, [
                _biometricType,
              ]),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppStrings.init(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Security Section
        if (_biometricAvailable) ...[
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surface,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.security,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text('$_biometricType ${AppStrings.biometricLock}'),
                  subtitle: Text(
                    (widget.biometricEnabled ?? false)
                        ? '${AppStrings.appIsLockedWith} $_biometricType'
                        : AppStrings.format(AppStrings.requireToOpenApp, [
                            _biometricType,
                          ]),
                  ),
                  value: widget.biometricEnabled ?? false,
                  onChanged: widget.onBiometricChanged != null
                      ? _toggleBiometric
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        _buildThemeSection(context),
        const SizedBox(height: 16),

        _buildLanguageSection(context),
        const SizedBox(height: 16),

        // Categories Management Section
        if (widget.categories != null) ...[
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surface,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.categories,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(AppStrings.manageCategories),
                  subtitle: Text(
                    AppStrings.format(AppStrings.categoriesCount, [
                      widget.categories!.length.toString(),
                    ]),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCategoriesManagement(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Data Management Section
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.dataManagement,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.upload_file, color: Colors.green),
                ),
                title: Text(AppStrings.exportData),
                subtitle: Text(AppStrings.saveDataBackup),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _handleExport(context),
              ),
              Divider(
                height: 1,
                indent: 72,
                color: theme.colorScheme.outlineVariant,
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.download, color: Colors.blue),
                ),
                title: Text(AppStrings.importData),
                subtitle: Text(AppStrings.restoreFromBackup),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _handleImport(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // App Information Section
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.appInformation,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(AppStrings.about),
                subtitle: Text(AppStrings.appVersionInfo),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: AppStrings.appName,
                    applicationVersion: AppStrings.appVersion,
                    applicationIcon: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    children: [
                      const SizedBox(height: 16),
                      Text(AppStrings.appDescription),
                    ],
                  );
                },
              ),

              Divider(
                height: 1,
                indent: 72,
                color: theme.colorScheme.outlineVariant,
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Colors.orange,
                  ),
                ),
                title: Text(AppStrings.privacyPolicy),
                subtitle: Text(AppStrings.howWeHandleData),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppStrings.privacyPolicy),
                      content: SingleChildScrollView(
                        child: Text(AppStrings.privacyMessage),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppStrings.close),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                indent: 72,
                color: theme.colorScheme.outlineVariant,
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.code, color: Colors.blue),
                ),
                title: Text(AppStrings.sourceCode),
                subtitle: Text(AppStrings.viewOnGitHub),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final uri = Uri.parse(
                    'https://github.com/alfahrelrifananda/wallet-app',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Danger Zone Section
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.dangerZone,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: Text(AppStrings.resetAllData),
                subtitle: Text(AppStrings.deleteAllTransactions),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      icon: const Icon(
                        Icons.warning_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      title: Text(AppStrings.resetDataQuestion),
                      content: Text(AppStrings.resetWarning),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppStrings.cancel),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            if (widget.onReset != null) {
                              widget.onReset!();
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text(AppStrings.reset),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    final theme = Theme.of(context);
    final languageManager = Provider.of<LanguageManager>(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.language_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.language,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.translate, color: theme.colorScheme.primary),
            ),
            title: Text(AppStrings.changeLanguage),
            subtitle: Text(
              '${AppStrings.currentLanguage}: ${languageManager.getLanguageLabel()}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final theme = Theme.of(context);
    final languageManager = Provider.of<LanguageManager>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle and header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
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
                    AppStrings.changeLanguage,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Language options
            _buildLanguageOption(
              context,
              theme,
              languageManager,
              'en',
              AppStrings.english,
              'English',
            ),
            Divider(
              height: 1,
              indent: 72,
              color: theme.colorScheme.outlineVariant,
            ),
            _buildLanguageOption(
              context,
              theme,
              languageManager,
              'id',
              AppStrings.indonesian,
              'Bahasa Indonesia',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    ThemeData theme,
    LanguageManager languageManager,
    String languageCode,
    String title,
    String subtitle,
  ) {
    final isSelected = languageManager.languageCode == languageCode;

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : Icon(
              Icons.circle_outlined,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
      onTap: () async {
        await languageManager.setLanguage(languageCode);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.format(AppStrings.languageChangedTo, [title]),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.appearance,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),

          // Theme Mode Selector
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                themeManager.themeMode == ThemeMode.light
                    ? Icons.light_mode
                    : themeManager.themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.brightness_auto,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(AppStrings.theme),
            subtitle: Text(themeManager.getThemeModeLabel()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeModeDialog(context),
          ),

          Divider(
            height: 1,
            indent: 72,
            color: theme.colorScheme.outlineVariant,
          ),

          // Dynamic Color Toggle
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.colorize, color: theme.colorScheme.primary),
            ),
            title: Text(AppStrings.materialYou),
            subtitle: Text(
              themeManager.useDynamicColor
                  ? AppStrings.usingSystemColors
                  : AppStrings.usingDefaultColors,
            ),
            value: themeManager.useDynamicColor,
            onChanged: (value) {
              themeManager.setUseDynamicColor(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? AppStrings.dynamicColorsEnabled
                        : AppStrings.dynamicColorsDisabled,
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle and header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
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
                    AppStrings.chooseTheme,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Theme options
            _buildThemeOption(
              context,
              theme,
              themeManager,
              ThemeMode.light,
              Icons.light_mode,
              AppStrings.light,
              AppStrings.alwaysUseLightTheme,
              Colors.amber,
            ),
            Divider(
              height: 1,
              indent: 72,
              color: theme.colorScheme.outlineVariant,
            ),
            _buildThemeOption(
              context,
              theme,
              themeManager,
              ThemeMode.dark,
              Icons.dark_mode,
              AppStrings.dark,
              AppStrings.alwaysUseDarkTheme,
              Colors.indigo,
            ),
            Divider(
              height: 1,
              indent: 72,
              color: theme.colorScheme.outlineVariant,
            ),
            _buildThemeOption(
              context,
              theme,
              themeManager,
              ThemeMode.system,
              Icons.brightness_auto,
              AppStrings.system,
              AppStrings.followSystemSettings,
              Colors.purple,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeData theme,
    ThemeManager themeManager,
    ThemeMode mode,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    final isSelected = themeManager.themeMode == mode;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : Icon(
              Icons.circle_outlined,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
      onTap: () {
        themeManager.setThemeMode(mode);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.format(AppStrings.themeChangedTo, [title]),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void _showCategoriesManagement(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle and header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.manageCategories,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _showAddEditCategory(
                            context,
                            null,
                            onSuccess: () => setModalState(() {}),
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(AppStrings.add),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Categories list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Expense categories
                    Text(
                      AppStrings.expenseCategories,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.categories!
                        .where((c) => c.isExpense && c.name != 'Transfer')
                        .map(
                          (category) => _buildCategoryTile(
                            context,
                            category,
                            onUpdate: () => setModalState(() {}),
                          ),
                        ),
                    const SizedBox(height: 24),
                    // Income categories
                    Text(
                      AppStrings.incomeCategories,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.categories!
                        .where((c) => !c.isExpense && c.name != 'Transfer')
                        .map(
                          (category) => _buildCategoryTile(
                            context,
                            category,
                            onUpdate: () => setModalState(() {}),
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

  Widget _buildCategoryTile(
    BuildContext context,
    Category category, {
    VoidCallback? onUpdate,
  }) {
    final theme = Theme.of(context);
    final isDefaultCategory = _isDefaultCategory(category.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: category.color.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(category.icon, color: category.color, size: 20),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          isDefaultCategory
              ? AppStrings.defaultCategory
              : AppStrings.customCategory,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () =>
                  _showAddEditCategory(context, category, onSuccess: onUpdate),
              tooltip: AppStrings.edit,
            ),
            if (category.isDeletable)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red,
                onPressed: () => _confirmDeleteCategory(
                  context,
                  category,
                  onSuccess: onUpdate,
                ),
                tooltip: AppStrings.delete,
              ),
          ],
        ),
      ),
    );
  }

  void _showAddEditCategory(
    BuildContext context,
    Category? category, {
    VoidCallback? onSuccess,
  }) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: category?.name ?? '');
    final isEditing = category != null;
    bool isExpense = category?.isExpense ?? true;
    IconData selectedIcon = category?.icon ?? Icons.category;
    Color selectedColor = category?.color ?? Colors.blue;

    final availableIcons = [
      Icons.restaurant,
      Icons.local_cafe,
      Icons.fastfood,
      Icons.shopping_bag,
      Icons.shopping_cart,
      Icons.card_giftcard,
      Icons.directions_car,
      Icons.local_gas_station,
      Icons.flight,
      Icons.home,
      Icons.bolt,
      Icons.water_drop,
      Icons.wifi,
      Icons.phone_android,
      Icons.movie,
      Icons.sports_esports,
      Icons.sports_soccer,
      Icons.fitness_center,
      Icons.medical_services,
      Icons.medication,
      Icons.school,
      Icons.work,
      Icons.account_balance,
      Icons.savings,
      Icons.trending_up,
      Icons.pets,
      Icons.child_care,
      Icons.checkroom,
      Icons.dry_cleaning,
      Icons.build,
      Icons.computer,
      Icons.headphones,
      Icons.book,
      Icons.brush,
    ];

    final availableColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
    ];

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
                  // Drag handle
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
                    isEditing
                        ? AppStrings.editCategory
                        : AppStrings.addCategory,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category type
                  Text(
                    AppStrings.type,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text(AppStrings.expense),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(AppStrings.income),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                    selected: {isExpense},
                    onSelectionChanged: (v) {
                      setDialogState(() => isExpense = v.first);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Category name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.categoryName,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Icon selector
                  Text(
                    AppStrings.icon,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = availableIcons[index];
                        final isSelected = icon == selectedIcon;
                        return InkWell(
                          onTap: () {
                            setDialogState(() => selectedIcon = icon);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withOpacity(0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? selectedColor
                                    : theme.colorScheme.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? selectedColor
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Color selector
                  Text(
                    AppStrings.color,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: availableColors.map((color) {
                      final isSelected = color == selectedColor;
                      return InkWell(
                        onTap: () {
                          setDialogState(() => selectedColor = color);
                        },
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
                  const SizedBox(height: 32),

                  // Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selectedIcon,
                            color: selectedColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.preview,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nameController.text.isEmpty
                                    ? AppStrings.categoryName
                                    : nameController.text,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isExpense
                                    ? AppStrings.expense
                                    : AppStrings.income,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
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
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.pleaseEnterCategoryName,
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final newCategory = Category(
                              id:
                                  category?.id ??
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                              name: nameController.text.trim(),
                              icon: selectedIcon,
                              color: selectedColor,
                              isExpense: isExpense,
                            );

                            if (isEditing) {
                              widget.onUpdateCategory?.call(newCategory);
                            } else {
                              widget.onAddCategory?.call(newCategory);
                            }

                            Navigator.pop(context);
                            onSuccess?.call();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? AppStrings.categoryUpdatedSuccess
                                      : AppStrings.categoryAddedSuccess,
                                ),
                                backgroundColor: Colors.green,
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
                          child: Text(
                            isEditing ? AppStrings.update : AppStrings.add,
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
        ),
      ),
    );
  }

  bool _isDefaultCategory(String name) {
    const defaultCategories = [
      'Food & Dining',
      'Transportation',
      'Shopping',
      'Entertainment',
      'Bills & Utilities',
      'Healthcare',
      'Education',
      'Other',
      'Salary',
      'Investment',
      'Gift',
    ];
    return defaultCategories.contains(name);
  }

  void _confirmDeleteCategory(
    BuildContext context,
    Category category, {
    VoidCallback? onSuccess,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_rounded, color: Colors.orange, size: 48),
        title: Text(AppStrings.deleteCategory),
        content: Text(
          AppStrings.format(AppStrings.deleteCategoryConfirm, [category.name]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              widget.onDeleteCategory?.call(category.id);
              Navigator.pop(context);
              onSuccess?.call();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.categoryDeleted),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      if (widget.onExportData == null) {
        _showErrorSnackBar(context, AppStrings.exportFunctionNotAvailable);
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get the data from parent
      final jsonData = await widget.onExportData!();

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Create a temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .split('.')[0]
          .replaceAll(':', '-');
      final file = File('${directory.path}/wallet_backup_$timestamp.json');
      await file.writeAsString(jsonData);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Wallet Backup',
        text: 'My wallet financial data backup',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.dataExportedSuccess),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading if still open
        _showErrorSnackBar(
          context,
          AppStrings.format(AppStrings.exportFailed, [e.toString()]),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    try {
      // Show file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      // Read the file
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // Validate JSON
      try {
        json.decode(jsonString);
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, AppStrings.invalidBackupFile);
        }
        return;
      }

      // Show confirmation dialog
      if (context.mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.warning_rounded,
              color: Colors.orange,
              size: 48,
            ),
            title: Text(AppStrings.importDataQuestion),
            content: Text(AppStrings.importWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppStrings.import),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );

          // Import the data
          if (widget.onImportData != null) {
            await widget.onImportData!(jsonString);
          }

          // Close loading
          if (context.mounted) Navigator.pop(context);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.dataImportedSuccess),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          AppStrings.format(AppStrings.importFailed, [e.toString()]),
        );
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
