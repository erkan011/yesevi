import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/box_card.dart';
import '../viewmodels/box_list_viewmodel.dart';
import '../../auth/views/login_view.dart'; // ListenableBuilder importu için

/// Kutuların liste halinde gösterildiği ekran
class BoxListView extends StatefulWidget {
  const BoxListView({super.key});

  @override
  State<BoxListView> createState() => _BoxListViewState();
}

class _BoxListViewState extends State<BoxListView>
    with SingleTickerProviderStateMixin {
  late final BoxListViewModel _viewModel;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _viewModel = BoxListViewModel();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _viewModel.setTabIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Bağış Kutuları'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Arama Çubuğu
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMD,
                  vertical: 8,
                ),
                child: AppTextField(
                  controller: _viewModel.searchController,
                  hintText: 'Mekan adı ara...',
                  prefixIcon: Icons.search_rounded,
                  onChanged: _viewModel.onSearchChanged,
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Bekleyenler'),
                  Tab(text: 'Alınanlar'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final boxes = _viewModel.filteredBoxes;

          if (boxes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.textTertiary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kutu bulunamadı',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: boxes.length,
            itemBuilder: (context, index) {
              final box = boxes[index];
              final dateFormat = DateFormat('dd MMM yyyy', 'tr_TR');
              
              return BoxCard(
                shopName: box.shopName,
                status: box.status.name,
                droppedBy: box.droppedBy,
                date: dateFormat.format(box.droppedAt),
                onTap: () {
                  // İsteğe bağlı: Kutu detay modals eklenebilir.
                },
              );
            },
          );
        },
      ),
    );
  }
}
