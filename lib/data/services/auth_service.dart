import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

/// Firebase Authentication servis katmanı
///
/// Tüm auth işlemleri bu sınıf üzerinden yapılır.
/// ViewModel'ler bu servisi kullanarak kullanıcı işlemlerini yönetir.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Şu anki kullanıcıyı döndürür (giriş yapılmamışsa null)
  User? get currentUser => _auth.currentUser;

  /// Kullanıcı oturum durumu stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// E-posta ve şifre ile giriş yap
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Giriş başarısız. Lütfen tekrar deneyin.',
        );
      }

      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// E-posta ve şifre ile yeni hesap oluştur
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Kayıt başarısız. Lütfen tekrar deneyin.',
        );
      }

      // Kullanıcının ismini profiline kaydet
      await user.updateDisplayName(displayName);

      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Oturumu kapat
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Şifre değiştir
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı bulunamadı.');
    await user.updatePassword(newPassword);
  }

  /// Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Hesabı sil
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı bulunamadı.');
    await user.delete();
  }

  /// Mevcut kullanıcı bilgilerini UserModel olarak döndür
  UserModel? getCurrentUserModel() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
    );
  }

  /// Firebase Auth hatalarını kullanıcı dostu mesajlara çevir
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresine ait bir hesap bulunamadı.';
      case 'wrong-password':
        return 'Şifre hatalı. Lütfen tekrar deneyin.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen biraz bekleyin.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return e.message ?? 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
