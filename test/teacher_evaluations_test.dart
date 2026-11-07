import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panama_historica/models/academic_evaluation_model.dart';
import 'package:panama_historica/screens/teacher/evaluation_register_screen.dart';
import 'package:panama_historica/screens/teacher/teacher_evaluations_screen.dart';
import 'package:panama_historica/screens/teacher/teacher_students_screen.dart';
import 'package:panama_historica/services/evaluation_storage_service.dart';
import 'package:panama_historica/services/report_export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    EvaluationStorageService().resetForTesting();
  });

  group('1. Modelo de Calificación Académica (AcademicEvaluationModel)', () {
    test('Serialización y deserialización JSON completa de una evaluación', () {
      final now = DateTime(2024, 11, 4, 10, 30);
      final eval = AcademicEvaluationModel(
        id: 'eval_test_01',
        studentId: 'usr_001',
        studentName: 'Ricardo Arias',
        studentGrade: '11° Grado',
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: '9 de enero de 1964',
        activityTitle: 'Comprobación de Lectura',
        score: 95.5,
        observations: 'Excelente análisis historiográfico.',
        createdAt: now,
      );

      final json = eval.toJson();
      expect(json['id'], equals('eval_test_01'));
      expect(json['score'], equals(95.5));
      expect(json['studentName'], equals('Ricardo Arias'));

      final restored = AcademicEvaluationModel.fromJson(json);
      expect(restored.id, equals(eval.id));
      expect(restored.score, equals(95.5));
      expect(restored.isApproved, isTrue);
      expect(restored.performanceLevel, equals('Sobresaliente'));
      expect(restored.formattedDate, equals('04/11/2024'));
    });

    test('Clasificación exacta de niveles de desempeño según escala MEDUCA', () {
      AcademicEvaluationModel makeEval(double score) => AcademicEvaluationModel(
            id: 'test',
            studentId: 'usr_001',
            studentName: 'Test',
            studentGrade: '11° Grado',
            teacherId: 'doc_001',
            teacherName: 'Prof.',
            moduleId: 'mod_1',
            moduleTitle: 'Mod 1',
            sectionTitle: 'Sec 1',
            activityTitle: 'Act 1',
            score: score,
            observations: '',
            createdAt: DateTime.now(),
          );

      expect(makeEval(100.0).performanceLevel, equals('Sobresaliente'));
      expect(makeEval(90.0).performanceLevel, equals('Sobresaliente'));
      expect(makeEval(89.9).performanceLevel, equals('Bueno'));
      expect(makeEval(80.0).performanceLevel, equals('Bueno'));
      expect(makeEval(79.9).performanceLevel, equals('Regular'));
      expect(makeEval(71.0).performanceLevel, equals('Regular'));
      expect(makeEval(70.9).performanceLevel, equals('Requiere Refuerzo'));
      expect(makeEval(45.0).performanceLevel, equals('Requiere Refuerzo'));

      expect(makeEval(71.0).isApproved, isTrue);
      expect(makeEval(70.9).isApproved, isFalse);
    });
  });

  group('2. Servicio de Persistencia y Validaciones (EvaluationStorageService)', () {
    test('Carga de evaluaciones base (seed) y persistencia en SharedPreferences', () async {
      final service = EvaluationStorageService();
      await service.initialize();

      final evals = await service.getAllEvaluations();
      expect(evals.isNotEmpty, isTrue);
      expect(evals.length, greaterThanOrEqualTo(5));

      final ricardoEvals = await service.getEvaluationsForStudent('usr_001');
      expect(ricardoEvals.isNotEmpty, isTrue);
    });

    test('Validación estricta de rango: rechaza notas < 0 o > 100', () async {
      final service = EvaluationStorageService();
      await service.initialize();

      expect(
        () async => await service.saveEvaluation(
          studentId: 'usr_001',
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero',
          activityTitle: 'Test',
          score: -5.0,
          observations: '',
        ),
        throwsA(predicate((e) => e.toString().contains('comprendida estrictamente entre 0 y 100'))),
      );

      expect(
        () async => await service.saveEvaluation(
          studentId: 'usr_001',
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero',
          activityTitle: 'Test',
          score: 105.0,
          observations: '',
        ),
        throwsA(predicate((e) => e.toString().contains('comprendida estrictamente entre 0 y 100'))),
      );
    });

    test('Validación estricta de campos obligatorios: estudiante y módulo', () async {
      final service = EvaluationStorageService();
      await service.initialize();

      expect(
        () async => await service.saveEvaluation(
          studentId: '',
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero',
          activityTitle: 'Test',
          score: 85.0,
          observations: '',
        ),
        throwsA(predicate((e) => e.toString().contains('Debe seleccionar un estudiante'))),
      );

      expect(
        () async => await service.saveEvaluation(
          studentId: 'usr_001',
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
          moduleId: '   ',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero',
          activityTitle: 'Test',
          score: 85.0,
          observations: '',
        ),
        throwsA(predicate((e) => e.toString().contains('Debe seleccionar el módulo histórico'))),
      );
    });

    test('Registro exitoso y actualización de evaluación existente', () async {
      final service = EvaluationStorageService();
      await service.initialize();

      final eval1 = await service.saveEvaluation(
        studentId: 'usr_002',
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Tratados Torrijos-Carter',
        activityTitle: 'Ensayo Soberanía 1977',
        score: 88.0,
        observations: 'Buen avance inicial.',
      );

      expect(eval1.score, equals(88.0));
      expect(eval1.studentName, equals('Valeria Castillo'));

      // Modificar la misma evaluación (mismo estudiante, módulo, sección y actividad)
      final updated = await service.saveEvaluation(
        studentId: 'usr_002',
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Tratados Torrijos-Carter',
        activityTitle: 'Ensayo Soberanía 1977',
        score: 96.0,
        observations: 'Excelente revisión final con fuentes de apoyo.',
      );

      expect(updated.score, equals(96.0));
      expect(updated.observations, contains('Excelente revisión final'));

      // Comprobar que no se duplicó
      final studentEvals = await service.getEvaluationsForStudent('usr_002');
      final matching = studentEvals.where((e) => e.activityTitle == 'Ensayo Soberanía 1977');
      expect(matching.length, equals(1));
    });

    test('Eliminación de una evaluación del registro', () async {
      final service = EvaluationStorageService();
      await service.initialize();

      final created = await service.saveEvaluation(
        studentId: 'usr_003',
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'General',
        activityTitle: 'Actividad a eliminar',
        score: 75.0,
        observations: '',
      );

      await service.deleteEvaluation(created.id);
      final list = await service.getAllEvaluations();
      expect(list.any((e) => e.id == created.id), isFalse);
    });
  });

  group('3. Cálculos Analíticos Reales (Sin Datos Falsos ni Simulados)', () {
    test('Cálculo dinámico de promedio general, conteo y tasa de aprobación', () async {
      final service = EvaluationStorageService();
      await service.initialize();
      final evals = await service.getAllEvaluations();

      final average = service.calculateAverage(evals);
      expect(average, greaterThanOrEqualTo(0.0));
      expect(average, lessThanOrEqualTo(100.0));

      final countUnique = service.countEvaluatedStudents(evals);
      expect(countUnique, greaterThan(0));
      expect(countUnique, lessThanOrEqualTo(5));

      final lowPerformers = service.getLowPerformance(evals);
      for (final e in lowPerformers) {
        expect(e.score, lessThan(71.0));
      }

      final topPerformers = service.getTopPerformance(evals);
      for (final e in topPerformers) {
        expect(e.score, greaterThanOrEqualTo(90.0));
      }

      final distribution = service.getDistribution(evals);
      final totalInDist = distribution.values.fold<int>(0, (sum, val) => sum + val);
      expect(totalInDist, equals(evals.length));

      final moduleAvg = service.getAveragePerModule(evals);
      expect(moduleAvg.containsKey('Panamá Contemporánea'), isTrue);
      expect(moduleAvg['Panamá Contemporánea']!, greaterThan(0.0));
    });

    test('Aplicación de filtros por estudiante, módulo y rango de fechas', () async {
      final service = EvaluationStorageService();
      await service.initialize();

      final filteredStudent = service.applyFilters(studentId: 'usr_001');
      for (final e in filteredStudent) {
        expect(e.studentId, equals('usr_001'));
      }

      final filteredModule = service.applyFilters(moduleId: 'Panamá Contemporánea');
      for (final e in filteredModule) {
        expect(e.moduleTitle, equals('Panamá Contemporánea'));
      }

      final filteredDate = service.applyFilters(
        startDate: DateTime(2024, 11, 1),
        endDate: DateTime(2024, 11, 30),
      );
      for (final e in filteredDate) {
        expect(e.createdAt.month, equals(11));
        expect(e.createdAt.year, equals(2024));
      }
    });
  });

  group('4. Exportación Oficial a PDF y Excel (ReportExportService)', () {
    test('Generación de informe oficial en PDF no vacío con estructura institucional', () async {
      final exportService = ReportExportService();
      final storageService = EvaluationStorageService();
      await storageService.initialize();

      final evals = await storageService.getAllEvaluations();
      final avg = storageService.calculateAverage(evals);
      final count = storageService.countEvaluatedStudents(evals);

      final File pdfFile = await exportService.generatePdfReport(
        reportTitle: 'Informe Oficial de Rendimiento',
        teacherName: 'Prof. Alejandro Méndez',
        institution: 'Instituto Nacional de Panamá',
        evaluations: evals,
        averageScore: avg,
        evaluatedStudentsCount: count,
      );

      expect(pdfFile.existsSync(), isTrue);
      final bytes = await pdfFile.readAsBytes();
      expect(bytes.length, greaterThan(500));

      // Comprobar cabecera de archivo PDF
      final header = String.fromCharCodes(bytes.take(4));
      expect(header, equals('%PDF'));
    });

    test('Generación de hoja de cálculo Excel (CSV estructurado con UTF-8 BOM)', () async {
      final exportService = ReportExportService();
      final storageService = EvaluationStorageService();
      await storageService.initialize();

      final evals = await storageService.getAllEvaluations();
      final avg = storageService.calculateAverage(evals);
      final count = storageService.countEvaluatedStudents(evals);

      final File csvFile = await exportService.generateExcelReport(
        reportTitle: 'Planilla de Calificaciones',
        teacherName: 'Prof. Alejandro Méndez',
        institution: 'Instituto Nacional de Panamá',
        evaluations: evals,
        averageScore: avg,
        evaluatedStudentsCount: count,
      );

      expect(csvFile.existsSync(), isTrue);
      final bytes = await csvFile.readAsBytes();

      // Comprobar presencia de UTF-8 BOM (0xEF, 0xBB, 0xBF) para apertura nativa en Microsoft Excel
      expect(bytes.take(3).toList(), equals([0xEF, 0xBB, 0xBF]));

      final content = await csvFile.readAsString();
      expect(content, contains('REPÚBLICA DE PANAMÁ - MINISTERIO DE EDUCACIÓN'));
      expect(content, contains('Promedio General (0-100)'));
      expect(content, contains('Ricardo Arias'));
      expect(content, contains('Panamá Contemporánea'));
    });
  });

  group('5. Pantallas e Integración de Interfaz de Usuario', () {
    testWidgets('EvaluationRegisterScreen: Valida campos y rechaza notas mayores a 100', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EvaluationRegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar elementos principales
      expect(find.text('Registrar Calificación'), findsOneWidget);
      expect(find.text('1. Estudiante a Evaluar *'), findsOneWidget);
      expect(find.text('2. Módulo Histórico y Contenido *'), findsOneWidget);

      // Encontrar campo de calificación numérica (0-100 pts)
      final scoreField = find.widgetWithText(TextFormField, 'Ej. 95.0');
      expect(scoreField, findsOneWidget);

      // Introducir nota inválida (150 pts)
      await tester.enterText(scoreField, '150');
      await tester.pumpAndSettle();

      expect(find.text('La calificación no puede ser mayor a 100.'), findsOneWidget);

      // Introducir letras inválidas
      await tester.enterText(scoreField, 'abc');
      await tester.pumpAndSettle();

      expect(find.text('Introduzca únicamente números válidos (0 a 100).'), findsOneWidget);

      // Introducir nota válida (92.5)
      await tester.enterText(scoreField, '92.5');
      await tester.pumpAndSettle();

      expect(find.text('Introduzca únicamente números válidos (0 a 100).'), findsNothing);
    });

    testWidgets('TeacherEvaluationsScreen: Muestra pestañas de Historial y Reportes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TeacherEvaluationsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evaluación y Reportes'), findsOneWidget);
      expect(find.text('Historial y Registros'), findsOneWidget);
      expect(find.text('Reportes y Analíticas'), findsOneWidget);
      expect(find.text('Registrar Calificación'), findsOneWidget);

      // Comprobar que en la lista de historial hay tarjetas de evaluación
      expect(find.text('Ricardo Arias'), findsWidgets);

      // Cambiar a la pestaña de Reportes y Analíticas
      await tester.tap(find.text('Reportes y Analíticas'));
      await tester.pumpAndSettle();

      expect(find.text('Promedio General Calculado'), findsOneWidget);
      expect(find.text('Distribución de Rendimiento Académico'), findsOneWidget);
      expect(find.text('Exportar PDF'), findsOneWidget);
      expect(find.text('Exportar Excel'), findsOneWidget);
    });

    testWidgets('TeacherStudentsScreen: Muestra promedio calculado y abre detalle con acciones integradas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TeacherStudentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gestión de Estudiantes'), findsOneWidget);
      expect(find.text('Ricardo Arias'), findsWidgets);

      // Tocar sobre un estudiante para abrir la ficha de detalles
      await tester.tap(find.text('Ricardo Arias').first);
      await tester.pumpAndSettle();

      expect(find.text('Ficha del Estudiante'), findsOneWidget);
      expect(find.text('Progreso en Módulos Históricos'), findsOneWidget);
      expect(find.text('Ver Historial'), findsOneWidget);
      expect(find.text('Evaluar Estudiante'), findsOneWidget);
    });
  });
}
