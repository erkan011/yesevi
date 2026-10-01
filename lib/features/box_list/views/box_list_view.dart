import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/box_status.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/box_card.dart';
import '../viewmodels/box_list_viewmodel.dart';
import 'box_detail_view.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Bağış Kutuları'),
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
                  Tab(text: 'Boşaltılanlar'),
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
                    _tabController.index == 0 
                        ? Icons.inventory_2_outlined 
                        : _tabController.index == 1
                            ? Icons.inbox_outlined
                            : Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.textTertiary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tabController.index == 0
                        ? 'Bekleyen kutu bulunamadı'
                        : _tabController.index == 1
                            ? 'Boşaltılan kutu bulunamadı'
                            : 'Alınan kutu bulunamadı',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
              final numberFormat = NumberFormat('#,##0.00', 'tr_TR');
              
              // Alt bilgi metni
              String subtitle;
              if (box.status == BoxStatus.collected) {
                subtitle = '${box.collectedBy ?? "-"} • ${dateFormat.format(box.collectedAt ?? box.droppedAt)}';
                if (box.donationAmount != null) {
                  subtitle += ' • ₺${numberFormat.format(box.donationAmount)}';
                }
              } else if (box.status == BoxStatus.emptied) {
                subtitle = '${box.collectedBy ?? "-"} • Boşaltıldı'; // collectedBy includes emptiedBy here via firestore update
                if (box.collectedAt != null) {
                  subtitle += ' • ${dateFormat.format(box.collectedAt!)}';
                }
                if (box.donationAmount != null) {
                  subtitle += ' • ₺${numberFormat.format(box.donationAmount)}';
                }
              } else {
                subtitle = '${box.droppedBy} • ${dateFormat.format(box.droppedAt)}';
              }

              return BoxCard(
                shopName: box.shopName,
                status: box.status.name,
                droppedBy: subtitle,
                date: '',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BoxDetailView(box: box),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
