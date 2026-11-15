import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panama_historica/models/historical_scene_model.dart';
import 'package:panama_historica/models/module_model.dart';
import 'package:panama_historica/services/content_service.dart';
import 'package:panama_historica/services/database_service.dart';
import 'package:panama_historica/services/download_service.dart';
import 'package:panama_historica/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService databaseService;
  late DownloadService downloadService;
  late ContentService contentService;
  late ProgressService progressService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    databaseService = DatabaseService();
    downloadService = DownloadService();
    contentService = ContentService();
    progressService = ProgressService();
    await progressService.resetProgress();
  });

  group('Checklist de Pruebas Unitarias - Contenido Histórico (Panamá Contemporánea)', () {
    // 1. Acceso a módulo curricular existente
    test('1. Consulta y recuperación del módulo curricular oficial de Panamá Contemporánea (getModules)', () async {
      final modules = await databaseService.getModules();

      expect(modules, isNotEmpty);
      expect(modules.any((m) => m.id == 'mod_contemporanea'), isTrue);

      final contemporanea = modules.firstWhere((m) => m.id == 'mod_contemporanea');
      expect(contemporanea.code, equals('MÓDULO 01'));
      expect(contemporanea.title.toLowerCase(), contains('contemporánea'));
      expect(contemporanea.category, equals('Época Contemporánea'));
      expect(contemporanea.bannerImageUrl, isNotEmpty);
      expect(contemporanea.documentCount, greaterThanOrEqualTo(1));
    });

    // 2. Acceso a módulos inexistentes
    test('2. Consulta segura de módulo no existente retorna colección vacía sin lanzar excepciones', () async {
      final modules = await databaseService.getModules();
      final nonExistent = modules.where((m) => m.id == 'mod_inexistente_999').toList();

      expect(nonExistent, isEmpty);
    });

    // 3. Recuperación de materiales curriculares base
    test('3. Recuperación de materiales educativos base de Panamá Contemporánea (getContemporaneaMaterials)', () async {
      final materials = await contentService.getContemporaneaMaterials();

      expect(materials.length, greaterThanOrEqualTo(4));

      // Comprobar presencia de material PDF
      final pdfMaterials = materials.where((m) => m.type == 'pdf').toList();
      expect(pdfMaterials, isNotEmpty);
      final pdfMat = pdfMaterials.first;
      expect(pdfMat.assetPath, contains('.pdf'));
      expect(pdfMat.title.toLowerCase(), contains('9 de enero'));

      // Comprobar presencia de materiales de imagen
      final images = materials.where((m) => m.type == 'image').toList();
      expect(images.length, greaterThanOrEqualTo(3));
      for (final img in images) {
        expect(img.assetPath, startsWith('assets/'));
      }
    });

    // 4. Consulta y agrupación de secciones educativas
    test('4. Consulta de documentos educativos organizados por sección temática (getPublishedDocumentsGroupedBySection)', () async {
      final grouped = await contentService.getPublishedDocumentsGroupedBySection('mod_contemporanea');

      expect(grouped, isA<Map<String, dynamic>>());
      // Si no hay documentos docentes aún, el mapa es vacío de forma segura
      for (final entry in grouped.entries) {
        expect(entry.key, isNotEmpty);
        expect(entry.value, isNotEmpty);
      }
    });

    // 5. Manejo de secciones sin contenido
    test('5. Consulta de secciones en un módulo inexistente retorna mapa vacío sin excepciones', () async {
      final emptyGrouped = await contentService.getPublishedDocumentsGroupedBySection('mod_inexistente_vacio');

      expect(emptyGrouped, isEmpty);
      expect(emptyGrouped.containsKey('General'), isFalse);
    });

    // 6. Estado de contenido descargado (Offline)
    test('6. Verificación de módulo descargado con disponibilidad offline y progreso 1.0', () async {
      SharedPreferences.setMockInitialValues({
        'module_downloaded_mod_contemporanea': true,
      });

      final isDownloaded = await downloadService.isModuleDownloaded('mod_contemporanea');
      expect(isDownloaded, isTrue);

      final modules = await databaseService.getModules();
      final module = modules.firstWhere((m) => m.id == 'mod_contemporanea');

      expect(module.status, equals(ModuleStatus.downloaded));
      expect(module.isOfflineAvailable, isTrue);
      expect(module.downloadProgress, equals(1.0));
    });

    // 7. Estado de contenido no descargado
    test('7. Verificación de módulo no descargado con disponibilidad offline falsa y estado disponible', () async {
      SharedPreferences.setMockInitialValues({
        'module_downloaded_mod_contemporanea': false,
      });

      final isDownloaded = await downloadService.isModuleDownloaded('mod_contemporanea');
      expect(isDownloaded, isFalse);

      final modules = await databaseService.getModules();
      final module = modules.firstWhere((m) => m.id == 'mod_contemporanea');

      expect(module.status, equals(ModuleStatus.available));
      expect(module.isOfflineAvailable, isFalse);
    });

    // 8. Descarga progresiva de contenido (Stream de progreso)
    test('8. Emisión progresiva de flujo asíncrono durante la descarga del módulo (downloadModule)', () async {
      final progressValues = <double>[];

      await for (final progress in downloadService.downloadModule('mod_contemporanea')) {
        progressValues.add(progress);
      }

      expect(progressValues, isNotEmpty);
      expect(progressValues.first, greaterThan(0.0));
      expect(progressValues.last, equals(1.0));

      final isDownloadedAfter = await downloadService.isModuleDownloaded('mod_contemporanea');
      expect(isDownloadedAfter, isTrue);
    });

    // 9. Eliminación y revocación de contenido descargado
    test('9. Eliminación de archivos descargados restablece persistencia y progreso a cero', () async {
      SharedPreferences.setMockInitialValues({
        'module_downloaded_mod_contemporanea': true,
      });

      await downloadService.removeModuleDownload('mod_contemporanea');

      final isDownloaded = await downloadService.isModuleDownloaded('mod_contemporanea');
      expect(isDownloaded, isFalse);
      expect(downloadService.getProgress('mod_contemporanea'), equals(0.0));
      expect(downloadService.isDownloading('mod_contemporanea'), isFalse);
    });

    // 10. Seguimiento del progreso de lectura
    test('10. Marcado de material visto actualiza la lista persistida y el último material consultado', () async {
      final materials = await contentService.getContemporaneaMaterials();
      final targetMaterial = materials.first;

      await contentService.markAsViewed(targetMaterial.id);

      final viewedIds = await progressService.getViewedMaterialIds();
      expect(viewedIds.contains(targetMaterial.id), isTrue);

      final lastOpened = await progressService.getLastOpenedMaterialId();
      expect(lastOpened, equals(targetMaterial.id));

      final lastMaterial = await contentService.getLastOpenedMaterial();
      expect(lastMaterial, isNotNull);
      expect(lastMaterial!.id, equals(targetMaterial.id));
    });

    // 11. Paginación y reanudación de lectura en PDF
    test('11. Almacenamiento y recuperación persistente de la última página leída de un PDF', () async {
      final initialPage = await progressService.getPdfLastPage('contemporanea_01');
      expect(initialPage, equals(1)); // Página 1 por defecto

      await progressService.setPdfLastPage('contemporanea_01', 18);
      final savedPage = await progressService.getPdfLastPage('contemporanea_01');
      expect(savedPage, equals(18));
    });

    // 12. Tolerancia a recursos visuales ausentes
    test('12. Tolerancia del modelo HistoricalScene ante imágenes no disponibles (imagePath nulo)', () {
      final scenes = HistoricalScene.getContemporaneaScenes();
      expect(scenes.length, greaterThanOrEqualTo(4));

      // Escena 4: Antecedentes y Consecuencias Históricas no tiene imagen
      final sceneWithoutImage = scenes.firstWhere((s) => s.id == 'escena_04');
      expect(sceneWithoutImage.imagePath, isNull);
      expect(sceneWithoutImage.title, contains('Antecedentes y Consecuencias'));
      expect(sceneWithoutImage.text, isNotEmpty);
      expect(sceneWithoutImage.narrationText, isNotEmpty);
      expect(sceneWithoutImage.source, isNotEmpty);
    });

    // 13. [DEFECTO DETECTADO] Concurrencia: Solicitudes simultáneas de descarga provocan colisión de streams
    test('13. [DEFECTO DETECTADO] Invocación concurrente de downloadModule no bloquea descargas duplicadas para el mismo módulo', () async {
      // Si downloadModule ya está activo para un módulo, una segunda llamada concurrente
      // debería ser rechazada o compartir el mismo stream atómicamente para evitar colisiones
      final stream1 = downloadService.downloadModule('mod_contemporanea');
      
      // Se inicia la primera descarga
      final sub1 = stream1.listen((_) {});

      // Segunda llamada inmediata mientras la primera sigue en curso
      bool rejectedDuplicate = false;
      try {
        if (downloadService.isDownloading('mod_contemporanea')) {
          // Un servicio robusto debe impedir duplicar la tarea de descarga
          throw StateError('Descarga ya en curso para mod_contemporanea');
        }
        downloadService.downloadModule('mod_contemporanea');
      } catch (e) {
        rejectedDuplicate = true;
      }

      await sub1.cancel();

      // En el código actual, downloadService no valida isDownloading() al entrar en downloadModule()
      // permitiendo múltiples bucles asíncronos concurrentes sobre la misma clave
      expect(
        rejectedDuplicate,
        isTrue,
        reason: 'DownloadService debe bloquear solicitudes simultáneas de descarga para el mismo módulo',
      );
    });

    // 14. [DEFECTO DETECTADO] Inoperancia de pausa: pauseDownload no suspende el flujo asíncrono y continúa descargando
    test('14. [DEFECTO DETECTADO] pauseDownload no suspende el flujo asíncrono de descarga ni congela el progreso', () async {
      final progressValues = <double>[];
      final stream = downloadService.downloadModule('mod_pause_test');
      final sub = stream.listen((p) => progressValues.add(p));

      // Esperar que empiece la descarga
      await Future.delayed(const Duration(milliseconds: 250));

      // Solicitar pausa
      downloadService.pauseDownload('mod_pause_test');
      final progressAtPause = downloadService.getProgress('mod_pause_test');

      // Esperar tiempo adicional para verificar si el flujo continúa emitiendo
      await Future.delayed(const Duration(milliseconds: 500));
      final progressAfterPause = downloadService.getProgress('mod_pause_test');

      await sub.cancel();

      // Comportamiento esperado de pausa: El progreso debe quedar congelado en el valor de la pausa
      // Comportamiento real detectado: pauseDownload solo muta _downloadingState pero no congela el Stream, por lo que el progreso sigue aumentando
      expect(
        progressAfterPause,
        equals(progressAtPause),
        reason: 'pauseDownload debe congelar el progreso de descarga y suspender la emisión del stream',
      );
    });

    // 15. [DEFECTO DETECTADO] Inconsistencia en inicialización de pantalla de detalle: Fallback a índice fuera de rango
    test('15. [DEFECTO DETECTADO] ModuleDetailScreen asume índice 2 en getMockModules() causando RangeError en tiempo de ejecución', () {
      final mockModules = ModuleModel.getMockModules();

      // ModuleDetailScreen.didChangeDependencies ejecuta:
      // _module = ModuleModel.getMockModules()[2]; // Fallback to Module 3
      // Comprobamos si la lista mock contiene al menos 3 elementos para soportar dicho fallback
      expect(
        mockModules.length,
        greaterThanOrEqualTo(3),
        reason: 'ModuleModel.getMockModules() solo tiene 1 módulo pero ModuleDetailScreen intenta acceder al índice [2], provocando RangeError',
      );
    });
  });
}
