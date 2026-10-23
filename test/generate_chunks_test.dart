// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('Generate full indexed chunks from PDF', () async {
    final file = File('assets/modules/contemporanea/documents/PDF_9 ENERO 1964_WTRIBALDOS_2023.pdf');
    final bytes = file.readAsBytesSync();
    final doc = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(doc);

    final List<Map<String, dynamic>> chunks = [];
    const docTitle = 'El 9 de enero de 1964: lo que no me contaron (Wendy Tribaldos, 2023)';

    String getSectionName(int page) {
      if (page < 10) return 'Preliminares y Dedicatoria';
      if (page <= 14) return 'Introducción: un porqué';
      if (page <= 24) return 'El contexto';
      if (page <= 42) return 'Arropados bajo una enseña';
      if (page <= 122) return 'Los sucesos del 9, 10 y 11 de enero de 1964';
      if (page <= 146) return 'La memoria perdida… y reinventada';
      if (page <= 150) return 'Concluir… para comenzar';
      if (page <= 168) return 'Testimonios, protagonistas y mártires';
      if (page <= 174) return 'Cronología de los acontecimientos';
      return 'Bibliografía y fuentes documentales';
    }

    for (int i = 0; i < doc.pages.count; i++) {
      final pageNum = i + 1;
      final rawText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      final cleanedText = rawText
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .trim();

      if (cleanedText.isEmpty) continue;

      // Filter out pure header/footer lines if repeated
      final lines = cleanedText.split('\n');
      final contentLines = <String>[];
      for (var line in lines) {
        final trimmed = line.trim();
        // Remove standard running headers like "EL 9 DE ENERO DE 1964 | WENDY TRIBALDOS"
        if (trimmed == 'EL 9 DE ENERO DE 1964 | WENDY TRIBALDOS' ||
            trimmed == '1964lo que no me contaronel 9 de enero de' ||
            trimmed == '$pageNum') {
          continue;
        }
        if (trimmed.isNotEmpty) {
          contentLines.add(trimmed);
        }
      }

      final pageBody = contentLines.join('\n');
      if (pageBody.trim().length < 20) continue;

      // Split into paragraphs or chunks of roughly 500-900 chars if page is long
      final paragraphs = pageBody.split(RegExp(r'\n\s*\n'));
      var currentChunk = '';
      int chunkIndex = 1;

      void addChunk(String text) {
        final trimmed = text.trim();
        if (trimmed.length > 30) {
          chunks.add({
            'id': 'tribaldos_p${pageNum}_c$chunkIndex',
            'doc_id': 'pdf_tribaldos_1964',
            'document_title': docTitle,
            'section': getSectionName(pageNum),
            'page': pageNum,
            'text': trimmed,
          });
          chunkIndex++;
        }
      }

      for (var para in paragraphs) {
        final p = para.trim().replaceAll('\n', ' ');
        if (p.isEmpty) continue;

        if ((currentChunk.length + p.length) < 800) {
          currentChunk = currentChunk.isEmpty ? p : '$currentChunk $p';
        } else {
          if (currentChunk.isNotEmpty) {
            addChunk(currentChunk);
          }
          currentChunk = p;
        }
      }
      if (currentChunk.isNotEmpty) {
        addChunk(currentChunk);
      }
    }

    doc.dispose();

    print('Total chunks generated: ${chunks.length}');
    final outFile = File('assets/modules/contemporanea/documents/indexed_chunks.json');
    await outFile.writeAsString(jsonEncode(chunks), flush: true);
    print('Saved to: ${outFile.path} (Size: ${outFile.lengthSync()} bytes)');
  });
}
