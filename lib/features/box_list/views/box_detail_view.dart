import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/box_status.dart';
import '../../../data/models/donation_box_model.dart';

/// Kutu detay sayfası — tüm bilgiler + gider PDF çıktısı
class BoxDetailView extends StatelessWidget {
  final DonationBox box;

  const BoxDetailView({super.key, required this.box});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR');
    final numberFormat = NumberFormat('#,##0.00', 'tr_TR');

    // Durum bilgileri
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (box.status) {
      case BoxStatus.waiting:
        statusColor = AppColors.statusWaiting;
        statusText = 'Bekliyor';
        statusIcon = Icons.inventory_2_outlined;
        break;
      case BoxStatus.emptied:
        statusColor = AppColors.statusEmptied;
        statusText = 'Boşaltıldı';
        statusIcon = Icons.inbox_outlined;
        break;
      case BoxStatus.collected:
        statusColor = AppColors.statusCollected;
        statusText = 'Alındı';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Kutu Detayı'),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            // PDF butonu sadece alınan kutular için (gider varsa)
            if (box.status == BoxStatus.collected && 
                box.expenses != null && 
                box.expenses!.isNotEmpty)
              IconButton(
                onPressed: () => _generateAndPrintPdf(context),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Giderleri PDF Olarak İndir',
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Durum Kartı ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            box.shopName,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Mekan Bilgileri ──
              _buildInfoCard(
                title: 'Mekan Bilgileri',
                icon: Icons.store_outlined,
                children: [
                  _buildInfoRow('Mekan Adı', box.shopName),
                  if (box.shopPhone != null && box.shopPhone!.isNotEmpty)
                    _buildInfoRow('Mekan No', box.shopPhone!),
                ],
              ),

              const SizedBox(height: 12),

              // ── Bırakan Personel ──
              _buildInfoCard(
                title: 'Bırakan Personel',
                icon: Icons.person_outline_rounded,
                children: [
                  _buildInfoRow('İsim Soyisim', box.droppedBy),
                  if (box.droppedByPhone != null && box.droppedByPhone!.isNotEmpty)
                    _buildInfoRow('Telefon', box.droppedByPhone!),
                  _buildInfoRow('Tarih', dateFormat.format(box.droppedAt)),
                ],
              ),

              const SizedBox(height: 12),



              // ── Fotoğraf ──
              if (box.imageUrl != null && box.imageUrl!.isNotEmpty) ...[
                _buildInfoCard(
                  title: 'Fotoğraf',
                  icon: Icons.photo_camera_outlined,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        box.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined, size: 40, color: AppColors.textTertiary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Toplama Bilgileri (Alındıysa) ──
              if (box.status == BoxStatus.collected) ...[
                _buildInfoCard(
                  title: 'Toplama Bilgileri',
                  icon: Icons.assignment_turned_in_outlined,
                  children: [
                    _buildInfoRow('Toplayan', box.collectedBy ?? '-'),
                    if (box.collectedAt != null)
                      _buildInfoRow('Alınma Tarihi', dateFormat.format(box.collectedAt!)),
                    if (box.donationAmount != null)
                      _buildInfoRow(
                        'Bağış Miktarı',
                        '₺${numberFormat.format(box.donationAmount)}',
                        valueColor: AppColors.primary,
                        isBold: true,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Giderler ──
              if (box.expenses != null && box.expenses!.isNotEmpty) ...[
                _buildInfoCard(
                  title: 'Giderler',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    ...box.expenses!.map((expense) => _buildInfoRow(
                      expense.type,
                      '₺${numberFormat.format(expense.amount)}',
                      valueColor: AppColors.error,
                    )),
                    const Divider(height: 20),
                    _buildInfoRow(
                      'Toplam Gider',
                      '₺${numberFormat.format(box.totalExpenses)}',
                      valueColor: AppColors.error,
                      isBold: true,
                    ),
                    _buildInfoRow(
                      'Net Bağış',
                      '₺${numberFormat.format(box.netDonation)}',
                      valueColor: AppColors.primary,
                      isBold: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── PDF İndirme Butonu ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _generateAndPrintPdf(context),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Giderleri PDF Olarak İndir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Bilgi kartı bileşeni
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// Bilgi satırı
  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PDF oluşturma ve yazdırma/paylaşma
  Future<void> _generateAndPrintPdf(BuildContext context) async {
    final numberFormat = NumberFormat('#,##0.00', 'tr_TR');
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR');

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Başlık
              pw.Text(
                'BAGIS KUTUSU GIDER RAPORU',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Yesevi Hareketi Gaziantep',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),

              // Mekan Bilgileri
              pw.Text(
                'MEKAN BILGILERI',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              _buildPdfRow('Mekan Adi', box.shopName),
              if (box.shopPhone != null && box.shopPhone!.isNotEmpty)
                _buildPdfRow('Mekan No', box.shopPhone!),
              _buildPdfRow('Birakan', box.droppedBy),
              _buildPdfRow('Birakma Tarihi', dateFormat.format(box.droppedAt)),
              pw.SizedBox(height: 16),

              // Toplama Bilgileri
              pw.Text(
                'TOPLAMA BILGILERI',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              _buildPdfRow('Toplayan', box.collectedBy ?? '-'),
              if (box.collectedAt != null)
                _buildPdfRow('Alinma Tarihi', dateFormat.format(box.collectedAt!)),
              _buildPdfRow('Bagis Miktari', 'TL ${numberFormat.format(box.donationAmount ?? 0)}'),

              pw.SizedBox(height: 24),

              // Giderler Tablosu
              pw.Text(
                'GIDER DETAYI',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              // Tablo
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Başlık satırı
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _buildPdfCell('No', isHeader: true),
                      _buildPdfCell('Gider Turu', isHeader: true),
                      _buildPdfCell('Tutar (TL)', isHeader: true),
                    ],
                  ),
                  // Gider satırları
                  if (box.expenses != null)
                    ...box.expenses!.asMap().entries.map((entry) {
                      return pw.TableRow(
                        children: [
                          _buildPdfCell('${entry.key + 1}'),
                          _buildPdfCell(entry.value.type),
                          _buildPdfCell(numberFormat.format(entry.value.amount)),
                        ],
                      );
                    }),
                  // Toplam satırı
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _buildPdfCell(''),
                      _buildPdfCell('TOPLAM GIDER', isHeader: true),
                      _buildPdfCell(numberFormat.format(box.totalExpenses), isHeader: true),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Özet
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    _buildPdfSummaryRow('Bagis Miktari', 'TL ${numberFormat.format(box.donationAmount ?? 0)}'),
                    _buildPdfSummaryRow('Toplam Gider', 'TL ${numberFormat.format(box.totalExpenses)}'),
                    pw.Divider(),
                    _buildPdfSummaryRow('NET BAGIS', 'TL ${numberFormat.format(box.netDonation)}', isBold: true),
                  ],
                ),
              ),

              pw.Spacer(),

              // Alt bilgi
              pw.Divider(),
              pw.Text(
                'Bu rapor Yesevi Gaziantep uygulamasi tarafindan olusturulmustur.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Olusturma Tarihi: ${dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );

    // PDF'i yazdır/paylaş
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Gider_Raporu_${box.shopName.replaceAll(' ', '_')}',
    );
  }

  /// PDF satırı
  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Text(
            ': $value',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// PDF tablo hücresi
  pw.Widget _buildPdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// PDF özet satırı
  pw.Widget _buildPdfSummaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
