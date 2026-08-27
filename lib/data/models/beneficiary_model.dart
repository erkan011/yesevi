import 'package:cloud_firestore/cloud_firestore.dart';

/// İhtiyaç sahibi veri modeli
///
/// Saha personelinin harita üzerinden kaydettiği
/// ihtiyaç sahibi bilgilerini tutar.
/// `kurum_id` alanı SaaS izolasyonu için zorunludur.
class Beneficiary {
  final String id;
  final String? kurumId;
  final String fullName;
  final String phone;
  final String address;
  final String needStatus; // 'Bekliyor', 'Acil', 'Tamamlandı'
  final double latitude;
  final double longitude;
  final String addedBy;
  final DateTime createdAt;
  final String? notes;

  const Beneficiary({
    required this.id,
    this.kurumId,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.needStatus,
    required this.latitude,
    required this.longitude,
    required this.addedBy,
    required this.createdAt,
    this.notes,
  });

  /// Firestore'dan gelen veriden model oluşturma
  factory Beneficiary.fromFirestore(DocumentSnapshot doc) {
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

    return Beneficiary(
      id: doc.id,
      kurumId: data['kurum_id']?.toString(),
      fullName: data['fullName']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      needStatus: data['needStatus']?.toString() ?? 'Bekliyor',
      latitude: parseDouble(data['latitude']),
      longitude: parseDouble(data['longitude']),
      addedBy: data['addedBy']?.toString() ?? '',
      createdAt: parseDate(data['createdAt']),
      notes: data['notes']?.toString(),
    );
  }

  /// Modeli Firestore'a yazmak için Map'e çevirme
  Map<String, dynamic> toMap() {
    return {
      'kurum_id': kurumId,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'needStatus': needStatus,
      'latitude': latitude,
      'longitude': longitude,
      'addedBy': addedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }

  Beneficiary copyWith({
    String? id,
    String? kurumId,
    String? fullName,
    String? phone,
    String? address,
    String? needStatus,
    double? latitude,
    double? longitude,
    String? addedBy,
    DateTime? createdAt,
    String? notes,
  }) {
    return Beneficiary(
      id: id ?? this.id,
      kurumId: kurumId ?? this.kurumId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      needStatus: needStatus ?? this.needStatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}
