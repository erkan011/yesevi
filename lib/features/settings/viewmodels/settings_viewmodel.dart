import 'package:flutter/material.dart';

import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';

/// Ayarlar ViewModel'i
class SettingsViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? get currentUser => _authService.getCurrentUserModel();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Çıkış Yap
  Future<bool> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hesabı Sil
  Future<bool> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.deleteAccount();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
