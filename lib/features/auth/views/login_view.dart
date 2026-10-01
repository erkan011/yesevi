import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../viewmodels/login_viewmodel.dart';

/// Kullanıcı giriş ekranı
///
/// Minimalist, sade tasarım:
/// Logo alanı + E-posta + Şifre + Giriş Yap butonu
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  late final LoginViewModel _viewModel;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel();

    // Giriş animasyonu
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final success = await _viewModel.signIn();
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SizedBox(
            height: size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // ── Logo Alanı ──
                      _buildLogoSection(theme, isDark, scaffoldBg),

                      const Spacer(flex: 2),

                      // ── Form Alanı ──
                      _buildForm(theme, isDark),

                      const SizedBox(height: 28),

                      // ── Hata Mesajı ──
                      _buildErrorMessage(),

                      // ── Giriş Butonu ──
                      _buildLoginButton(),

                      const Spacer(flex: 3),

                      // ── Alt Bilgi ──
                      _buildFooter(theme, isDark),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Logo ve başlık alanı
  Widget _buildLogoSection(ThemeData theme, bool isDark, Color scaffoldBg) {
    return Column(
      children: [
        // Logo İkonu (Yesevi) — arka plan sayfa rengi ile aynı
        Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scaffoldBg,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/yesevi_logo.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                color: scaffoldBg,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Uygulama adı
        Text(
          'Bağış Takip',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.titleLarge?.color,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        // Alt başlık
        Text(
          'Bağış Kutusu Takip Sistemi',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  /// E-posta ve şifre formu
  Widget _buildForm(ThemeData theme, bool isDark) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Form(
          key: _viewModel.formKey,
          child: Column(
            children: [
              // Kurum Adı
              _buildInputField(
                controller: _viewModel.kurumController,
                hintText: 'Kurum Adı',
                prefixIcon: Icons.business_outlined,
                keyboardType: TextInputType.text,
                validator: _viewModel.validateKurum,
                textInputAction: TextInputAction.next,
                theme: theme,
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              // E-posta
              _buildInputField(
                controller: _viewModel.emailController,
                hintText: 'E-posta adresiniz',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: _viewModel.validateEmail,
                textInputAction: TextInputAction.next,
                theme: theme,
                isDark: isDark,
              ),

              const SizedBox(height: 14),

              // Şifre
              _buildInputField(
                controller: _viewModel.passwordController,
                hintText: 'Şifreniz',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _viewModel.obscurePassword,
                validator: _viewModel.validatePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
                theme: theme,
                isDark: isDark,
                suffixIcon: GestureDetector(
                  onTap: _viewModel.togglePasswordVisibility,
                  child: Icon(
                    _viewModel.obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Özel input alanı
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required ThemeData theme,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: (_) => _viewModel.clearError(),
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: theme.textTheme.titleLarge?.color,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(prefixIcon, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
      ),
    );
  }

  /// Hata mesajı
  Widget _buildErrorMessage() {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.errorMessage == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _viewModel.errorMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Giriş butonu
  Widget _buildLoginButton() {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _viewModel.isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0072B5), // Yesevi Mavisi
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF0072B5).withOpacity(0.6),
              elevation: 0,
              shadowColor: const Color(0xFF0072B5).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _viewModel.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Giriş Yap',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        );
      },
    );
  }

  /// Alt bilgi
  Widget _buildFooter(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Ayırıcı çizgi
        Row(
          children: [
            Expanded(
              child: Divider(
                color: theme.dividerTheme.color ?? AppColors.border,
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Yesevi Hareketi',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodySmall?.color,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.dividerTheme.color ?? AppColors.border,
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Saha personeli hesabınız ile giriş yapın',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hesabınız yok mu?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.register),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Kayıt Ol',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0072B5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
