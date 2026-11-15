import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panama_historica/models/student_tracking_model.dart';
import 'package:panama_historica/services/student_tracking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StudentTrackingService trackingService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    trackingService = StudentTrackingService();
  });

  group('Checklist de Pruebas Unitarias - Seguimiento de Estudiantes (Panel Docente)', () {
    // 1. Consulta del directorio oficial de estudiantes autorizados
    test('1. Consulta del directorio oficial de estudiantes con datos iniciales completos (getStudents)', () {
      final students = trackingService.getStudents();

      expect(students.length, greaterThanOrEqualTo(5));
      expect(students.any((s) => s.id == 'usr_001' && s.name == 'Ricardo Arias'), isTrue);
      expect(students.any((s) => s.id == 'usr_002' && s.name == 'Valeria Castillo'), isTrue);
      expect(students.any((s) => s.id == 'usr_003' && s.name == 'Diego Montero'), isTrue);
      expect(students.any((s) => s.id == 'usr_004' && s.name == 'Sofía Quintero'), isTrue);
      expect(students.any((s) => s.id == 'usr_005' && s.name == 'Mateo Espino'), isTrue);

      for (final s in students) {
        expect(s.name, isNotEmpty);
        expect(s.email, contains('@'));
        expect(s.grade, isNotEmpty);
        expect(s.section, isNotEmpty);
        expect(s.fullGradeSection, contains(' - '));
      }
    });

    // 2. Lógica booleana de atención pedagógica prioritaria (requiresFollowup)
    test('2. Evaluación de condición OR de atención prioritaria requiresFollowup (progreso < 0.50 o Inactivo)', () {
      // Caso 1: Progreso bajo (< 0.50) y estado Activo (Diego Montero: 0.40)
      final diego = trackingService.getStudentById('usr_003')!;
      expect(diego.progress, lessThan(0.50));
      expect(diego.status, equals('Activo'));
      expect(diego.requiresFollowup, isTrue);

      // Caso 2: Estado Inactivo con progreso bajo (Mateo Espino: 0.25, Inactivo)
      final mateo = trackingService.getStudentById('usr_005')!;
      expect(mateo.status, equals('Inactivo'));
      expect(mateo.requiresFollowup, isTrue);

      // Caso 3: Progreso alto (>= 0.50) y estado Activo (Ricardo Arias: 0.75, Activo)
      final ricardo = trackingService.getStudentById('usr_001')!;
      expect(ricardo.progress, greaterThanOrEqualTo(0.50));
      expect(ricardo.status, equals('Activo'));
      expect(ricardo.requiresFollowup, isFalse);
    });

    // 3. Filtrado de búsqueda de estudiantes por nombre y correo
    test('3. Filtrado por búsqueda de texto con resultados válidos por nombre y correo insensible a mayúsculas', () {
      final allStudents = trackingService.getStudents();

      // Búsqueda por nombre 'ricardo'
      final searchByName = allStudents.where((s) {
        return s.name.toLowerCase().contains('ricardo'.toLowerCase()) ||
            s.email.toLowerCase().contains('ricardo'.toLowerCase());
      }).toList();
      expect(searchByName.length, equals(1));
      expect(searchByName.first.name, equals('Ricardo Arias'));

      // Búsqueda por correo parcial 'v.castillo'
      final searchByEmail = allStudents.where((s) {
        return s.name.toLowerCase().contains('v.castillo'.toLowerCase()) ||
            s.email.toLowerCase().contains('v.castillo'.toLowerCase());
      }).toList();
      expect(searchByEmail.length, equals(1));
      expect(searchByEmail.first.name, equals('Valeria Castillo'));
    });

    // 4. Filtrado de búsqueda sin coincidencias en el padrón
    test('4. Filtrado por búsqueda de texto sin coincidencias existentes en el padrón', () {
      final allStudents = trackingService.getStudents();
      const query = 'estudiante_fantasma_inexistente_xyz';

      final results = allStudents.where((s) {
        return s.name.toLowerCase().contains(query.toLowerCase()) ||
            s.email.toLowerCase().contains(query.toLowerCase());
      }).toList();

      expect(results.isEmpty, isTrue);
    });

    // 5. Combinación lógica de filtros (Búsqueda + Grado + Estado)
    test('5. Evaluación de combinación lógica AND entre filtro de texto, grado y estado', () {
      final allStudents = trackingService.getStudents();
      const searchQuery = 'a'; // coincide con Arias, Castillo, etc.
      const gradeFilter = '11° Grado';
      const statusFilter = 'Activos';

      final filtered = allStudents.where((s) {
        final matchesSearch = s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            s.email.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesGrade = gradeFilter == 'Todos' || s.grade == gradeFilter;
        final matchesStatus = statusFilter == 'Activos' ? s.status == 'Activo' : true;

        return matchesSearch && matchesGrade && matchesStatus;
      }).toList();

      expect(filtered.isNotEmpty, isTrue);
      for (final s in filtered) {
        expect(s.grade, equals('11° Grado'));
        expect(s.status, equals('Activo'));
      }
      expect(filtered.any((s) => s.name == 'Ricardo Arias'), isTrue);
      expect(filtered.any((s) => s.name == 'Valeria Castillo'), isTrue);
      // Mateo Espino está en 11° Grado pero es Inactivo, no debe figurar
      expect(filtered.any((s) => s.name == 'Mateo Espino'), isFalse);
    });

    // 6. Deserialización y tolerancia a datos incompletos
    test('6. Tolerancia ante datos incompletos y sustitución por valores por defecto seguros (StudentTrackingModel.fromJson)', () {
      final incompleteJson = <String, dynamic>{
        'id': 'usr_incompleto_01',
      };

      final restored = StudentTrackingModel.fromJson(incompleteJson);

      expect(restored.id, equals('usr_incompleto_01'));
      expect(restored.name, isEmpty);
      expect(restored.email, isEmpty);
      expect(restored.grade, equals('11° Grado'));
      expect(restored.section, equals('Sección A'));
      expect(restored.progress, equals(0.0));
      expect(restored.studyHours, equals('0.0h'));
      expect(restored.status, equals('Activo'));
      expect(restored.completedModules, isEmpty);
      expect(restored.pendingModules, isEmpty);
      expect(restored.moduleProgress, isEmpty);
    });

    // 7. Consulta de estudiante inexistente o no asignado
    test('7. Consulta de un perfil de estudiante inexistente o no asignado al docente (getStudentById)', () {
      final notFound = trackingService.getStudentById('usr_no_asignado_999');
      expect(notFound, isNull);
    });

    // 8. Cálculo de promedio grupal y límites de progreso
    test('8. Cálculo de promedio grupal y validación de valores límite del progreso (calculateAverageProgress)', () {
      final average = trackingService.calculateAverageProgress();

      expect(average, greaterThan(0.0));
      expect(average, lessThanOrEqualTo(100.0));

      // Verificación matemática del cálculo
      final students = trackingService.getStudents();
      final expectedSum = students.fold<double>(0.0, (acc, s) => acc + s.progress);
      final expectedAvg = double.parse(((expectedSum / students.length) * 100).toStringAsFixed(1));
      expect(average, equals(expectedAvg));
    });

    // 9. Coherencia curricular entre módulos completados y mapa porcentual
    test('9. Coherencia curricular: Los módulos completados deben registrar progreso 1.0 en moduleProgress', () {
      final valeria = trackingService.getStudentById('usr_002')!;

      expect(valeria.completedModules, contains('Época Prehispánica'));
      expect(valeria.completedModules, contains('Época Colonial'));
      expect(valeria.completedModules, contains('Época Departamental'));

      // Comprobar que en moduleProgress figure 1.0 (100%)
      for (final mod in valeria.completedModules) {
        expect(valeria.moduleProgress[mod], equals(1.0));
      }

      // Módulo pendiente debe tener avance < 1.0
      expect(valeria.pendingModules, contains('Época Republicana'));
      expect(valeria.moduleProgress['Época Republicana'], equals(0.60));
    });

    // 10. [DEFECTO ST-02] Validación de datos obligatorios en adición de estudiantes
    test('10. Validación de obligatoriedad: Rechazo de estudiantes con nombre o correo vacíos (addStudent)', () {
      // Debe lanzar excepción impidiendo agregar estudiantes con datos corruptos/vacíos
      expect(
        () => trackingService.addStudent(
          const StudentTrackingModel(
            id: 'usr_corrupto_sin_nombre',
            name: '',
            email: '',
            grade: '10° Grado',
            progress: 0.1,
            studyHours: '0h',
            lastActive: 'Nunca',
            status: 'Activo',
            activeModule: 'Ninguno',
            documentsRead: 0,
          ),
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('El nombre y correo del estudiante son obligatorios'),
        )),
      );
    });

    // 11. [DEFECTO ST-03] Ordenamiento cronológico de la bitácora grupal
    test('11. Ordenamiento cronológico: Las actividades más recientes deben encabezar la bitácora grupal (getRecentGroupActivities)', () {
      final activities = trackingService.getRecentGroupActivities();

      expect(activities.isNotEmpty, isTrue);

      // Sofía Quintero registró actividad 'Hace 2 horas', mientras que Ricardo registró 'Hoy, 10:30 AM'
      // Una bitácora de actividad reciente debe ordenar por tiempo en lugar de agrupar por inserción de alumno
      final firstActivity = activities.first;
      expect(
        firstActivity['studentName'],
        equals('Sofía Quintero'),
        reason: 'La bitácora debe estar ordenada cronológicamente con la actividad más reciente primero',
      );
    });

    // 12. Prevención de duplicidad de estudiantes por ID
    test('12. Prevención de duplicidad: addStudent no debe insertar estudiantes con ID ya existente', () {
      final countBefore = trackingService.getStudents().length;

      // Intentar agregar con ID existente 'usr_001'
      trackingService.addStudent(
        const StudentTrackingModel(
          id: 'usr_001',
          name: 'Ricardo Arias Clonado',
          email: 'clon@test.pa',
          grade: '11° Grado',
          progress: 0.5,
          studyHours: '10h',
          lastActive: 'Hoy',
          status: 'Activo',
          activeModule: 'Panamá Contemporánea',
          documentsRead: 2,
        ),
      );

      final countAfter = trackingService.getStudents().length;
      expect(countAfter, equals(countBefore));
    });

    // 13. Inmutabilidad en actualización de progreso con copyWith
    test('13. Inmutabilidad: Actualización atómica de progreso conservando ID y demás atributos (copyWith)', () {
      final original = trackingService.getStudentById('usr_001')!;

      final updated = original.copyWith(progress: 0.88, studyHours: '45.0h');

      expect(updated.id, equals(original.id));
      expect(updated.name, equals(original.name));
      expect(updated.progress, equals(0.88));
      expect(updated.studyHours, equals('45.0h'));
      expect(original.progress, equals(0.75)); // inalterado
    });

    // 14. [DEFECTO ST-01] Capacidad de reinicio y consulta de directorio vacío en Singleton
    test('14. Gestión de ciclo de vida: El servicio debe proveer método de reinicio/vaciado para evaluar directorio vacío', () {
      // Un servicio de producción debe exponer un método de restablecimiento de pruebas (clear/reset)
      // Comprobamos si la instancia permite reiniciar para verificar el cálculo de promedio en 0.0
      expect(
        () => (trackingService as dynamic).resetForTesting(),
        returnsNormally,
        reason: 'StudentTrackingService debe contar con resetForTesting() para permitir aislamiento entre pruebas',
      );
    });

    // 15. Concurrencia y dos consultas simultáneas al directorio
    test('15. Concurrencia: Manejo de dos consultas simultáneas al directorio mediante Future.wait', () async {
      final results = await Future.wait([
        Future.value(trackingService.getStudents()),
        Future.value(trackingService.calculateAverageProgress()),
      ]);

      expect(results.length, equals(2));
      expect((results[0] as List).length, greaterThanOrEqualTo(5));
      expect((results[1] as double), greaterThan(0.0));
    });
  });
}

