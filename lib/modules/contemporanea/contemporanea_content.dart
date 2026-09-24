import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/historical_scene_model.dart';
import '../../services/content_service.dart';
import 'contemporanea_data.dart';
import 'widgets/historical_scene_widget.dart';
import 'widgets/image_viewer_widget.dart';
import 'widgets/pdf_viewer_widget.dart';
import 'widgets/progress_bar_widget.dart';

/// Pantalla que despliega la lista de contenidos, escenas históricas y materiales educativos del módulo Panamá Contemporánea.
/// Muestra las escenas históricas (9 de enero de 1964) con sus imágenes locales existentes, textos de fuente e integración de narración IA.
class ContemporaneaContent extends StatefulWidget {
  const ContemporaneaContent({super.key});

  @override
  State<ContemporaneaContent> createState() => _ContemporaneaContentState();
}

class _ContemporaneaContentState extends State<ContemporaneaContent> {
  final ContentService _contentService = ContentService();

  List<ContemporaneaMaterial> _materials = [];
  List<HistoricalScene> _scenes = [];
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
    final scenes = HistoricalScene.getContemporaneaScenes();

    if (mounted) {
      setState(() {
        _materials = materials;
        _scenes = scenes;
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

    _loadMaterials();
  }

  void _openScene(HistoricalScene scene) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoricalSceneWidget(scene: scene),
      ),
    );
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

                  // Continuar lectura previa si existe
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
                    const SizedBox(height: 24),
                  ],

                  // --------------------------------------------------
                  // SECCIÓN: ESCENAS HISTÓRICAS (9 DE ENERO DE 1964)
                  // --------------------------------------------------
                  const Row(
                    children: [
                      Icon(Icons.theater_comedy, color: AppColors.primaryTeal, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Escenas Históricas Ilustradas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Explora las escenas históricas con imágenes locales y narración IA.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._scenes.map((scene) => _buildSceneCard(scene)),

                  const SizedBox(height: 28),

                  // --------------------------------------------------
                  // SECCIÓN: DOCUMENTOS E IMÁGENES DEL MÓDULO
                  // --------------------------------------------------
                  const Row(
                    children: [
                      Icon(Icons.folder_copy_outlined,
                          color: AppColors.primaryTeal, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Materiales Bibliográficos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ..._materials.map((material) {
                    return _buildMaterialCard(material);
                  }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSceneCard(HistoricalScene scene) {
    final bool hasImage = scene.imagePath != null && scene.imagePath!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openScene(scene),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage) ...[
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      Image.asset(
                        scene.imagePath!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.volume_up,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Narración IA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.sandAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            scene.period,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C2D12),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.timer_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          scene.duration,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scene.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scene.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.menu_book,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Fuente: ${scene.source}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.primaryTeal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
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
      ),
    );
  }
}
