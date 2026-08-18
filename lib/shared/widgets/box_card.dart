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
                color: isWaiting
                    ? AppColors.statusWaiting.withOpacity(0.12)
                    : AppColors.statusCollected.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isWaiting
                    ? Icons.inventory_2_outlined
                    : Icons.check_circle_outline,
                color: isWaiting
                    ? AppColors.statusWaiting
                    : AppColors.statusCollected,
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
                    '$droppedBy • $date',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Ok İkonu
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
