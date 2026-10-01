// Home View — Ana sayfa (Bottom Navigation ile sayfa yönetimi)
//
// Bu sayfa Map, List, İhtiyaç Sahipleri ve Settings sayfalarını
// Bottom Navigation Bar ile birleştirir.
//
// BUGFIX: Geri tuşu hatası — PopScope ile ana haritaya yönlendirme

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../map/views/map_view.dart';
import '../../box_list/views/box_list_view.dart';
import '../../beneficiaries/views/beneficiaries_view.dart';
import '../../settings/views/settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  // Lazy yükleme: Sadece gerektiğinde widget oluştur
  final List<Widget?> _pages = [null, null, null, null];

  Widget _getPage(int index) {
    if (_pages[index] == null) {
      switch (index) {
        case 0:
          _pages[index] = const MapView();
          break;
        case 1:
          _pages[index] = const BoxListView();
          break;
        case 2:
          _pages[index] = const BeneficiariesView();
          break;
        case 3:
          _pages[index] = const SettingsView();
          break;
      }
    }
    return _pages[index]!;
  }

  /// Geri tuşu davranışı
  Future<bool> _onWillPop() async {
    // Harita sayfasında değilsek → harita sayfasına dön
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    
    // Harita sayfasındaysak → uygulama çıkış onayı
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış'),
        content: const Text('Uygulamadan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _getPage(0),
            _getPage(1),
            _getPage(2),
            _getPage(3),
          ],
        ),
        bottomNavigationBar: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final navBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

            return Container(
              decoration: BoxDecoration(
                color: navBg,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : AppColors.shadow,
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: navBg,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.map_outlined),
                      activeIcon: Icon(Icons.map),
                      label: 'Harita',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.list_alt_outlined),
                      activeIcon: Icon(Icons.list_alt),
                      label: 'Kutular',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people_outline_rounded),
                      activeIcon: Icon(Icons.people_rounded),
                      label: 'İhtiyaç',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings_outlined),
                      activeIcon: Icon(Icons.settings),
                      label: 'Ayarlar',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
