class UserSettingsModel {
  const UserSettingsModel({
    required this.userId,
    required this.themeMode,
    required this.languageCode,
    this.updatedAt,
  });

  final int userId;
  final String themeMode;
  final String languageCode;
  final DateTime? updatedAt;

  bool get isDarkMode => themeMode == 'dark';
  bool get isArabic => languageCode == 'ar';

  factory UserSettingsModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final String rawTheme =
        json['theme_mode']?.toString().trim().toLowerCase() ??
            'light';

    final String rawLanguage =
        json['language_code']?.toString().trim().toLowerCase() ??
            'en';

    return UserSettingsModel(
      userId: int.tryParse(
        json['user_id']?.toString() ?? '',
      ) ??
          0,
      themeMode: rawTheme == 'dark' ? 'dark' : 'light',
      languageCode: rawLanguage == 'ar' ? 'ar' : 'en',
      updatedAt: DateTime.tryParse(
        json['updated_at']?.toString() ?? '',
      ),
    );
  }
}
