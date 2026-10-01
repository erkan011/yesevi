import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/map_picker_view.dart';
import '../../../data/models/beneficiary_model.dart';
import '../../../data/services/beneficiary_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/session_manager.dart';

/// Yeni İhtiyaç Sahibi Ekleme Ekranı (Form)
class AddBeneficiaryView extends StatefulWidget {
  const AddBeneficiaryView({super.key});

  @override
  State<AddBeneficiaryView> createState() => _AddBeneficiaryViewState();
}

class _AddBeneficiaryViewState extends State<AddBeneficiaryView> {
  final LocationService _locationService = LocationService();
  LatLng? _selectedLocation;
  bool _isLocating = true;

  // ── Form ──
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedStatus = 'Bekliyor';
  
  final _beneficiaryService = BeneficiaryService();
  final _authService = AuthService();

  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<String> _statusOptions = [
    'Bekliyor',
    'Acil',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Başlangıçta GPS'ten mevcut konumu al
  Future<void> _fetchCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLocating = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Tam ekran harita üzerinden manuel konum seçimi
  Future<void> _openMapPicker() async {
    final LatLng? pickedLocation = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapPickerView(initialLocation: _selectedLocation),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
      });
    }
  }

  /// Formu kaydet
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      setState(() => _errorMessage = 'Lütfen konum seçin.');
      return;
    }

    final kurumId = SessionManager.instance.kurumId;
    if (kurumId == null || kurumId.isEmpty) {
      setState(() => _errorMessage = 'Kurum bilgisi bulunamadı. Lütfen tekrar giriş yapın.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = _authService.getCurrentUserModel();
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı.');

      final beneficiary = Beneficiary(
        id: '', // Firestore auto-generate edecek
        kurumId: kurumId,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        needStatus: _selectedStatus,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        addedBy: user.displayName.isNotEmpty ? user.displayName : user.email,
        createdAt: DateTime.now(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      await _beneficiaryService.addBeneficiary(beneficiary);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'İhtiyaç sahibi başarıyla kaydedildi.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yeni İhtiyaç Sahibi',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    if (_isLocating && _selectedLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Konum alınıyor...',
              style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seçilen konum bilgisi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                   Icon(
                    _selectedLocation != null ? Icons.location_on_rounded : Icons.location_off_outlined,
                    size: 24,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konum Bilgisi',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_selectedLocation != null)
                          Text(
                            'Lat: ${_selectedLocation!.latitude.toStringAsFixed(5)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          Text(
                            'Konum alınamadı',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _openMapPicker,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _selectedLocation != null ? 'Değiştir' : 'Seç',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Ad Soyad
            _buildLabel('Ad Soyad'),
            const SizedBox(height: 8),
            AppTextField(
              controller: _nameController,
              hintText: 'Örn: Ahmet Yılmaz',
              prefixIcon: Icons.person_outline_rounded,
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Ad soyad zorunludur'
                  : null,
            ),

            const SizedBox(height: 18),

            // Telefon
            _buildLabel('Telefon'),
            const SizedBox(height: 8),
            AppTextField(
              controller: _phoneController,
              hintText: 'Örn: 05XX XXX XX XX',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Telefon numarası zorunludur'
                  : null,
            ),

            const SizedBox(height: 18),

            // Adres Açıklaması
            _buildLabel('Adres Açıklaması'),
            const SizedBox(height: 8),
            AppTextField(
              controller: _addressController,
              hintText: 'Örn: Şahinbey, 15 Temmuz Mah. No:12',
              prefixIcon: Icons.location_on_outlined,
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Adres zorunludur'
                  : null,
            ),

            const SizedBox(height: 18),

            // İhtiyaç Durumu (Dropdown)
            _buildLabel('İhtiyaç Durumu'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(
                    status,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedStatus = val);
                }
              },
            ),

            const SizedBox(height: 18),

            // Not (Opsiyonel)
            _buildLabel('Not (Opsiyonel)'),
            const SizedBox(height: 8),
            AppTextField(
              controller: _notesController,
              hintText: 'Ek bilgi varsa yazın...',
              prefixIcon: Icons.notes_rounded,
            ),

            // Hata mesajı
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: AppButton(
                text: 'Kaydet',
                isLoading: _isSubmitting,
                icon: Icons.save_rounded,
                onPressed: _handleSubmit,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Form etiket widget'ı
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
    );
  }
}
