import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

class LocalizationProvider with ChangeNotifier {
  String _languageCode = 'ru';

  String get languageCode => _languageCode;

  Future<void> setLanguage(String languageCode) async {
    FlutterLocalization.instance.translate(languageCode);
    _languageCode = languageCode;
    notifyListeners(); // Уведомляем слушателей
  }
}