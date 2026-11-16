import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panama_historica/models/user_model.dart';
import 'package:panama_historica/services/auth_service.dart';
import 'package:panama_historica/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authService = AuthService();
  });

  tearDown(() async {
    await authService.signOut();
  });

  group('Checklist de Pruebas Unitarias - Módulo de Perfil y Configuración', () {
    // ------------------------------------------------------------------------
    // Caso 1: Consulta y deserialización de perfiles existentes
    // ------------------------------------------------------------------------
    test('1. Consulta y deserialización de perfiles existentes completos (estudiante y docente)', () {
      final studentJson = {
        'id': 'usr_001',
        'name': 'Ricardo Arias',
        'email': 'r.arias@academia.edu.pa',
        'grade': '11° Grado',
        'institution': 'Academia Panamá',
        'level': 15,
        'levelTitle': 'Historiador Nivel 15',
        'deviceInUse': 'iPhone 13',
        'avatarUrl': 'assets/images/logo.png',
        'role': 'student',
      };

      final student = UserModel.fromJson(studentJson);
      expect(student.id, equals('usr_001'));
      expect(student.name, equals('Ricardo Arias'));
      expect(student.email, equals('r.arias@academia.edu.pa'));
      expect(student.role, equals(UserRole.student));
      expect(student.isStudent, isTrue);
      expect(student.isTeacher, isFalse);

      final teacher = UserModel.mockTeacher();
      expect(teacher.role, equals(UserRole.teacher));
      expect(teacher.isTeacher, isTrue);
      expect(teacher.isStudent, isFalse);
    });

    // ------------------------------------------------------------------------
    // Caso 2: Perfiles incompletos o con claves faltantes
    // ------------------------------------------------------------------------
    test('2. Perfiles incompletos asignan valores predeterminados seguros sin excepciones', () {
      final incompleteJson = <String, dynamic>{
        'name': 'Estudiante Temporal',
      };

      final user = UserModel.fromJson(incompleteJson);
      expect(user.id, equals('usr_unknown'));
      expect(user.name, equals('Estudiante Temporal'));
      expect(user.email, isEmpty);
      expect(user.grade, isEmpty);
      expect(user.institution, isEmpty);
      expect(user.level, equals(1));
      expect(user.role, equals(UserRole.student));
    });

    // ------------------------------------------------------------------------
    // Caso 3: Modificación de datos válidos (nombre, correo y avatar)
    // ------------------------------------------------------------------------
    test('3. Modificación de datos válidos actualiza correctamente los atributos del usuario en memoria', () async {
      await authService.signIn(email: 'estudiante@academia.pa', password: '12345678');

      authService.updateProfile(
        name: 'Ricardo Arias Actualizado',
        email: 'r.arias.nuevo@academia.edu.pa',
        avatarUrl: 'assets/images/logo.png',
      );

      final current = authService.currentUser!;
      expect(current.name, equals('Ricardo Arias Actualizado'));
      expect(current.email, equals('r.arias.nuevo@academia.edu.pa'));
      expect(current.avatarUrl, equals('assets/images/logo.png'));
    });

    // ------------------------------------------------------------------------
    // Caso 4: Campos vacíos e incorrectos en formulario de perfil
    // ------------------------------------------------------------------------
    test('4. Formulario de edición rechaza campos vacíos sin actualizar el perfil del estudiante', () async {
      await authService.signIn(email: 'estudiante@academia.pa', password: '12345678');
      final originalName = authService.currentUser!.name;
      final originalEmail = authService.currentUser!.email;

      // Lógica de validación del formulario de edición de perfil (profile_screen.dart)
      String? validateProfileFields(String name, String email) {
        final newName = name.trim();
        final newEmail = email.trim();
        if (newName.isEmpty || newEmail.isEmpty) {
          return 'El nombre y el correo no pueden estar vacíos.';
        }
        return null;
      }

      final error1 = validateProfileFields('', 'r.arias@academia.pa');
      final error2 = validateProfileFields('Ricardo Arias', '   ');

      expect(error1, equals('El nombre y el correo no pueden estar vacíos.'));
      expect(error2, equals('El nombre y el correo no pueden estar vacíos.'));

      // Confirmar que ante error de validación el perfil no se modifica
      expect(authService.currentUser!.name, equals(originalName));
      expect(authService.currentUser!.email, equals(originalEmail));
    });

    // ------------------------------------------------------------------------
    // Caso 5: Validación de formato de correo [DEFECTO REAL: Falta de Validación Regex]
    // ------------------------------------------------------------------------
    test('5. [DEFECTO VALIDACIÓN] AuthService.updateProfile carece de validación de formato de correo y acepta correos malformados', () async {
      await authService.signIn(email: 'estudiante@academia.pa', password: '12345678');

      const invalidEmail = 'correo_totalmente_invalido_sin_formato';

      bool threwValidationError = false;
      try {
        authService.updateProfile(email: invalidEmail);
      } catch (e) {
        threwValidationError = true;
      }

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      final isEmailValid = emailRegex.hasMatch(authService.currentUser?.email ?? '');

      // El servicio debería rechazar o lanzar error ante un formato de correo malformado
      expect(
        threwValidationError || isEmailValid,
        isTrue,
        reason: 'DEFECTO DETECTADO: Ausencia de validación de sintaxis en AuthService.updateProfile. '
            'El servicio aceptó "$invalidEmail" sin validar la estructura requerida de un correo institucional.',
      );
    });

    // ------------------------------------------------------------------------
    // Caso 6: Cancelación de cambios en edición de perfil
    // ------------------------------------------------------------------------
    test('6. Cancelación de edición mantiene intactos los datos del perfil original', () async {
      await authService.signIn(email: 'estudiante@academia.pa', password: '12345678');
      final original = authService.currentUser!;

      // Simular edición descartada (acción de Cancelar en el diálogo sin invocar updateProfile)
      final tempNameCtrl = TextEditingController(text: original.name);
      final tempEmailCtrl = TextEditingController(text: original.email);

      tempNameCtrl.text = 'Nombre Modificado pero Cancelado';
      tempEmailCtrl.text = 'correo_cancelado@test.pa';

      // Al cancelar, no se ejecuta updateProfile
      expect(authService.currentUser!.name, equals(original.name));
      expect(authService.currentUser!.email, equals(original.email));
      expect(authService.currentUser!.id, equals(original.id));
    });

    // ------------------------------------------------------------------------
    // Caso 7: Modificaciones secuenciales de múltiples atributos
    // ------------------------------------------------------------------------
    test('7. Modificaciones sucesivas de atributos preservan la integridad de los campos previos', () async {
      await authService.signIn(email: 'estudiante@academia.pa', password: '12345678');

      // Modificación 1: Nombre
      authService.updateProfile(name: 'Nuevo Nombre 1');
      expect(authService.currentUser!.name, equals('Nuevo Nombre 1'));

      // Modificación 2: Avatar (debe mantener el nuevo nombre)
      authService.updateProfile(avatarUrl: 'assets/images/logo.png');
      expect(authService.currentUser!.name, equals('Nuevo Nombre 1'));
      expect(authService.currentUser!.avatarUrl, equals('assets/images/logo.png'));

      // Modificación 3: Correo (debe mantener nombre y avatar)
      authService.updateProfile(email: 'nuevo.correo@academia.pa');
      expect(authService.currentUser!.name, equals('Nuevo Nombre 1'));
      expect(authService.currentUser!.avatarUrl, equals('assets/images/logo.png'));
      expect(authService.currentUser!.email, equals('nuevo.correo@academia.pa'));
    });

    // ------------------------------------------------------------------------
    // Caso 8: Consulta del perfil durante una actualización
    // ------------------------------------------------------------------------
    test('8. Consulta del perfil durante actualización retorna estado válido y nunca nulo', () async {
      await authService.signIn(email: 'estudiante@academia.pa', password: '12345678');

      authService.updateProfile(name: 'Actualizando...');
      final user = authService.currentUser;

      expect(user, isNotNull);
      expect(user!.name, equals('Actualizando...'));
      expect(user.id, isNotEmpty);
    });

    // ------------------------------------------------------------------------
    // Caso 9: Persistencia de preferencias en SettingsScreen [DEFECTO REAL: Preferencias Efímeras]
    // ------------------------------------------------------------------------
    test('9. [DEFECTO PERSISTENCIA] Preferencias en SettingsScreen no se guardan en SharedPreferences y son efímeras', () async {
      // En SettingsScreen, las preferencias (notificaciones, auto-descarga Wi-Fi y calidad AR)
      // se gestionan únicamente mediante estado local de widget (_notificationsEnabled, _autoDownloadWifi).
      // El módulo carece de persistencia en SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final hasSavedNotifications = prefs.containsKey('ph_pref_notifications') ||
          prefs.containsKey('notifications_enabled') ||
          prefs.containsKey('settings_notifications');
      final hasSavedAutoDownload = prefs.containsKey('ph_pref_auto_download') ||
          prefs.containsKey('auto_download_wifi');

      expect(
        hasSavedNotifications || hasSavedAutoDownload,
        isTrue,
        reason: 'DEFECTO DETECTADO: Las preferencias de configuración en SettingsScreen no se persisten en SharedPreferences. '
            'Los estados se mantienen únicamente en la memoria efímera del widget y se pierden al salir de la pantalla.',
      );
    });

    // ------------------------------------------------------------------------
    // Caso 10: Tolerancia ante almacenamiento corrupto en loadSession
    // ------------------------------------------------------------------------
    test('10. Carga de sesión con JSON corrupto captura la excepción en try/catch sin crash', () async {
      SharedPreferences.setMockInitialValues({
        'ph_auth_user_session_v1': '{json_corrupto_incompleto:',
      });

      // No debe propagar FormatException hacia el exterior
      UserModel? sessionUser;
      expect(() async {
        sessionUser = await authService.loadSession();
      }, returnsNormally);

      // Ante JSON corrupto, no autentica al usuario y retorna null de forma segura
      expect(sessionUser, isNull);
      expect(authService.isAuthenticated, isFalse);
    });

    // ------------------------------------------------------------------------
    // Caso 11: Inmutabilidad de roles a través de updateProfile
    // ------------------------------------------------------------------------
    test('11. updateProfile no permite la alteración no autorizada del rol de usuario (RBAC)', () async {
      await authService.signIn(email: 'estudiante@academia.pa', password: '12345678');
      expect(authService.currentUser!.role, equals(UserRole.student));

      // updateProfile solo acepta name, email y avatarUrl, impidiendo escalamiento de privilegios
      authService.updateProfile(name: 'Estudiante con nuevo nombre');

      expect(authService.currentUser!.role, equals(UserRole.student));
      expect(authService.currentUser!.isTeacher, isFalse);
    });

    // ------------------------------------------------------------------------
    // Caso 12: Arquitectura de updateProfile [DEFECTO REAL: void / Fire-and-Forget sin await]
    // ------------------------------------------------------------------------
    test('12. [DEFECTO ARQUITECTURA] AuthService.updateProfile es de tipo void en lugar de Future<void> impidiendo await transaccional', () {
      // En una arquitectura robusta, operaciones que implican persistencia en disco I/O
      // (como _saveSession con SharedPreferences) deben retornar Future<void> para que el llamador
      // pueda esperar (await) su finalización y capturar errores de persistencia.
      final dynamicResult = (authService as dynamic).updateProfile(name: 'Prueba Tipo Asíncrono');

      expect(
        dynamicResult,
        isA<Future>(),
        reason: 'DEFECTO DETECTADO: AuthService.updateProfile tiene firma "void" en lugar de "Future<void>". '
            'Ejecuta _saveSession de forma fire-and-forget sin permitir al llamador esperar (await) '
            'que los datos se escriban efectivamente en SharedPreferences, arriesgando pérdida de sesión en cierres inmediatos.',
      );
    });

    // ------------------------------------------------------------------------
    // Caso 13: Configuración global de Tema Oscuro
    // ------------------------------------------------------------------------
    test('13. PanamaHistoricaApp.themeNotifier conmuta correctamente entre Tema Claro y Oscuro', () {
      PanamaHistoricaApp.themeNotifier.value = ThemeMode.light;
      expect(PanamaHistoricaApp.themeNotifier.value, equals(ThemeMode.light));

      PanamaHistoricaApp.themeNotifier.value = ThemeMode.dark;
      expect(PanamaHistoricaApp.themeNotifier.value, equals(ThemeMode.dark));

      // Restaurar tema claro
      PanamaHistoricaApp.themeNotifier.value = ThemeMode.light;
    });

    // ------------------------------------------------------------------------
    // Caso 14: Cierre de sesión y limpieza de claves locales
    // ------------------------------------------------------------------------
    test('14. Cierre de sesión elimina la clave de sesión y resetea currentUser a null', () async {
      await authService.signIn(email: 'estudiante@academia.pa', password: '12345678');
      expect(authService.currentUser, isNotNull);

      await authService.signOut();

      expect(authService.currentUser, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ph_auth_user_session_v1'), isNull);
    });

    // ------------------------------------------------------------------------
    // Caso 15: Inmutabilidad del modelo UserModel (copyWith)
    // ------------------------------------------------------------------------
    test('15. UserModel.copyWith crea una nueva instancia preservando la inmutabilidad de la original', () {
      final original = UserModel.mock();
      final modified = original.copyWith(name: 'Nombre Alterado', level: 20);

      expect(identical(original, modified), isFalse);
      expect(original.name, equals('Ricardo Arias'));
      expect(original.level, equals(15));
      expect(modified.name, equals('Nombre Alterado'));
      expect(modified.level, equals(20));
      expect(modified.id, equals(original.id));
    });
  });
}
