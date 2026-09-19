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
  /// Tab 0: Bekleyenler (waiting)
  /// Tab 1: Boşaltılanlar (emptied)
  /// Tab 2: Alınanlar (collected)
  List<DonationBox> get filteredBoxes {
    return _allBoxes.where((box) {
      bool matchesStatus = false;
      if (_currentTabIndex == 0) {
        matchesStatus = box.status == BoxStatus.waiting;
      } else if (_currentTabIndex == 1) {
        matchesStatus = box.status == BoxStatus.emptied;
      } else {
        matchesStatus = box.status == BoxStatus.collected;
      }

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
