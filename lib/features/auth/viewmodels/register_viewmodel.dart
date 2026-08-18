import 'package:flutter/material.dart';

import '../../../data/services/auth_service.dart';

/// Kayıt (Register) ekranı state yönetimi
class RegisterViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // ── Controllers ──
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // ── State ──
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Şifre görünürlüğünü değiştir
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Ad Soyad validasyonu
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ad Soyad giriniz';
    }
    return null;
  }

  /// E-posta validasyonu
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi giriniz';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi giriniz';
    }
    return null;
  }

  /// Şifre validasyonu
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre giriniz';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }
    return null;
  }

  /// Kayıt ol
  Future<bool> signUp() async {
    // Form validasyonu
    if (!formKey.currentState!.validate()) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUpWithEmail(
        email: emailController.text,
        password: passwordController.text,
        displayName: nameController.text.trim(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
