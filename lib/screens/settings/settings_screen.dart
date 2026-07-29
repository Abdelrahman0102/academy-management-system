// settings_screen.dart

import 'package:flutter/material.dart';

import '../../repositories/user_settings_repository.dart';
import '../../settings/app_settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.controller,
    super.key,
  });

  final AppSettingsController controller;

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
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
      await widget.controller
          .loadCurrentUserSettings();
    } on UserSettingsException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Unable to load the settings.',
      );
    }
  }

  Future<void> _changeDarkMode(
      bool enabled,
      ) async {
    try {
      await widget.controller.setDarkMode(enabled);

      if (!mounted) {
        return;
      }

      _showMessage(
        enabled
            ? 'Dark mode has been enabled.'
            : 'Light mode has been enabled.',
      );
    } on UserSettingsException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Unable to save the setting.',
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
        final ThemeData theme =
        Theme.of(context);
        final ColorScheme colorScheme =
            theme.colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
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
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    padding:
                    const EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      32,
                    ),
                    children: <Widget>[
                      _HeaderCard(
                        isDarkMode:
                        widget.controller.isDarkMode,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Appearance',
                        style: theme
                            .textTheme.titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        clipBehavior:
                        Clip.antiAlias,
                        child: Column(
                          children: <Widget>[
                            SwitchListTile.adaptive(
                              value: widget
                                  .controller.isDarkMode,
                              onChanged: widget
                                  .controller
                                  .isLoading ||
                                  widget.controller
                                      .isSaving
                                  ? null
                                  : _changeDarkMode,
                              secondary: Container(
                                width: 42,
                                height: 42,
                                decoration:
                                BoxDecoration(
                                  color: colorScheme
                                      .primary
                                      .withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(
                                    13,
                                  ),
                                ),
                                child: Icon(
                                  widget.controller
                                      .isDarkMode
                                      ? Icons
                                      .dark_mode_rounded
                                      : Icons
                                      .light_mode_rounded,
                                  color:
                                  colorScheme.primary,
                                ),
                              ),
                              title: const Text(
                                'Dark Mode',
                              ),
                              subtitle: Text(
                                widget.controller
                                    .isDarkMode
                                    ? 'The application is using the dark appearance.'
                                    : 'The application is using the light appearance.',
                              ),
                            ),
                            if (widget.controller
                                .isSaving ||
                                widget.controller
                                    .isLoading)
                              const LinearProgressIndicator(
                                minHeight: 2,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _InformationCard(
                        icon: Icons
                            .cloud_done_rounded,
                        title:
                        'Saved to your account',
                        message:
                        'This appearance is stored in the database and will be restored whenever you sign in, even on another device.',
                      ),
                      if (widget.controller
                          .errorMessage !=
                          null) ...<Widget>[
                        const SizedBox(height: 14),
                        _ErrorCard(
                          message: widget.controller
                              .errorMessage!,
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isDarkMode,
  });

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
        colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant
              .withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colorScheme.primary
                  .withValues(alpha: 0.13),
              borderRadius:
              BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.settings_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Application Settings',
                  style: theme
                      .textTheme.titleLarge
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDarkMode
                      ? 'Dark appearance is active.'
                      : 'Light appearance is active.',
                  style: theme
                      .textTheme.bodyMedium
                      ?.copyWith(
                    color: colorScheme
                        .onSurfaceVariant,
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
    final ColorScheme colorScheme =
        theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary
              .withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme
                      .textTheme.titleSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme
                      .textTheme.bodySmall
                      ?.copyWith(
                    color: colorScheme
                        .onSurfaceVariant,
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
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme =
        theme.colorScheme;

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
            color:
            colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme
                  .textTheme.bodyMedium
                  ?.copyWith(
                color:
                colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

