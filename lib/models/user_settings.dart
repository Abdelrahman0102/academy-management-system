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

  factory UserSettingsModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final String rawTheme =
        json['theme_mode']?.toString().trim().toLowerCase() ??
            'light';

    return UserSettingsModel(
      userId: int.tryParse(
        json['user_id']?.toString() ?? '',
      ) ??
          0,
      themeMode: rawTheme == 'dark' ? 'dark' : 'light',
      languageCode:
      json['language_code']?.toString().trim().isNotEmpty == true
          ? json['language_code'].toString().trim()
          : 'en',
      updatedAt: DateTime.tryParse(
        json['updated_at']?.toString() ?? '',
      ),
    );
  }
}
