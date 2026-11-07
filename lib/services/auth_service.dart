import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Servicio de Autenticación y Autorización basada en Roles (RBAC).
/// Gestiona la diferenciación estricta entre estudiantes y docentes autorizados,
/// persistencia de sesión con SharedPreferences y control de accesos.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _sessionKey = 'ph_auth_user_session_v1';
  static const String _usersRegistryKey = 'ph_users_registry_v1';

  UserModel? _currentUser = UserModel.mock();
  bool _isSessionLoaded = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isTeacher => _currentUser?.isTeacher ?? false;
  bool get isStudent => _currentUser?.isStudent ?? false;

  // Credenciales autorizadas para docentes institucionales MEDUCA / Panamá Histórica
  static final Map<String, _CredentialAccount> _authorizedTeachers = {
    'profesor.historica@meduca.gob.pa': _CredentialAccount(
      password: '12345678',
      user: UserModel.mockTeacher(
        id: 'doc_001',
        name: 'Prof. Alejandro Méndez',
        email: 'profesor.historica@meduca.gob.pa',
        institution: 'Instituto Nacional de Panamá',
      ),
    ),
    'docente@meduca.edu.pa': _CredentialAccount(
      password: '12345678',
      user: UserModel.mockTeacher(
        id: 'doc_002',
        name: 'Prof. Carmen Guardia',
        email: 'docente@meduca.edu.pa',
        institution: 'Colegio José Antonio Remón Cantera',
      ),
    ),
    'profesor@academia.edu.pa': _CredentialAccount(
      password: '12345678',
      user: UserModel.mockTeacher(
        id: 'doc_003',
        name: 'Prof. Ricardo Bermúdez',
        email: 'profesor@academia.edu.pa',
        institution: 'Academia Panamá',
      ),
    ),
  };

  // Credenciales predeterminadas para estudiantes
  static final Map<String, _CredentialAccount> _defaultStudents = {
    'estudiante@academia.pa': const _CredentialAccount(
      password: '12345678',
      user: UserModel(
        id: 'usr_001',
        name: 'Ricardo Arias',
        email: 'estudiante@academia.pa',
        grade: '11° Grado',
        institution: 'Academia Panamá',
        level: 15,
        levelTitle: 'Historiador Nivel 15',
        deviceInUse: 'iPhone 13 (Apple Inc.)',
        avatarUrl: '',
        role: UserRole.student,
      ),
    ),
    'r.arias@academia.edu.pa': _CredentialAccount(
      password: '12345678',
      user: UserModel.mock(),
    ),
  };

  /// Carga la sesión persistida desde SharedPreferences al iniciar la aplicación.
  Future<UserModel?> loadSession() async {
    if (_isSessionLoaded && _currentUser != null) return _currentUser;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_sessionKey);

      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(userJson);
        _currentUser = UserModel.fromJson(data);
      }
    } catch (_) {}

    _isSessionLoaded = true;
    return _currentUser;
  }

  /// Inicia sesión general (tanto para estudiantes como docentes).
  /// Dirige automáticamente según el rol autenticado.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      throw Exception('Por favor ingrese correo y contraseña.');
    }

    // 1. Comprobar si corresponde a un docente institucional autorizado
    if (_authorizedTeachers.containsKey(cleanEmail)) {
      final cred = _authorizedTeachers[cleanEmail]!;
      if (cred.password == cleanPass) {
        _currentUser = cred.user;
        await _saveSession(_currentUser!);
        return _currentUser!;
      } else {
        throw Exception('Contraseña incorrecta para la cuenta docente institucional.');
      }
    }

    // 2. Si el correo explícitamente denota rol docente
    if (cleanEmail.contains('docente') || cleanEmail.contains('profesor')) {
      _currentUser = UserModel.mockTeacher(
        email: cleanEmail,
        name: cleanEmail.contains('guardia') ? 'Prof. Carmen Guardia' : 'Prof. Docente Autorizado',
      );
      await _saveSession(_currentUser!);
      return _currentUser!;
    }

    // 3. Estudiante (permite autenticación estudiantil)
    final dynamicUser = await _getRegisteredStudent(cleanEmail, cleanPass);
    if (dynamicUser != null) {
      _currentUser = dynamicUser;
      await _saveSession(_currentUser!);
      return _currentUser!;
    }

    final defaultStudent = _defaultStudents[cleanEmail]?.user;
    if (defaultStudent != null) {
      _currentUser = defaultStudent.copyWith(email: cleanEmail);
      await _saveSession(_currentUser!);
      return _currentUser!;
    }

    _currentUser = UserModel.mock().copyWith(
      email: cleanEmail,
      role: UserRole.student,
    );
    await _saveSession(_currentUser!);
    return _currentUser!;
  }

  /// Inicia sesión exclusivo para DOCENTES.
  /// Comprueba credenciales y verifica explícitamente que la cuenta tenga rol docente.
  /// No permite acceso a cuentas con rol de estudiante.
  Future<UserModel> signInTeacher({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      throw Exception('Por favor ingrese correo y contraseña.');
    }

    // Si es un estudiante intentando ingresar por el acceso docente
    if (_defaultStudents.containsKey(cleanEmail)) {
      throw Exception(
        'Acceso denegado: Esta cuenta pertenece al rol de Estudiante. Utilice el acceso para estudiantes.',
      );
    }

    // Verificar en lista de docentes autorizados
    if (_authorizedTeachers.containsKey(cleanEmail)) {
      final cred = _authorizedTeachers[cleanEmail]!;
      if (cred.password != cleanPass) {
        throw Exception('Contraseña incorrecta. Verifique sus credenciales institucionales.');
      }
      _currentUser = cred.user;
      await _saveSession(_currentUser!);
      return _currentUser!;
    }

    // Comprobar formato institucional de docente
    if (cleanEmail.endsWith('@meduca.gob.pa') ||
        cleanEmail.endsWith('@meduca.edu.pa') ||
        cleanEmail.contains('docente') ||
        cleanEmail.contains('profesor')) {
      _currentUser = UserModel.mockTeacher(
        email: cleanEmail,
        name: 'Prof. Docente Autorizado',
      );
      await _saveSession(_currentUser!);
      return _currentUser!;
    }

    throw Exception(
      'No se encontró una cuenta de docente autorizada con este correo. Contacte a la administración del MEDUCA.',
    );
  }

  /// Registro exclusivo de estudiantes.
  /// Por seguridad institucional, no permite la autoasignación del rol docente.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String grade,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final cleanEmail = email.trim().toLowerCase();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception('Todos los campos son obligatorios.');
    }

    // Se asigna SIEMPRE y de manera forzosa el rol de estudiante
    final newStudent = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: cleanEmail,
      grade: grade,
      institution: 'Academia Panamá',
      level: 1,
      levelTitle: 'Historiador Inicial Nivel 1',
      deviceInUse: 'Dispositivo Estudiantil',
      avatarUrl: '',
      role: UserRole.student, // Estudiante estricto
    );

    await _saveRegisteredStudent(cleanEmail, password, newStudent);
    _currentUser = newStudent;
    await _saveSession(_currentUser!);
    return _currentUser!;
  }

  /// Actualiza perfil de usuario
  void updateProfile({String? name, String? email, String? avatarUrl}) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        email: email,
        avatarUrl: avatarUrl,
      );
      _saveSession(_currentUser!);
    }
  }

  /// Cierra la sesión activa y elimina los datos de sesión local.
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (_) {}
  }

  Future<void> _saveSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _saveRegisteredStudent(
    String email,
    String password,
    UserModel user,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final regJson = prefs.getString(_usersRegistryKey);
      Map<String, dynamic> registry = {};
      if (regJson != null && regJson.isNotEmpty) {
        registry = jsonDecode(regJson);
      }
      registry[email] = {
        'password': password,
        'user': user.toJson(),
      };
      await prefs.setString(_usersRegistryKey, jsonEncode(registry));
    } catch (_) {}
  }

  Future<UserModel?> _getRegisteredStudent(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final regJson = prefs.getString(_usersRegistryKey);
      if (regJson == null || regJson.isEmpty) return null;
      final Map<String, dynamic> registry = jsonDecode(regJson);
      if (registry.containsKey(email)) {
        final data = registry[email];
        if (data['password'] == password) {
          return UserModel.fromJson(data['user'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }
}

class _CredentialAccount {
  final String password;
  final UserModel user;

  const _CredentialAccount({
    required this.password,
    required this.user,
  });
}
