import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/enums/box_status.dart';

/// Bağış kutusu veri modeli
///
/// SaaS izolasyonu için `kurumId` alanı zorunludur.
/// Tüm CRUD işlemlerinde bu alanın dolu olması beklenir.
class DonationBox {
  final String id;
  final String? kurumId;
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
    this.kurumId,
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
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseDateNullable(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return DonationBox(
      id: doc.id,
      kurumId: data['kurum_id']?.toString(),
      shopName: data['shopName']?.toString() ?? '',
      latitude: parseDouble(data['latitude']),
      longitude: parseDouble(data['longitude']),
      droppedBy: data['droppedBy']?.toString() ?? '',
      droppedAt: parseDate(data['droppedAt']),
      status: data['status'] == 'collected'
          ? BoxStatus.collected
          : BoxStatus.waiting,
      collectedBy: data['collectedBy']?.toString(),
      collectedAt: parseDateNullable(data['collectedAt']),
      donationAmount: data['donationAmount'] != null ? parseDouble(data['donationAmount']) : null,
    );
  }

  /// Modeli Firestore'a yazmak için Map'e çevirme
  Map<String, dynamic> toMap() {
    return {
      'kurum_id': kurumId,
      'shopName': shopName,
      'latitude': latitude,
      'longitude': longitude,
      'droppedBy': droppedBy,
      'droppedAt': Timestamp.fromDate(droppedAt),
      'status': status == BoxStatus.collected ? 'collected' : 'dropped',
      'collectedBy': collectedBy,
      'collectedAt':
          collectedAt != null ? Timestamp.fromDate(collectedAt!) : null,
      'donationAmount': donationAmount,
    };
  }

  /// Kopya oluştur ve bazı alanları güncelle
  DonationBox copyWith({
    String? id,
    String? kurumId,
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
      kurumId: kurumId ?? this.kurumId,
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
