import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Bağış kutusu için modern kart widget'ı
class BoxCard extends StatelessWidget {
  final String shopName;
  final String status;
  final String droppedBy;
  final String date;
  final VoidCallback? onTap;

  const BoxCard({
    super.key,
    required this.shopName,
    required this.status,
    required this.droppedBy,
    required this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWaiting = status == 'waiting';
    final isEmptied = status == 'emptied';
    final isCollected = status == 'collected';

    // Durum rengi
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (isWaiting) {
      statusColor = AppColors.statusWaiting;
      statusIcon = Icons.inventory_2_outlined;
      statusLabel = 'Bekliyor';
    } else if (isEmptied) {
      statusColor = AppColors.statusEmptied;
      statusIcon = Icons.inbox_outlined;
      statusLabel = 'Boşaltıldı';
    } else {
      statusColor = AppColors.statusCollected;
      statusIcon = Icons.check_circle_outline;
      statusLabel = 'Alındı';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: 6,
        ),
        padding: const EdgeInsets.all(AppConstants.paddingMD),
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
            // Durum İkonu
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Bilgi Alanı
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    droppedBy.isNotEmpty 
                        ? droppedBy 
                        : date,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Durum Etiketi + Ok İkonu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
