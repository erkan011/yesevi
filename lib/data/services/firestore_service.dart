import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/donation_box_model.dart';
import '../../core/enums/box_status.dart';

/// Firestore bağlantısı ve Kutular (Boxes) için servis katmanı
class BoxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'boxes';

  /// Tüm bağış kutularını gerçek zamanlı (Stream) çeker
  Stream<List<DonationBox>> getBoxesStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('droppedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DonationBox.fromFirestore(doc))
            .toList());
  }

  /// Yeni kutu bırakma işlemi (CREATE)
  Future<void> addBox(DonationBox box) async {
    await _firestore.collection(_collectionName).doc(box.id).set(box.toMap());
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
