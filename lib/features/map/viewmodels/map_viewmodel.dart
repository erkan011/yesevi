import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'dart:async';

import '../../../core/constants/app_constants.dart';
import '../../../core/enums/box_status.dart';
import '../../../data/models/donation_box_model.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/firestore_service.dart';

/// Harita sayfası state yönetimi
///
/// Marker oluşturma, bottom sheet kontrolü,
/// kullanıcı konumu ve Firestore veri yönetimini sağlar.
class MapViewModel extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final BoxService _boxService = BoxService();
  StreamSubscription? _boxSubscription;

  // ── Google Maps Controller ──
  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;

  // ── Kullanıcı Konumu ──
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  // ── Harita Durumu ──
  bool _isMapReady = false;
  bool get isMapReady => _isMapReady;

  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;

  String? _locationError;
  String? get locationError => _locationError;

  // ── Bottom Sheet ──
  DonationBox? _selectedBox;
  DonationBox? get selectedBox => _selectedBox;

  bool _isBottomSheetOpen = false;
  bool get isBottomSheetOpen => _isBottomSheetOpen;

  // ── Bağış Kutuları (Gerçek Zamanlı Veriler) ──
  List<DonationBox> _boxes = [];
  List<DonationBox> get boxes => _boxes;

  MapViewModel() {
    _initBoxStream();
  }

  void _initBoxStream() {
    _boxSubscription = _boxService.getBoxesStream().listen((boxesList) {
      _boxes = boxesList;
      // Kutu güncellendiğinde eğer selectedBox var ise,
      // seçili kutuyu da güncelle (Miktar/Durum değişirse bottom sheet anında güncellensin)
      if (_selectedBox != null) {
        try {
          _selectedBox = _boxes.firstWhere((b) => b.id == _selectedBox!.id);
        } catch (_) {
          _selectedBox = null;
          _isBottomSheetOpen = false;
        }
      }
      notifyListeners();
    });
  }

  // ── Markers ──
  Set<Marker> get markers => _buildMarkers();

  /// Varsayılan kamera pozisyonu (Gaziantep Merkez)
  CameraPosition get initialCameraPosition => const CameraPosition(
        target: LatLng(
          AppConstants.defaultLatitude,
          AppConstants.defaultLongitude,
        ),
        zoom: AppConstants.defaultZoom,
      );

  /// Harita hazır olduğunda çağrılır
  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    notifyListeners();

    // Harita yüklendikten sonra konumu al
    _fetchCurrentLocation();
  }

  /// Kullanıcı konumunu al
  Future<void> _fetchCurrentLocation() async {
    _isLoadingLocation = true;
    _locationError = null;
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentLocation();
      _isLoadingLocation = false;
      notifyListeners();
    } on LocationServiceException catch (e) {
      _locationError = e.message;
      _isLoadingLocation = false;
      notifyListeners();
    } catch (e) {
      _locationError = 'Konum alınırken bir hata oluştu.';
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Konumu yeniden al (kullanıcı butonuyla)
  Future<void> refreshLocation() async {
    await _fetchCurrentLocation();
  }

  /// Kamerayı kullanıcının konumuna götür
  Future<void> goToMyLocation() async {
    if (_currentPosition == null) {
      await _fetchCurrentLocation();
    }

    if (_currentPosition != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  /// Kamerayı belirli bir kutunun konumuna götür
  Future<void> focusOnBox(DonationBox box) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(box.latitude, box.longitude),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  /// Marker'a tıklandığında çağrılır
  void onMarkerTapped(DonationBox box) {
    _selectedBox = box;
    _isBottomSheetOpen = true;
    notifyListeners();

    // Kamerayı kutunun konumuna yakınlaştır
    focusOnBox(box);
  }

  /// Bottom Sheet kapatıldığında çağrılır
  void closeBottomSheet() {
    _isBottomSheetOpen = false;
    _selectedBox = null;
    notifyListeners();
  }

  /// Yol tarifi aç
  Future<void> openDirections(DonationBox box) async {
    try {
      await _locationService.openDirections(
        destinationLat: box.latitude,
        destinationLng: box.longitude,
        destinationName: box.shopName,
      );
    } on LocationServiceException catch (e) {
      _locationError = e.message;
      notifyListeners();
    }
  }

  /// Kullanıcının konumundan kutunun uzaklığını hesapla
  String? getDistanceToBox(DonationBox box) {
    if (_currentPosition == null) return null;

    final distance = _locationService.calculateDistance(
      startLatitude: _currentPosition!.latitude,
      startLongitude: _currentPosition!.longitude,
      endLatitude: box.latitude,
      endLongitude: box.longitude,
    );

    return _locationService.formatDistance(distance);
  }

  /// Marker set'ini oluştur
  Set<Marker> _buildMarkers() {
    return _boxes.map((box) {
      final isWaiting = box.status == BoxStatus.waiting;

      return Marker(
        markerId: MarkerId(box.id),
        position: LatLng(box.latitude, box.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isWaiting
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(
          title: box.shopName,
          snippet: isWaiting ? 'Bekliyor' : 'Alındı',
        ),
        onTap: () => onMarkerTapped(box),
      );
    }).toSet();
  }

  /// Hata mesajını temizle
  void clearLocationError() {
    _locationError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _boxSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
