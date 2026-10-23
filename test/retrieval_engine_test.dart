// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:panama_historica/services/rag/document_indexer_service.dart';
import 'package:panama_historica/services/rag/retrieval_engine.dart';

void main() {
  setUpAll(() async {
    final file = File('assets/modules/contemporanea/documents/indexed_chunks.json');
    final jsonContent = file.readAsStringSync();
    await DocumentIndexerService().initialize(customJsonContent: jsonContent);
  });

  test('Retrieval finds evidence for 9 de enero Balboa High School', () {
    final engine = RetrievalEngine();
    final result = engine.retrieve('¿Por qué marcharon los estudiantes a la Escuela de Balboa?');

    expect(result.hasSufficientEvidence, isTrue);
    expect(result.chunks.isNotEmpty, isTrue);
    print('Found ${result.chunks.length} chunks. Top score: ${result.topScore}');
    print('First chunk: Page ${result.chunks.first.page} - ${result.chunks.first.text.substring(0, 100)}...');
  });

  test('Retrieval finds evidence for acuerdo Chiari-Kennedy', () {
    final engine = RetrievalEngine();
    final result = engine.retrieve('¿En qué consistía el acuerdo Chiari Kennedy sobre las banderas?');

    expect(result.hasSufficientEvidence, isTrue);
    expect(result.chunks.isNotEmpty, isTrue);
    print('Found ${result.chunks.length} chunks. Top score: ${result.topScore}');
  });

  test('Retrieval abstains when question is outside available documents (e.g. Waterloo)', () {
    final engine = RetrievalEngine();
    final result = engine.retrieve('¿Quién ganó la batalla de Waterloo y en qué año ocurrió?');

    expect(result.hasSufficientEvidence, isFalse);
    expect(result.chunks.isEmpty, isTrue);
  });

  test('Retrieval abstains when question is about unrelated modern tech', () {
    final engine = RetrievalEngine();
    final result = engine.retrieve('¿Cómo se programa una red neuronal convolucional en Python?');

    expect(result.hasSufficientEvidence, isFalse);
    expect(result.chunks.isEmpty, isTrue);
  });
}
