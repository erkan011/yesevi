import 'package:flutter/material.dart';

import '../../features/splash/views/splash_view.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/register_view.dart';
import '../../features/home/views/home_view.dart';
import '../../features/box_list/views/box_detail_view.dart';
import '../../data/models/donation_box_model.dart';

/// Uygulama rotalarını (sayfalar arası geçişleri) yöneten sınıf
class AppRouter {
  AppRouter._();

  // ── Rota İsimleri ──
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String map = '/map';
  static const String list = '/list';
  static const String settings = '/settings';
  static const String boxDetail = '/box-detail';

  /// Route generator
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return _buildRoute(const SplashView(), routeSettings);
      case login:
        return _buildRoute(const LoginView(), routeSettings);
      case register:
        return _buildRoute(const RegisterView(), routeSettings);
      case home:
        return _buildRoute(const HomeView(), routeSettings);
      case boxDetail:
        final box = routeSettings.arguments as DonationBox;
        return _buildRoute(BoxDetailView(box: box), routeSettings);
      default:
        // Sayfa bulunamadığında splash'a yönlendir
        return _buildRoute(const SplashView(), routeSettings);
    }
  }

  /// Sayfa geçiş animasyonu ile route oluşturma
  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
