import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/enums/box_status.dart';

/// Bağış kutusu veri modeli
class DonationBox {
  final String id;
  final String shopName;
  final double latitude;
  final double longitude;
  final String droppedBy;
  final DateTime droppedAt;
  final BoxStatus status;
  final String? collectedBy;
  final DateTime? collectedAt;
  final double? donationAmount;

  const DonationBox({
    required this.id,
    required this.shopName,
    required this.latitude,
    required this.longitude,
    required this.droppedBy,
    required this.droppedAt,
    this.status = BoxStatus.waiting,
    this.collectedBy,
    this.collectedAt,
    this.donationAmount,
  });

  /// Firestore'dan gelen veriden model oluşturma
  factory DonationBox.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DonationBox(
      id: doc.id,
      shopName: data['shopName'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      droppedBy: data['droppedBy'] ?? '',
      droppedAt: (data['droppedAt'] as Timestamp).toDate(),
      status: data['status'] == 'collected'
          ? BoxStatus.collected
          : BoxStatus.waiting,
      collectedBy: data['collectedBy'],
      collectedAt: data['collectedAt'] != null
          ? (data['collectedAt'] as Timestamp).toDate()
          : null,
      donationAmount: data['donationAmount']?.toDouble(),
    );
  }

  /// Modeli Firestore'a yazmak için Map'e çevirme
  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'latitude': latitude,
      'longitude': longitude,
      'droppedBy': droppedBy,
      'droppedAt': Timestamp.fromDate(droppedAt),
      'status': status == BoxStatus.collected ? 'collected' : 'waiting',
      'collectedBy': collectedBy,
      'collectedAt':
          collectedAt != null ? Timestamp.fromDate(collectedAt!) : null,
      'donationAmount': donationAmount,
    };
  }

  /// Kopya oluştur ve bazı alanları güncelle
  DonationBox copyWith({
    String? id,
    String? shopName,
    double? latitude,
    double? longitude,
    String? droppedBy,
    DateTime? droppedAt,
    BoxStatus? status,
    String? collectedBy,
    DateTime? collectedAt,
    double? donationAmount,
  }) {
    return DonationBox(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      droppedBy: droppedBy ?? this.droppedBy,
      droppedAt: droppedAt ?? this.droppedAt,
      status: status ?? this.status,
      collectedBy: collectedBy ?? this.collectedBy,
      collectedAt: collectedAt ?? this.collectedAt,
      donationAmount: donationAmount ?? this.donationAmount,
    );
  }
}
