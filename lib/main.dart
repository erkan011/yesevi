import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  String initialRoute = AppRouter.login;

  // Firebase başlat
  try {
    await Firebase.initializeApp();
    // Oturum açıksa doğrudan anasayfaya yönlendir
    if (FirebaseAuth.instance.currentUser != null) {
      initialRoute = AppRouter.home;
    }
  } catch (e) {
    debugPrint('Firebase başlatılamadı. Uygulamanın açılması için bu hata yakalandı: $e');
    debugPrint('Lütfen google-services.json dosyanızı kontrol edin veya flutterfire configure komutunu çalıştırın.');
  }

  // Durum çubuğu rengini açık tema için ayarla
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Dikey mod sabitlenmesi (opsiyonel)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(YeseviApp(initialRoute: initialRoute));
}
