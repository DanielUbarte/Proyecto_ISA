import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../models/historical_scene_model.dart';
import '../../models/rag_chunk_model.dart';

/// Servicio responsable de gestionar, procesar e indexar todos los libros y
/// documentos históricos disponibles dentro de la aplicación Panamá Histórica.
class DocumentIndexerService {
  static final DocumentIndexerService _instance = DocumentIndexerService._internal();
  factory DocumentIndexerService() => _instance;
  DocumentIndexerService._internal();

  final List<DocumentChunk> _chunks = [];
  final Set<String> _documentTitles = {};
  bool _isInitialized = false;

  List<DocumentChunk> get chunks => List.unmodifiable(_chunks);
  List<String> get availableDocumentTitles => _documentTitles.toList();
  bool get isInitialized => _isInitialized;

  /// Restablece el índice para pruebas unitarias.
  void resetForTesting() {
    _chunks.clear();
    _documentTitles.clear();
    _isInitialized = false;
  }

  /// Inicializa el índice cargando los documentos estructurados y escenas históricas locales.
  Future<void> initialize({String? customJsonContent}) async {
    if (_isInitialized) return;

    try {
      String jsonString;
      if (customJsonContent != null) {
        jsonString = customJsonContent;
      } else {
        jsonString = await rootBundle.loadString(
          'assets/modules/contemporanea/documents/indexed_chunks.json',
        );
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          final chunk = DocumentChunk.fromJson(item);
          _chunks.add(chunk);
          _documentTitles.add(chunk.documentTitle);
        }
      }
    } catch (e) {
      // Si ocurre un error al cargar el asset JSON, se continúa para cargar escenas locales
    }

    // Incorporar también las escenas históricas locales de Panamá Contemporánea
    final scenes = HistoricalScene.getContemporaneaScenes();
    for (final scene in scenes) {
      final docTitle = scene.source.contains('Wendy Tribaldos')
          ? scene.source
          : '${scene.source} (Wendy Tribaldos)';
      final chunk = DocumentChunk(
        id: 'scene_${scene.id}',
        docId: 'scene_${scene.id}',
        documentTitle: docTitle,
        section: scene.period,
        page: _parsePageNumber(scene.sourcePage),
        text: '${scene.title}. ${scene.text}',
      );
      _chunks.add(chunk);
      _documentTitles.add(docTitle);
    }

    _isInitialized = true;
  }

  /// Permite incorporar nuevos documentos PDF en tiempo de ejecución o desde recursos locales
  /// extrayendo su texto página por página y generando fragmentos manejables con metadatos.
  Future<int> addDocumentFromPdfBytes({
    required Uint8List pdfBytes,
    required String documentTitle,
    required String docId,
  }) async {
    final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    int addedChunks = 0;

    try {
      for (int i = 0; i < document.pages.count; i++) {
        final pageNum = i + 1;
        final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i).trim();
        if (pageText.isEmpty) continue;

        final paragraphs = pageText.split(RegExp(r'\n\s*\n'));
        var currentChunk = '';
        int chunkIdx = 1;

        for (final p in paragraphs) {
          final cleanP = p.trim().replaceAll('\n', ' ');
          if (cleanP.isEmpty) continue;

          if ((currentChunk.length + cleanP.length) < 800) {
            currentChunk = currentChunk.isEmpty ? cleanP : '$currentChunk $cleanP';
          } else {
            if (currentChunk.isNotEmpty) {
              _chunks.add(DocumentChunk(
                id: '${docId}_p${pageNum}_c$chunkIdx',
                docId: docId,
                documentTitle: documentTitle,
                section: 'Página $pageNum',
                page: pageNum,
                text: currentChunk,
              ));
              chunkIdx++;
              addedChunks++;
            }
            currentChunk = cleanP;
          }
        }

        if (currentChunk.isNotEmpty) {
          _chunks.add(DocumentChunk(
            id: '${docId}_p${pageNum}_c$chunkIdx',
            docId: docId,
            documentTitle: documentTitle,
            section: 'Página $pageNum',
            page: pageNum,
            text: currentChunk,
          ));
          addedChunks++;
        }
      }

      _documentTitles.add(documentTitle);
    } finally {
      document.dispose();
    }

    return addedChunks;
  }

  /// Incorpora fragmentos al índice a partir de texto plano extraído de un documento o recurso educativo.
  Future<int> addDocumentFromRawText({
    required String docId,
    required String documentTitle,
    required String sectionTitle,
    required String text,
  }) async {
    // Remover fragmentos previos del mismo documento para evitar duplicidad
    removeDocumentChunks(docId);

    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    int addedCount = 0;
    var currentChunk = '';
    int chunkIdx = 1;

    for (final p in paragraphs) {
      final clean = p.trim().replaceAll('\n', ' ');
      if (clean.isEmpty) continue;

      if ((currentChunk.length + clean.length) < 800) {
        currentChunk = currentChunk.isEmpty ? clean : '$currentChunk $clean';
      } else {
        if (currentChunk.isNotEmpty) {
          _chunks.add(DocumentChunk(
            id: '${docId}_c$chunkIdx',
            docId: docId,
            documentTitle: documentTitle,
            section: sectionTitle,
            page: 1,
            text: currentChunk,
          ));
          chunkIdx++;
          addedCount++;
        }
        currentChunk = clean;
      }
    }

    if (currentChunk.isNotEmpty) {
      _chunks.add(DocumentChunk(
        id: '${docId}_c$chunkIdx',
        docId: docId,
        documentTitle: documentTitle,
        section: sectionTitle,
        page: 1,
        text: currentChunk,
      ));
      addedCount++;
    }

    _documentTitles.add(documentTitle);
    return addedCount;
  }

  /// Retira todos los fragmentos asociados a un documento despublicado, archivado o eliminado.
  void removeDocumentChunks(String docId) {
    _chunks.removeWhere((chunk) => chunk.docId == docId);
    _recomputeDocumentTitles();
  }

  void _recomputeDocumentTitles() {
    _documentTitles.clear();
    for (final c in _chunks) {
      _documentTitles.add(c.documentTitle);
    }
  }

  int _parsePageNumber(String sourcePage) {
    final match = RegExp(r'\d+').firstMatch(sourcePage);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 1;
    }
    return 1;
  }
}
