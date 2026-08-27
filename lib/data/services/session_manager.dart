import '../models/user_model.dart';

/// Global oturum yöneticisi (Singleton)
///
/// Login sonrası Firestore'dan çekilen kurum_id ve kullanıcı bilgisini
/// uygulama genelinde erişilebilir kılar. Tüm servisler buradaki
/// kurumId'yi kullanarak veri izolasyonunu sağlar.
class SessionManager {
  SessionManager._();
  static final SessionManager _instance = SessionManager._();
  static SessionManager get instance => _instance;

  UserModel? _currentUser;

  /// Oturum açmış kullanıcı bilgisi
  UserModel? get currentUser => _currentUser;

  /// Aktif kurum_id (SaaS izolasyonu için tüm servisler bunu kullanır)
  String? get kurumId => _currentUser?.kurumId;

  /// Kullanıcı adı veya e-posta
  String get displayNameOrEmail {
    if (_currentUser == null) return '';
    return _currentUser!.displayName.isNotEmpty
        ? _currentUser!.displayName
        : _currentUser!.email;
  }

  /// Login sonrası çağrılır — kullanıcı bilgisini session'a yazar
  void setUser(UserModel user) {
    _currentUser = user;
  }

  /// Logout veya hata sonrası session'ı temizler
  void clear() {
    _currentUser = null;
  }

  /// Kullanıcı oturumu açık ve kurum_id mevcut mu?
  bool get isAuthenticated => _currentUser != null && _currentUser!.kurumId != null;
}
