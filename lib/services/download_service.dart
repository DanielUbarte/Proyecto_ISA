import 'dart:async';

/// Service abstraction for module download and offline management.
class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _downloadingState = {};

  double getProgress(String moduleId) => _downloadProgress[moduleId] ?? 0.0;
  bool isDownloading(String moduleId) => _downloadingState[moduleId] ?? false;

  /// Simulates background downloading of a module with progress updates.
  Stream<double> downloadModule(String moduleId) async* {
    _downloadingState[moduleId] = true;
    double progress = 0.0;
    while (progress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 300));
      progress += 0.15;
      if (progress > 1.0) progress = 1.0;
      _downloadProgress[moduleId] = progress;
      yield progress;
    }
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
