import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../viewmodels/settings_viewmodel.dart';

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
    final success = await _viewModel.signOut();
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
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
      final success = await _viewModel.deleteAccount();
      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _viewModel.currentUser;
    final userName = user?.displayName?.isNotEmpty == true
        ? user!.displayName
        : 'Saha Personeli';
    final userEmail = user?.email ?? 'ornek@yesevihareketi.org.tr';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Ayarlar'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Profil Alanı
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMD,
                    vertical: AppConstants.paddingXL,
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Kullanıcı Bilgileri
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName!,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Ayarlar Listesi
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
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
                      ),
                      const Divider(),
                      _buildListTile(
                        icon: Icons.logout_rounded,
                        title: 'Çıkış Yap',
                        iconColor: AppColors.error,
                        textColor: AppColors.error,
                        onTap: _handleSignOut,
                        isLoading: _viewModel.isLoading,
                      ),
                      const Divider(),
                      _buildListTile(
                        icon: Icons.person_remove_outlined,
                        title: 'Hesabımı Sil',
                        iconColor: AppColors.error,
                        textColor: AppColors.error,
                        onTap: _handleDeleteAccount,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Versiyon ve Alt Bilgi
                Text(
                  'Yesevi Gaziantep • v1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool isLoading = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textPrimary,
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
              color: AppColors.textTertiary,
            ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      ),
      onTap: isLoading ? null : onTap,
    );
  }
}
