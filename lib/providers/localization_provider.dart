import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider with ChangeNotifier {
  String _languageCode = 'ru';

  String get languageCode => _languageCode;

  Future<void> setLanguage(String languageCode) async {
    FlutterLocalization.instance.translate(languageCode);
    _languageCode = languageCode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);

    notifyListeners(); // Обновляем UI
  }

  Future<void> initLanguageFromPrefs(String savedLanguageCode) async {
    FlutterLocalization.instance.translate(savedLanguageCode);
    _languageCode = savedLanguageCode;
    notifyListeners();
  }
}