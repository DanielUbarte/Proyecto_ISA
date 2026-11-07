import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/document_model.dart';
import 'rag/document_indexer_service.dart';

/// Servicio de almacenamiento persistente y gestión de documentos educativos.
/// Garantiza la persistencia local en dispositivo, copiado de archivos físicos y
/// sincronización compartida con los módulos del estudiante y el Historiador IA.
class DocumentStorageService {
  static final DocumentStorageService _instance = DocumentStorageService._internal();
  factory DocumentStorageService() => _instance;
  DocumentStorageService._internal();

  static const String _storageKey = 'ph_educational_documents_v1';
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB
  static int _idCounter = 0;

  final DocumentIndexerService _indexerService = DocumentIndexerService();

  List<EducationalDocumentModel> _documents = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Restablece el estado interno para pruebas unitarias.
  void resetForTesting() {
    _documents = [];
    _isInitialized = false;
  }

  /// Inicializa el servicio, carga documentos almacenados o crea los predeterminados.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(jsonString);
        _documents = list
            .map((item) => EducationalDocumentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _documents = _getInitialSeedDocuments();
        await _persistDocuments();
      }
    } else {
      _documents = _getInitialSeedDocuments();
      await _persistDocuments();
    }

    _isInitialized = true;

    // Asegurar que los documentos publicados queden indexados en el Historiador IA
    for (final doc in _documents.where((d) => d.isPublished && !d.isIndexed)) {
      await indexDocumentForAI(doc.id);
    }
  }

  /// Lista completa de documentos en la biblioteca.
  Future<List<EducationalDocumentModel>> getAllDocuments() async {
    if (!_isInitialized) await initialize();
    return List.unmodifiable(_documents);
  }

  /// Filtra documentos creados por un docente específico.
  Future<List<EducationalDocumentModel>> getDocumentsForTeacher(String teacherId) async {
    if (!_isInitialized) await initialize();
    return _documents.where((d) => d.teacherId == teacherId).toList();
  }

  /// Retorna exclusivamente los documentos publicados de un módulo y sección específicos
  /// para la consulta del estudiante.
  Future<List<EducationalDocumentModel>> getPublishedDocumentsForSection({
    required String moduleId,
    required String sectionTitle,
  }) async {
    if (!_isInitialized) await initialize();

    final cleanSection = sectionTitle.toLowerCase().trim();

    return _documents.where((d) {
      if (!d.isPublished) return false;
      if (d.moduleId != moduleId) return false;
      return d.sectionTitle.toLowerCase().trim() == cleanSection ||
          d.sectionId.toLowerCase().trim() == cleanSection;
    }).toList();
  }

  /// Retorna todos los documentos publicados de un módulo histórico.
  Future<List<EducationalDocumentModel>> getPublishedDocumentsForModule(String moduleId) async {
    if (!_isInitialized) await initialize();
    return _documents.where((d) => d.isPublished && d.moduleId == moduleId).toList();
  }

  /// Obtiene la lista de secciones únicas registradas para un módulo.
  Future<List<String>> getSectionsForModule(String moduleId) async {
    if (!_isInitialized) await initialize();

    final defaultSections = <String>[
      '9 de enero de 1964',
      'Movimiento Inquilinario de 1925',
      'Tratados Torrijos-Carter de 1977',
      'Otros acontecimientos',
    ];

    final customSections = _documents
        .where((d) => d.moduleId == moduleId)
        .map((d) => d.sectionTitle)
        .toSet();

    final result = <String>{...defaultSections, ...customSections}.toList();
    result.sort();
    return result;
  }

  /// Agrega un nuevo documento educativo con validaciones completas y guardado permanente.
  Future<EducationalDocumentModel> addDocument({
    required String title,
    required String description,
    required String author,
    required String moduleId,
    required String moduleTitle,
    required String sectionTitle,
    required String sourceFilePath,
    required String fileName,
    required int fileSizeBytes,
    required String teacherId,
    required String teacherName,
    DocumentPublicationStatus status = DocumentPublicationStatus.draft,
    Uint8List? fileBytes,
  }) async {
    if (!_isInitialized) await initialize();

    // 1. Validaciones obligatorias
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw Exception('El título del documento es obligatorio.');
    }

    if (author.trim().isEmpty) {
      throw Exception('El autor o fuente del documento es obligatorio.');
    }

    if (moduleId.trim().isEmpty || sectionTitle.trim().isEmpty) {
      throw Exception('Debe asociar el documento a un módulo histórico y una sección temática.');
    }

    final ext = _extractExtension(fileName);
    final allowedExts = {'pdf', 'jpg', 'jpeg', 'png', 'jfif', 'webp'};
    if (!allowedExts.contains(ext)) {
      throw Exception('Formato de archivo incompatible ($ext). Solo se admiten archivos PDF e imágenes (JPG, PNG).');
    }

    if (fileSizeBytes <= 0) {
      throw Exception('El archivo seleccionado está vacío.');
    }

    if (fileSizeBytes > maxFileSizeBytes) {
      throw Exception('El archivo excede el tamaño máximo permitido de 25 MB.');
    }

    // 2. Validación de duplicados
    final isDuplicate = _documents.any((d) =>
        d.moduleId == moduleId &&
        d.sectionTitle.toLowerCase().trim() == sectionTitle.toLowerCase().trim() &&
        (d.title.toLowerCase().trim() == cleanTitle.toLowerCase() ||
            d.fileName.toLowerCase().trim() == fileName.toLowerCase().trim()));

    if (isDuplicate) {
      throw Exception('Ya existe un documento con este título o nombre de archivo en la misma sección.');
    }

    // 3. Copiado seguro del archivo a almacenamiento permanente de la aplicación
    final fileType = ext == 'pdf' ? 'pdf' : 'image';
    final savedPath = await _saveFileLocally(
      sourceFilePath: sourceFilePath,
      fileName: fileName,
      fileBytes: fileBytes,
    );

    final newId = 'doc_${DateTime.now().microsecondsSinceEpoch}_${++_idCounter}';
    final sectionId = 'sec_${sectionTitle.replaceAll(RegExp(r'\s+'), '_').toLowerCase()}';

    var doc = EducationalDocumentModel(
      id: newId,
      fileName: fileName,
      title: cleanTitle,
      description: description.trim(),
      author: author.trim(),
      createdAt: DateTime.now(),
      teacherId: teacherId,
      teacherName: teacherName,
      moduleId: moduleId,
      moduleTitle: moduleTitle,
      sectionId: sectionId,
      sectionTitle: sectionTitle.trim(),
      status: status,
      filePath: savedPath,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      isIndexed: false,
    );

    _documents.add(doc);
    await _persistDocuments();

    // Si fue creado como publicado, procesar de inmediato su texto e indexarlo para el Historiador IA
    if (doc.isPublished) {
      doc = await indexDocumentForAI(doc.id) ?? doc;
    }

    return doc;
  }

  /// Actualiza los metadatos de un documento existente.
  Future<EducationalDocumentModel> updateDocument(EducationalDocumentModel updated) async {
    if (!_isInitialized) await initialize();

    final index = _documents.indexWhere((d) => d.id == updated.id);
    if (index == -1) {
      throw Exception('Documento no encontrado.');
    }

    if (updated.title.trim().isEmpty) {
      throw Exception('El título del documento no puede estar vacío.');
    }

    _documents[index] = updated;
    await _persistDocuments();

    if (updated.isPublished && !updated.isIndexed) {
      await indexDocumentForAI(updated.id);
    } else if (!updated.isPublished && updated.isIndexed) {
      // Si pasa a borrador o archivado, remover del índice del Historiador IA
      _indexerService.removeDocumentChunks(updated.id);
      _documents[index] = updated.copyWith(isIndexed: false);
      await _persistDocuments();
    }

    return _documents[index];
  }

  /// Cambia el estado de publicación (Borrador, Publicado, Archivado).
  Future<EducationalDocumentModel> setPublicationStatus(
    String documentId,
    DocumentPublicationStatus newStatus,
  ) async {
    if (!_isInitialized) await initialize();

    final index = _documents.indexWhere((d) => d.id == documentId);
    if (index == -1) {
      throw Exception('Documento no encontrado.');
    }

    final current = _documents[index];

    // Validar antes de publicar que tenga información completa
    if (newStatus == DocumentPublicationStatus.published) {
      if (current.title.trim().isEmpty ||
          current.moduleId.trim().isEmpty ||
          current.sectionTitle.trim().isEmpty) {
        throw Exception('El documento debe contar con título, módulo y sección válidos antes de ser publicado.');
      }
    }

    final updated = current.copyWith(status: newStatus);
    _documents[index] = updated;
    await _persistDocuments();

    if (newStatus == DocumentPublicationStatus.published) {
      final indexed = await indexDocumentForAI(documentId);
      return indexed ?? updated;
    } else {
      // Al despublicar o archivar, retirar del índice del Historiador IA
      _indexerService.removeDocumentChunks(documentId);
      _documents[index] = updated.copyWith(isIndexed: false);
      await _persistDocuments();
      return _documents[index];
    }
  }

  /// Elimina un documento de la biblioteca.
  Future<void> deleteDocument(String documentId) async {
    if (!_isInitialized) await initialize();

    final index = _documents.indexWhere((d) => d.id == documentId);
    if (index == -1) return;

    final doc = _documents[index];
    _indexerService.removeDocumentChunks(documentId);

    // Intentar eliminar archivo local si no es un asset
    if (!doc.filePath.startsWith('assets/')) {
      try {
        final file = File(doc.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    _documents.removeAt(index);
    await _persistDocuments();
  }

  /// Extrae el texto del documento e indexa sus fragmentos en el motor RAG del Historiador IA.
  Future<EducationalDocumentModel?> indexDocumentForAI(String documentId) async {
    final index = _documents.indexWhere((d) => d.id == documentId);
    if (index == -1) return null;

    final doc = _documents[index];
    if (!doc.isPublished) return doc; // Solo indexar documentos publicados

    String? fullText;

    if (doc.isPdf) {
      fullText = await _extractPdfText(doc.filePath);
      if (fullText != null && fullText.isNotEmpty) {
        await _indexerService.addDocumentFromRawText(
          docId: doc.id,
          documentTitle: doc.title,
          sectionTitle: doc.sectionTitle,
          text: fullText,
        );
      }
    } else {
      // Imágenes históricas: indexar con su descripción y fuente histórica estructurada
      fullText = '${doc.title}. ${doc.description}. Fuente histórica: ${doc.author}.';
      await _indexerService.addDocumentFromRawText(
        docId: doc.id,
        documentTitle: doc.title,
        sectionTitle: doc.sectionTitle,
        text: fullText,
      );
    }

    final updated = doc.copyWith(
      isIndexed: true,
      extractedText: fullText,
    );
    _documents[index] = updated;
    await _persistDocuments();
    return updated;
  }

  /// Extrae texto de un archivo PDF usando Syncfusion.
  Future<String?> _extractPdfText(String filePath) async {
    try {
      Uint8List bytes;
      if (filePath.startsWith('assets/')) {
        final data = await rootBundle.load(filePath);
        bytes = data.buffer.asUint8List();
      } else {
        final file = File(filePath);
        if (!await file.exists()) return null;
        bytes = await file.readAsBytes();
      }

      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return text;
    } catch (_) {
      return null;
    }
  }

  /// Guarda una copia del archivo seleccionado en el directorio de la aplicación.
  Future<String> _saveFileLocally({
    required String sourceFilePath,
    required String fileName,
    Uint8List? fileBytes,
  }) async {
    // Si ya es un asset del proyecto, conservar su ruta relativa
    if (sourceFilePath.startsWith('assets/')) {
      return sourceFilePath;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/educational_documents');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      final safeName = '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(RegExp(r'[^\w\.-]'), '_')}';
      final targetFile = File('${docsDir.path}/$safeName');

      if (fileBytes != null && fileBytes.isNotEmpty) {
        await targetFile.writeAsBytes(fileBytes, flush: true);
      } else if (sourceFilePath.isNotEmpty) {
        final source = File(sourceFilePath);
        if (await source.exists()) {
          await source.copy(targetFile.path);
        } else {
          return sourceFilePath;
        }
      }

      return targetFile.path;
    } catch (_) {
      // Fallback a la ruta de origen en caso de entornos de prueba o permisos
      return sourceFilePath;
    }
  }

  String _extractExtension(String pathOrName) {
    final clean = pathOrName.split('?').first.toLowerCase();
    final parts = clean.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  Future<void> _persistDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _documents.map((d) => d.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// Documentos iniciales del repositorio (material curricular preexistente de Panamá Contemporánea).
  List<EducationalDocumentModel> _getInitialSeedDocuments() {
    return [
      EducationalDocumentModel(
        id: 'seed_doc_01',
        fileName: 'PDF_9 ENERO 1964_WTRIBALDOS_2023.pdf',
        title: 'El 9 de enero de 1964: lo que no me contaron',
        description: 'Investigación histórica completa y fuentes testimoniales sobre la gesta patriótica de 1964.',
        author: 'Wendy Tribaldos (2.ª edición ampliada, 2023)',
        createdAt: DateTime(2024, 1, 9),
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionId: 'sec_01',
        sectionTitle: '9 de enero de 1964',
        status: DocumentPublicationStatus.published,
        filePath: 'assets/modules/contemporanea/documents/PDF_9 ENERO 1964_WTRIBALDOS_2023.pdf',
        fileType: 'pdf',
        fileSizeBytes: 24500000,
        isIndexed: true,
      ),
      EducationalDocumentModel(
        id: 'seed_doc_02',
        fileName: 'martires-panama.jpg',
        title: 'Mártires de Panamá - Homenaje a la Soberanía',
        description: 'Fotografía documental del monumento y memoria a los mártires de la gesta del 9 de enero.',
        author: 'Archivo Histórico Nacional',
        createdAt: DateTime(2024, 1, 9),
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionId: 'sec_01',
        sectionTitle: '9 de enero de 1964',
        status: DocumentPublicationStatus.published,
        filePath: 'assets/modules/contemporanea/images/martires-panama.jpg',
        fileType: 'image',
        fileSizeBytes: 450000,
        isIndexed: true,
      ),
      EducationalDocumentModel(
        id: 'seed_doc_03',
        fileName: 'martires-panama-2.jpg',
        title: 'Mártires de Panamá - Registro Gráfico',
        description: 'Registro histórico fotográfico de las movilizaciones y avenidas limítrofes en 1964.',
        author: 'Patrimonio Histórico de Panamá',
        createdAt: DateTime(2024, 1, 9),
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionId: 'sec_01',
        sectionTitle: '9 de enero de 1964',
        status: DocumentPublicationStatus.published,
        filePath: 'assets/modules/contemporanea/images/martires-panama-2.jpg',
        fileType: 'image',
        fileSizeBytes: 520000,
        isIndexed: true,
      ),
      EducationalDocumentModel(
        id: 'seed_doc_04',
        fileName: 'martires.jfif',
        title: 'Fotografía Histórica de los Mártires',
        description: 'Retratos e imágenes conmemorativas de los jóvenes patriotas.',
        author: 'Comisión de Monumentos Históricos',
        createdAt: DateTime(2024, 1, 9),
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionId: 'sec_01',
        sectionTitle: '9 de enero de 1964',
        status: DocumentPublicationStatus.published,
        filePath: 'assets/modules/contemporanea/images/martires.jfif',
        fileType: 'image',
        fileSizeBytes: 380000,
        isIndexed: true,
      ),
    ];
  }
}
