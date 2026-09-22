import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Componente para mostrar el progreso de lectura del módulo Panamá Contemporánea.
/// Muestra porcentaje de avance y conteo de materiales vistos.
class ContemporaneaProgressBar extends StatelessWidget {
  final int viewedCount;
  final int totalCount;

  const ContemporaneaProgressBar({
    super.key,
    required this.viewedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final double progressRatio = totalCount > 0 ? (viewedCount / totalCount) : 0.0;
    final int percentage = (progressRatio * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_stories, color: AppColors.primaryTeal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Progreso de lectura',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$viewedCount de $totalCount materiales vistos',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              if (percentage == 100)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.forestGreen, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '¡Completado!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
