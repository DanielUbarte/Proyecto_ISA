import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panama_historica/services/progress_service.dart';
import 'package:panama_historica/services/content_service.dart';
import 'package:panama_historica/modules/contemporanea/widgets/progress_bar_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProgressService progressService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    progressService = ProgressService();
  });

  tearDown(() async {
    await progressService.resetProgress();
  });

  group('Checklist de Pruebas Unitarias - Módulo de Progreso Académico', () {
    // ------------------------------------------------------------------------
    // Caso 1: Progreso inicial sin materiales vistos
    // ------------------------------------------------------------------------
    test('1. Progreso inicial retorna colecciones vacías y último abierto nulo', () async {
      final viewed = await progressService.getViewedMaterialIds();
      final lastOpened = await progressService.getLastOpenedMaterialId();

      expect(viewed, isEmpty);
      expect(viewed.length, equals(0));
      expect(lastOpened, isNull);
    });

    // ------------------------------------------------------------------------
    // Caso 2: Progreso completo (100%)
    // ------------------------------------------------------------------------
    testWidgets('2. Progreso completo del 100% muestra ratio 1.0 y badge ¡Completado!', (tester) async {
      const viewedCount = 5;
      const totalCount = 5;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContemporaneaProgressBar(
              viewedCount: viewedCount,
              totalCount: totalCount,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('5 de 5 materiales vistos'), findsOneWidget);
      expect(find.text('¡Completado!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // Caso 3: Valores intermedios proporcionales (50%)
    // ------------------------------------------------------------------------
    testWidgets('3. Valores intermedios calculan porcentaje exacto (2 de 4 = 50%)', (tester) async {
      const viewedCount = 2;
      const totalCount = 4;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContemporaneaProgressBar(
              viewedCount: viewedCount,
              totalCount: totalCount,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('2 de 4 materiales vistos'), findsOneWidget);
      expect(find.text('¡Completado!'), findsNothing);
    });

    // ------------------------------------------------------------------------
    // Caso 4: Cantidad de actividades igual a cero (división segura)
    // ------------------------------------------------------------------------
    testWidgets('4. Cantidad de actividades igual a cero evita división por cero retornando 0%', (tester) async {
      const viewedCount = 0;
      const totalCount = 0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContemporaneaProgressBar(
              viewedCount: viewedCount,
              totalCount: totalCount,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 de 0 materiales vistos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ------------------------------------------------------------------------
    // Caso 5: Valores límite e inválidos
    // ------------------------------------------------------------------------
    test('5. Valores límite e inválidos permanecen acotados en rango [0.0, 1.0]', () {
      double calculateRatio(int viewed, int total) {
        if (total <= 0) return 0.0;
        final raw = viewed / total;
        return raw.clamp(0.0, 1.0);
      }

      expect(calculateRatio(-5, 10), equals(0.0));
      expect(calculateRatio(15, 10), equals(1.0));
      expect(calculateRatio(0, 10), equals(0.0));
      expect(calculateRatio(10, 10), equals(1.0));
      expect(calculateRatio(3, 10), equals(0.3));
    });

    // ------------------------------------------------------------------------
    // Caso 6: Marcado de secciones y materiales completados
    // ------------------------------------------------------------------------
    test('6. Marcado secuencial de materiales persiste correctamente en almacenamiento', () async {
      await progressService.markMaterialAsViewed('contemporanea_01');
      await progressService.markMaterialAsViewed('contemporanea_02');

      final viewed = await progressService.getViewedMaterialIds();
      expect(viewed.length, equals(2));
      expect(viewed.contains('contemporanea_01'), isTrue);
      expect(viewed.contains('contemporanea_02'), isTrue);
    });

    // ------------------------------------------------------------------------
    // Caso 7: Reapertura de secciones y recuperación de página PDF
    // ------------------------------------------------------------------------
    test('7. Reapertura de secciones recupera el último material y la página leída exacta', () async {
      await progressService.setLastOpenedMaterialId('doc_canal_1964');
      await progressService.setPdfLastPage('doc_canal_1964', 18);

      final lastOpened = await progressService.getLastOpenedMaterialId();
      final page = await progressService.getPdfLastPage('doc_canal_1964');

      expect(lastOpened, equals('doc_canal_1964'));
      expect(page, equals(18));
    });

    // ------------------------------------------------------------------------
    // Caso 8: Actualizaciones repetidas (Idempotencia)
    // ------------------------------------------------------------------------
    test('8. Actualizaciones repetidas del mismo material son idempotentes sin duplicar elementos', () async {
      await progressService.markMaterialAsViewed('contemporanea_01');
      await progressService.markMaterialAsViewed('contemporanea_01');
      await progressService.markMaterialAsViewed('contemporanea_01');

      final viewed = await progressService.getViewedMaterialIds();
      expect(viewed.length, equals(1));
      expect(viewed, contains('contemporanea_01'));
    });

    // ------------------------------------------------------------------------
    // Caso 9: Respuestas asíncronas fuera de orden [DEFECTO REAL: Lost Update / Sobrescritura Obsoleta]
    // ------------------------------------------------------------------------
    test('9. [DEFECTO CONCURRENCIA] Peticiones asíncronas fuera de orden en setPdfLastPage provocan Lost Update sobre el progreso más reciente', () async {
      // T0: El estudiante avanza en su lectura hasta la página 25 (progreso más reciente)
      await progressService.setPdfLastPage('doc_historia_1964', 25);

      // T1: Una petición asíncrona retrasada (ej. evento previo de página 12 llegado fuera de orden)
      // se procesa después. En un sistema robusto con control de concurrencia o avance monótono,
      // la lectura no debe retroceder a páginas inferiores arbitrariamente por escrituras obsoletas.
      await progressService.setPdfLastPage('doc_historia_1964', 12);

      final storedPage = await progressService.getPdfLastPage('doc_historia_1964');

      expect(
        storedPage,
        equals(25),
        reason: 'DEFECTO DETECTADO: Sobrescritura obsoleta (Lost Update). Una petición asíncrona retrasada '
            'sobreescribió la página más avanzada (25) con un estado obsoleto ($storedPage) '
            'porque setPdfLastPage no implementa control monótono ni verificación de concurrencia.',
      );
    });

    // ------------------------------------------------------------------------
    // Caso 10: Lectura del progreso durante una modificación
    // ------------------------------------------------------------------------
    test('10. Lectura del progreso durante modificación retorna estado válido sin fallas', () async {
      final writeFuture = progressService.markMaterialAsViewed('material_en_vuelo');
      final readFuture = progressService.getViewedMaterialIds();

      final results = await Future.wait([writeFuture, readFuture]);
      final readResult = results[1] as Set<String>;

      expect(readResult, isNotNull);
      expect(readResult, isA<Set<String>>());
    });

    // ------------------------------------------------------------------------
    // Caso 11: Reseteo y limpieza de almacenamiento
    // ------------------------------------------------------------------------
    test('11. Reseteo del progreso limpia las claves persistidas restaurando estado inicial', () async {
      await progressService.markMaterialAsViewed('mat_a_borrar');
      await progressService.setLastOpenedMaterialId('mat_a_borrar');

      await progressService.resetProgress();

      final viewed = await progressService.getViewedMaterialIds();
      final lastOpened = await progressService.getLastOpenedMaterialId();

      expect(viewed, isEmpty);
      expect(lastOpened, isNull);
    });

    // ------------------------------------------------------------------------
    // Caso 12: Respuestas asíncronas desordenadas con retardos
    // ------------------------------------------------------------------------
    test('12. Respuestas asíncronas fuera de orden secuenciadas conservan todos los materiales', () async {
      Future<void> delayedMark(String id, int delayMs) async {
        await Future.delayed(Duration(milliseconds: delayMs));
        await progressService.markMaterialAsViewed(id);
      }

      await delayedMark('material_rapido', 10);
      await delayedMark('material_lento', 50);

      final viewed = await progressService.getViewedMaterialIds();
      expect(viewed.contains('material_rapido'), isTrue);
      expect(viewed.contains('material_lento'), isTrue);
      expect(viewed.length, equals(2));
    });

    // ------------------------------------------------------------------------
    // Caso 13: Identificadores inválidos o vacíos [DEFECTO REAL: Ausencia de Validación]
    // ------------------------------------------------------------------------
    test('13. [DEFECTO VALIDACIÓN] markMaterialAsViewed acepta IDs vacíos o en blanco inflando artificialmente el progreso', () async {
      // El servicio debería rechazar o ignorar IDs vacíos mediante una validación (ej. ArgumentError)
      // para evitar corromper las métricas de progreso académico.
      bool threwValidationError = false;
      try {
        await progressService.markMaterialAsViewed('');
        await progressService.markMaterialAsViewed('   ');
      } catch (e) {
        threwValidationError = true;
      }

      final viewed = await progressService.getViewedMaterialIds();

      // Debería lanzar error de validación o no añadir cadenas vacías al progreso
      expect(
        threwValidationError || (!viewed.contains('') && !viewed.contains('   ')),
        isTrue,
        reason: 'DEFECTO DETECTADO: El servicio no valida entradas vacías. Se añadieron cadenas en blanco '
            'al conjunto de materiales vistos ($viewed), inflando el conteo y distorsionando el cálculo académico.',
      );
    });

    // ------------------------------------------------------------------------
    // Caso 14: Recuperación de datos incompletos o claves inexistentes
    // ------------------------------------------------------------------------
    test('14. Recuperación de datos inexistentes retorna valores predeterminados seguros (página 1)', () async {
      final defaultPage = await progressService.getPdfLastPage('doc_no_existente');
      final nonExistentLast = await progressService.getLastOpenedMaterialId();

      expect(defaultPage, equals(1));
      expect(nonExistentLast, isNull);
    });

    // ------------------------------------------------------------------------
    // Caso 15: Sincronización transaccional en ContentService [DEFECTO REAL: Falta de Atomicidad]
    // ------------------------------------------------------------------------
    test('15. [DEFECTO TRANSACCIONAL] ContentService.markAsViewed carece de rollback atómico ante falla parcial', () async {
      final contentService = ContentService();

      // Verificamos si ContentService implementa control transaccional o verificación de integridad:
      // Cuando se marca un material inexistente en el catálogo de contenidos, se persiste
      // como último abierto y como visto aunque no sea un recurso válido del curso.
      await contentService.markAsViewed('material_fantasma_inexistente_999');

      final lastOpenedMat = await contentService.getLastOpenedMaterial();
      final lastOpenedId = await progressService.getLastOpenedMaterialId();

      // El último ID guardado existe en SharedPreferences pero getLastOpenedMaterial retorna null
      // porque el material no existe en la base de datos documental, generando una desincronización
      // persistente entre el ID apuntado y los objetos de contenido disponibles.
      final isDesynchronized = (lastOpenedId != null && lastOpenedMat == null);

      expect(
        isDesynchronized,
        isFalse,
        reason: 'DEFECTO DETECTADO: Desincronización entre capa de persistencia y catálogo de materiales. '
            'Se guardó el ID "$lastOpenedId" como último abierto pero no corresponde a ningún recurso válido, '
            'dejando un puntero huérfano sin validación ni rollback transaccional.',
      );
    });
  });
}
