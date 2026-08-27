import 'package:flutter/material.dart';

import 'dart:async';

import '../../../data/models/beneficiary_model.dart';
import '../../../data/services/beneficiary_service.dart';

/// İhtiyaç Sahipleri ekranı state yönetimi
class BeneficiariesViewModel extends ChangeNotifier {
  final BeneficiaryService _service = BeneficiaryService();
  StreamSubscription? _subscription;

  // ── Liste Verisi ──
  List<Beneficiary> _beneficiaries = [];
  List<Beneficiary> get beneficiaries => _beneficiaries;

  // ── Arama ──
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';

  // ── Filtre (needStatus) ──
  String _selectedFilter = 'Tümü';
  String get selectedFilter => _selectedFilter;

  static const List<String> filterOptions = [
    'Tümü',
    'Bekliyor',
    'Acil',
    'Tamamlandı',
  ];

  // ── Görünüm Modu ──
  bool _isMapView = false;
  bool get isMapView => _isMapView;

  BeneficiariesViewModel() {
    _initStream();
  }

  void _initStream() {
    _subscription = _service.getBeneficiariesStream().listen((list) {
      _beneficiaries = list;
      notifyListeners();
    });
  }

  /// Arama metni değiştiğinde
  void onSearchChanged(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  /// Filtre değiştiğinde
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Görünüm modunu değiştir (Liste ↔ Harita)
  void toggleViewMode() {
    _isMapView = !_isMapView;
    notifyListeners();
  }

  /// Filtrelenmiş liste
  List<Beneficiary> get filteredBeneficiaries {
    return _beneficiaries.where((b) {
      // Durum filtresi
      final matchesFilter = _selectedFilter == 'Tümü' ||
          b.needStatus == _selectedFilter;

      // Arama filtresi
      final matchesSearch = _searchQuery.isEmpty ||
          b.fullName.toLowerCase().contains(_searchQuery) ||
          b.address.toLowerCase().contains(_searchQuery) ||
          b.phone.contains(_searchQuery);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  /// İhtiyaç sahibini sil
  Future<void> deleteBeneficiary(String id) async {
    await _service.deleteBeneficiary(id);
  }

  /// İhtiyaç durumunu güncelle
  Future<void> updateNeedStatus(String id, String newStatus) async {
    await _service.updateBeneficiary(id, {'needStatus': newStatus});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
