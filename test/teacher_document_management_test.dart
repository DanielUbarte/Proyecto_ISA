import 'package:flutter_test/flutter_test.dart';
import 'package:panama_historica/models/document_model.dart';
import 'package:panama_historica/models/user_model.dart';
import 'package:panama_historica/services/auth_service.dart';
import 'package:panama_historica/services/content_service.dart';
import 'package:panama_historica/services/document_storage_service.dart';
import 'package:panama_historica/services/rag/document_indexer_service.dart';
import 'package:panama_historica/services/rag/retrieval_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DocumentStorageService().resetForTesting();
    DocumentIndexerService().resetForTesting();
  });

  group('1. Autenticación y Diferenciación de Roles (Docente vs Estudiante)', () {
    test('Inicio de sesión docente exitoso con credenciales institucionales MEDUCA', () async {
      final auth = AuthService();
      final teacher = await auth.signInTeacher(
        email: 'profesor.historica@meduca.gob.pa',
        password: '12345678',
      );

      expect(teacher.role, equals(UserRole.teacher));
      expect(teacher.isTeacher, isTrue);
      expect(teacher.isStudent, isFalse);
      expect(teacher.name, contains('Prof. Alejandro Méndez'));
    });

    test('Estudiante no puede acceder mediante el portal de docentes', () async {
      final auth = AuthService();

      expect(
        () async => await auth.signInTeacher(
          email: 'estudiante@academia.pa',
          password: '12345678',
        ),
        throwsA(predicate((e) =>
            e.toString().contains('Acceso denegado') &&
            e.toString().contains('Estudiante'))),
      );
    });

    test('Rechazo de credenciales docentes con contraseña incorrecta', () async {
      final auth = AuthService();

      expect(
        () async => await auth.signInTeacher(
          email: 'profesor.historica@meduca.gob.pa',
          password: 'wrong_password',
        ),
        throwsA(predicate((e) => e.toString().contains('Contraseña incorrecta'))),
      );
    });

    test('Rechazo de campos vacíos en acceso docente', () async {
      final auth = AuthService();

      expect(
        () async => await auth.signInTeacher(email: '', password: ''),
        throwsA(predicate((e) => e.toString().contains('Por favor ingrese'))),
      );
    });

    test('Registro obligatorio asigna exclusivamente rol estudiante (sin escalamiento a docente)', () async {
      final auth = AuthService();

      final newStudent = await auth.register(
        name: 'Carlos Rivera',
        email: 'carlos.rivera@instituto.pa',
        password: 'password123',
        grade: '11° Grado',
      );

      expect(newStudent.role, equals(UserRole.student));
      expect(newStudent.isStudent, isTrue);
      expect(newStudent.isTeacher, isFalse);
    });

    test('Cierre de sesión docente limpia el usuario activo', () async {
      final auth = AuthService();
      await auth.signInTeacher(
        email: 'profesor.historica@meduca.gob.pa',
        password: '12345678',
      );
      expect(auth.isAuthenticated, isTrue);

      await auth.signOut();
      expect(auth.currentUser, isNull);
    });
  });

  group('2. Gestión de Documentos y Validaciones', () {
    test('Inicialización de biblioteca con documentos semilla publicados', () async {
      final storage = DocumentStorageService();
      await storage.initialize();

      final docs = await storage.getAllDocuments();
      expect(docs.isNotEmpty, isTrue);

      final published = docs.where((d) => d.isPublished).toList();
      expect(published.length, greaterThanOrEqualTo(4));

      // Verificar que el libro principal de 1964 esté presente
      final mainPdf = docs.firstWhere((d) => d.fileName.contains('PDF_9 ENERO 1964'));
      expect(mainPdf.title, contains('El 9 de enero de 1964'));
      expect(mainPdf.isPdf, isTrue);
      expect(mainPdf.isPublished, isTrue);
    });

    test('Validación: No permitir documentos sin título', () async {
      final storage = DocumentStorageService();
      await storage.initialize();

      expect(
        () async => await storage.addDocument(
          title: '   ',
          description: 'Descripción válida',
          author: 'Wendy Tribaldos',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero de 1964',
          sourceFilePath: 'assets/dummy.pdf',
          fileName: 'documento.pdf',
          fileSizeBytes: 1024,
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
        throwsA(predicate((e) => e.toString().contains('El título del documento es obligatorio'))),
      );
    });

    test('Validación: No permitir archivos vacíos', () async {
      final storage = DocumentStorageService();
      await storage.initialize();

      expect(
        () async => await storage.addDocument(
          title: 'Tratado Histórico',
          description: 'Descripción',
          author: 'Autor',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero de 1964',
          sourceFilePath: 'assets/empty.pdf',
          fileName: 'empty.pdf',
          fileSizeBytes: 0,
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
        throwsA(predicate((e) => e.toString().contains('vacío'))),
      );
    });

    test('Validación: No permitir formatos incompatibles (ej. .exe, .docx)', () async {
      final storage = DocumentStorageService();
      await storage.initialize();

      expect(
        () async => await storage.addDocument(
          title: 'Archivo Incompatible',
          description: 'Descripción',
          author: 'Autor',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero de 1964',
          sourceFilePath: 'assets/app.exe',
          fileName: 'app.exe',
          fileSizeBytes: 5000,
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
        throwsA(predicate((e) => e.toString().contains('incompatible'))),
      );
    });

    test('Validación: No exceder tamaño máximo de 25 MB', () async {
      final storage = DocumentStorageService();
      await storage.initialize();

      expect(
        () async => await storage.addDocument(
          title: 'Archivo Enorme',
          description: 'Descripción',
          author: 'Autor',
          moduleId: 'mod_contemporanea',
          moduleTitle: 'Panamá Contemporánea',
          sectionTitle: '9 de enero de 1964',
          sourceFilePath: 'assets/huge.pdf',
          fileName: 'huge.pdf',
          fileSizeBytes: 26 * 1024 * 1024, // 26 MB
          teacherId: 'doc_001',
          teacherName: 'Prof. Méndez',
        ),
        throwsA(predicate((e) => e.toString().contains('25 MB'))),
      );
    });

    test('Incorporación y asociación jerárquica: Módulo -> Sección -> Documento', () async {
      final storage = DocumentStorageService();
      await storage.initialize();

      final newDoc = await storage.addDocument(
        title: 'Memorias de la Federación de Estudiantes de Panamá',
        description: 'Documento histórico sobre la organización estudiantil en el siglo XX.',
        author: 'FEP Archivo Histórico',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Movimiento Estudiantil',
        sourceFilePath: 'assets/fep_1964.pdf',
        fileName: 'fep_1964.pdf',
        fileSizeBytes: 1500000,
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        status: DocumentPublicationStatus.draft,
      );

      expect(newDoc.id.startsWith('doc_'), isTrue);
      expect(newDoc.moduleId, equals('mod_contemporanea'));
      expect(newDoc.sectionTitle, equals('Movimiento Estudiantil'));
      expect(newDoc.isDraft, isTrue);
      expect(newDoc.isPublished, isFalse);

      final sections = await storage.getSectionsForModule('mod_contemporanea');
      expect(sections.contains('Movimiento Estudiantil'), isTrue);
    });

    test('Control de publicación: Publicar, Pasar a Borrador y Archivar', () async {
      final storage = DocumentStorageService();
      await storage.initialize();

      final doc = await storage.addDocument(
        title: 'Documento de Estado y Soberanía',
        description: 'Análisis de soberanía',
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

      // 1. Publicar
      final published = await storage.setPublicationStatus(doc.id, DocumentPublicationStatus.published);
      expect(published.isPublished, isTrue);
      expect(published.isDraft, isFalse);

      // 2. Despublicar a Borrador
      final draftAgain = await storage.setPublicationStatus(doc.id, DocumentPublicationStatus.draft);
      expect(draftAgain.isDraft, isTrue);
      expect(draftAgain.isPublished, isFalse);

      // 3. Archivar
      final archived = await storage.setPublicationStatus(doc.id, DocumentPublicationStatus.archived);
      expect(archived.isArchived, isTrue);
      expect(archived.isPublished, isFalse);
    });
  });

  group('3. Visualización y Filtrado desde la Cuenta del Estudiante', () {
    test('El estudiante visualiza ÚNICAMENTE documentos con estado Publicado para su sección', () async {
      final storage = DocumentStorageService();
      await storage.initialize();

      // Agregar un documento en borrador y otro archivado en la sección 'Tratados'
      final draftDoc = await storage.addDocument(
        title: 'Borrador Confidencial de Tratados',
        description: 'No debe ser visible para estudiantes',
        author: 'Autor X',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Tratados Torrijos-Carter',
        sourceFilePath: 'assets/draft.pdf',
        fileName: 'draft.pdf',
        fileSizeBytes: 500000,
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
        status: DocumentPublicationStatus.draft,
      );

      final publishedDoc = await storage.addDocument(
        title: 'Tratados Torrijos-Carter de 1977 (Texto Oficial)',
        description: 'Documento oficial publicado para estudiantes',
        author: 'Ministerio de Relaciones Exteriores',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Tratados Torrijos-Carter',
        sourceFilePath: 'assets/tratados_1977.pdf',
        fileName: 'tratados_1977.pdf',
        fileSizeBytes: 1200000,
        teacherId: 'doc_001',
        teacherName: 'Prof. Méndez',
        status: DocumentPublicationStatus.published,
      );

      final studentDocs = await storage.getPublishedDocumentsForSection(
        moduleId: 'mod_contemporanea',
        sectionTitle: 'Tratados Torrijos-Carter',
      );

      // Comprobar que solo el publicado esté disponible para el estudiante
      final docIds = studentDocs.map((d) => d.id).toList();
      expect(docIds.contains(publishedDoc.id), isTrue);
      expect(docIds.contains(draftDoc.id), isFalse);
      for (final d in studentDocs) {
        expect(d.isPublished, isTrue);
        expect(d.isDraft, isFalse);
        expect(d.isArchived, isFalse);
      }
    });

    test('ContentService agrupa documentos publicados por sección para los módulos del estudiante', () async {
      final contentService = ContentService();
      final grouped = await contentService.getPublishedDocumentsGroupedBySection('mod_contemporanea');

      expect(grouped.isNotEmpty, isTrue);
      expect(grouped.containsKey('9 de enero de 1964'), isTrue);

      final sectionDocs = grouped['9 de enero de 1964']!;
      expect(sectionDocs.isNotEmpty, isTrue);
      for (final doc in sectionDocs) {
        expect(doc.isPublished, isTrue);
      }
    });
  });

  group('4. Integración de Documentos Publicados con el Historiador IA', () {
    test('Indexación de texto de documento publicado y recuperación en motor RAG', () async {
      final indexer = DocumentIndexerService();
      await indexer.initialize();

      // Agregar texto de un nuevo documento publicado por el profesor
      final addedChunks = await indexer.addDocumentFromRawText(
        docId: 'doc_test_ascanio',
        documentTitle: 'Biografía Documentada de Ascanio Arosemena',
        sectionTitle: 'Mártires de Enero',
        text: 'Ascanio Arosemena Chávez nació en Panamá en 1944. Fue estudiante de la Escuela Profesional Isabel Herrera Obaldía. El 9 de enero de 1964 socorrió valientemente a los estudiantes heridos en la avenida 4 de Julio antes de caer abatido mortalmente por disparos zoneítas.',
      );

      expect(addedChunks, greaterThanOrEqualTo(1));
      expect(indexer.availableDocumentTitles.contains('Biografía Documentada de Ascanio Arosemena'), isTrue);

      final retrievalEngine = RetrievalEngine();
      final result = retrievalEngine.retrieve('Ascanio Arosemena Escuela Profesional');

      expect(result.hasSufficientEvidence, isTrue);
      expect(result.chunks.isNotEmpty, isTrue);
      final retrieved = result.chunks.firstWhere((c) => c.docId == 'doc_test_ascanio');
      expect(retrieved.documentTitle, equals('Biografía Documentada de Ascanio Arosemena'));
      expect(retrieved.text, contains('Isabel Herrera Obaldía'));
    });

    test('Despublicación retira inmediatamente los fragmentos del Historiador IA', () async {
      final indexer = DocumentIndexerService();
      await indexer.initialize();

      const docId = 'doc_test_despublicar';
      await indexer.addDocumentFromRawText(
        docId: docId,
        documentTitle: 'Documento que será retirado',
        sectionTitle: 'Tema Temporal',
        text: 'Contenido histórico temporal sobre la construcción del ferrocarril transístmico.',
      );

      expect(indexer.chunks.any((c) => c.docId == docId), isTrue);

      // Simular despublicación
      indexer.removeDocumentChunks(docId);

      expect(indexer.chunks.any((c) => c.docId == docId), isFalse);
    });
  });
}
