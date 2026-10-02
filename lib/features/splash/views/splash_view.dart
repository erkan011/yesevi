import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Arka planda Firebase'i başlat ve Google Maps / Flutter yüklemelerini saklamak için ~2.5 sn bekle
      await Firebase.initializeApp();

      if (!mounted) return;

      if (FirebaseAuth.instance.currentUser != null) {
        final authService = AuthService();
        await authService.restoreSession();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRouter.login);
      }
    } catch (e) {
      debugPrint('Splash init error: $e');
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1500));
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Daima karanlık mod
    const scaffoldBg = Color(0xFF121212);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo — büyük ve yuvarlak
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/yesevi_logo.jpg',
                    fit: BoxFit.cover,
                    width: 220,
                    height: 220,
                  ),
                ),
              ),
              const SizedBox(height: 64),
              // Yükleme Animasyonu
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
