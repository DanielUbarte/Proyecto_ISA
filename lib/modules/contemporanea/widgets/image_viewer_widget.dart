import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../services/content_service.dart';

/// Visor interactivo de imágenes históricas del módulo Panamá Contemporánea.
/// Permite zoom táctil, paneo y desplazamiento sin salir de la aplicación.
class ImageViewerWidget extends StatefulWidget {
  final String materialId;
  final String title;
  final String assetPath;

  const ImageViewerWidget({
    super.key,
    required this.materialId,
    required this.title,
    required this.assetPath,
  });

  @override
  State<ImageViewerWidget> createState() => _ImageViewerWidgetState();
}

class _ImageViewerWidgetState extends State<ImageViewerWidget> {
  final ContentService _contentService = ContentService();
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _markViewed();
  }

  Future<void> _markViewed() async {
    await _contentService.markAsViewed(widget.materialId);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.aspect_ratio),
            tooltip: 'Restablecer Zoom',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.8,
            maxScale: 4.0,
            child: Image.asset(
              widget.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  color: AppColors.backgroundLight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image,
                          size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No se pudo cargar la imagen: ${widget.assetPath}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
