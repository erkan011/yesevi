import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/box_status.dart';
import '../../../data/models/donation_box_model.dart';
import '../viewmodels/map_viewmodel.dart';
import '../../box_action/widgets/box_action_sheet.dart';

/// Harita Sayfası (Ana Sayfa)
///
/// Google Maps üzerinde bağış kutularının pin olarak gösterildiği,
/// pinlere tıklandığında Bottom Sheet açılan modern harita ekranı.
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late final MapViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MapViewModel();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});

    // Bottom Sheet açılması gerekiyorsa
    if (_viewModel.isBottomSheetOpen && _viewModel.selectedBox != null) {
      _showBoxBottomSheet(_viewModel.selectedBox!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Harita ──
          _buildMap(),

          // ── Üst Bilgi Çubuğu (Gradient Overlay) ──
          _buildTopBar(),

          // ── Konum Hatası ──
          if (_viewModel.locationError != null) _buildLocationErrorBanner(),

          // ── Sağ Alt Butonlar ──
          _buildFloatingButtons(),
        ],
      ),
    );
  }

  /// Google Maps widget'ı
  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: _viewModel.initialCameraPosition,
      onMapCreated: _viewModel.onMapCreated,
      markers: _viewModel.markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      mapType: MapType.normal,
      padding: const EdgeInsets.only(
        top: 100,
        bottom: 80,
      ),
      style: _mapStyle,
    );
  }

  /// Üst gradient bar — sayfa başlığı
  Widget _buildTopBar() {
    final waitingCount = _viewModel.boxes
        .where((b) => b.status == BoxStatus.waiting)
        .length;
    final emptiedCount = _viewModel.boxes
        .where((b) => b.status == BoxStatus.emptied)
        .length;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 20,
          right: 20,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF121212)
                  : Colors.white,
              (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF121212)
                  : Colors.white).withOpacity(0.95),
              (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF121212)
                  : Colors.white).withOpacity(0.0),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Row(
          children: [
            // Sol — Başlık
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bağış Kutusu Noktaları',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_viewModel.boxes.length} kutu takip ediliyor',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),

            // Sağ — Durum göstergeleri
            _buildStatusChip(
              count: waitingCount,
              label: 'Bekliyor',
              color: AppColors.statusWaiting,
            ),
            const SizedBox(width: 8),
            _buildStatusChip(
              count: emptiedCount,
              label: 'Boşaltıldı',
              color: AppColors.statusEmptied,
            ),
          ],
        ),
      ),
    );
  }

  /// Durum chip'i (üst bar için)
  Widget _buildStatusChip({
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Konum hatası banner'ı
  Widget _buildLocationErrorBanner() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: Material(
        borderRadius: BorderRadius.circular(14),
        elevation: 4,
        shadowColor: AppColors.shadow,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.warning.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _viewModel.locationError!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _viewModel.clearLocationError();
                  _viewModel.refreshLocation();
                },
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sağ alt FAB butonları
  Widget _buildFloatingButtons() {
    return Positioned(
      right: 16,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Konumuma git butonu
          _buildCircleFAB(
            icon: Icons.my_location_rounded,
            onTap: _viewModel.goToMyLocation,
            heroTag: 'my_location',
          ),
          const SizedBox(height: 12),

          // Kutu ekle butonu
          FloatingActionButton(
            heroTag: 'add_box',
            onPressed: () {
              BoxActionSheet.showDropBoxSheet(context);
            },
            backgroundColor: AppColors.primary,
            elevation: 3,
            child: const Icon(
              Icons.add_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Yuvarlak mini FAB
  Widget _buildCircleFAB({
    required IconData icon,
    required VoidCallback onTap,
    required String heroTag,
  }) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      onPressed: onTap,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252525) : Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 22,
        color: AppColors.primary,
      ),
    );
  }

  // ────────────────────────────────────────────
  //  BOTTOM SHEET
  // ────────────────────────────────────────────

  /// Kutu bilgi Bottom Sheet'ini göster
  void _showBoxBottomSheet(DonationBox box) {
    final isWaiting = box.status == BoxStatus.waiting;
    final isEmptied = box.status == BoxStatus.emptied;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR');
    final distance = _viewModel.getDistanceToBox(box);

    // Durum rengi ve metni
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isWaiting) {
      statusColor = AppColors.statusWaiting;
      statusText = 'Bekliyor';
      statusIcon = Icons.inventory_2_outlined;
    } else if (isEmptied) {
      statusColor = AppColors.statusEmptied;
      statusText = 'Boşaltıldı';
      statusIcon = Icons.inbox_outlined;
    } else {
      statusColor = AppColors.statusCollected;
      statusText = 'Alındı';
      statusIcon = Icons.check_circle_outline_rounded;
    }

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
              // ── Tutma Çubuğu ──
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
                    // ── Başlık Satırı ──
                    Row(
                      children: [
                        // Durum İkonu
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            statusIcon,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // İsim ve Durum
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                box.shopName,
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
                                    statusText,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: statusColor,
                                    ),
                                  ),
                                  if (distance != null) ...[
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.near_me_outlined,
                                      size: 14,
                                      color: AppColors.textTertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      distance,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Bırakan Kişi Bilgileri ──
                    _buildSectionHeader(ctx, 'Bırakan Personel'),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      ctx,
                      icon: Icons.person_outline_rounded,
                      label: 'İsim',
                      value: box.droppedBy,
                    ),
                    if (box.droppedByPhone != null && box.droppedByPhone!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        ctx,
                        icon: Icons.phone_outlined,
                        label: 'Telefon',
                        value: box.droppedByPhone!,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      ctx,
                      icon: Icons.calendar_today_outlined,
                      label: 'Tarih',
                      value: dateFormat.format(box.droppedAt),
                    ),

                    // (Teslim Alan Kişi bölümü kaldırıldı)

                    // ── Mekan Numarası ──
                    if (box.shopPhone != null && box.shopPhone!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        ctx,
                        icon: Icons.store_outlined,
                        label: 'Mekan No',
                        value: box.shopPhone!,
                      ),
                    ],

                    // Alındıysa ek bilgiler
                    if (box.status == BoxStatus.collected) ...[
                      const SizedBox(height: 16),
                      _buildSectionHeader(ctx, 'Toplama Bilgileri'),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        ctx,
                        icon: Icons.person_outline_rounded,
                        label: 'Alan',
                        value: box.collectedBy ?? '-',
                      ),
                      if (box.collectedAt != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          ctx,
                          icon: Icons.event_available_outlined,
                          label: 'Alınma',
                          value: dateFormat.format(box.collectedAt!),
                        ),
                      ],
                      if (box.donationAmount != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          ctx,
                          icon: Icons.payments_outlined,
                          label: 'Bağış',
                          value:
                              '₺${NumberFormat('#,##0.00', 'tr_TR').format(box.donationAmount)}',
                          valueColor: AppColors.primary,
                          isBold: true,
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),

                    // ── Aksiyon Butonları (3 buton) ──
                    if (isWaiting || isEmptied) ...[
                      // Yol Tarifi
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _viewModel.openDirections(box);
                          },
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text('Yol Tarifi'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          // Kutuyu Boşalt
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                BoxActionSheet.showEmptyBoxSheet(context, box);
                              },
                              icon: const Icon(Icons.inbox_outlined, size: 18),
                              label: const Text('Boşalt'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.statusEmptied,
                                side: const BorderSide(
                                  color: AppColors.statusEmptied,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Kutuyu Al
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                BoxActionSheet.showCollectBoxSheet(context, box);
                              },
                              icon: const Icon(Icons.archive_outlined, size: 18),
                              label: const Text('Kutuyu Al'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

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
    ).whenComplete(() {
      _viewModel.closeBottomSheet();
    });
  }


  /// Bölüm başlığı
  Widget _buildSectionHeader(BuildContext ctx, String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(ctx).textTheme.bodyMedium?.color,
        letterSpacing: 0.3,
      ),
    );
  }

  /// Detay satırı (ikon + etiket + değer)
  Widget _buildDetailRow(BuildContext ctx, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
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
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: valueColor ?? Theme.of(ctx).textTheme.titleMedium?.color,
            ),
          ),
        ),
      ],
    );
  }

  // ── Minimal Harita Stili (Opsiyonel — daha temiz görüntü) ──
  static const String _mapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  }
]
''';
}
