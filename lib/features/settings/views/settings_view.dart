import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../../../data/services/session_manager.dart';
import '../../../data/services/auth_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _handleSignOut() async {
    // Tüm sayfaları temizleyip login sayfasına dön ki dinlenen streamler kapansın
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
    // Arka planda çıkış yap
    await AuthService().signOut();
  }

  void _handleDeleteAccount() async {
    // Silme onayı dialog'u
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
            'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
      await AuthService().deleteAccount();
    }
  }

  /// Tema seçimi modalı
  void _showThemeDialog() {
    final themeNotifier = ThemeNotifier.instance;

    showDialog(
      context: context,
      builder: (ctx) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, _) {
            return AlertDialog(
              title: Text(
                'Tema Seçimi',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemeOption(
                    ctx: ctx,
                    icon: Icons.light_mode_rounded,
                    title: 'Aydınlık Tema',
                    subtitle: 'Beyaz arka plan, koyu metinler',
                    isSelected: currentMode == ThemeMode.light,
                    onTap: () {
                      themeNotifier.setThemeMode(ThemeMode.light);
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildThemeOption(
                    ctx: ctx,
                    icon: Icons.dark_mode_rounded,
                    title: 'Karanlık Tema',
                    subtitle: 'Koyu arka plan, açık metinler',
                    isSelected: currentMode == ThemeMode.dark,
                    onTap: () {
                      themeNotifier.setThemeMode(ThemeMode.dark);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(ctx);
    final cardColor = isSelected
        ? AppColors.primary.withOpacity(0.08)
        : theme.cardTheme.color ?? Colors.white;
    final borderColor = isSelected
        ? AppColors.primary.withOpacity(0.4)
        : theme.dividerTheme.color ?? Colors.grey.shade300;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : theme.textTheme.bodyMedium?.color,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF252525) : Colors.white;
    final bgColor = theme.scaffoldBackgroundColor;

    final sessionUser = SessionManager.instance.currentUser;
    final user = _viewModel.currentUser;
    final userName = sessionUser?.displayName.isNotEmpty == true
        ? sessionUser!.displayName
        : user?.displayName?.isNotEmpty == true
            ? user!.displayName
            : 'Saha Personeli';
    final userEmail = sessionUser?.email ?? user?.email ?? 'ornek@yesevihareketi.org.tr';
    final userRole = sessionUser?.role ?? 'personel';
    // Telefon numarası varsayımı (session veya firestore verisinden alınabilir ama şu an modelde yoksa sabit olabilir)
    final userPhone = '-';

    // Rol görüntü metni
    String roleDisplay;
    switch (userRole) {
      case 'super-admin':
        roleDisplay = 'Süper Admin';
        break;
      case 'admin':
        roleDisplay = 'Kurum Yöneticisi';
        break;
      default:
        roleDisplay = 'Saha Personeli';
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Ayarlar'),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Kişisel Bilgiler Kartı ──
                _buildSectionCard(
                  title: 'Kişisel Bilgiler',
                  surfaceColor: surfaceColor,
                  children: [
                    _buildInfoTile(
                      icon: Icons.person_outline_rounded,
                      label: 'İsim Soyisim',
                      value: userName!,
                    ),
                    Divider(height: 1, color: theme.dividerTheme.color),
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      label: 'E-posta',
                      value: userEmail,
                    ),
                    Divider(height: 1, color: theme.dividerTheme.color),
                    _buildInfoTile(
                      icon: Icons.badge_outlined,
                      label: 'Rol',
                      value: roleDisplay,
                    ),
                    Divider(height: 1, color: theme.dividerTheme.color),
                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Telefon Numarası',
                      value: userPhone,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // ── Tema Ayarları Kartı ──
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : AppColors.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Görünüm',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: ThemeNotifier.instance,
                        builder: (context, currentMode, _) {
                          return _buildListTile(
                            icon: currentMode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            title: currentMode == ThemeMode.dark
                                ? 'Karanlık Tema'
                                : 'Aydınlık Tema',
                            onTap: _showThemeDialog,
                            surfaceColor: surfaceColor,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                // ── İşlemler Kartı ──
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : AppColors.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Şifre Değiştir',
                        onTap: () {
                          // Şifre değiştirme sayfasına yönlendirme veya modal
                        },
                        surfaceColor: surfaceColor,
                      ),
                      Divider(color: theme.dividerTheme.color),
                      _buildListTile(
                        icon: Icons.logout_rounded,
                        title: 'Çıkış Yap',
                        iconColor: AppColors.error,
                        textColor: AppColors.error,
                        onTap: _handleSignOut,
                        isLoading: _viewModel.isLoading,
                        surfaceColor: surfaceColor,
                      ),
                      Divider(color: theme.dividerTheme.color),
                      _buildListTile(
                        icon: Icons.person_remove_outlined,
                        title: 'Hesabımı Sil',
                        iconColor: AppColors.error,
                        textColor: AppColors.error,
                        onTap: _handleDeleteAccount,
                        surfaceColor: surfaceColor,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Versiyon ve Alt Bilgi
                Text(
                  'Bağış Takip • v${AppConstants.appVersion}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Bölüm kartı (başlıklı)
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required Color surfaceColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Bilgi kutucuğu (salt okunur)
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: 12,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color surfaceColor,
    Color? iconColor,
    Color? textColor,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? theme.textTheme.bodyMedium?.color,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor ?? theme.textTheme.titleMedium?.color,
          ),
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.chevron_right_rounded,
                color: theme.textTheme.bodySmall?.color,
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        onTap: isLoading ? null : onTap,
      ),
    );
  }
}
