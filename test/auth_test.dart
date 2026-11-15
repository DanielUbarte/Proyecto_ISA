import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panama_historica/models/user_model.dart';
import 'package:panama_historica/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    authService = AuthService();
    await authService.signOut();
  });

  group('Checklist de Pruebas Unitarias - Módulo de Autenticación y Roles (RBAC)', () {
    // 1. Identificación y Normalización de Roles
    test('1. Normalización y conversión de roles (UserRole.fromString y displayName)', () {
      expect(UserRole.fromString('teacher'), equals(UserRole.teacher));
      expect(UserRole.fromString('DOCENTE'), equals(UserRole.teacher));
      expect(UserRole.fromString('  profesor  '), equals(UserRole.teacher));
      expect(UserRole.fromString(null), equals(UserRole.student));
      expect(UserRole.fromString(''), equals(UserRole.student));
      expect(UserRole.fromString('   '), equals(UserRole.student));
      expect(UserRole.fromString('estudiante'), equals(UserRole.student));
      expect(UserRole.fromString('rol_inexistente'), equals(UserRole.student));
      expect(UserRole.student.displayName, equals('Estudiante'));
      expect(UserRole.teacher.displayName, equals('Docente'));
    });

    // 2. Banderas Booleanas de Rol y Estado de Autenticación
    test('2. Evaluación de banderas booleanas de rol y estado tras cierre de sesión (signOut)', () async {
      final student = UserModel.mock();
      expect(student.isStudent, isTrue);
      expect(student.isTeacher, isFalse);

      final teacher = UserModel.mockTeacher();
      expect(teacher.isTeacher, isTrue);
      expect(teacher.isStudent, isFalse);

      await authService.signOut();
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.isTeacher, isFalse);
      expect(authService.isStudent, isFalse);
    });

    // 3. Validación de Campos Vacíos y con Espacios en Inicio de Sesión
    test('3. Validación de campos vacíos y espacios en blanco en inicio de sesión (signIn)', () async {
      expect(
        () => authService.signIn(email: '', password: '12345678'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Por favor ingrese correo y contraseña.'),
        )),
      );

      expect(
        () => authService.signIn(email: 'usuario@academia.pa', password: ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Por favor ingrese correo y contraseña.'),
        )),
      );

      expect(
        () => authService.signIn(email: '   ', password: '   '),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Por favor ingrese correo y contraseña.'),
        )),
      );
    });

    // 4. Autenticación Exitosa de Docente Institucional Autorizado
    test('4. Inicio de sesión exitoso de docente institucional autorizado y persistencia (signIn)', () async {
      final user = await authService.signIn(
        email: 'profesor.historica@meduca.gob.pa',
        password: '12345678',
      );

      expect(user.isTeacher, isTrue);
      expect(user.role, equals(UserRole.teacher));
      expect(user.name, equals('Prof. Alejandro Méndez'));
      expect(user.institution, equals('Instituto Nacional de Panamá'));
      expect(authService.isAuthenticated, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString('ph_auth_user_session_v1');
      expect(sessionJson, isNotNull);
      expect(sessionJson, contains('profesor.historica@meduca.gob.pa'));
    });

    // 5. Manejo de Contraseña Incorrecta en Cuenta Docente Institucional
    test('5. Rechazo por contraseña incorrecta en cuenta docente institucional (signIn)', () async {
      expect(
        () => authService.signIn(
          email: 'profesor.historica@meduca.gob.pa',
          password: 'contrasena_invalida',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Contraseña incorrecta para la cuenta docente institucional.'),
        )),
      );

      expect(authService.isAuthenticated, isFalse);
    });

    // 6. [DEFECTO H-03] Restricción RBAC: Vulnerabilidad de asignación docente por subcadena laxa
    test('6. Restricción RBAC: Denegación de acceso docente a estudiante con subcadena profesor en correo (signInTeacher)', () async {
      // Un estudiante con correo 'estudiante.profesorado@alumno.pa' no debe obtener acceso de docente
      expect(
        () => authService.signInTeacher(
          email: 'estudiante.profesorado@alumno.pa',
          password: 'password123',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('No se encontró una cuenta de docente autorizada con este correo.'),
        )),
      );
    });

    // 7. Autenticación Docente por Patrón de Correo Institucional
    test('7. Acceso docente autorizado por patrón institucional @meduca.edu.pa (signInTeacher)', () async {
      final user = await authService.signInTeacher(
        email: 'nuevo.tutor@meduca.edu.pa',
        password: 'PasswordValido123',
      );

      expect(user.role, equals(UserRole.teacher));
      expect(user.isTeacher, isTrue);
      expect(user.email, equals('nuevo.tutor@meduca.edu.pa'));
      expect(user.name, equals('Prof. Docente Autorizado'));
      expect(authService.currentUser?.isTeacher, isTrue);
    });

    // 8. [DEFECTO H-05] Rechazo de credenciales inexistentes - Prevención de usuarios fantasma
    test('8. Rechazo de credenciales inexistentes para usuario no registrado en login general (signIn)', () async {
      // Un correo desconocido no debe autenticarse ni generar un usuario fantasma automáticamente
      expect(
        () => authService.signIn(
          email: 'usuario.fantasma.desconocido@noexiste.pa',
          password: 'password123',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Credenciales no válidas o usuario no registrado.'),
        )),
      );
    });

    // 9. Validación de Campos Obligatorios en Registro de Estudiante
    test('9. Validación de campos obligatorios en registro de estudiante (register)', () async {
      expect(
        () => authService.register(
          name: '',
          email: 'estudiante.nuevo@academia.pa',
          password: 'password123',
          grade: '10° Grado',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Todos los campos son obligatorios.'),
        )),
      );

      expect(
        () => authService.register(
          name: 'Luis González',
          email: '',
          password: 'password123',
          grade: '10° Grado',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Todos los campos son obligatorios.'),
        )),
      );

      expect(
        () => authService.register(
          name: 'Luis González',
          email: 'luis@academia.pa',
          password: '',
          grade: '10° Grado',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Todos los campos son obligatorios.'),
        )),
      );
    });

    // 10. Inmutabilidad de Privilegios en Registro Estudiantil
    test('10. Asignación forzosa del rol estudiante en auto-registro sin escalamiento (register)', () async {
      final student = await authService.register(
        name: 'Mariana Díaz',
        email: 'mariana.diaz@academia.pa',
        password: 'password123',
        grade: '11° Grado',
      );

      expect(student.role, equals(UserRole.student));
      expect(student.isStudent, isTrue);
      expect(student.isTeacher, isFalse);
      expect(student.level, equals(1));
      expect(student.levelTitle, equals('Historiador Inicial Nivel 1'));

      final prefs = await SharedPreferences.getInstance();
      final registryJson = prefs.getString('ph_users_registry_v1');
      expect(registryJson, isNotNull);
      expect(registryJson, contains('mariana.diaz@academia.pa'));
    });

    // 11. Idempotencia y Manejo de Doble Envío de Formulario
    test('11. Idempotencia ante doble envío del formulario de registro de estudiante (register)', () async {
      final firstAttempt = await authService.register(
        name: 'Carlos Ruiz',
        email: 'carlos.ruiz@academia.pa',
        password: 'passwordSeguro1',
        grade: '12° Grado',
      );

      final secondAttempt = await authService.register(
        name: 'Carlos Ruiz',
        email: 'carlos.ruiz@academia.pa',
        password: 'passwordSeguro1',
        grade: '12° Grado',
      );

      expect(firstAttempt.email, equals(secondAttempt.email));
      expect(secondAttempt.role, equals(UserRole.student));
      expect(authService.currentUser?.email, equals('carlos.ruiz@academia.pa'));

      await authService.signOut();
      final loggedUser = await authService.signIn(
        email: 'carlos.ruiz@academia.pa',
        password: 'passwordSeguro1',
      );
      expect(loggedUser.name, equals('Carlos Ruiz'));
      expect(loggedUser.isStudent, isTrue);
    });

    // 12. Concurrencia y Solicitudes Simultáneas de Autenticación
    test('12. Manejo concurrente de solicitudes simultáneas de autenticación (Future.wait)', () async {
      final responses = await Future.wait([
        authService.signIn(
          email: 'r.arias@academia.edu.pa',
          password: '12345678',
        ),
        authService.signInTeacher(
          email: 'profesor.historica@meduca.gob.pa',
          password: '12345678',
        ),
      ]);

      expect(responses.length, equals(2));
      expect(responses[0], isA<UserModel>());
      expect(responses[1], isA<UserModel>());
      expect(authService.currentUser, isNotNull);
      expect(authService.isAuthenticated, isTrue);
    });

    // 13. [DEFECTO H-04] Consistencia en el mensaje de excepción ante credenciales inválidas (signIn vs signInTeacher)
    test('13. Estandarización de mensajes de excepción ante credenciales inválidas (signIn vs signInTeacher)', () async {
      late String errorSignIn;
      late String errorSignInTeacher;

      try {
        await authService.signIn(
          email: 'profesor.historica@meduca.gob.pa',
          password: 'wrong_password',
        );
      } catch (e) {
        errorSignIn = e.toString().replaceAll('Exception: ', '');
      }

      try {
        await authService.signInTeacher(
          email: 'profesor.historica@meduca.gob.pa',
          password: 'wrong_password',
        );
      } catch (e) {
        errorSignInTeacher = e.toString().replaceAll('Exception: ', '');
      }

      expect(
        errorSignInTeacher,
        equals(errorSignIn),
        reason: 'El mensaje de error ante contraseña incorrecta debe estar estandarizado en todo el módulo',
      );
    });

    // 14. Manejo Robusto de Inconsistencias y Corrupción en el Estado de Sesión
    test('14. Resiliencia ante datos corruptos en el almacenamiento de sesión (loadSession)', () async {
      await authService.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ph_auth_user_session_v1', '{"corrupt_json": [incompleto');

      final loaded = await authService.loadSession();

      expect(loaded, isNull);
      expect(authService.isAuthenticated, isFalse);
    });

    // 15. Serialización Completa, Deserialización y Tolerancia a Nulos
    test('15. Serialización, deserialización y valores por defecto ante datos incompletos (UserModel)', () {
      final teacherModel = UserModel.mockTeacher(
        id: 'doc_custom_01',
        name: 'Dra. María Obaldía',
        email: 'mobaldia@meduca.gob.pa',
        institution: 'Instituto Fermín Naudeau',
      );

      final json = teacherModel.toJson();
      expect(json['id'], equals('doc_custom_01'));
      expect(json['role'], equals('teacher'));
      expect(json['email'], equals('mobaldia@meduca.gob.pa'));

      final reconstructed = UserModel.fromJson(json);
      expect(reconstructed.id, equals(teacherModel.id));
      expect(reconstructed.name, equals(teacherModel.name));
      expect(reconstructed.isTeacher, isTrue);

      final emptyJson = <String, dynamic>{};
      final defaultUser = UserModel.fromJson(emptyJson);
      expect(defaultUser.id, equals('usr_unknown'));
      expect(defaultUser.name, isEmpty);
      expect(defaultUser.email, isEmpty);
      expect(defaultUser.level, equals(1));
      expect(defaultUser.role, equals(UserRole.student));
      expect(defaultUser.isStudent, isTrue);
      expect(defaultUser.isTeacher, isFalse);
    });
  });
}
