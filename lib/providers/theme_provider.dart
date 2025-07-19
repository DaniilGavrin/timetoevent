// theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode;

  ThemeProvider({ThemeMode? initialThemeMode})
      : _themeMode = initialThemeMode ?? ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  ThemeData get currentTheme => _themeMode == ThemeMode.light
      ? _buildLightTheme()
      : _buildDarkTheme();

  void toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
    await _saveThemeMode(_themeMode);
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.toString());
  }

  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);
    return themeModeString == 'ThemeMode.dark'
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6750A4),
        secondary: Color(0xFF625B71),
        tertiary: Color(0xFF7D5260),
        background: Color(0xFFF5F5F5),
        surface: Color(0xFFFFFBFE),
        onPrimary: Colors.white,
        onBackground: Color(0xFF1C1B1F),
        onSurface: Color(0xFF1C1B1F),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1B1F),
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1C1B1F),
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Color(0xFF49454F),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1B1F),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF6750A4),
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFFFFFFFF),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF79747E),
          fontSize: 16,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFF5F5F5),
        selectedItemColor: Color(0xFF6750A4),
        unselectedItemColor: Color(0xFF79747E),
        elevation: 4,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD0BCFF),
        secondary: Color(0xFFCCC2DC),
        tertiary: Color(0xFFEFB8C8),
        background: Color(0xFF1C1B1F),
        surface: Color(0xFF121212),
        onPrimary: Colors.black,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Color(0xFFE6E1E5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFD0BCFF),
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2B2B2B),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD0BCFF),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2B2B2B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF545256),
          fontSize: 16,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1C1B1F),
        selectedItemColor: Color(0xFFD0BCFF),
        unselectedItemColor: Color(0xFF545256),
        elevation: 4,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
