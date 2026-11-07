import '../models/document_model.dart';
import '../modules/contemporanea/contemporanea_data.dart';
import 'document_storage_service.dart';
import 'progress_service.dart';

/// Servicio responsable de proveer el contenido y materiales del módulo Panamá Contemporánea.
/// Integra los materiales base curriculares con los documentos educativos incorporados y publicados por docentes.
class ContentService {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  final ProgressService _progressService = ProgressService();
  final DocumentStorageService _storageService = DocumentStorageService();

  /// Obtiene los materiales actualizados con el estado de lectura persistido.
  /// Incluye tanto los recursos base como los nuevos documentos publicados por los docentes.
  Future<List<ContemporaneaMaterial>> getContemporaneaMaterials() async {
    final viewedIds = await _progressService.getViewedMaterialIds();
    final publishedDocs = await _storageService.getPublishedDocumentsForModule('mod_contemporanea');

    // Mapear documentos publicados dinámicos a ContemporaneaMaterial
    final dynamicMaterials = publishedDocs.map((doc) {
      return ContemporaneaMaterial(
        id: doc.id,
        title: doc.title,
        type: doc.fileType,
        assetPath: doc.filePath,
        viewed: viewedIds.contains(doc.id),
        order: doc.isPdf ? 1 : 2,
      );
    }).toList();

    // Si no hubiera documentos dinámicos aún, fallback a los iniciales
    if (dynamicMaterials.isEmpty) {
      final initial = ContemporaneaMaterial.getInitialMaterials();
      return initial.map((mat) {
        return mat.copyWith(viewed: viewedIds.contains(mat.id));
      }).toList();
    }

    return dynamicMaterials;
  }

  /// Retorna los documentos educativos publicados organizados por sección para el módulo.
  Future<Map<String, List<EducationalDocumentModel>>> getPublishedDocumentsGroupedBySection(
    String moduleId,
  ) async {
    final docs = await _storageService.getPublishedDocumentsForModule(moduleId);
    final Map<String, List<EducationalDocumentModel>> grouped = {};

    for (final doc in docs) {
      final section = doc.sectionTitle.isNotEmpty ? doc.sectionTitle : 'General';
      if (!grouped.containsKey(section)) {
        grouped[section] = [];
      }
      grouped[section]!.add(doc);
    }

    return grouped;
  }

  /// Obtiene el último material abierto por el estudiante.
  Future<ContemporaneaMaterial?> getLastOpenedMaterial() async {
    final materials = await getContemporaneaMaterials();
    final lastId = await _progressService.getLastOpenedMaterialId();
    if (lastId == null) return null;
    try {
      return materials.firstWhere((m) => m.id == lastId);
    } catch (_) {
      return null;
    }
  }

  /// Registra un material como visto y guarda su estado.
  Future<void> markAsViewed(String materialId) async {
    await _progressService.markMaterialAsViewed(materialId);
    await _progressService.setLastOpenedMaterialId(materialId);
  }
}
