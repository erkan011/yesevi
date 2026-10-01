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
import '../../../data/services/session_manager.dart';
import '../../../shared/widgets/map_picker_view.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      builder: (ctx) => _CollectBoxForm(box: box, isRemoval: true),
    );
  }

  /// Kutuyu Boşaltma Formu (Haritada kalır)
  static void showEmptyBoxSheet(BuildContext context, DonationBox box) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CollectBoxForm(box: box, isRemoval: false),
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
  final _shopPhoneController = TextEditingController();
  
  final _boxService = BoxService();
  final _authService = AuthService();
  final _locationService = LocationService();

  LatLng? _selectedLocation;
  bool _isLocating = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLocating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _openMapPicker() async {
    final LatLng? pickedLocation = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapPickerView(initialLocation: _selectedLocation),
      ),
    );

    if (pickedLocation != null && mounted) {
      setState(() {
        _selectedLocation = pickedLocation;
      });
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleDropBox() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      setState(() => _errorMessage = 'Lütfen konum seçin.');
      return;
    }

    // kurum_id kontrolü
    final kurumId = SessionManager.instance.kurumId;
    if (kurumId == null || kurumId.isEmpty) {
      setState(() => _errorMessage = 'Kurum bilgisi bulunamadı. Lütfen tekrar giriş yapın.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 2. Kullanıcıyı al
      final user = _authService.getCurrentUserModel();
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı.');

      // 3. Modeli oluştur (kurum_id dahil)
      final newBox = DonationBox(
        id: const Uuid().v4(),
        kurumId: kurumId,
        shopName: _shopNameController.text.trim(),
        shopPhone: _shopPhoneController.text.trim().isNotEmpty 
            ? _shopPhoneController.text.trim() : null,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        droppedBy: user.displayName.isNotEmpty ? user.displayName : user.email,
        droppedByPhone: null, // Kullanıcıdan alınabilir (opsiyonel)
        droppedAt: DateTime.now(),
        status: BoxStatus.waiting,
        recipientName: null,
        recipientPhone: null,
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: bottomInset + 20,
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
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kutu bilgilerini girin, konum GPS ile otomatik seçilir.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 24),

              // Konum Seçici alanı
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
                            'Kutu Konumu',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_isLocating) 
                            Text('Konum alınıyor...', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary))
                          else if (_selectedLocation != null)
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

              const SizedBox(height: 20),

              // ── Mekan Bilgileri ──
              _buildSectionLabel('Mekan Bilgileri'),
              const SizedBox(height: 10),

              AppTextField(
                controller: _shopNameController,
                hintText: 'Mekan adı (Örn: Ahmet Bakkal)',
                prefixIcon: Icons.storefront_outlined,
                validator: (val) => val == null || val.trim().isEmpty 
                    ? 'Mekan adı zorunludur' : null,
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _shopPhoneController,
                hintText: 'Mekan numarası (Opsiyonel)',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 20),

              // ── Görsel Ekle (Devre Dışı) ──
              _buildSectionLabel('Fotoğraf'),
              const SizedBox(height: 10),
              Opacity(
                opacity: 0.5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 20, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Text(
                        'Görsel Ekle',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Yakında',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.titleMedium?.color,
      ),
    );
  }
}

// ────────────────────────────────────────────
// KUTUYU (BAĞIŞI) TESLİM AL FORMU — GİDERLER DAHİL
// ────────────────────────────────────────────

class _CollectBoxForm extends StatefulWidget {
  final DonationBox box;
  final bool isRemoval; // true = Kutuyu Al (haritadan sil), false = Boşalt (haritada sarı bırak)
  
  const _CollectBoxForm({required this.box, required this.isRemoval});

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

  // Gider listesi
  final List<_ExpenseEntry> _expenseEntries = [];

  @override
  void dispose() {
    _amountController.dispose();
    for (final entry in _expenseEntries) {
      entry.typeController.dispose();
      entry.amountController.dispose();
    }
    super.dispose();
  }

  void _addExpenseEntry() {
    setState(() {
      _expenseEntries.add(_ExpenseEntry(
        typeController: TextEditingController(),
        amountController: TextEditingController(),
      ));
    });
  }

  void _removeExpenseEntry(int index) {
    setState(() {
      _expenseEntries[index].typeController.dispose();
      _expenseEntries[index].amountController.dispose();
      _expenseEntries.removeAt(index);
    });
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

      // Giderleri oluştur
      final expenses = _expenseEntries
          .where((e) => e.typeController.text.trim().isNotEmpty && 
                        e.amountController.text.trim().isNotEmpty)
          .map((e) {
            final expAmount = double.tryParse(
                e.amountController.text.replaceAll(',', '.')) ?? 0.0;
            return ExpenseItem(
              type: e.typeController.text.trim(),
              amount: expAmount,
            );
          })
          .toList();

      if (widget.isRemoval) {
        // Kutuyu tamamen al
        await _boxService.collectAndRemoveBox(
          boxId: widget.box.id,
          collectedBy: collectedBy,
          donationAmount: amount,
          expenses: expenses.isNotEmpty ? expenses : null,
        );
      } else {
        // Sadece boşalt ve geçmiş kaydı (yeni kayıt) oluştur
        await _boxService.emptyBoxWithAmount(
          box: widget.box,
          emptiedBy: collectedBy,
          donationAmount: amount,
          expenses: expenses.isNotEmpty ? expenses : null,
        );
      }

      if (mounted) {
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: bottomInset + 20,
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
                widget.isRemoval ? 'Kutuyu Al' : 'Kutuyu Boşalt',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.box.shopName} mekanındaki kutudan toplanan bağış miktarını ve giderleri girin.'
                '${widget.isRemoval ? '' : ' Kutu haritada sarı renkli olarak işaretlenecektir.'}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 24),

              // ── Bağış Miktarı ──
              Text(
                'Bağış Miktarı',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: 10),

              AppTextField(
                controller: _amountController,
                hintText: 'Miktar (Örn: 250.50)',
                prefixIcon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val == null || val.trim().isEmpty 
                    ? 'Miktar zorunludur' : null,
              ),

              const SizedBox(height: 24),

              // ── Giderler Bölümü ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giderler',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addExpenseEntry,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Gider Ekle'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),

              if (_expenseEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Henüz gider eklenmedi.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),

              ..._expenseEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final expense = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: expense.typeController,
                          decoration: InputDecoration(
                            hintText: 'Tür (Yakıt, vb.)',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: expense.amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: '₺ Tutar',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeExpenseEntry(index),
                        child: Icon(
                          Icons.remove_circle_outline,
                          size: 20,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                );
              }),

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
                      text: widget.isRemoval ? 'Kutuyu Al' : 'Boşalt',
                      isLoading: _isLoading,
                      onPressed: _handleCollectBox,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gider satırı veri tutucu
class _ExpenseEntry {
  final TextEditingController typeController;
  final TextEditingController amountController;

  _ExpenseEntry({
    required this.typeController,
    required this.amountController,
  });
}
