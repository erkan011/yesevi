// Home View — Ana sayfa (Bottom Navigation ile sayfa yönetimi)
//
// Bu sayfa Map, List, İhtiyaç Sahipleri ve Settings sayfalarını
// Bottom Navigation Bar ile birleştirir.

import 'package:flutter/material.dart';

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

  final List<Widget> _pages = [
    const MapView(),
    const BoxListView(),
    const BeneficiariesView(),
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
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
      ),
    );
  }
}
