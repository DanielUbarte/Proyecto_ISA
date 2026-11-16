import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panama_historica/models/rag_chunk_model.dart';
import 'package:panama_historica/services/ai_service.dart';
import 'package:panama_historica/services/rag/document_indexer_service.dart';
import 'package:panama_historica/services/rag/rag_response_generator.dart';
import 'package:panama_historica/services/rag/retrieval_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DocumentIndexerService indexer;
  late RetrievalEngine retrievalEngine;
  late AIService aiService;

  setUpAll(() async {
    indexer = DocumentIndexerService();
    retrievalEngine = RetrievalEngine();
    aiService = AIService();

    // Cargar fragmentos reales del JSON del proyecto
    final jsonFile = File('assets/modules/contemporanea/documents/indexed_chunks.json');
    if (jsonFile.existsSync()) {
      final jsonContent = jsonFile.readAsStringSync();
      await indexer.initialize(customJsonContent: jsonContent);
    } else {
      await indexer.initialize();
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Checklist de Pruebas Unitarias - Historiador IA y Motor RAG', () {
    // 1. Validación de preguntas vacías o sin contenido sustantivo
    test('1. Validación de preguntas vacías retorna resultado insuficiente sin ejecutar búsquedas', () {
      final tokensEmpty = RetrievalEngine.tokenize('');
      expect(tokensEmpty, isEmpty);

      final tokensSpaces = RetrievalEngine.tokenize('    \n\t   ');
      expect(tokensSpaces, isEmpty);

      final tokensPunctuation = RetrievalEngine.tokenize('¿? ¡! ... ---');
      expect(tokensPunctuation, isEmpty);

      final result = retrievalEngine.retrieve('   ');
      expect(result.hasSufficientEvidence, isFalse);
      expect(result.chunks, isEmpty);
    });

    // 2. Consulta con evidencia documental existente
    test('2. Consulta válida sobre el 9 de enero recupera fragmentos con evidencia suficiente (score >= 3.2)', () {
      const question = '¿Por qué marcharon los estudiantes a la Escuela de Balboa?';
      final result = retrievalEngine.retrieve(question);

      expect(result.hasSufficientEvidence, isTrue);
      expect(result.chunks, isNotEmpty);
      expect(result.topScore, greaterThanOrEqualTo(3.2));
      expect(result.chunks.first.documentTitle, contains('9 de enero de 1964'));

      final response = RAGResponseGenerator.generate(
        question: question,
        retrievalResult: result,
      );

      expect(response.isAbstention, isFalse);
      expect(response.text, isNotEmpty);
      expect(response.references, isNotEmpty);
    });

    // 3. Consulta sin información disponible (Abstención estricta anti-alucinación)
    test('3. Consulta sobre temas ajenos al corpus documental provoca abstención estricta sin alucinación', () {
      const externalQuestion = '¿Quién ganó la Batalla de Waterloo entre Napoleón Bonaparte y el Duque de Wellington?';
      final result = retrievalEngine.retrieve(externalQuestion);

      expect(result.hasSufficientEvidence, isFalse);
      expect(result.chunks, isEmpty);

      final response = RAGResponseGenerator.generate(
        question: externalQuestion,
        retrievalResult: result,
      );

      expect(response.isAbstention, isTrue);
      expect(response.text, equals(RAGResponseGenerator.abstentionMessage));
      expect(response.references, isEmpty);
    });

    // 4. Generación estricta de abstención sin inventar datos
    test('4. Generación con resultado insuficiente retorna mensaje oficial de abstención y lista de referencias vacía', () {
      final insufficient = RetrievalResult.insufficient(normalizedQuery: 'tema_desconocido');
      final response = RAGResponseGenerator.generate(
        question: '¿Qué ocurrió con Albert Einstein en 1905?',
        retrievalResult: insufficient,
      );

      expect(response.isAbstention, isTrue);
      expect(response.text, contains('No encuentro información suficiente'));
      expect(response.references, isEmpty);
      expect(response.tags, contains('Sin fuentes internas'));
    });

    // 5. Descarte de términos hiper-genéricos por umbral BM25
    test('5. Pregunta con términos hiper-genéricos no supera el umbral de relevancia y es descartada', () {
      const genericQuery = '¿Qué ocurrió en aquel año en la historia durante ese tiempo?';
      final result = retrievalEngine.retrieve(genericQuery);

      expect(result.hasSufficientEvidence, isFalse);
      expect(result.chunks, isEmpty);
    });

    // 6. Comportamiento ante documentos sin indexar (Índice vacío)
    test('6. Consulta con índice vacío retorna insuficiente de forma segura sin excepciones', () {
      indexer.resetForTesting();
      expect(indexer.chunks, isEmpty);

      final result = retrievalEngine.retrieve('acuerdo Chiari-Kennedy bandera panameña');
      expect(result.hasSufficientEvidence, isFalse);
      expect(result.chunks, isEmpty);

      // Restaurar índice para las siguientes pruebas
      final jsonFile = File('assets/modules/contemporanea/documents/indexed_chunks.json');
      if (jsonFile.existsSync()) {
        indexer.initialize(customJsonContent: jsonFile.readAsStringSync());
      }
    });

    // 7. Generación y formato de referencias documentales verificables
    test('7. Respuestas fundamentadas incluyen referencias con título, página, sección y extracto textual', () {
      const question = '¿En qué consistía el acuerdo Chiari-Kennedy?';
      final result = retrievalEngine.retrieve(question);
      expect(result.hasSufficientEvidence, isTrue);

      final response = RAGResponseGenerator.generate(
        question: question,
        retrievalResult: result,
      );

      expect(response.references, isNotEmpty);
      for (final ref in response.references) {
        expect(ref.documentTitle, isNotEmpty);
        expect(ref.section, isNotEmpty);
        expect(ref.page, greaterThan(0));
        expect(ref.excerpt, isNotEmpty);
      }
    });

    // 8. Detección y manejo de información contradictoria (Contraste historiográfico)
    test('8. Detección de contraste historiográfico ante versiones encontradas entre testimonios y reportes oficiales', () {
      const chunkInstitutor = DocumentChunk(
        id: 'c_inst',
        docId: 'd1',
        documentTitle: 'El 9 de enero: lo que no me contaron',
        section: 'Gesta Patriótica',
        page: 15,
        text: 'Los estudiantes del Instituto Nacional denunciaron el desgarro de la bandera panameña y la agresión.',
      );

      const chunkZonians = DocumentChunk(
        id: 'c_zon',
        docId: 'd2',
        documentTitle: 'Reporte de la Zona',
        section: 'Informes Limítrofes',
        page: 20,
        text: 'La policía de la zona y los zonians sostuvieron que no se dio fuego de ametralladoras y justificaron la fuerza.',
      );

      const result = RetrievalResult(
        hasSufficientEvidence: true,
        chunks: [chunkInstitutor, chunkZonians],
        topScore: 6.5,
        normalizedQuery: 'bandera policia zonians',
      );

      final response = RAGResponseGenerator.generate(
        question: '¿Qué pasó con la bandera y la policía de la zona?',
        retrievalResult: result,
      );

      expect(response.text, contains('Nota historiográfica de contraste'));
      expect(response.text, contains('versiones encontradas'));
    });

    // 9. Deduplicación de referencias pertenecientes a la misma página
    test('9. Múltiples fragmentos de la misma página y documento son deduplicados en las referencias', () {
      const chunk1 = DocumentChunk(
        id: 'chunk_p11_a',
        docId: 'doc_tribaldos',
        documentTitle: 'El 9 de enero de 1964: lo que no me contaron',
        section: 'Introducción',
        page: 11,
        text: 'Los 200 estudiantes del Instituto Nacional marcharon pacíficamente.',
      );

      const chunk2 = DocumentChunk(
        id: 'chunk_p11_b',
        docId: 'doc_tribaldos',
        documentTitle: 'El 9 de enero de 1964: lo que no me contaron',
        section: 'Introducción',
        page: 11,
        text: 'En el tenso encuentro que siguió, la histórica bandera se desgarró.',
      );

      const result = RetrievalResult(
        hasSufficientEvidence: true,
        chunks: [chunk1, chunk2],
        topScore: 7.2,
        normalizedQuery: 'marcharon pacíficamente bandera',
      );

      final response = RAGResponseGenerator.generate(
        question: '¿Qué ocurrió en Balboa según la página 11?',
        retrievalResult: result,
      );

      // Deben deduplicarse a una sola referencia para la página 11
      expect(response.references.length, equals(1));
      expect(response.references.first.page, equals(11));
    });

    // 10. Idempotencia ante preguntas repetidas
    test('10. Preguntas idénticas enviadas consecutivamente generan respuestas y referencias consistentes', () async {
      const q = '¿Quién fue Ascanio Arosemena y cuál fue su papel el 9 de enero?';
      final res1 = await aiService.askHistorian(q);
      final res2 = await aiService.askHistorian(q);

      expect(res1.message, equals(res2.message));
      expect(res1.cardTitle, equals(res2.cardTitle));
      expect(res1.isAbstention, isFalse);
      expect(res2.isAbstention, isFalse);
    });

    // 11. Fallback automático ante fallos en servicios externos de IA
    test('11. Falla o ausencia de API externa activa transparentemente el generador local RAG estricto', () async {
      // Sin backend ni Gemini API configurados, askHistorian recurre al generador local
      final answer = await aiService.askHistorian('¿Cuáles fueron las consecuencias diplomáticas del 9 de enero?');

      expect(answer.sender, equals('ai'));
      expect(answer.message, contains('Ruptura de relaciones diplomáticas'));
      expect(answer.message, contains('Tratados Torrijos-Carter'));
      expect(answer.isAbstention, isFalse);
    });

    // 12. Normalización lingüística y filtrado de stopwords en español
    test('12. Normalización remueve acentos y puntuación, y tokenización descarta stopwords en español', () {
      const rawText = '¿CÓMO, CUÁNDO y DÓNDE ocurrió la RECLAMACIÓN patriótica de 1964?';
      final normalized = RetrievalEngine.normalize(rawText);

      expect(normalized, equals('como cuando y donde ocurrio la reclamacion patriotica de 1964'));

      final tokens = RetrievalEngine.tokenize(rawText);
      expect(tokens, contains('ocurrio'));
      expect(tokens, contains('reclamacion'));
      expect(tokens, contains('patriotica'));
      expect(tokens, contains('1964'));

      // Las stopwords en español deben ser filtradas
      expect(tokens, isNot(contains('como')));
      expect(tokens, isNot(contains('cuando')));
      expect(tokens, isNot(contains('donde')));
      expect(tokens, isNot(contains('la')));
      expect(tokens, isNot(contains('de')));
    });

    // 13. [DEFECTO DETECTADO] Concurrencia: Solicitudes simultáneas intercalan mensajes en _messages sin exclusión mutua
    test('13. [DEFECTO DETECTADO] Consultas simultáneas a askHistorian intercalan mensajes de usuario corrompiendo los turnos del chat', () async {
      // Forzar estado no inicializado para evaluar la brecha asíncrona de inicialización/red
      indexer.resetForTesting();

      // Iniciar dos consultas simultáneas
      final future1 = aiService.askHistorian('Consulta Concurrente Alfa');
      final future2 = aiService.askHistorian('Consulta Concurrente Beta');

      await Future.wait([future1, future2]);

      final allMsgs = aiService.messages;
      final idxAlfa = allMsgs.lastIndexWhere((m) => m.message == 'Consulta Concurrente Alfa');

      // En un chat transaccional atómico por turnos, a la pregunta de Alfa debe seguirle inmediatamente su respuesta
      // Al existir una brecha asíncrona sin cola de exclusión mutua, userMsg_Beta se intercala antes de aiResponse_Alfa
      final nextMsg = allMsgs[idxAlfa + 1];

      expect(
        nextMsg.sender,
        equals('ai'),
        reason: 'AIService carece de cola de exclusión mutua; dos preguntas concurrentes intercalan mensajes de usuario desfasando las respuestas',
      );
    });

    // 14. [DEFECTO DETECTADO] Respuestas fuera de orden: Falta de correlación o número de secuencia (correlationId / turnId)
    test('14. [DEFECTO DETECTADO] ChatMessageModel carece de identificador de correlación o turno para respuestas asíncronas fuera de orden', () async {
      final msg = await aiService.askHistorian('Consulta con validación de secuencia');

      // Comprobar si ChatMessageModel posee campo correlationId o replyToId para asociar respuestas a preguntas
      final hasCorrelation = msg.runtimeType.toString().contains('Correlated') ||
          msg.toString().contains('replyToId');

      expect(
        hasCorrelation,
        isTrue,
        reason: 'ChatMessageModel no incluye correlationId ni replyToId, impidiendo ordenar respuestas cuando llegan fuera de orden',
      );
    });

    // 15. [DEFECTO DETECTADO] Cancelación: Falta de señal de aborto o cancelación (CancellationToken) en peticiones en vuelo
    test('15. [DEFECTO DETECTADO] AIService carece de mecanismo para cancelar consultas asíncronas en vuelo al abandonar pantalla', () {
      // Verificamos si AIService implementa método de cancelación o soporte para CancellationToken
      final hasCancellationMethod = aiService.runtimeType.toString().contains('Cancellable');

      expect(
        hasCancellationMethod,
        isTrue,
        reason: 'AIService no expone métodos para cancelar peticiones HTTP ni consultas RAG en vuelo cuando el estudiante sale de la pantalla',
      );
    });
  });
}
