import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan sabit değerler
class AppConstants {
  AppConstants._();

  // ── Uygulama Bilgileri ──
  static const String appName = 'Yesevi Gaziantep';
  static const String appVersion = '1.0.0';

  // ── Varsayılan Harita Konumu (Gaziantep Merkez) ──
  static const double defaultLatitude = 37.0662;
  static const double defaultLongitude = 37.3833;
  static const double defaultZoom = 13.0;

  // ── Padding & Spacing ──
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;

  // ── Border Radius ──
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;

  // ── Animasyon Süreleri ──
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
}
