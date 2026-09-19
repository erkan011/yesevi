import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan renk paleti
///
/// Minimalist, ferah ve modern bir görünüm için
/// açık yeşil tonları ve nötral gri'ler kullanılır.
class AppColors {
  AppColors._();

  // ── Primary (Açık Yeşil) ──
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primarySurface = Color(0xFFE8F5E9);

  // ── Arka Planlar ──
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF1F3F5);

  // ── Metin Renkleri ──
  static const Color textPrimary = Color(0xFF1A1D21);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textTertiary = Color(0xFFADB5BD);

  // ── Kenarlık & Gölge ──
  static const Color border = Color(0xFFE9ECEF);
  static const Color shadow = Color(0x0D000000);
  static const Color shadowMedium = Color(0x1A000000);

  // ── Durum Renkleri ──
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // ── Kutu Durumları ──
  static const Color statusWaiting = Color(0xFFFFC107);    // Sarı — Yeni Bırakıldı / Bekliyor
  static const Color statusEmptied = Color(0xFFFFC107);    // Sarı — Boşaltıldı
  static const Color statusCollected = Color(0xFFEF5350);  // Kırmızı — Alındı/Kaldırıldı
}
