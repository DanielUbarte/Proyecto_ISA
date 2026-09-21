import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/module_model.dart';

class ModuleCard extends StatelessWidget {
  final ModuleModel module;
  final VoidCallback onTap;
  final VoidCallback? onActionTap;

  const ModuleCard({
    super.key,
    required this.module,
    required this.onTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLocked = module.status == ModuleStatus.locked;
    final bool isDownloading = module.status == ModuleStatus.downloading;
    final bool isDownloaded = module.status == ModuleStatus.downloaded;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image & Badges
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    image: DecorationImage(
                      image: NetworkImage(module.bannerImageUrl),
                      fit: BoxFit.cover,
                      colorFilter: isLocked
                          ? ColorFilter.mode(
                              Colors.grey.shade400, BlendMode.saturation)
                          : null,
                    ),
                  ),
                ),
                if (module.isOfflineAvailable)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Disponible offline',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isDownloading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(module.downloadProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                              const Text(
                                'Descargando...',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.code.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? AppColors.textMuted : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isDownloading) ...[
                    LinearProgressIndicator(
                      value: module.downloadProgress,
                      backgroundColor: Colors.grey.shade200,
                      color: AppColors.primaryTeal,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Procesando contenido...',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ] else if (isLocked) ...[
                    Row(
                      children: [
                        const Icon(Icons.help_outline,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          module.unlockRequirement,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDownloaded
                                  ? Icons.access_time
                                  : Icons.description_outlined,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isDownloaded
                                  ? module.duration
                                  : '${module.documentCount} Documentos • ${module.size}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(110, 38),
                            backgroundColor: isDownloaded
                                ? const Color(0xFF475569)
                                : AppColors.surfaceWhite,
                            foregroundColor: isDownloaded
                                ? Colors.white
                                : AppColors.primaryTeal,
                            elevation: isDownloaded ? 1 : 0,
                            side: isDownloaded
                                ? BorderSide.none
                                : const BorderSide(
                                    color: AppColors.borderGrey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: onActionTap ?? onTap,
                          child: Text(
                            isDownloaded ? 'Estudiar' : 'Descargar',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
