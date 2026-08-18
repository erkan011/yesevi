import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// GPS konum servisi
///
/// Cihaz konumunu alır, konum izinlerini yönetir
/// ve harici haritaya yol tarifi yönlendirmesi yapar.
class LocationService {
  /// Konum servisinin aktif ve iznin verilmiş olduğunu kontrol eder.
  /// Gerekirse kullanıcıdan izin ister.
  ///
  /// Döndürülen değerler:
  /// - `true` → izin verildi, konum alınabilir
  /// - Exception fırlatır → izin reddedildi veya servis kapalı
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // GPS servisi açık mı?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Konum servisleri kapalı. Lütfen cihaz ayarlarından GPS\'i açın.',
      );
    }

    // Mevcut izin durumunu kontrol et
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // İlk kez izin iste
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
          'Konum izni reddedildi. Harita özelliğini kullanabilmek için izin gereklidir.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Kalıcı olarak reddedilmiş — ayarlara yönlendir
      throw LocationServiceException(
        'Konum izni kalıcı olarak reddedildi. Lütfen uygulama ayarlarından izin verin.',
        isPermanentlyDenied: true,
      );
    }

    return true;
  }

  /// Cihazın anlık konumunu alır
  ///
  /// Önce izin kontrolü yapar, ardından konumu çeker.
  /// [desiredAccuracy] varsayılan olarak `high` (en hassas GPS).
  Future<Position> getCurrentLocation({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
  }) async {
    await handleLocationPermission();

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: desiredAccuracy,
    );
  }

  /// İki koordinat arasındaki mesafeyi metre cinsinden hesaplar
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Mesafeyi okunabilir formata çevirir (m / km)
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Harici harita uygulamasında yol tarifi açar
  ///
  /// Google Maps deep link kullanır.
  /// Kullanıcının cihazında Google Maps yoksa tarayıcıda açar.
  Future<void> openDirections({
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
  }) async {
    final encodedName =
        Uri.encodeComponent(destinationName ?? 'Bağış Kutusu');

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destinationLat,$destinationLng'
      '&destination_place_id=$encodedName'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw LocationServiceException(
        'Harita uygulaması açılamadı.',
      );
    }
  }

  /// Uygulama konum ayarlarını açar (kalıcı red durumunda)
  Future<void> openLocationSettings() async {
    await Geolocator.openAppSettings();
  }
}

/// Konum servisi özel hata sınıfı
class LocationServiceException implements Exception {
  final String message;
  final bool isPermanentlyDenied;

  LocationServiceException(
    this.message, {
    this.isPermanentlyDenied = false,
  });

  @override
  String toString() => message;
}
