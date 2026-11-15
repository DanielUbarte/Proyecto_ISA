import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panama_historica/models/document_model.dart';
import 'package:panama_historica/services/document_storage_service.dart';
import 'package:panama_historica/services/rag/document_indexer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DocumentStorageService storageService;
  late DocumentIndexerService indexerService;

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
    storageService = DocumentStorageService();
    indexerService = DocumentIndexerService();
    storageService.resetForTesting();
    indexerService.resetForTesting();
    await storageService.initialize();
  });

  group('Checklist de Pruebas Unitarias - Gestión de Documentos del Docente', () {
    // 1. Carga de documentos PDF con metadatos completos
    test('1. Carga e incorporación exitosa de documento PDF con metadatos completos (addDocument)', () async {
      final doc = await storageService.addDocument(
        title: 'Constitución Política de la República de 1972',
        description: 'Texto histórico de la carta magna republicana y sus reformas.',
        author: 'Asamblea Nacional de Representantes',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Constitución y Leyes',
        sourceFilePath: 'assets/modules/contemporanea/documents/PDF_9 ENERO 1964_WTRIBALDOS_2023.pdf',
        fileName: 'constitucion_1972.pdf',
        fileSizeBytes: 2048500,
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        status: DocumentPublicationStatus.draft,
      );

      expect(doc.id.startsWith('doc_'), isTrue);
      expect(doc.title, equals('Constitución Política de la República de 1972'));
      expect(doc.isPdf, isTrue);
      expect(doc.isImage, isFalse);
      expect(doc.fileSizeBytes, equals(2048500));
      expect(doc.isDraft, isTrue);
      expect(doc.isPublished, isFalse);
      expect(doc.isArchived, isFalse);

      final allDocs = await storageService.getAllDocuments();
      expect(allDocs.any((d) => d.id == doc.id), isTrue);
    });

    // 2. Carga de documentos de tipo imagen (JPG, PNG, JFIF)
    test('2. Carga e incorporación exitosa de documento de tipo imagen (addDocument)', () async {
      final imageDoc = await storageService.addDocument(
        title: 'Plaza 5 de Mayo en 1964',
        description: 'Fotografía testimonial de la concentración popular en defensa de la bandera.',
        author: 'Archivo Histórico de la Ciudad',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: '9 de enero de 1964',
        sourceFilePath: 'assets/modules/contemporanea/images/martires-panama.jpg',
        fileName: 'plaza_5_mayo.jpg',
        fileSizeBytes: 540000,
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        status: DocumentPublicationStatus.published,
      );

      expect(imageDoc.isImage, isTrue);
      expect(imageDoc.isPdf, isFalse);
      expect(imageDoc.fileType, equals('image'));
      expect(imageDoc.formattedFileSize, equals('527.3 KB'));
      expect(imageDoc.formattedDate, isNotEmpty);
      expect(imageDoc.isPublished, isTrue);
    });

    // 3. Formatos de archivo incompatibles
    test('3. Rechazo preventivo ante formatos no permitidos (.exe, .docx, .mp4) (addDocument)', () async {
      expect(
        () => storageService.addDocument(
          title: 'Archivo Malicioso',
          description: 'Intento de cargar un binario ejecutable',
          author: 'Desconocido',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero de 1964',
          sourceFilePath: 'assets/payload.exe',
          fileName: 'payload.exe',
          fileSizeBytes: 10240,
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Formato de archivo incompatible (exe)'),
        )),
      );
    });

    // 4. Archivos vacíos
    test('4. Validación de valor límite: Rechazo de archivos vacíos con tamaño cero o negativo (addDocument)', () async {
      expect(
        () => storageService.addDocument(
          title: 'Documento Vacío',
          description: 'Archivo de cero bytes',
          author: 'Profesor de Historia',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero de 1964',
          sourceFilePath: 'assets/empty.pdf',
          fileName: 'empty.pdf',
          fileSizeBytes: 0,
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('El archivo seleccionado está vacío.'),
        )),
      );
    });

    // 5. Tamaño máximo permitido (25 MB)
    test('5. Validación de valor límite superior: Rechazo de archivos que superan 25 MB (addDocument)', () async {
      const int overSize = 26 * 1024 * 1024; // 26 MB

      expect(
        () => storageService.addDocument(
          title: 'Archivo Enorme',
          description: 'Supera el límite institucional',
          author: 'Ministerio de Educación',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero de 1964',
          sourceFilePath: 'assets/huge_archive.pdf',
          fileName: 'huge_archive.pdf',
          fileSizeBytes: overSize,
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('El archivo excede el tamaño máximo permitido de 25 MB.'),
        )),
      );
    });

    // 6. Campos obligatorios
    test('6. Validación de obligatoriedad de campos (título, autor y módulo/sección) (addDocument)', () async {
      expect(
        () => storageService.addDocument(
          title: '   ',
          description: 'Sin título',
          author: 'Autor Válido',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero de 1964',
          sourceFilePath: 'assets/test.pdf',
          fileName: 'test.pdf',
          fileSizeBytes: 1024,
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('El título del documento es obligatorio.'),
        )),
      );

      expect(
        () => storageService.addDocument(
          title: 'Título Válido',
          description: 'Sin autor',
          author: '   ',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero de 1964',
          sourceFilePath: 'assets/test.pdf',
          fileName: 'test.pdf',
          fileSizeBytes: 1024,
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('El autor o fuente del documento es obligatorio.'),
        )),
      );
    });

    // 7. Detección y rechazo de archivos duplicados
    test('7. Prevención de colisión y rechazo de documentos duplicados en la misma sección (addDocument)', () async {
      await storageService.addDocument(
        title: 'Tratado Hay-Bunau Varilla Original',
        description: 'Copia histórica de 1903',
        author: 'Philippe Bunau-Varilla',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Tratados Canaleros',
        sourceFilePath: 'assets/tratado_1903.pdf',
        fileName: 'tratado_1903.pdf',
        fileSizeBytes: 500000,
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
      );

      expect(
        () => storageService.addDocument(
          title: 'Tratado Hay-Bunau Varilla Original',
          description: 'Duplicado con otro archivo',
          author: 'Otro Autor',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: 'Tratados Canaleros',
          sourceFilePath: 'assets/otro_archivo.pdf',
          fileName: 'otro_archivo.pdf',
          fileSizeBytes: 600000,
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Ya existe un documento con este título o nombre de archivo en la misma sección.'),
        )),
      );
    });

    // 8. Máquina de estados: Borrador -> Publicado -> Archivado
    test('8. Ciclo completo de transiciones de estado: Borrador ➔ Publicado ➔ Archivado (setPublicationStatus)', () async {
      final doc = await storageService.addDocument(
        title: 'Soberanía en la Zona del Canal',
        description: 'Documento en borrador inicial',
        author: 'Dr. Carlos Mendoza',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Soberanía Canalera',
        sourceFilePath: 'assets/soberania.pdf',
        fileName: 'soberania.pdf',
        fileSizeBytes: 800000,
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
        status: DocumentPublicationStatus.draft,
      );
      expect(doc.isDraft, isTrue);

      final publishedDoc = await storageService.setPublicationStatus(
        doc.id,
        DocumentPublicationStatus.published,
      );
      expect(publishedDoc.isPublished, isTrue);

      final archivedDoc = await storageService.setPublicationStatus(
        doc.id,
        DocumentPublicationStatus.archived,
      );
      expect(archivedDoc.isArchived, isTrue);

      final draftDoc = await storageService.setPublicationStatus(
        doc.id,
        DocumentPublicationStatus.draft,
      );
      expect(draftDoc.isDraft, isTrue);
    });

    // 9. Edición de documento existente y validación de título vacío
    test('9. Modificación de metadatos de documento y validación de título no vacío (updateDocument)', () async {
      final doc = await storageService.addDocument(
        title: 'Manifiesto Estudiantil de 1958',
        description: 'Operación Soberanía',
        author: 'FEP',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Movimiento Estudiantil',
        sourceFilePath: 'assets/fep_1958.pdf',
        fileName: 'fep_1958.pdf',
        fileSizeBytes: 450000,
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
      );

      final updated = await storageService.updateDocument(
        doc.copyWith(
          title: 'Operación Soberanía y Siembra de Banderas de 1958',
          description: 'Descripción histórica ampliada con testimonios.',
        ),
      );

      expect(updated.title, equals('Operación Soberanía y Siembra de Banderas de 1958'));
      expect(updated.description, contains('testimonios'));

      expect(
        () => storageService.updateDocument(doc.copyWith(title: '   ')),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('El título del documento no puede estar vacío.'),
        )),
      );
    });

    // 10. [DEFECTO D-02] Asimetría de notificación ante eliminación de documento inexistente
    test('10. Consistencia de excepciones: Notificación de Documento no encontrado en eliminación de ID inexistente (deleteDocument)', () async {
      // Debe lanzar excepción de 'Documento no encontrado' de forma simétrica a updateDocument y setPublicationStatus
      expect(
        () => storageService.deleteDocument('doc_fantasma_inexistente_999'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Documento no encontrado'),
        )),
      );
    });

    // 11. Eliminación y tolerancia a fallos
    test('11. Eliminación efectiva de documento existente en biblioteca documental (deleteDocument)', () async {
      final doc = await storageService.addDocument(
        title: 'Documento Para Eliminar Definitivo',
        description: 'Documento temporal',
        author: 'Profesor X',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Sección Temporal',
        sourceFilePath: 'assets/temp.pdf',
        fileName: 'temp.pdf',
        fileSizeBytes: 20000,
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
      );

      await storageService.deleteDocument(doc.id);
      final docsAfter = await storageService.getAllDocuments();
      expect(docsAfter.any((d) => d.id == doc.id), isFalse);
    });

    // 12. Control de visibilidad para estudiantes
    test('12. Control de visibilidad: El estudiante solo puede consultar documentos en estado Publicado (getPublishedDocumentsForSection)', () async {
      final draftDoc = await storageService.addDocument(
        title: 'Borrador Exclusivo del Profesor',
        description: 'Material confidencial no disponible para alumnos',
        author: 'Prof. Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Gestas Patrióticas',
        sourceFilePath: 'assets/draft_gesta.pdf',
        fileName: 'draft_gesta.pdf',
        fileSizeBytes: 100000,
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
        status: DocumentPublicationStatus.draft,
      );

      final publishedDoc = await storageService.addDocument(
        title: 'Guía de Estudio de la Gesta Patriótica',
        description: 'Guía oficial para todos los estudiantes',
        author: 'Prof. Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Gestas Patrióticas',
        sourceFilePath: 'assets/guia_gesta.pdf',
        fileName: 'guia_gesta.pdf',
        fileSizeBytes: 200000,
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
        status: DocumentPublicationStatus.published,
      );

      final studentDocs = await storageService.getPublishedDocumentsForSection(
        moduleId: 'mod_contemporanea',
        sectionTitle: 'Gestas Patrióticas',
      );

      final studentDocIds = studentDocs.map((d) => d.id).toList();
      expect(studentDocIds.contains(publishedDoc.id), isTrue);
      expect(studentDocIds.contains(draftDoc.id), isFalse);

      for (final d in studentDocs) {
        expect(d.isPublished, isTrue);
        expect(d.isDraft, isFalse);
        expect(d.isArchived, isFalse);
      }
    });

    // 13. [DEFECTO D-01] Inconsistencia en RAG: Marcado indebido de indexación cuando el PDF carece de texto extraíble
    test('13. Integridad de estado en IA: No marcar isIndexed en true si no se pudo extraer texto del PDF (indexDocumentForAI)', () async {
      final unextractablePdf = await storageService.addDocument(
        title: 'PDF Escaneado Sin Capa de Texto',
        description: 'Documento sin OCR',
        author: 'Archivo Antiguo',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Archivos Antiguos',
        sourceFilePath: 'assets/archivo_sin_ocr.pdf',
        fileName: 'archivo_sin_ocr.pdf',
        fileSizeBytes: 500000,
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
        status: DocumentPublicationStatus.published,
      );

      // Si no se extrajo texto del PDF (extractedText == null), el documento NO debe marcarse como indexado en IA
      final result = await storageService.indexDocumentForAI(unextractablePdf.id);
      expect(
        result?.isIndexed,
        isFalse,
        reason: 'Un documento sin texto extraído no debe marcarse como isIndexed = true',
      );
    });

    // 14. [DEFECTO D-03] Sincronización: Capacidad de registrar documentos remotos nuevos de otros docentes
    test('14. Sincronización documental: Capacidad de incorporar documentos nuevos de otros docentes (updateDocument / upsert)', () async {
      final remoteDoc = EducationalDocumentModel(
        id: 'doc_remoto_docente_carmen_guardia_99',
        fileName: 'separacion_1903.pdf',
        title: 'Tratados y Separación de 1903',
        description: 'Documento cargado por otro docente en el servidor institucional',
        author: 'Prof. Carmen Guardia',
        createdAt: DateTime.now(),
        teacherId: 'doc_002',
        teacherName: 'Prof. Carmen Guardia',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionId: 'sec_1903',
        sectionTitle: 'Acontecimientos de 1903',
        status: DocumentPublicationStatus.published,
        filePath: 'assets/separacion_1903.pdf',
        fileType: 'pdf',
        fileSizeBytes: 600000,
      );

      // Al sincronizar desde el servidor, updateDocument debe incorporar el documento nuevo sin lanzar excepción de 'Documento no encontrado'
      expect(
        () => storageService.updateDocument(remoteDoc),
        returnsNormally,
        reason: 'El almacenamiento debe permitir incorporar documentos nuevos sincronizados desde el repositorio remoto',
      );
    });

    // 15. Concurrencia y dos cargas simultáneas
    test('15. Concurrencia: Manejo de dos cargas simultáneas de documentos sin colisión de IDs ni corrupción (Future.wait)', () async {
      final results = await Future.wait([
        storageService.addDocument(
          title: 'Documento Simultáneo Alfa',
          description: 'Carga concurrente A',
          author: 'Profesor Alfa',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: 'Concurrencia Docente',
          sourceFilePath: 'assets/alfa.pdf',
          fileName: 'alfa.pdf',
          fileSizeBytes: 50000,
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
        storageService.addDocument(
          title: 'Documento Simultáneo Beta',
          description: 'Carga concurrente B',
          author: 'Profesor Beta',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: 'Concurrencia Docente',
          sourceFilePath: 'assets/beta.pdf',
          fileName: 'beta.pdf',
          fileSizeBytes: 60000,
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
      ]);

      expect(results.length, equals(2));
      expect(results[0].id, isNot(equals(results[1].id)));
      expect(results[0].title, equals('Documento Simultáneo Alfa'));
      expect(results[1].title, equals('Documento Simultáneo Beta'));

      final allDocs = await storageService.getAllDocuments();
      expect(allDocs.any((d) => d.id == results[0].id), isTrue);
      expect(allDocs.any((d) => d.id == results[1].id), isTrue);
    });
  });
}
