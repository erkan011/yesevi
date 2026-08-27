import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/beneficiary_model.dart';
import 'session_manager.dart';

/// Firestore İhtiyaç Sahipleri (Beneficiaries) servis katmanı
///
/// ⚠️ SaaS İzolasyonu: Tüm okuma sorguları `kurum_id` filtresi ile yapılır.
/// Tüm yazma işlemlerinde `kurum_id` alanı otomatik olarak eklenir.
class BeneficiaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'beneficiaries';

  /// Aktif kurum_id'yi SessionManager'dan alır
  String? get _kurumId => SessionManager.instance.kurumId;

  /// Aktif kuruma ait ihtiyaç sahiplerini gerçek zamanlı (Stream) çeker
  ///
  /// ⚠️ kurum_id filtresi zorunlu — diğer kurumların verileri görünmez
  Stream<List<Beneficiary>> getBeneficiariesStream() {
    if (_kurumId == null || _kurumId!.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('kurum_id', isEqualTo: _kurumId)
        .snapshots()
        .map((snapshot) {
          final sortedList = snapshot.docs
              .map((doc) => Beneficiary.fromFirestore(doc))
              .toList();
          sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return sortedList;
        });
  }

  /// Yeni ihtiyaç sahibi ekleme (CREATE)
  ///
  /// kurum_id otomatik olarak SessionManager'dan eklenir
  Future<void> addBeneficiary(Beneficiary beneficiary) async {
    final data = beneficiary.toMap();
    // kurum_id'nin kesinlikle eklenmesini garanti et
    data['kurum_id'] = _kurumId;
    await _firestore.collection(_collectionName).add(data);
  }

  /// İhtiyaç sahibi güncelleme (UPDATE)
  Future<void> updateBeneficiary(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collectionName).doc(id).update(data);
  }

  /// İhtiyaç sahibi silme (DELETE)
  Future<void> deleteBeneficiary(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }
}
