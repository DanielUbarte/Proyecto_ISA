import '../models/module_model.dart';
import '../models/progress_model.dart';
import '../models/user_model.dart';

/// Service abstraction for local & cloud persistence.
/// Prepared for future integration with SQLite/Drift and Cloud Firestore.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Fetches modules list from local database / mock.
  Future<List<ModuleModel>> getModules() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ModuleModel.getMockModules();
  }

  /// Fetches student profile.
  Future<UserModel> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return UserModel.mock();
  }

  /// Fetches student progress summary.
  Future<StudentProgressModel> getStudentProgress() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return StudentProgressModel.mock();
  }

  /// Updates offline state of a module.
  Future<void> updateModuleOfflineState(String moduleId, bool isOffline) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
