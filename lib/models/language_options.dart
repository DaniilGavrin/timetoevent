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
  // Добавляйте новые языки сюда
];