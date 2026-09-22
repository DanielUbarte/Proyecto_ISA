import '../modules/contemporanea/contemporanea_data.dart';
import 'progress_service.dart';

/// Servicio responsable de proveer el contenido y materiales del módulo Panamá Contemporánea.
class ContentService {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  final ProgressService _progressService = ProgressService();

  /// Obtiene los materiales actualizados con el estado de lectura persistido.
  Future<List<ContemporaneaMaterial>> getContemporaneaMaterials() async {
    final initial = ContemporaneaMaterial.getInitialMaterials();
    final viewedIds = await _progressService.getViewedMaterialIds();

    return initial.map((mat) {
      return mat.copyWith(viewed: viewedIds.contains(mat.id));
    }).toList();
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
