import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../data/models/donation_box_model.dart';
import '../../../core/enums/box_status.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/location_service.dart';
import 'package:uuid/uuid.dart';

/// Yeni Kutu Bırak / Bağış Teslim Al Bottom Sheet Formları
class BoxActionSheet {
  BoxActionSheet._();

  /// Yeni Kutu Bırakma Formu
  static void showDropBoxSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _DropBoxForm(),
    );
  }

  /// Mevcut Kutuyu (Bağışı) Teslim Alma Formu
  static void showCollectBoxSheet(BuildContext context, DonationBox box) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CollectBoxForm(box: box),
    );
  }
}

// ────────────────────────────────────────────
// YENİ KUTU BIRAK FORMU
// ────────────────────────────────────────────

class _DropBoxForm extends StatefulWidget {
  const _DropBoxForm();

  @override
  State<_DropBoxForm> createState() => _DropBoxFormState();
}

class _DropBoxFormState extends State<_DropBoxForm> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  
  final _boxService = BoxService();
  final _authService = AuthService();
  final _locationService = LocationService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _handleDropBox() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Konumu al
      final position = await _locationService.getCurrentLocation();
      
      // 2. Kullanıcıyı al
      final user = _authService.getCurrentUserModel();
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı.');

      // 3. Modeli oluştur
      final newBox = DonationBox(
        id: const Uuid().v4(),
        shopName: _shopNameController.text.trim(),
        latitude: position.latitude,
        longitude: position.longitude,
        droppedBy: user.displayName.isNotEmpty ? user.displayName : user.email,
        droppedAt: DateTime.now(),
        status: BoxStatus.waiting,
      );

      // 4. Firestore'a yaz
      await _boxService.addBox(newBox);

      if (mounted) {
        Navigator.pop(context); // Formu kapat
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEE2E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Text(
              'Yeni Kutu Bırak',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cihazınızın mevcut konumu (GPS) kutu konumu olarak kaydedilecektir.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            AppTextField(
              controller: _shopNameController,
              hintText: 'Mekan adı (Örn: Ahmet Bakkal)',
              prefixIcon: Icons.storefront_outlined,
              validator: (val) => val == null || val.trim().isEmpty 
                  ? 'Mekan adı zorunludur' : null,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'İptal',
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Kutuyu Bırak',
                    isLoading: _isLoading,
                    onPressed: _handleDropBox,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────
// KUTUYU (BAĞIŞI) TESLİM AL FORMU
// ────────────────────────────────────────────

class _CollectBoxForm extends StatefulWidget {
  final DonationBox box;
  const _CollectBoxForm({required this.box});

  @override
  State<_CollectBoxForm> createState() => _CollectBoxFormState();
}

class _CollectBoxFormState extends State<_CollectBoxForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  final _boxService = BoxService();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleCollectBox() async {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount < 0) {
      setState(() => _errorMessage = 'Geçerli bir miktar giriniz.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _authService.getCurrentUserModel();
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı.');

      final collectedBy = user.displayName.isNotEmpty ? user.displayName : user.email;

      await _boxService.collectBox(
        boxId: widget.box.id,
        collectedBy: collectedBy,
        donationAmount: amount,
      );

      if (mounted) {
        // İki bottom sheet üst üste açık olabilir (Detay + Form), 
        // bu yüzden formu kapatıp geri dönmek güvenli.
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFDEE2E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Text(
              'Bağışı Teslim Al',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.box.shopName} mekanındaki kutudan toplanan bağış miktarını girin.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            AppTextField(
              controller: _amountController,
              hintText: 'Miktar (Örn: 250.50)',
              prefixIcon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) => val == null || val.trim().isEmpty 
                  ? 'Miktar zorunludur' : null,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'İptal',
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Kaydet',
                    isLoading: _isLoading,
                    onPressed: _handleCollectBox,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
