import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider with ChangeNotifier {
  String _languageCode = 'en';

  String get languageCode => _languageCode;

  Future<void> setLanguage(String code) async {
    FlutterLocalization.instance.translate(code);
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
    notifyListeners();
  }

  Future<void> initLanguageFromPrefs(String savedLanguageCode) async {
    FlutterLocalization.instance.translate(savedLanguageCode);
    _languageCode = savedLanguageCode;
    notifyListeners();
  }
}