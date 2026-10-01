import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/beneficiary_model.dart';
import '../viewmodels/beneficiaries_viewmodel.dart';
import 'add_beneficiary_view.dart';

/// İhtiyaç Sahipleri Ekranı
///
/// Liste ve harita görünümü arasında geçiş yapılabilir.
/// Arama, filtreleme ve FAB ile yeni kayıt ekleme desteği sunar.
class BeneficiariesView extends StatefulWidget {
  const BeneficiariesView({super.key});

  @override
  State<BeneficiariesView> createState() => _BeneficiariesViewState();
}

class _BeneficiariesViewState extends State<BeneficiariesView> {
  late final BeneficiariesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BeneficiariesViewModel();
    _viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          'İhtiyaç Sahipleri',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        bottom: TabBar(
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Liste', icon: Icon(Icons.list_alt_rounded)),
            Tab(text: 'Harita', icon: Icon(Icons.map_outlined)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Arama & Filtre Bölümü ──
          _buildSearchAndFilter(),

          // ── İçerik (Sekmeler) ──
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(), // Harita ile çakışmaması için kaydırmayı kapat
              children: [
                _buildListView(),
                _buildMapView(),
              ],
            ),
          ),
        ],
      ),
      // ── Yeni Kişi Ekle FAB ──
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_beneficiary',
        onPressed: () => _navigateToAddBeneficiary(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: Text(
          'Yeni Ekle',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

  /// Arama çubuğu ve durum filtresi
  Widget _buildSearchAndFilter() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Arama çubuğu
          TextField(
            controller: _viewModel.searchController,
            onChanged: _viewModel.onSearchChanged,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ad, adres veya telefon ile ara...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor ?? AppColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Durum filtre chip'leri
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: BeneficiariesViewModel.filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final filter = BeneficiariesViewModel.filterOptions[index];
                final isSelected = _viewModel.selectedFilter == filter;
                return ChoiceChip(
                  label: Text(
                    filter,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: theme.inputDecorationTheme.fillColor ?? AppColors.inputFill,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide.none,
                  onSelected: (_) => _viewModel.setFilter(filter),
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Liste görünümü
  Widget _buildListView() {
    final items = _viewModel.filteredBeneficiaries;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) => _buildBeneficiaryCard(items[index]),
    );
  }

  /// Harita görünümü  
  Widget _buildMapView() {
    final items = _viewModel.filteredBeneficiaries;

    final markers = items.map((b) {
      return Marker(
        markerId: MarkerId(b.id),
        position: LatLng(b.latitude, b.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerHue(b.needStatus),
        ),
        infoWindow: InfoWindow(
          title: b.fullName,
          snippet: 'Durum: ${b.needStatus}',
        ),
        onTap: () => _showBeneficiaryDetail(b),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(
          AppConstants.defaultLatitude,
          AppConstants.defaultLongitude,
        ),
        zoom: AppConstants.defaultZoom,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  /// Kişi kartı
  Widget _buildBeneficiaryCard(Beneficiary b) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF252525) : Colors.white;
    final dateFormat = DateFormat('dd MMM yyyy', 'tr_TR');
    final statusColor = _getStatusColor(b.needStatus);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showBeneficiaryDetail(b),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst satır (İsim + Durum badge)
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // İsim ve adres
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.fullName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b.address,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Durum badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        b.needStatus,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Alt satır (Telefon + Tarih)
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      b.phone,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateFormat.format(b.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Boş durum ekranı
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz kayıt yok',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sağ alttaki butona tıklayarak\nyeni ihtiyaç sahibi ekleyin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Kişi detay bottom sheet
  void _showBeneficiaryDetail(Beneficiary b) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR');
    final statusColor = _getStatusColor(b.needStatus);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEE2E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.fullName,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(ctx).textTheme.titleLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    b.needStatus,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Detay satırları
                    _buildDetailRow(
                      ctx,
                      icon: Icons.phone_outlined,
                      label: 'Telefon',
                      value: b.phone,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      ctx,
                      icon: Icons.location_on_outlined,
                      label: 'Adres',
                      value: b.address,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      ctx,
                      icon: Icons.person_outline_rounded,
                      label: 'Ekleyen',
                      value: b.addedBy,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      ctx,
                      icon: Icons.calendar_today_outlined,
                      label: 'Tarih',
                      value: dateFormat.format(b.createdAt),
                    ),
                    if (b.notes != null && b.notes!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        ctx,
                        icon: Icons.notes_rounded,
                        label: 'Not',
                        value: b.notes!,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Durum güncelleme butonları
                    Text(
                      'Durumu Güncelle',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatusButton(ctx, b.id, 'Bekliyor', AppColors.statusWaiting),
                        const SizedBox(width: 8),
                        _buildStatusButton(ctx, b.id, 'Acil', AppColors.error),
                        const SizedBox(width: 8),
                        _buildStatusButton(ctx, b.id, 'Tamamlandı', AppColors.statusCollected),
                      ],
                    ),

                    SizedBox(
                      height: MediaQuery.of(ctx).padding.bottom + 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusButton(BuildContext ctx, String id, String status, Color color) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          _viewModel.updateNeedStatus(id, status);
          Navigator.pop(ctx);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(
          status,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Detay satırı widget'ı
  Widget _buildDetailRow(BuildContext ctx, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(ctx).textTheme.titleMedium?.color,
            ),
          ),
        ),
      ],
    );
  }

  /// Yeni kişi ekleme sayfasına git
  void _navigateToAddBeneficiary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddBeneficiaryView(),
      ),
    );
  }

  /// Durum rengini döndür
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Acil':
        return AppColors.error;
      case 'Tamamlandı':
        return AppColors.statusCollected;
      case 'Bekliyor':
      default:
        return AppColors.statusWaiting;
    }
  }

  /// Harita marker rengi
  double _getMarkerHue(String status) {
    switch (status) {
      case 'Acil':
        return BitmapDescriptor.hueRed;
      case 'Tamamlandı':
        return BitmapDescriptor.hueGreen;
      case 'Bekliyor':
      default:
        return BitmapDescriptor.hueYellow;
    }
  }
}
