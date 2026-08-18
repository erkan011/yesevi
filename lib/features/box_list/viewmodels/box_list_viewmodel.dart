import 'package:flutter/material.dart';

import 'dart:async';

import '../../../core/enums/box_status.dart';
import '../../../data/models/donation_box_model.dart';
import '../../../data/services/firestore_service.dart';

/// Liste sayfası state yönetimi
class BoxListViewModel extends ChangeNotifier {
  final BoxService _boxService = BoxService();
  StreamSubscription? _boxSubscription;
  // Arama kontrolcüsü
  final TextEditingController searchController = TextEditingController();

  // Tab (Bekleyen/Alındı) state
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  // Arama metni
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ── Firestore Verileri ──
  List<DonationBox> _allBoxes = [];

  BoxListViewModel() {
    _boxSubscription = _boxService.getBoxesStream().listen((boxesList) {
      _allBoxes = boxesList;
      notifyListeners();
    });
  }

  /// Seçili tab değiştiğinde
  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  /// Arama metni değiştiğinde
  void onSearchChanged(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  /// Filtrelenmiş liste
  List<DonationBox> get filteredBoxes {
    final statusToFilter = _currentTabIndex == 0
        ? BoxStatus.waiting
        : BoxStatus.collected;

    return _allBoxes.where((box) {
      final matchesStatus = box.status == statusToFilter;
      final matchesSearch =
          box.shopName.toLowerCase().contains(_searchQuery);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _boxSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
