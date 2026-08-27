import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/location_service.dart';
import 'app_button.dart';

/// Harita üzerinden manuel konum seçme sayfası
class MapPickerView extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerView({super.key, this.initialLocation});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  late CameraPosition _cameraPosition;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _cameraPosition = CameraPosition(
      target: widget.initialLocation ??
          const LatLng(
            AppConstants.defaultLatitude,
            AppConstants.defaultLongitude,
          ),
      zoom: 16.0,
    );

    if (widget.initialLocation == null) {
      _goToCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await _locationService.getCurrentLocation();
      final latLng = LatLng(position.latitude, position.longitude);
      
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16.0),
        ),
      );
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    _cameraPosition = position;
  }

  void _onSelectTap() {
    Navigator.of(context).pop(_cameraPosition.target);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Konum Seçin'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _cameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Merkez İkon (Marker yerini belirten ikon)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40), // İkonun alt kısmı merkeze gelsin
              child: Icon(
                Icons.location_on,
                size: 50,
                color: AppColors.primary,
              ),
            ),
          ),
          
          // Sağ alt GPS butonu
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton.small(
              heroTag: 'map_picker_gps',
              onPressed: _goToCurrentLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              child: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
            ),
          ),
          
          // Alt Bilgi ve Buton
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Haritayı kaydırarak kırmızı pini hedefe getirin ve "Seç" butonuna basın.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: AppButton(
                      text: 'Konumu Seç',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: _onSelectTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
