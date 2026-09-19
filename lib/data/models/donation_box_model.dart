import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/enums/box_status.dart';

/// Tek bir gider kalemi
class ExpenseItem {
  final String type; // Gider türü (Yakıt, Diğer vb.)
  final double amount; // Gider tutarı

  const ExpenseItem({
    required this.type,
    required this.amount,
  });

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      type: map['type']?.toString() ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
    };
  }
}

/// Bağış kutusu veri modeli
///
/// SaaS izolasyonu için `kurumId` alanı zorunludur.
/// Tüm CRUD işlemlerinde bu alanın dolu olması beklenir.
class DonationBox {
  final String id;
  final String? kurumId;
  final String shopName;
  final String? shopPhone; // Mekan numarası
  final double latitude;
  final double longitude;
  final String droppedBy;
  final String? droppedByPhone; // Bırakan kişinin telefonu
  final DateTime droppedAt;
  final BoxStatus status;
  final String? recipientName; // Teslim alan kişi adı soyadı
  final String? recipientPhone; // Teslim alan kişi numarası
  final String? imageUrl; // Fotoğraf URL'si
  final String? collectedBy;
  final DateTime? collectedAt;
  final double? donationAmount;
  final List<ExpenseItem>? expenses; // Giderler listesi

  const DonationBox({
    required this.id,
    this.kurumId,
    required this.shopName,
    this.shopPhone,
    required this.latitude,
    required this.longitude,
    required this.droppedBy,
    this.droppedByPhone,
    required this.droppedAt,
    this.status = BoxStatus.waiting,
    this.recipientName,
    this.recipientPhone,
    this.imageUrl,
    this.collectedBy,
    this.collectedAt,
    this.donationAmount,
    this.expenses,
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

    BoxStatus parseStatus(dynamic value) {
      final statusStr = value?.toString() ?? 'dropped';
      switch (statusStr) {
        case 'collected':
        case 'collected_and_removed':
        case 'removed':
          return BoxStatus.collected;
        case 'emptied':
        case 'dropped_yellow':
          return BoxStatus.emptied;
        default:
          return BoxStatus.waiting;
      }
    }

    // Giderleri parse et
    List<ExpenseItem>? parseExpenses(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value
            .map((e) => ExpenseItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      return null;
    }

    return DonationBox(
      id: doc.id,
      kurumId: data['kurum_id']?.toString(),
      shopName: data['shopName']?.toString() ?? '',
      shopPhone: data['shopPhone']?.toString(),
      latitude: parseDouble(data['latitude']),
      longitude: parseDouble(data['longitude']),
      droppedBy: data['droppedBy']?.toString() ?? '',
      droppedByPhone: data['droppedByPhone']?.toString(),
      droppedAt: parseDate(data['droppedAt']),
      status: parseStatus(data['status']),
      recipientName: data['recipientName']?.toString(),
      recipientPhone: data['recipientPhone']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      collectedBy: data['collectedBy']?.toString(),
      collectedAt: parseDateNullable(data['collectedAt']),
      donationAmount: data['donationAmount'] != null ? parseDouble(data['donationAmount']) : null,
      expenses: parseExpenses(data['expenses']),
    );
  }

  /// Modeli Firestore'a yazmak için Map'e çevirme
  Map<String, dynamic> toMap() {
    String statusString;
    switch (status) {
      case BoxStatus.collected:
        statusString = 'collected';
        break;
      case BoxStatus.emptied:
        statusString = 'emptied';
        break;
      case BoxStatus.waiting:
      default:
        statusString = 'dropped';
    }

    return {
      'kurum_id': kurumId,
      'shopName': shopName,
      'shopPhone': shopPhone,
      'latitude': latitude,
      'longitude': longitude,
      'droppedBy': droppedBy,
      'droppedByPhone': droppedByPhone,
      'droppedAt': Timestamp.fromDate(droppedAt),
      'status': statusString,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'imageUrl': imageUrl,
      'collectedBy': collectedBy,
      'collectedAt': collectedAt != null ? Timestamp.fromDate(collectedAt!) : null,
      'donationAmount': donationAmount,
      'expenses': expenses?.map((e) => e.toMap()).toList(),
    };
  }

  /// Toplam gider tutarı
  double get totalExpenses {
    if (expenses == null || expenses!.isEmpty) return 0.0;
    return expenses!.fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Net bağış (Bağış - Giderler)
  double get netDonation {
    return (donationAmount ?? 0.0) - totalExpenses;
  }

  /// Kopya oluştur ve bazı alanları güncelle
  DonationBox copyWith({
    String? id,
    String? kurumId,
    String? shopName,
    String? shopPhone,
    double? latitude,
    double? longitude,
    String? droppedBy,
    String? droppedByPhone,
    DateTime? droppedAt,
    BoxStatus? status,
    String? recipientName,
    String? recipientPhone,
    String? imageUrl,
    String? collectedBy,
    DateTime? collectedAt,
    double? donationAmount,
    List<ExpenseItem>? expenses,
  }) {
    return DonationBox(
      id: id ?? this.id,
      kurumId: kurumId ?? this.kurumId,
      shopName: shopName ?? this.shopName,
      shopPhone: shopPhone ?? this.shopPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      droppedBy: droppedBy ?? this.droppedBy,
      droppedByPhone: droppedByPhone ?? this.droppedByPhone,
      droppedAt: droppedAt ?? this.droppedAt,
      status: status ?? this.status,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      imageUrl: imageUrl ?? this.imageUrl,
      collectedBy: collectedBy ?? this.collectedBy,
      collectedAt: collectedAt ?? this.collectedAt,
      donationAmount: donationAmount ?? this.donationAmount,
      expenses: expenses ?? this.expenses,
    );
  }
}
