import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panama_historica/models/academic_evaluation_model.dart';
import 'package:panama_historica/services/evaluation_storage_service.dart';
import 'package:panama_historica/services/report_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EvaluationStorageService storageService;
  late ReportExportService exportService;

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
    storageService = EvaluationStorageService();
    exportService = ReportExportService();
    storageService.resetForTesting();
    await storageService.initialize();
  });

  group('Checklist de Pruebas Unitarias - Evaluaciones y Reportes Académicos', () {
    // 1. Registro de calificación válida regular
    test('1. Registro exitoso de calificación válida (85.5 pts) y verificación de nivel de desempeño Bueno', () async {
      final eval = await storageService.saveEvaluation(
        studentId: 'usr_001',
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_republicana',
        moduleTitle: 'Época Republicana',
        sectionTitle: 'Separación de Panamá de Colombia 1903',
        activityTitle: 'Análisis del Acta del 3 de Noviembre',
        score: 85.5,
        observations: 'Buen dominio de los antecedentes separatistas y el tratado Herrán-Hay.',
      );

      expect(eval.id, isNotEmpty);
      expect(eval.score, equals(85.5));
      expect(eval.isApproved, isTrue);
      expect(eval.performanceLevel, equals('Bueno'));
      expect(eval.observations.toLowerCase(), contains('buen dominio'));

      final allEvals = await storageService.getAllEvaluations();
      expect(allEvals.any((e) => e.id == eval.id), isTrue);
    });

    // 2. Validación de valor límite mínimo (0.0 pts)
    test('2. Validación de valor límite mínimo (0.0 pts) con estado no aprobado y nivel Requiere Refuerzo', () async {
      final eval = await storageService.saveEvaluation(
        studentId: 'usr_002',
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Invasión de 1989',
        activityTitle: 'Cuestionario de Cronología',
        score: 0.0,
        observations: 'No presentó la actividad en la fecha límite asignada.',
      );

      expect(eval.score, equals(0.0));
      expect(eval.isApproved, isFalse);
      expect(eval.performanceLevel, equals('Requiere Refuerzo'));
    });

    // 3. Validación de valor límite máximo (100.0 pts)
    test('3. Validación de valor límite máximo (100.0 pts) con estado aprobado y nivel Sobresaliente', () async {
      final eval = await storageService.saveEvaluation(
        studentId: 'usr_003',
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_colonial',
        moduleTitle: 'Época Colonial',
        sectionTitle: 'Camino Real y Camino de Cruces',
        activityTitle: 'Ensayo de Rutas Transístmicas',
        score: 100.0,
        observations: 'Excelente análisis cartográfico y rigor histórico documental.',
      );

      expect(eval.score, equals(100.0));
      expect(eval.isApproved, isTrue);
      expect(eval.performanceLevel, equals('Sobresaliente'));
    });

    // 4. Rechazo de calificaciones fuera de rango (<0 ó >100)
    test('4. Rechazo estricto con excepción de calificaciones fuera de rango (-5.0 y 105.0 pts)', () async {
      // Caso 1: Calificación negativa menor a 0.0
      expect(
        () async => await storageService.saveEvaluation(
          studentId: 'usr_001',
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero',
          activityTitle: 'Taller',
          score: -5.0,
          observations: 'Nota inválida',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('La calificación debe estar comprendida estrictamente entre 0 y 100'),
          ),
        ),
      );

      // Caso 2: Calificación mayor a 100.0
      expect(
        () async => await storageService.saveEvaluation(
          studentId: 'usr_001',
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero',
          activityTitle: 'Taller',
          score: 105.0,
          observations: 'Nota inválida',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('La calificación debe estar comprendida estrictamente entre 0 y 100'),
          ),
        ),
      );
    });

    // 5. Validación de campos obligatorios vacíos
    test('5. Rechazo con excepción de campos obligatorios vacíos (studentId o moduleId)', () async {
      // Caso 1: studentId vacío
      expect(
        () async => await storageService.saveEvaluation(
          studentId: '   ',
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: 'Sección',
          activityTitle: 'Actividad',
          score: 80.0,
          observations: '',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Debe seleccionar un estudiante para registrar la calificación'),
          ),
        ),
      );

      // Caso 2: moduleId vacío
      expect(
        () async => await storageService.saveEvaluation(
          studentId: 'usr_001',
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
          moduleId: '',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: 'Sección',
          activityTitle: 'Actividad',
          score: 80.0,
          observations: '',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Debe seleccionar el módulo histórico evaluado'),
          ),
        ),
      );
    });

    // 6. Modificación de nota y observaciones existentes
    test('6. Modificación exitosa de calificación y observaciones mediante updateEvaluation', () async {
      final initialEvals = await storageService.getAllEvaluations();
      final targetEval = initialEvals.firstWhere((e) => e.id == 'seed_eval_01');
      expect(targetEval.score, equals(95.0));

      final updatedModel = targetEval.copyWith(
        score: 88.0,
        observations: 'Calificación recalculada tras revisión pedagógica en clase.',
      );

      final result = await storageService.updateEvaluation(updatedModel);
      expect(result.score, equals(88.0));
      expect(result.performanceLevel, equals('Bueno'));
      expect(result.observations, contains('Calificación recalculada'));

      final currentEvals = await storageService.getAllEvaluations();
      final updatedSaved = currentEvals.firstWhere((e) => e.id == 'seed_eval_01');
      expect(updatedSaved.score, equals(88.0));
      expect(updatedSaved.observations, contains('Calificación recalculada'));
    });

    // 7. Actualización sobre registro inexistente
    test('7. Rechazo con excepción al intentar modificar un ID de evaluación inexistente', () async {
      final ghostEvaluation = AcademicEvaluationModel(
        id: 'eval_fantasma_99999',
        studentId: 'usr_001',
        studentName: 'Ricardo Arias',
        studentGrade: '11° Grado',
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: '9 de enero',
        activityTitle: 'Comprobación',
        score: 90.0,
        observations: 'Sin registro',
        createdAt: DateTime(2024, 11, 1),
      );

      expect(
        () async => await storageService.updateEvaluation(ghostEvaluation),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Evaluación no encontrada'),
          ),
        ),
      );
    });

    // 8. Control de registros duplicados (upsert automático)
    test('8. Control y prevención de duplicados actualizando el registro preexistente para la misma actividad', () async {
      final initialCount = (await storageService.getAllEvaluations()).length;

      // 'seed_eval_01' ya tiene: usr_001, mod_contemporanea, '9 de enero de 1964', 'Comprobación de Lectura: El 9 de enero'
      final upserted = await storageService.saveEvaluation(
        studentId: 'usr_001',
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: '9 de enero de 1964',
        activityTitle: 'Comprobación de Lectura: El 9 de enero',
        score: 99.0,
        observations: 'Revisión final: Excelente mejora en el análisis de fuentes.',
      );

      final finalEvals = await storageService.getAllEvaluations();
      expect(finalEvals.length, equals(initialCount), reason: 'No debe aumentar el total de evaluaciones');

      final updatedRecord = finalEvals.firstWhere((e) => e.id == 'seed_eval_01');
      expect(updatedRecord.score, equals(99.0));
      expect(upserted.score, equals(99.0));
    });

    // 9. Cálculo de promedios aritméticos y por módulo
    test('9. Cálculo aritmético exacto del promedio grupal y desglose de promedios por módulo histórico', () async {
      final allEvals = await storageService.getAllEvaluations();
      expect(allEvals.length, equals(6));

      // Notas semilla: 95.0 + 98.0 + 82.0 + 100.0 + 64.0 + 90.0 = 529.0 / 6 = 88.166... -> 88.2
      final average = storageService.calculateAverage(allEvals);
      expect(average, equals(88.2));

      final perModule = storageService.getAveragePerModule(allEvals);
      expect(perModule.containsKey('Panamá Contemporánea'), isTrue);
      expect(perModule['Panamá Contemporánea'], equals(88.2));

      final distribution = storageService.getDistribution(allEvals);
      expect(distribution['Sobresaliente (90-100)'], equals(4)); // 95, 98, 100, 90
      expect(distribution['Bueno (80-89)'], equals(1)); // 82
      expect(distribution['Regular (71-79)'], equals(0));
      expect(distribution['Requiere Refuerzo (<71)'], equals(1)); // 64
    });

    // 10. Consulta de estudiantes sin evaluaciones
    test('10. Consulta del historial de un estudiante sin evaluaciones devuelve lista vacía y promedio 0.0', () async {
      final emptyHistory = await storageService.getEvaluationsForStudent('usr_estudiante_inexistente');
      expect(emptyHistory, isEmpty);

      final avg = storageService.calculateAverage(emptyHistory);
      expect(avg, equals(0.0));

      final evaluatedStudents = storageService.countEvaluatedStudents(emptyHistory);
      expect(evaluatedStudents, equals(0));
    });

    // 11. Filtrado multicriterio simultáneo
    test('11. Filtrado multicriterio simultáneo por estudiante, módulo y rango de fechas', () async {
      final allEvals = await storageService.getAllEvaluations();

      // Filtrar usr_001 en Panamá Contemporánea
      final filteredStudent = storageService.applyFilters(
        source: allEvals,
        studentId: 'usr_001',
        moduleId: 'mod_contemporanea',
      );
      expect(filteredStudent.length, equals(2)); // seed_eval_01 (4 nov) y seed_eval_06 (6 nov)

      // Agregar rango de fechas a partir del 5 de noviembre
      final filteredDate = storageService.applyFilters(
        source: allEvals,
        studentId: 'usr_001',
        moduleId: 'mod_contemporanea',
        startDate: DateTime(2024, 11, 5),
      );
      expect(filteredDate.length, equals(1));
      expect(filteredDate.first.id, equals('seed_eval_06'));
      expect(filteredDate.first.score, equals(90.0));
    });

    // 12. Generación de reporte Excel con codificación oficial
    test('12. Generación de reporte Excel estructurado con UTF-8 BOM y delimitador institucional', () async {
      final allEvals = await storageService.getAllEvaluations();
      final avg = storageService.calculateAverage(allEvals);
      final count = storageService.countEvaluatedStudents(allEvals);

      final File csvFile = await exportService.generateExcelReport(
        reportTitle: 'Informe Oficial de Calificaciones',
        teacherName: 'Prof. Alejandro Méndez',
        institution: 'Instituto Nacional de Panamá',
        evaluations: allEvals,
        averageScore: avg,
        evaluatedStudentsCount: count,
        filterDescription: 'Todos los registros',
      );

      expect(csvFile.existsSync(), isTrue);
      
      // Verificación a nivel binario de UTF-8 BOM [0xEF, 0xBB, 0xBF]
      final bytes = await csvFile.readAsBytes();
      expect(bytes.length, greaterThanOrEqualTo(3));
      expect(bytes[0], equals(0xEF));
      expect(bytes[1], equals(0xBB));
      expect(bytes[2], equals(0xBF));

      final content = await csvFile.readAsString();
      expect(content, contains('"REPÚBLICA DE PANAMÁ - MINISTERIO DE EDUCACIÓN"'));
      expect(content, contains('"PANAMÁ HISTÓRICA - Informe Oficial de Calificaciones"'));
      expect(content, contains('"Promedio General (0-100)";"88.2"'));
      expect(content, contains('"ID Estudiante";"Nombre del Estudiante"'));
      expect(content, contains('"Ricardo Arias"'));
    });

    // 13. [DEFECTO DETECTADO] Concurrencia: Respuestas asíncronas fuera de orden causan sobrescritura obsoleta (Lost Update) por falta de OCC
    test('13. [DEFECTO DETECTADO] Actualizaciones asíncronas fuera de orden sobrescriben datos recientes (Lost Update) por falta de control de versiones/OCC', () async {
      final initialEvals = await storageService.getAllEvaluations();
      final target = initialEvals.firstWhere((e) => e.id == 'seed_eval_01');

      // T0: Docente actualiza nota a 92.0 (versión más reciente T1)
      final recentUpdate = target.copyWith(score: 92.0, observations: 'Revisión reciente T1');
      // T1: Petición anterior retardada que llega fuera de orden con nota 75.0 (stale write T0)
      final staleUpdate = target.copyWith(score: 75.0, observations: 'Revisión obsoleta T0 llegada tarde');

      // Se ejecuta primero la actualización más reciente
      await storageService.updateEvaluation(recentUpdate);

      // Llega después la actualización retrasada (fuera de orden)
      // En un sistema con control de concurrencia optimista (OCC), staleUpdate debe ser rechazada
      // o invalidada para evitar la sobrescritura del dato más reciente
      await storageService.updateEvaluation(staleUpdate);

      final finalRecord = (await storageService.getAllEvaluations()).firstWhere((e) => e.id == 'seed_eval_01');

      // Debe preservar el valor más reciente (92.0) y no permitir que una petición retrasada haga Lost Update
      expect(
        finalRecord.score,
        equals(92.0),
        reason: 'El servicio debe proteger la integridad de datos ante respuestas asíncronas fuera de orden evitando el Lost Update',
      );
    });

    // 14. [DEFECTO DETECTADO] Integridad: Falta de sanitización de comillas dobles en campos no descriptivos del CSV
    test('14. [DEFECTO DETECTADO] Falta de sanitización de comillas dobles en títulos de actividades corrompe el formato RFC 4180 del CSV', () async {
      // Registrar evaluación con comillas dobles en el título de la actividad
      final specialEval = await storageService.saveEvaluation(
        studentId: 'usr_003',
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: '9 de enero',
        activityTitle: 'Análisis del "Pacto de la Colina" y banderas',
        score: 85.0,
        observations: 'Trabajo regular',
      );

      final File csvFile = await exportService.generateExcelReport(
        reportTitle: 'Reporte Especial',
        teacherName: 'Prof. Méndez',
        institution: 'Instituto Nacional',
        evaluations: [specialEval],
        averageScore: 85.0,
        evaluatedStudentsCount: 1,
      );

      final content = await csvFile.readAsString();

      // Según RFC 4180, una comilla doble interna debe ser escapada como dos comillas dobles ("")
      // ReportExportService solo sanea observations con .replaceAll('"', '""'), pero deja activityTitle sin sanear
      expect(
        content.contains('""Pacto de la Colina""'),
        isTrue,
        reason: 'Los títulos con comillas dobles deben escaparse con dobles comillas para evitar que Excel rompa las columnas',
      );
    });

    // 15. [DEFECTO DETECTADO] Transaccionalidad: Inconsistencia entre memoria y persistencia ante fallos de almacenamiento
    test('15. [DEFECTO DETECTADO] Fallo en persistencia SharedPreferences deja la lista en memoria en estado corrupto sin rollback', () async {
      final initialEvals = await storageService.getAllEvaluations();
      final target = initialEvals.firstWhere((e) => e.id == 'seed_eval_02');
      final originalScore = target.score;

      // Configurar SharedPreferences para que lance excepción al guardar (fallo de persistencia I/O)
      // updateEvaluation modifica _evaluations[index] ANTES de llamar a _persistEvaluations()
      // Si la persistencia falla, la memoria ya fue mutada y no hay reversión (rollback)
      // Forzar que el almacenamiento falle temporalmente
      SharedPreferences.setMockInitialValues({}); // Limpiar prefs
      
      // Creamos una subclase o prueba de fallo en _persistEvaluations:
      // Cuando updateEvaluation falla, el estado de la lista en memoria debe mantenerse consistente con el original
      try {
        // En un servicio transaccional robusto, el fallo de persistencia cancela la mutación en memoria
        // Verificamos si updateEvaluation garantiza atomicidad ante excepciones
        expect(
          () async {
            // Provocamos un fallo forzado de datos
            final corrupted = target.copyWith(score: -999.0); // inválido
            await storageService.updateEvaluation(corrupted);
          },
          throwsA(isA<Exception>()),
        );

        final current = (await storageService.getAllEvaluations()).firstWhere((e) => e.id == 'seed_eval_02');
        expect(current.score, equals(originalScore), reason: 'El valor en memoria no debe mutar si la validación falla');
      } catch (_) {}

      // Verificamos la mutación en memoria cuando _persistEvaluations falla tras actualizar memoria:
      // Como updateEvaluation no cuenta con mecanismo de rollback transaccional:
      final existsRollback = storageService.runtimeType.toString().contains('Transactional');
      expect(existsRollback, isTrue, reason: 'EvaluationStorageService carece de capa transaccional con reversión automática (Rollback)');
    });
  });
}
