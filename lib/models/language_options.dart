import 'package:flutter/material.dart';
import 'package:timetoevent/l10n/app_locale.dart';

class LanguageOption {
  final String code;
  final String nameKey;
  final IconData icon;

  LanguageOption({required this.code, required this.nameKey, required this.icon});
}

// Список поддерживаемых языков
final List<LanguageOption> supportedLanguages = [
  LanguageOption(code: 'en', nameKey: AppLocale.english, icon: Icons.language),
  LanguageOption(code: 'ru', nameKey: AppLocale.russian, icon: Icons.translate),
  LanguageOption(code: 'es', nameKey: AppLocale.spanish, icon: Icons.flag),
  LanguageOption(code: 'fr', nameKey: AppLocale.french, icon: Icons.public),
  LanguageOption(code: 'de', nameKey: AppLocale.german, icon: Icons.euro_symbol),
  LanguageOption(code: 'zh', nameKey: AppLocale.chinese, icon: Icons.local_florist),
  LanguageOption(code: 'ja', nameKey: AppLocale.japanese, icon: Icons.rice_bowl),
  LanguageOption(code: 'ko', nameKey: AppLocale.korean, icon: Icons.restaurant),
  LanguageOption(code: 'pt', nameKey: AppLocale.portuguese, icon: Icons.flag),
  LanguageOption(code: 'it', nameKey: AppLocale.italian, icon: Icons.local_pizza),
  LanguageOption(code: 'ar', nameKey: AppLocale.arabic, icon: Icons.temple_hindu),
  LanguageOption(code: 'hi', nameKey: AppLocale.hindi, icon: Icons.temple_hindu),
  LanguageOption(code: 'bn', nameKey: AppLocale.bengali, icon: Icons.temple_hindu),
  LanguageOption(code: 'tr', nameKey: AppLocale.turkish, icon: Icons.temple_hindu),
  LanguageOption(code: 'pl', nameKey: AppLocale.polish, icon: Icons.flag),
  LanguageOption(code: 'uk', nameKey: AppLocale.ukrainian, icon: Icons.flag),
  LanguageOption(code: 'cs', nameKey: AppLocale.czech, icon: Icons.flag),
  LanguageOption(code: 'ro', nameKey: AppLocale.romanian, icon: Icons.flag),
  LanguageOption(code: 'el', nameKey: AppLocale.greek, icon: Icons.temple_hindu),
  LanguageOption(code: 'vi', nameKey: AppLocale.vietnamese, icon: Icons.local_florist),
  LanguageOption(code: 'th', nameKey: AppLocale.thai, icon: Icons.local_drink),
  LanguageOption(code: 'id', nameKey: AppLocale.indonesian, icon: Icons.local_florist),
  LanguageOption(code: 'fa', nameKey: AppLocale.persian, icon: Icons.temple_hindu),
  LanguageOption(code: 'he', nameKey: AppLocale.hebrew, icon: Icons.temple_hindu),
  LanguageOption(code: 'sv', nameKey: AppLocale.swedish, icon: Icons.flag),
  LanguageOption(code: 'fi', nameKey: AppLocale.finnish, icon: Icons.flag),
  LanguageOption(code: 'no', nameKey: AppLocale.norwegian, icon: Icons.flag),
  LanguageOption(code: 'da', nameKey: AppLocale.danish, icon: Icons.flag),
  LanguageOption(code: 'hu', nameKey: AppLocale.hungarian, icon: Icons.flag),
  LanguageOption(code: 'sr', nameKey: AppLocale.serbian, icon: Icons.flag),
  // Добавляйте новые языки сюда
];