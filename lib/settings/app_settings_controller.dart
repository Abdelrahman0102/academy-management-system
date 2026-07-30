import 'package:flutter/material.dart';

import '../models/user_settings.dart';
import '../repositories/user_settings_repository.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    required this.repository,
  });

  final UserSettingsRepository repository;

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoadedCurrentUser = false;
  String? _errorMessage;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isArabic => languageCode == 'ar';
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasLoadedCurrentUser => _hasLoadedCurrentUser;
  String? get errorMessage => _errorMessage;

  Future<void> loadCurrentUserSettings({
    bool force = false,
  }) async {
    if (_isLoading) {
      return;
    }

    if (_hasLoadedCurrentUser && !force) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserSettingsModel settings =
      await repository.getSettings();

      _applySettings(settings);
      _hasLoadedCurrentUser = true;
    } on UserSettingsException catch (error) {
      _errorMessage = error.message;
      rethrow;
    } catch (_) {
      _errorMessage = 'Unable to load your application settings.';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    if (_isSaving || enabled == isDarkMode) {
      return;
    }

    final ThemeMode previousMode = _themeMode;

    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserSettingsModel savedSettings =
      await repository.updateThemeMode(
        darkMode: enabled,
      );

      _applySettings(savedSettings);
      _hasLoadedCurrentUser = true;
    } on UserSettingsException catch (error) {
      _themeMode = previousMode;
      _errorMessage = error.message;
      rethrow;
    } catch (_) {
      _themeMode = previousMode;
      _errorMessage = 'Unable to save the appearance setting.';
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> setLanguageCode(String value) async {
    final String normalized = value.trim().toLowerCase();

    if (normalized != 'en' && normalized != 'ar') {
      throw const UserSettingsException(
        'The selected language is not supported.',
      );
    }

    if (_isSaving || normalized == languageCode) {
      return;
    }

    final Locale previousLocale = _locale;

    _locale = Locale(normalized);
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserSettingsModel savedSettings =
      await repository.updateLanguageCode(
        languageCode: normalized,
      );

      _applySettings(savedSettings);
      _hasLoadedCurrentUser = true;
    } on UserSettingsException catch (error) {
      _locale = previousLocale;
      _errorMessage = error.message;
      rethrow;
    } catch (_) {
      _locale = previousLocale;
      _errorMessage = 'Unable to save the language setting.';
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _applySettings(UserSettingsModel settings) {
    _themeMode =
    settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _locale = Locale(settings.isArabic ? 'ar' : 'en');
  }

  void resetForLogout() {
    _themeMode = ThemeMode.light;
    _locale = const Locale('en');
    _isLoading = false;
    _isSaving = false;
    _hasLoadedCurrentUser = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}
