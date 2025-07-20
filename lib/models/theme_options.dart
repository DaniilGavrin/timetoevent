import 'package:flutter/material.dart';

class ThemeOption {
  final ThemeMode mode;
  final String name;
  final IconData icon;
  final Color color;

  ThemeOption({
    required this.mode,
    required this.name,
    required this.icon,
    required this.color,
  });
}