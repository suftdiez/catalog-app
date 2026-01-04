import 'mqtt_service.dart'; // Sesuaikan path-nya
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =======================================================
// THEME PROVIDER (DARK MODE)
// =======================================================
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadFromLocal();
  }

  // Toggle dark mode
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToLocal();
    notifyListeners();
  }

  // Set specific theme
  void setDarkMode(bool value) {
    _isDarkMode = value;
    _saveToLocal();
    notifyListeners();
  }

  // Dark theme data
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      fillColor: Colors.grey.shade800,
      filled: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    ),
  );

  // Light theme data
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.grey.shade50,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    ),
  );

  // Simpan ke local storage
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
  }

  // Load dari local storage
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    notifyListeners();
  }
}
