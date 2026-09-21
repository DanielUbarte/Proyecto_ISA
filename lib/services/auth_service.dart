import '../models/user_model.dart';

/// Service abstraction for Authentication.
/// Prepared for future integration with Firebase Authentication.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser = UserModel.mock();

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Simulates sign in with email and password.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Por favor ingrese correo y contraseña.');
    }
    _currentUser = UserModel.mock().copyWith(email: email);
    return _currentUser!;
  }

  /// Simulates registration.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String grade,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception('Todos los campos son obligatorios.');
    }
    _currentUser = UserModel.mock().copyWith(
      name: name,
      email: email,
      grade: grade,
    );
    return _currentUser!;
  }

  /// Simulates sign out.
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}
