import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de gestión de descargas y disponibilidad offline de módulos.
/// Preparado para futura integración con Firebase Storage / descarga remota.
class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _downloadingState = {};

  static const String _downloadedKeyPrefix = 'module_downloaded_';

  double getProgress(String moduleId) => _downloadProgress[moduleId] ?? 0.0;
  bool isDownloading(String moduleId) => _downloadingState[moduleId] ?? false;

  /// Verifica si un módulo ya ha sido descargado y está disponible offline.
  Future<bool> isModuleDownloaded(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_downloadedKeyPrefix$moduleId') ?? false;
  }

  /// Simula la descarga en segundo plano de un módulo con emisión de progreso.
  Stream<double> downloadModule(String moduleId) async* {
    _downloadingState[moduleId] = true;
    double progress = 0.0;
    while (progress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 200));
      progress += 0.25;
      if (progress > 1.0) progress = 1.0;
      _downloadProgress[moduleId] = progress;
      yield progress;
    }
    _downloadingState[moduleId] = false;

    // Guardar estado descargado de forma persistente
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_downloadedKeyPrefix$moduleId', true);
  }

  /// Elimina los archivos descargados y restablece el estado offline del módulo.
  Future<void> removeModuleDownload(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_downloadedKeyPrefix$moduleId', false);
    _downloadProgress[moduleId] = 0.0;
    _downloadingState[moduleId] = false;
  }

  void pauseDownload(String moduleId) {
    _downloadingState[moduleId] = false;
  }

  void cancelDownload(String moduleId) {
    _downloadingState[moduleId] = false;
    _downloadProgress[moduleId] = 0.0;
  }
}
