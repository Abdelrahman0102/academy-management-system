import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../repositories/user_settings_repository.dart';
import '../../settings/app_settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.controller,
    super.key,
  });

  final AppSettingsController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();

    if (!widget.controller.hasLoadedCurrentUser) {
      WidgetsBinding.instance.addPostFrameCallback(
            (_) => _loadSettings(),
      );
    }
  }

  Future<void> _loadSettings() async {
    try {
      await widget.controller.loadCurrentUserSettings();
    } on UserSettingsException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).unableLoadSettings,
      );
    }
  }

  Future<void> _changeDarkMode(bool enabled) async {
    try {
      await widget.controller.setDarkMode(enabled);

      if (!mounted) {
        return;
      }

      final AppLocalizations localizations =
      AppLocalizations.of(context);

      _showMessage(
        enabled
            ? localizations.darkModeEnabled
            : localizations.lightModeEnabled,
      );
    } on UserSettingsException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).unableSaveSetting,
      );
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    try {
      await widget.controller.setLanguageCode(languageCode);

      if (!mounted) {
        return;
      }

      final AppLocalizations localizations =
      AppLocalizations.of(context);

      _showMessage(
        languageCode == 'ar'
            ? localizations.arabicEnabled
            : localizations.englishEnabled,
      );
    } on UserSettingsException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).unableSaveSetting,
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger =
    ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (
          BuildContext context,
          Widget? child,
          ) {
        final ThemeData theme = Theme.of(context);
        final ColorScheme colorScheme = theme.colorScheme;
        final AppLocalizations localizations =
        AppLocalizations.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.settings),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                ),
                child: RefreshIndicator(
                  onRefresh: () => widget.controller
                      .loadCurrentUserSettings(
                    force: true,
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      32,
                    ),
                    children: <Widget>[
                      _HeaderCard(
                        title: localizations.applicationSettings,
                        subtitle: widget.controller.isDarkMode
                            ? localizations.darkAppearanceActive
                            : localizations.lightAppearanceActive,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations.appearance,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: <Widget>[
                            SwitchListTile.adaptive(
                              value: widget.controller.isDarkMode,
                              onChanged: widget.controller.isLoading ||
                                  widget.controller.isSaving
                                  ? null
                                  : _changeDarkMode,
                              secondary: _SettingIcon(
                                icon: widget.controller.isDarkMode
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                              ),
                              title: Text(localizations.darkMode),
                              subtitle: Text(
                                widget.controller.isDarkMode
                                    ? localizations.darkModeDescription
                                    : localizations.lightModeDescription,
                              ),
                            ),
                            if (widget.controller.isSaving ||
                                widget.controller.isLoading)
                              const LinearProgressIndicator(
                                minHeight: 2,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations.language,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: <Widget>[
                            ListTile(
                              enabled: !widget.controller.isLoading &&
                                  !widget.controller.isSaving,
                              onTap: () => _changeLanguage('en'),
                              leading: const _SettingIcon(
                                icon: Icons.language_rounded,
                              ),
                              title: Text(localizations.english),
                              subtitle: const Text('English'),
                              trailing:
                              widget.controller.languageCode == 'en'
                                  ? Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                              )
                                  : const Icon(
                                Icons.radio_button_unchecked_rounded,
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: colorScheme.outlineVariant,
                            ),
                            ListTile(
                              enabled: !widget.controller.isLoading &&
                                  !widget.controller.isSaving,
                              onTap: () => _changeLanguage('ar'),
                              leading: const _SettingIcon(
                                icon: Icons.translate_rounded,
                              ),
                              title: Text(localizations.arabic),
                              subtitle: const Text('العربية'),
                              trailing:
                              widget.controller.languageCode == 'ar'
                                  ? Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                              )
                                  : const Icon(
                                Icons.radio_button_unchecked_rounded,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                14,
                              ),
                              child: Align(
                                alignment:
                                AlignmentDirectional.centerStart,
                                child: Text(
                                  localizations.languageDescription,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                    colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.controller.isSaving ||
                                widget.controller.isLoading)
                              const LinearProgressIndicator(
                                minHeight: 2,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _InformationCard(
                        icon: Icons.cloud_done_rounded,
                        title: localizations.savedToAccount,
                        message:
                        localizations.savedToAccountDescription,
                      ),
                      if (widget.controller.errorMessage != null)
                        ...<Widget>[
                          const SizedBox(height: 14),
                          _ErrorCard(
                            message:
                            widget.controller.errorMessage!,
                            retryLabel: localizations.retry,
                            onRetry: _loadSettings,
                          ),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: colorScheme.primary,
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: <Widget>[
          const _SettingIcon(
            icon: Icons.settings_rounded,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
