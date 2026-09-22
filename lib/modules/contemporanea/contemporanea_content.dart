import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../services/content_service.dart';
import 'contemporanea_data.dart';
import 'widgets/image_viewer_widget.dart';
import 'widgets/pdf_viewer_widget.dart';
import 'widgets/progress_bar_widget.dart';

/// Pantalla que despliega la lista de contenidos y materiales educativos del módulo Panamá Contemporánea.
/// Muestra el progreso de lectura actualizado en tiempo real y permite abrir documentos e imágenes.
class ContemporaneaContent extends StatefulWidget {
  const ContemporaneaContent({super.key});

  @override
  State<ContemporaneaContent> createState() => _ContemporaneaContentState();
}

class _ContemporaneaContentState extends State<ContemporaneaContent> {
  final ContentService _contentService = ContentService();

  List<ContemporaneaMaterial> _materials = [];
  ContemporaneaMaterial? _lastOpenedMaterial;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    final materials = await _contentService.getContemporaneaMaterials();
    final lastOpened = await _contentService.getLastOpenedMaterial();

    if (mounted) {
      setState(() {
        _materials = materials;
        _lastOpenedMaterial = lastOpened;
        _isLoading = false;
      });
    }
  }

  void _openMaterial(ContemporaneaMaterial material) async {
    Widget viewer;
    if (material.type == 'pdf') {
      viewer = PdfViewerWidget(
        materialId: material.id,
        title: material.title,
        assetPath: material.assetPath,
      );
    } else {
      viewer = ImageViewerWidget(
        materialId: material.id,
        title: material.title,
        assetPath: material.assetPath,
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => viewer),
    );

    // Al regresar del visor, actualizar automáticamente la lista y el progreso
    _loadMaterials();
  }

  @override
  Widget build(BuildContext context) {
    final int viewedCount = _materials.where((m) => m.viewed).length;
    final int totalCount = _materials.length;

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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : RefreshIndicator(
              onRefresh: _loadMaterials,
              color: AppColors.primaryTeal,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Widget de Barra de Progreso de Lectura
                  ContemporaneaProgressBar(
                    viewedCount: viewedCount,
                    totalCount: totalCount,
                  ),
                  const SizedBox(height: 20),

                  // Botón de "Continuar desde el último material consultado" si existe
                  if (_lastOpenedMaterial != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.sandAccent.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.amberBadge),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: Color(0xFF7C2D12)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Continuar lectura',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7C2D12),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _lastOpenedMaterial!.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _openMaterial(_lastOpenedMaterial!),
                            child: const Text(
                              'Continuar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Encabezado de la lista
                  const Text(
                    'Lista de Materiales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Elementos de la lista de materiales
                  ..._materials.map((material) {
                    return _buildMaterialCard(material);
                  }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildMaterialCard(ContemporaneaMaterial material) {
    final bool isPdf = material.type == 'pdf';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: material.viewed
              ? const Color(0xFF86EFAC)
              : AppColors.borderGrey,
          width: material.viewed ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPdf
                ? Colors.red.shade50
                : AppColors.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isPdf ? '📄' : '🖼️',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          material.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: material.viewed ? AppColors.textDark : AppColors.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                isPdf ? 'Documento histórico (PDF)' : 'Imagen histórica',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              if (material.viewed)
                const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.forestGreen, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Visto',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.primaryTeal,
        ),
        onTap: () => _openMaterial(material),
      ),
    );
  }
}
