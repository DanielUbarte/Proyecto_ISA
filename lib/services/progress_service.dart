import 'package:shared_preferences/shared_preferences.dart';

/// Servicio responsable de la persistencia local del progreso de lectura.
/// Guarda los materiales vistos, el último material consultado y la página
/// actual de los documentos PDF para que persistan aunque se cierre la app.
class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  static const String _viewedKeyPrefix = 'contemporanea_viewed_';
  static const String _lastOpenedKey = 'contemporanea_last_opened';
  static const String _pdfPageKeyPrefix = 'contemporanea_pdf_page_';

  /// Obtiene el conjunto de IDs de materiales marcados como vistos.
  Future<Set<String>> getViewedMaterialIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? viewedList = prefs.getStringList('${_viewedKeyPrefix}ids');
    return viewedList != null ? viewedList.toSet() : <String>{};
  }

  /// Marca un material como visto de forma persistente.
  Future<void> markMaterialAsViewed(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getViewedMaterialIds();
    set.add(materialId);
    await prefs.setStringList('${_viewedKeyPrefix}ids', set.toList());
  }

  /// Obtiene el ID del último material abierto.
  Future<String?> getLastOpenedMaterialId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOpenedKey);
  }

  /// Guarda el ID del último material abierto.
  Future<void> setLastOpenedMaterialId(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenedKey, materialId);
  }

  /// Obtiene la última página leída de un PDF (1-based index por defecto 1).
  Future<int> getPdfLastPage(String materialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_pdfPageKeyPrefix$materialId') ?? 1;
  }

  /// Guarda la última página leída de un PDF.
  Future<void> setPdfLastPage(String materialId, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_pdfPageKeyPrefix$materialId', page);
  }

  /// Limpia el progreso (útil si se deseara reiniciar).
  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_viewedKeyPrefix}ids');
    await prefs.remove(_lastOpenedKey);
  }
}
