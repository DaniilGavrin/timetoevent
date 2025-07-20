import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  int updateInterval = 5; // Значение по умолчанию


  Future<void> setUpdateInterval(int value) async {
    if (value < 1) value = 1;
    if (value > 1600) value = 1600;

    updateInterval = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('update_interval', value);
    notifyListeners();
  }

  Future<void> initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    updateInterval = prefs.getInt('update_interval') ?? 5;
    notifyListeners();
  }
}