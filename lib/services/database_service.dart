import '../models/module_model.dart';
import '../models/progress_model.dart';
import '../models/user_model.dart';
import 'download_service.dart';

/// Service abstraction for local & cloud persistence.
/// Prepared for future integration with SQLite/Drift and Cloud Firestore.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final DownloadService _downloadService = DownloadService();

  /// Fetches modules list from local database / mock with dynamic download status.
  Future<List<ModuleModel>> getModules() async {
    final rawModules = ModuleModel.getMockModules();
    final List<ModuleModel> updated = [];

    for (final m in rawModules) {
      final isDownloaded = await _downloadService.isModuleDownloaded(m.id);
      final isDownloading = _downloadService.isDownloading(m.id);
      final progress = _downloadService.getProgress(m.id);

      ModuleStatus status = m.status;
      if (isDownloaded) {
        status = ModuleStatus.downloaded;
      } else if (isDownloading) {
        status = ModuleStatus.downloading;
      } else {
        status = ModuleStatus.available;
      }

      updated.add(m.copyWith(
        status: status,
        isOfflineAvailable: isDownloaded,
        downloadProgress: isDownloaded ? 1.0 : progress,
      ));
    }

    return updated;
  }

  /// Fetches student profile.
  Future<UserModel> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return UserModel.mock();
  }

  /// Fetches student progress summary.
  Future<StudentProgressModel> getStudentProgress() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return StudentProgressModel.mock();
  }

  /// Updates offline state of a module.
  Future<void> updateModuleOfflineState(String moduleId, bool isOffline) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
