import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/donation_box_model.dart';
import '../../core/enums/box_status.dart';
import 'session_manager.dart';

/// Firestore bağlantısı ve Kutular (Boxes) için servis katmanı
///
/// ⚠️ SaaS İzolasyonu: Tüm okuma sorguları `kurum_id` filtresi ile yapılır.
/// Tüm yazma işlemlerinde `kurum_id` alanı otomatik olarak eklenir.
class BoxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'boxes';

  /// Aktif kurum_id'yi SessionManager'dan alır
  String? get _kurumId => SessionManager.instance.kurumId;

  /// Aktif kuruma ait bağış kutularını gerçek zamanlı (Stream) çeker
  /// 
  /// ⚠️ kurum_id filtresi zorunlu — diğer kurumların verileri görünmez
  Stream<List<DonationBox>> getBoxesStream() {
    if (_kurumId == null || _kurumId!.isEmpty) {
      // kurum_id yoksa boş stream döndür (güvenlik)
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('kurum_id', isEqualTo: _kurumId)
        .snapshots()
        .map((snapshot) {
          final sortedList = snapshot.docs
              .map((doc) => DonationBox.fromFirestore(doc))
              .toList();
          sortedList.sort((a, b) => b.droppedAt.compareTo(a.droppedAt));
          return sortedList;
        });
  }

  /// Yeni kutu bırakma işlemi (CREATE)
  /// 
  /// kurum_id otomatik olarak modele eklenir
  Future<void> addBox(DonationBox box) async {
    final boxWithKurum = box.copyWith(kurumId: _kurumId);
    await _firestore.collection(_collectionName).doc(box.id).set(boxWithKurum.toMap());
  }

  /// Kutu detaylarını güncelleme veya Kutuyu Teslim Alma işlemi (UPDATE)
  Future<void> updateBox(DonationBox box) async {
    await _firestore
        .collection(_collectionName)
        .doc(box.id)
        .update(box.toMap());
  }

  /// Kutuyu Teslim Al (özel helper metot)
  Future<void> collectBox({
    required String boxId,
    required String collectedBy,
    required double donationAmount,
  }) async {
    await _firestore.collection(_collectionName).doc(boxId).update({
      'status': 'collected',
      'collectedBy': collectedBy,
      'collectedAt': FieldValue.serverTimestamp(),
      'donationAmount': donationAmount,
    });
  }

  /// Bağış kutusu silme işlemi (DELETE)
  Future<void> deleteBox(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }
}
