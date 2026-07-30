import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? localizations =
    Localizations.of<AppLocalizations>(context, AppLocalizations);

    assert(
    localizations != null,
    'AppLocalizations was not found in the widget tree.',
    );

    return localizations!;
  }

  bool get isArabic => locale.languageCode.toLowerCase() == 'ar';

  String _text(String key) {
    final Map<String, String> selected =
    _translations[isArabic ? 'ar' : 'en']!;

    return selected[key] ?? _translations['en']![key] ?? key;
  }

  // Settings
  String get settings => _text('settings');
  String get applicationSettings => _text('applicationSettings');
  String get appearance => _text('appearance');
  String get darkMode => _text('darkMode');
  String get darkAppearanceActive => _text('darkAppearanceActive');
  String get lightAppearanceActive => _text('lightAppearanceActive');
  String get darkModeDescription => _text('darkModeDescription');
  String get lightModeDescription => _text('lightModeDescription');
  String get savedToAccount => _text('savedToAccount');
  String get savedToAccountDescription =>
      _text('savedToAccountDescription');
  String get unableLoadSettings => _text('unableLoadSettings');
  String get darkModeEnabled => _text('darkModeEnabled');
  String get lightModeEnabled => _text('lightModeEnabled');
  String get unableSaveSetting => _text('unableSaveSetting');
  String get retry => _text('retry');
  String get language => _text('language');
  String get applicationLanguage => _text('applicationLanguage');
  String get english => _text('english');
  String get arabic => _text('arabic');
  String get englishEnabled => _text('englishEnabled');
  String get arabicEnabled => _text('arabicEnabled');
  String get languageDescription => _text('languageDescription');

  // Evaluation
  String get playerEvaluation => _text('playerEvaluation');
  String get technicalSkills => _text('technicalSkills');
  String get physical => _text('physical');
  String get tactical => _text('tactical');
  String get psychologicalPerformance =>
      _text('psychologicalPerformance');
  String get personalTraits => _text('personalTraits');
  String get disciplineRules => _text('disciplineRules');
  String get performanceUnderMatchPressure =>
      _text('performanceUnderMatchPressure');
  String get coachNotes => _text('coachNotes');
  String get notesHint => _text('notesHint');
  String get evaluationSummary => _text('evaluationSummary');
  String get saveEvaluation => _text('saveEvaluation');
  String get saving => _text('saving');
  String get evaluationSaved => _text('evaluationSaved');
  String get unableSaveEvaluation => _text('unableSaveEvaluation');

  String scoreField(String id) => _text('score_$id');

  String statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return _text('statusActive');
      case 'injured':
        return _text('statusInjured');
      case 'inactive':
      default:
        return _text('statusInactive');
    }
  }

  String ratingLabel(String ratingKey) {
    switch (ratingKey) {
      case 'exceptional':
        return _text('ratingExceptional');
      case 'very_good':
        return _text('ratingVeryGood');
      case 'good':
        return _text('ratingGood');
      case 'average':
        return _text('ratingAverage');
      case 'needs_improvement':
      default:
        return _text('ratingNeedsImprovement');
    }
  }

  String categoryLabel(String categoryKey) {
    switch (categoryKey) {
      case 'technical':
        return _text('summaryTechnical');
      case 'physical':
        return _text('summaryPhysical');
      case 'tactical':
        return _text('summaryTactical');
      case 'psychological':
        return _text('summaryPsychological');
      case 'personal':
        return _text('summaryPersonal');
      case 'discipline':
        return _text('summaryDiscipline');
      case 'pressure':
      default:
        return _text('summaryPressure');
    }
  }

  String ageYears(String value) {
    return isArabic ? '$value سنة' : '$value yrs';
  }

  static const Map<String, Map<String, String>> _translations =
  <String, Map<String, String>>{
    'en': <String, String>{
      'settings': 'Settings',
      'applicationSettings': 'Application Settings',
      'appearance': 'Appearance',
      'darkMode': 'Dark Mode',
      'darkAppearanceActive': 'Dark appearance is active.',
      'lightAppearanceActive': 'Light appearance is active.',
      'darkModeDescription': 'The application is using the dark appearance.',
      'lightModeDescription': 'The application is using the light appearance.',
      'savedToAccount': 'Saved to your account',
      'savedToAccountDescription':
      'Your appearance and language are stored in the database and restored whenever you sign in, even on another device.',
      'unableLoadSettings': 'Unable to load the settings.',
      'darkModeEnabled': 'Dark mode has been enabled.',
      'lightModeEnabled': 'Light mode has been enabled.',
      'unableSaveSetting': 'Unable to save the setting.',
      'retry': 'Retry',
      'language': 'Language',
      'applicationLanguage': 'Application Language',
      'english': 'English',
      'arabic': 'Arabic',
      'englishEnabled': 'English has been selected.',
      'arabicEnabled': 'Arabic has been selected.',
      'languageDescription':
      'Choose the language used for the evaluation screen and translated settings.',
      'playerEvaluation': 'Player Evaluation',
      'technicalSkills': 'Technical & Skills',
      'physical': 'Physical',
      'tactical': 'Tactical',
      'psychologicalPerformance': 'Psychological Performance',
      'personalTraits': 'Personal Traits',
      'disciplineRules': 'Discipline & Rules',
      'performanceUnderMatchPressure': 'Performance Under Match Pressure',
      'coachNotes': 'Coach Notes',
      'notesHint': 'Write notes about this evaluation...',
      'evaluationSummary': 'Evaluation Summary',
      'saveEvaluation': 'Save Evaluation',
      'saving': 'Saving...',
      'evaluationSaved': 'Evaluation saved successfully',
      'unableSaveEvaluation': 'Unable to save evaluation',
      'score_passing': 'Passing',
      'score_dribbling': 'Dribbling',
      'score_shooting': 'Shooting',
      'score_running_with_ball': 'Running with Ball',
      'score_ball_control': 'Ball Control',
      'score_agility_flexibility': 'Agility & Flexibility',
      'score_strength': 'Strength',
      'score_speed': 'Speed',
      'score_coordination': 'Coordination',
      'score_attack': 'Attack',
      'score_defense': 'Defense',
      'score_decision_making': 'Decision Making',
      'score_awareness': 'Awareness',
      'score_attention_focus': 'Attention & Focus',
      'score_determination': 'Determination',
      'score_creativity': 'Creativity',
      'score_self_confidence': 'Self Confidence',
      'score_leadership': 'Leadership',
      'score_cooperation': 'Cooperation',
      'score_emotional_stability': 'Emotional Stability',
      'score_training_attendance': 'Training Attendance',
      'score_following_instructions': 'Following Instructions',
      'score_uniform_commitment': 'Uniform Commitment',
      'score_behavior': 'Behavior',
      'summaryTechnical': 'Technical',
      'summaryPhysical': 'Physical',
      'summaryTactical': 'Tactical',
      'summaryPsychological': 'Psychological',
      'summaryPersonal': 'Personal',
      'summaryDiscipline': 'Discipline',
      'summaryPressure': 'Pressure',
      'ratingExceptional': 'Exceptional',
      'ratingVeryGood': 'Very Good',
      'ratingGood': 'Good',
      'ratingAverage': 'Average',
      'ratingNeedsImprovement': 'Needs Improvement',
      'statusActive': 'Active',
      'statusInjured': 'Injured',
      'statusInactive': 'Inactive',
    },
    'ar': <String, String>{
      'settings': 'الإعدادات',
      'applicationSettings': 'إعدادات التطبيق',
      'appearance': 'المظهر',
      'darkMode': 'الوضع الداكن',
      'darkAppearanceActive': 'المظهر الداكن مفعّل.',
      'lightAppearanceActive': 'المظهر الفاتح مفعّل.',
      'darkModeDescription': 'يستخدم التطبيق حاليًا المظهر الداكن.',
      'lightModeDescription': 'يستخدم التطبيق حاليًا المظهر الفاتح.',
      'savedToAccount': 'محفوظ في حسابك',
      'savedToAccountDescription':
      'يتم حفظ المظهر واللغة في قاعدة البيانات واستعادتهما عند تسجيل الدخول، حتى من جهاز آخر.',
      'unableLoadSettings': 'تعذر تحميل الإعدادات.',
      'darkModeEnabled': 'تم تفعيل الوضع الداكن.',
      'lightModeEnabled': 'تم تفعيل الوضع الفاتح.',
      'unableSaveSetting': 'تعذر حفظ الإعداد.',
      'retry': 'إعادة المحاولة',
      'language': 'اللغة',
      'applicationLanguage': 'لغة التطبيق',
      'english': 'الإنجليزية',
      'arabic': 'العربية',
      'englishEnabled': 'تم اختيار اللغة الإنجليزية.',
      'arabicEnabled': 'تم اختيار اللغة العربية.',
      'languageDescription':
      'اختر اللغة المستخدمة في شاشة التقييم والإعدادات المترجمة.',
      'playerEvaluation': 'تقييم اللاعب',
      'technicalSkills': 'الفني والمهاري',
      'physical': 'البدني',
      'tactical': 'الخططي',
      'psychologicalPerformance': 'الأداء النفسي',
      'personalTraits': 'السمات الشخصية',
      'disciplineRules': 'الانضباط والقواعد',
      'performanceUnderMatchPressure': 'الأداء تحت ضغط المباراة',
      'coachNotes': 'ملاحظات المدرب',
      'notesHint': 'اكتب ملاحظاتك حول هذا التقييم...',
      'evaluationSummary': 'ملخص التقييم',
      'saveEvaluation': 'حفظ التقييم',
      'saving': 'جارٍ الحفظ...',
      'evaluationSaved': 'تم حفظ التقييم بنجاح',
      'unableSaveEvaluation': 'تعذر حفظ التقييم',
      'score_passing': 'التمرير',
      'score_dribbling': 'المراوغة',
      'score_shooting': 'التسديد',
      'score_running_with_ball': 'الجري بالكرة',
      'score_ball_control': 'التحكم بالكرة',
      'score_agility_flexibility': 'الرشاقة والمرونة',
      'score_strength': 'القوة',
      'score_speed': 'السرعة',
      'score_coordination': 'التوافق الحركي',
      'score_attack': 'الهجوم',
      'score_defense': 'الدفاع',
      'score_decision_making': 'اتخاذ القرار',
      'score_awareness': 'الوعي',
      'score_attention_focus': 'الانتباه والتركيز',
      'score_determination': 'الإصرار',
      'score_creativity': 'الإبداع',
      'score_self_confidence': 'الثقة بالنفس',
      'score_leadership': 'القيادة',
      'score_cooperation': 'التعاون',
      'score_emotional_stability': 'الثبات الانفعالي',
      'score_training_attendance': 'الالتزام بحضور التدريب',
      'score_following_instructions': 'اتباع التعليمات',
      'score_uniform_commitment': 'الالتزام بالزي',
      'score_behavior': 'السلوك',
      'summaryTechnical': 'الفني',
      'summaryPhysical': 'البدني',
      'summaryTactical': 'الخططي',
      'summaryPsychological': 'النفسي',
      'summaryPersonal': 'الشخصي',
      'summaryDiscipline': 'الانضباط',
      'summaryPressure': 'الضغط',
      'ratingExceptional': 'استثنائي',
      'ratingVeryGood': 'جيد جدًا',
      'ratingGood': 'جيد',
      'ratingAverage': 'متوسط',
      'ratingNeedsImprovement': 'يحتاج إلى تحسين',
      'statusActive': 'نشط',
      'statusInjured': 'مصاب',
      'statusInactive': 'غير نشط',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
          (Locale supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations(locale),
    );
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
