import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tema durumunu yöneten global notifier.
///
/// Uygulamanın her yerinden `ThemeNotifier.instance` ile erişilir.
/// Değişiklikler SharedPreferences'a KAYDEDILMEZ (kalıcılık istenmiyorsa
/// basit ve lightweight kalır).  Gerekirse persist edilebilir.
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier._() : super(ThemeMode.light);

  static final ThemeNotifier instance = ThemeNotifier._();

  bool get isDark => value == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    value = mode;

    // Durum çubuğu renklerini güncelle
    SystemChrome.setSystemUIOverlayStyle(
      mode == ThemeMode.dark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: Color(0xFF121212),
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );
  }

  void toggleTheme() {
    setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
