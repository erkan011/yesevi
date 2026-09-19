import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      await Future.wait([
        Firebase.initializeApp(),
        Future.delayed(const Duration(milliseconds: 2500)),
      ]);

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              // App Adı
              Text(
                'Yesevi Harekatına',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'HOŞGELDİNİZ',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
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
