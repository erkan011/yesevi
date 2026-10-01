import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import 'session_manager.dart';

/// Firebase Authentication + Firestore servis katmanı
///
/// Login sonrası Firestore `users` koleksiyonundan kurum_id ve role çekerek
/// SessionManager'a yazar. SaaS multi-tenant izolasyonunun temeli burasıdır.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Şu anki kullanıcıyı döndürür (giriş yapılmamışsa null)
  User? get currentUser => _auth.currentUser;

  /// Kullanıcı oturum durumu stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 1. Önce girilen "Kurum Adı" ile `kurumlar` koleksiyonunda sorgu yap ve eşleşen kurumun `kurum_id`'sini bul
  /// 2. Firebase Auth ile Email & Şifre girişini gerçekleştir.
  /// 3. `users` koleksiyonundan giriş yapan personelin dokümanını çek.
  /// 4. Personelin dokümanındaki `kurum_id` ile 1. adımda bulduğun `kurum_id` eşleşiyorsa girişe izin ver
  Future<UserModel> signInWithEmail({
    required String kurumAdi,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Önce Auth Girişi yap (Firestore yetkilendirmesi için)
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

      // 2. Firestore'dan personelin dokümanını çek
      final userModel = await _fetchUserFromFirestore(user);

      if (userModel.kurumId == null || userModel.kurumId!.isEmpty) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'kurum-not-found',
          message: 'Hesabınıza tanımlı bir kurum bulunamadı.',
        );
      }

      // 3. Giriş yaptıktan sonra kurum adı ile sorgu yap (Artık okuma yetkimiz var)
      final kurumQuery = await _firestore
          .collection('kurumlar')
          .where('name', isEqualTo: kurumAdi.trim())
          .limit(1)
          .get();

      if (kurumQuery.docs.isEmpty) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'kurum-not-found',
          message: 'Böyle bir kurum bulunamadı.',
        );
      }
      
      final foundKurumId = kurumQuery.docs.first.id;

      // 4. Kurum ID eşleşme kontrolü
      if (userModel.kurumId != foundKurumId) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'kurum-mismatch',
          message: 'Bu kuruma ait personel değilsiniz.',
        );
      }

      // 5. Session'a yaz
      SessionManager.instance.setUser(userModel);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Firestore `users` koleksiyonundan uid ile kullanıcı bilgisi çeker
  Future<UserModel> _fetchUserFromFirestore(User firebaseUser) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return UserModel(
          uid: firebaseUser.uid,
          email: data['email'] ?? firebaseUser.email ?? '',
          displayName: data['name'] ?? data['displayName'] ?? firebaseUser.displayName ?? '',
          kurumId: data['kurum_id'],
          role: data['role'],
        );
      }

      // Firestore'da users dokümanı yoksa sadece Auth bilgileriyle devam et
      return UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
      );
    } catch (e) {
      // Firestore okuma hatası durumunda yine Auth bilgileriyle devam et
      return UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
      );
    }
  }

  /// Uygulama açılışında mevcut oturumu kontrol et ve SessionManager'ı doldur
  Future<UserModel?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userModel = await _fetchUserFromFirestore(user);
    SessionManager.instance.setUser(userModel);
    return userModel;
  }

  /// Yeni Kurum ve Yönetici (Admin) oluşturma akışı
  /// 
  /// 1. Firebase Auth ile yeni kullanıcı oluştur
  /// 2. Firestore `kurumlar` koleksiyonuna kurumu kaydet ve id al
  /// 3. Firestore `users` koleksiyonuna kullanıcıyı 'admin' yetkisiyle kaydet
  /// 4. SessionManager'ı güncelle
  Future<UserModel> registerNewKurumAndAdmin({
    required String kurumAdi,
    required String displayName,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Firebase Auth ile hesap oluştur
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

      await user.updateDisplayName(displayName);

      // 2. Kurum oluştur ve yeni kurumun referansını/ID'sini al
      final kurumRef = await _firestore.collection('kurumlar').add({
        'name': kurumAdi.trim(),
        'durum': 'aktif',
        'olusturma_tarihi': FieldValue.serverTimestamp(),
      });
      final newKurumId = kurumRef.id;

      // 3. User dokümanını 'admin' rolüyle oluştur
      await _firestore.collection('users').doc(user.uid).set({
        'name': displayName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'kurum_id': newKurumId,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        kurumId: newKurumId,
        role: 'admin',
      );

      // 4. Session'ı güncelle
      SessionManager.instance.setUser(userModel);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Oturumu kapat
  Future<void> signOut() async {
    SessionManager.instance.clear();
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
    SessionManager.instance.clear();
    await user.delete();
  }

  /// Mevcut kullanıcı bilgilerini UserModel olarak döndür
  UserModel? getCurrentUserModel() {
    // SessionManager'da varsa oradan döndür (kurum_id bilgisi dahil)
    if (SessionManager.instance.currentUser != null) {
      return SessionManager.instance.currentUser;
    }

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
      case 'kurum-not-found':
        return e.message ?? 'Böyle bir kurum bulunamadı.';
      case 'kurum-mismatch':
        return e.message ?? 'Bu kuruma ait personel değilsiniz.';
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
