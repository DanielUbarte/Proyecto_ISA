import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panama_historica/models/student_tracking_model.dart';
import 'package:panama_historica/screens/teacher/student_detail_screen.dart';
import 'package:panama_historica/screens/teacher/teacher_students_screen.dart';
import 'package:panama_historica/services/evaluation_storage_service.dart';
import 'package:panama_historica/services/student_tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    EvaluationStorageService().resetForTesting();
  });

  group('1. Modelo de Seguimiento Estudiantil (StudentTrackingModel)', () {
    test('Serialización y deserialización JSON completa de un estudiante', () {
      const student = StudentTrackingModel(
        id: 'usr_test_01',
        name: 'Carlos Mendoza',
        email: 'c.mendoza@academia.edu.pa',
        grade: '11° Grado',
        section: 'Sección B',
        progress: 0.85,
        studyHours: '38.0h',
        lastActive: 'Hoy, 11:00 AM',
        status: 'Activo',
        activeModule: 'Panamá Contemporánea',
        documentsRead: 3,
        completedModules: ['Época Colonial'],
        pendingModules: ['Época Republicana'],
        pendingSections: ['El 9 de enero de 1964'],
        recentActivities: ['Lectura de tratado'],
        consultedDocuments: ['Documento PDF'],
        historianInquiries: ['¿Qué ocurrió en 1964?'],
      );

      final json = student.toJson();
      expect(json['id'], equals('usr_test_01'));
      expect(json['section'], equals('Sección B'));
      expect(json['progress'], equals(0.85));

      final restored = StudentTrackingModel.fromJson(json);
      expect(restored.id, equals(student.id));
      expect(restored.name, equals('Carlos Mendoza'));
      expect(restored.fullGradeSection, equals('11° Grado - Sección B'));
      expect(restored.requiresFollowup, isFalse);
    });

    test('Lógica del indicador requiresFollowup (progreso < 50% o estado Inactivo)', () {
      const studentLowProgress = StudentTrackingModel(
        id: 's1',
        name: 'Alumno 1',
        email: 'a1@test.pa',
        grade: '10° Grado',
        progress: 0.35,
        studyHours: '10h',
        lastActive: 'Ayer',
        status: 'Activo',
        activeModule: 'Panamá Contemporánea',
        documentsRead: 1,
      );
      expect(studentLowProgress.requiresFollowup, isTrue);

      const studentInactive = StudentTrackingModel(
        id: 's2',
        name: 'Alumno 2',
        email: 'a2@test.pa',
        grade: '11° Grado',
        progress: 0.80,
        studyHours: '40h',
        lastActive: 'Hace 5 días',
        status: 'Inactivo',
        activeModule: 'Panamá Contemporánea',
        documentsRead: 4,
      );
      expect(studentInactive.requiresFollowup, isTrue);

      const studentNormal = StudentTrackingModel(
        id: 's3',
        name: 'Alumno 3',
        email: 'a3@test.pa',
        grade: '11° Grado',
        progress: 0.75,
        studyHours: '45h',
        lastActive: 'Hoy',
        status: 'Activo',
        activeModule: 'Panamá Contemporánea',
        documentsRead: 4,
      );
      expect(studentNormal.requiresFollowup, isFalse);
    });
  });

  group('2. Servicio de Seguimiento Estudiantil (StudentTrackingService)', () {
    test('Consulta del directorio oficial de estudiantes autorizados', () {
      final service = StudentTrackingService();
      final students = service.getStudents();

      expect(students.length, greaterThanOrEqualTo(5));
      expect(students.any((s) => s.name == 'Ricardo Arias'), isTrue);
      expect(students.any((s) => s.name == 'Valeria Castillo'), isTrue);
      expect(students.any((s) => s.name == 'Diego Montero'), isTrue);
      expect(students.any((s) => s.name == 'Sofía Quintero'), isTrue);
      expect(students.any((s) => s.name == 'Mateo Espino'), isTrue);
    });

    test('Búsqueda por ID devuelve el estudiante correcto o null si no existe', () {
      final service = StudentTrackingService();
      final found = service.getStudentById('usr_001');
      expect(found, isNotNull);
      expect(found!.name, equals('Ricardo Arias'));

      final notFound = service.getStudentById('inexistente');
      expect(notFound, isNull);
    });

    test('Cálculo real de métricas grupales: promedio, activos y seguimiento', () {
      final service = StudentTrackingService();

      final avgProgress = service.calculateAverageProgress();
      expect(avgProgress, greaterThan(0.0));
      expect(avgProgress, lessThanOrEqualTo(100.0));

      final activeCount = service.getActiveStudentsCount();
      expect(activeCount, greaterThan(0));
      expect(activeCount, lessThanOrEqualTo(service.getStudents().length));

      final followupStudents = service.getStudentsRequiringFollowup();
      expect(followupStudents.isNotEmpty, isTrue);
      for (final s in followupStudents) {
        expect(s.requiresFollowup, isTrue);
      }
    });

    test('Compilación de actividades recientes del grupo', () {
      final service = StudentTrackingService();
      final activities = service.getRecentGroupActivities();

      expect(activities.isNotEmpty, isTrue);
      for (final a in activities) {
        expect(a.containsKey('studentName'), isTrue);
        expect(a.containsKey('activity'), isTrue);
      }
    });
  });

  group('3. Interfaz de Usuario y Navegación Docente', () {
    testWidgets('TeacherStudentsScreen: Muestra métricas de grupo, listado y filtros', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TeacherStudentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Métricas superiores reales
      expect(find.text('Gestión de Estudiantes'), findsOneWidget);
      expect(find.text('Total Alumnos'), findsOneWidget);
      expect(find.text('Estudiantes Activos'), findsOneWidget);
      expect(find.text('Progreso Promedio'), findsOneWidget);
      expect(find.text('Seguimiento'), findsWidgets);

      // Elementos de la lista
      expect(find.text('Ricardo Arias'), findsWidgets);
      expect(find.text('Valeria Castillo'), findsWidgets);
      expect(find.text('Diego Montero'), findsWidgets);

      // Filtro de grado: Seleccionar 10° Grado
      await tester.tap(find.text('10° Grado'));
      await tester.pumpAndSettle();

      expect(find.text('Diego Montero'), findsWidgets);
      expect(find.text('Valeria Castillo'), findsNothing);

      // Restablecer
      await tester.tap(find.text('Restablecer'));
      await tester.pumpAndSettle();

      expect(find.text('Valeria Castillo'), findsWidgets);
    });

    testWidgets('StudentDetailScreen: Muestra módulos, lecturas, IA y evaluaciones', (tester) async {
      final student = StudentTrackingService().getStudentById('usr_001')!;

      await tester.pumpWidget(
        MaterialApp(
          home: StudentDetailScreen(student: student),
        ),
      );
      await tester.pumpAndSettle();

      // Cabecera y datos
      expect(find.text('Ficha del Estudiante'), findsOneWidget);
      expect(find.text('Ricardo Arias'), findsOneWidget);
      expect(find.text('11° Grado - Sección A • r.arias@academia.edu.pa'), findsOneWidget);

      // Secciones de la ficha
      expect(find.text('Progreso en Módulos Históricos'), findsOneWidget);
      expect(find.text('Módulos Históricos Completados:'), findsOneWidget);
      expect(find.text('Secciones Pendientes de Estudio'), findsOneWidget);
      expect(find.text('Documentos y Materiales Consultados'), findsOneWidget);
      expect(find.text('Consultas al Historiador IA'), findsOneWidget);
      expect(find.text('Evaluaciones y Observaciones'), findsOneWidget);

      // Botones de acción
      expect(find.text('Ver Historial'), findsOneWidget);
      expect(find.text('Evaluar Estudiante'), findsOneWidget);
    });
  });
}
