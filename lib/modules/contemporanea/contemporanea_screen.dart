import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../services/content_service.dart';
import '../../services/download_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_button.dart';

/// Pantalla principal del módulo "Panamá Contemporánea".
/// Muestra la información básica, total de materiales, estado y progreso de descarga,
/// y permite acceder al contenido del módulo o gestionar las descargas locales.
class ContemporaneaScreen extends StatefulWidget {
  const ContemporaneaScreen({super.key});

  @override
  State<ContemporaneaScreen> createState() => _ContemporaneaScreenState();
}

class _ContemporaneaScreenState extends State<ContemporaneaScreen> {
  final DownloadService _downloadService = DownloadService();
  final ContentService _contentService = ContentService();

  static const String moduleId = 'mod_contemporanea';

  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _materialCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final isDownloaded = await _downloadService.isModuleDownloaded(moduleId);
    final materials = await _contentService.getContemporaneaMaterials();

    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
        _materialCount = materials.length;
        _isLoading = false;
      });
    }
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    _downloadService.downloadModule(moduleId).listen((progress) {
      if (mounted) {
        setState(() {
          _downloadProgress = progress;
          if (progress >= 1.0) {
            _isDownloading = false;
            _isDownloaded = true;
          }
        });
      }
    });
  }

  Future<void> _deleteDownload() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar material descargado'),
        content: const Text(
            '¿Deseas borrar los archivos de Panamá Contemporánea de tu dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _downloadService.removeModuleDownload(moduleId);
      await _checkStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivos descargados eliminados del dispositivo.'),
          ),
        );
      }
    }
  }

  void _navigateToContent() {
    Navigator.pushNamed(context, AppRoutes.contemporaneaContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Panamá Contemporánea'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner decorativo del módulo Panamá Contemporánea
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryTealDark, AppColors.primaryTeal],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.history_edu,
                              size: 80,
                              color: AppColors.sandAccent,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Época Contemporánea',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nombre del módulo
                  const Text(
                    'PANAMÁ CONTEMPORÁNEA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                      fontFamily: 'Serif',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Descripción del módulo
                  const Text(
                    'Material educativo de Historia de Panamá. Análisis de la gesta patriótica de 1964, los acontecimientos contemporáneos y el desarrollo social e histórico del istmo.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tarjeta de información de materiales disponibles
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.folder_zip,
                              color: AppColors.primaryTeal, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Materiales educativos',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                'Materiales: $_materialCount',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Estado de descarga
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isDownloaded
                          ? const Color(0xFFDCFCE7)
                          : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDownloaded
                            ? const Color(0xFF86EFAC)
                            : AppColors.borderGrey,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isDownloaded
                              ? Icons.check_circle
                              : (_isDownloading
                                  ? Icons.downloading
                                  : Icons.cloud_download_outlined),
                          color: _isDownloaded
                              ? const Color(0xFF166534)
                              : AppColors.primaryTeal,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estado:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                _isDownloaded
                                    ? 'Material descargado'
                                    : (_isDownloading
                                        ? 'Descargando material...'
                                        : 'Material no descargado'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _isDownloaded
                                      ? const Color(0xFF166534)
                                      : AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progreso de descarga si está descargando
                  if (_isDownloading) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progreso de descarga',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                '${(_downloadProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: const Color(0xFFE2E8F0),
                            color: AppColors.primaryTeal,
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 12),

                  // Botones de acción principales
                  if (!_isDownloaded && !_isDownloading)
                    CustomButton(
                      text: 'DESCARGAR MATERIAL',
                      icon: Icons.download,
                      variant: CustomButtonVariant.green,
                      onPressed: _startDownload,
                    )
                  else if (_isDownloaded) ...[
                    CustomButton(
                      text: 'VER MATERIAL',
                      icon: Icons.menu_book,
                      variant: CustomButtonVariant.primary,
                      onPressed: _navigateToContent,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Borrar archivos descargados',
                      icon: Icons.delete_outline,
                      variant: CustomButtonVariant.secondary,
                      onPressed: _deleteDownload,
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}
