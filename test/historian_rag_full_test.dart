// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:panama_historica/services/ai_service.dart';
import 'package:panama_historica/services/rag/document_indexer_service.dart';
import 'package:panama_historica/services/rag/rag_response_generator.dart';

void main() {
  setUpAll(() async {
    final file = File('assets/modules/contemporanea/documents/indexed_chunks.json');
    final jsonContent = file.readAsStringSync();
    await DocumentIndexerService().initialize(customJsonContent: jsonContent);
  });

  group('Historiador IA - Pruebas de Recuperación y Abstención Documental', () {
    test('Pregunta documentada: 9 de enero y Balboa High School', () async {
      final aiService = AIService();
      final response = await aiService.askHistorian(
        '¿Por qué marcharon los estudiantes a la escuela secundaria de Balboa?',
      );

      expect(response.isAbstention, isFalse);
      expect(response.message, isNot(contains(RAGResponseGenerator.abstentionMessage)));
      expect(response.hasReferences, isTrue);

      final ref = response.references!.first;
      expect(ref.documentTitle, contains('Wendy Tribaldos'));
      expect(ref.page, isPositive);
      expect(ref.section.isNotEmpty, isTrue);
      expect(ref.excerpt.isNotEmpty, isTrue);

      print('--- Respuesta documentada ---');
      print('Mensaje: ${response.message.substring(0, 150)}...');
      print('Fuente: ${ref.documentTitle} | Pág. ${ref.page} | Sección: ${ref.section}');
      print('Cita: ${ref.excerpt}');
    });

    test('Pregunta documentada: Acuerdo Chiari-Kennedy sobre banderas', () async {
      final aiService = AIService();
      final response = await aiService.askHistorian(
        '¿Qué establecía el acuerdo Chiari-Kennedy sobre la izada de la bandera panameña?',
      );

      expect(response.isAbstention, isFalse);
      expect(response.hasReferences, isTrue);
      expect(response.references!.first.documentTitle, contains('Wendy Tribaldos'));
    });

    test('Pregunta no documentada: Batalla de Waterloo (Abstención estricta)', () async {
      final aiService = AIService();
      final response = await aiService.askHistorian(
        '¿Quién comandó las tropas británicas en la batalla de Waterloo?',
      );

      expect(response.isAbstention, isTrue);
      expect(
        response.message,
        equals(
          'No encuentro información suficiente sobre este tema en los libros y documentos disponibles en Panamá Histórica. Intenta consultar otro documento o formular otra pregunta relacionada con el contenido disponible.',
        ),
      );
      // No debe contener referencias inventadas
      expect(response.references, isNull);
    });

    test('Pregunta no documentada: Inteligencia Artificial y Machine Learning', () async {
      final aiService = AIService();
      final response = await aiService.askHistorian(
        'Explícame cómo funciona un transformador de atención en redes neuronales',
      );

      expect(response.isAbstention, isTrue);
      expect(
        response.message,
        equals(
          'No encuentro información suficiente sobre este tema en los libros y documentos disponibles en Panamá Histórica. Intenta consultar otro documento o formular otra pregunta relacionada con el contenido disponible.',
        ),
      );
      expect(response.references, isNull);
    });

    test('Pregunta con palabras genéricas sin contexto documental', () async {
      final aiService = AIService();
      final response = await aiService.askHistorian('¿Qué pasó en el año 1815 en Francia?');

      expect(response.isAbstention, isTrue);
      expect(
        response.message,
        equals(
          'No encuentro información suficiente sobre este tema en los libros y documentos disponibles en Panamá Histórica. Intenta consultar otro documento o formular otra pregunta relacionada con el contenido disponible.',
        ),
      );
    });
  });
}
