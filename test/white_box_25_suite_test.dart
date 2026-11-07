import 'dart:io';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:panama_historica/services/ai_service.dart';
import 'package:panama_historica/services/auth_service.dart';
import 'package:panama_historica/services/progress_service.dart';
import 'package:panama_historica/services/rag/document_indexer_service.dart';
import 'package:panama_historica/services/rag/rag_response_generator.dart';
import 'package:panama_historica/services/rag/retrieval_engine.dart';
import 'package:panama_historica/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configuración del mock de FlutterTts para llamadas de MethodChannel
  void setupMockTts({String? failingMethod}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async {
        if (failingMethod != null && methodCall.method == failingMethod) {
          throw PlatformException(
            code: 'TTS_HARDWARE_ERROR',
            message: 'Fallo simulado en el canal nativo de FlutterTts para $failingMethod',
          );
        }
        return 1;
      },
    );
  }

  setUpAll(() async {
    // Configurar SharedPreferences mock para pruebas
    SharedPreferences.setMockInitialValues({});

    // Cargar e indexar los fragmentos documentales para el Historiador IA
    final file = File('assets/modules/contemporanea/documents/indexed_chunks.json');
    if (file.existsSync()) {
      final jsonContent = file.readAsStringSync();
      await DocumentIndexerService().initialize(customJsonContent: jsonContent);
    }
  });

  setUp(() {
    setupMockTts();
  });

  // ===========================================================================
  // GRUPO 1: MÓDULO FUNCIONAL 1 - NARRACIÓN DE CONTENIDOS (TTSService)
  // Casos TC-01 a TC-10
  // ===========================================================================
  group('Módulo Funcional 1: Narración de Contenidos (TTSService)', () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
      ttsService.stop();
    });

    test('TC-01: Reproducción inicial de narración con parámetros válidos', () async {
      // Camino: _isTTSEnabled == true && text no vacío, _isPaused == false
      expect(ttsService.isPaused, isFalse);
      expect(ttsService.isPlaying, isFalse);

      await ttsService.speak(
        'El 9 de enero de 1964 los estudiantes marcharon pacíficamente.',
        sceneId: 'escena_01',
        durationSeconds: 120,
      );

      expect(ttsService.isPlaying, isTrue);
      expect(ttsService.isPaused, isFalse);
      expect(ttsService.currentSceneId, 'escena_01');
      expect(ttsService.totalDurationSeconds, 120);
      expect(ttsService.elapsedSeconds, 0);
      expect(ttsService.progress, 0.0);
    });

    test('TC-02: Rechazo de reproducción con texto vacío o compuesto solo por espacios', () async {
      // Camino: Línea 89 -> if (!_isTTSEnabled || text.trim().isEmpty) return;
      await ttsService.speak('   ', sceneId: 'escena_01');

      expect(ttsService.isPlaying, isFalse);
      expect(ttsService.currentSceneId, isEmpty);
      expect(ttsService.currentText, isEmpty);
    });

    test('TC-03: Bloqueo de reproducción cuando la narración está deshabilitada', () async {
      // Camino: !_isTTSEnabled -> return;
      ttsService.toggleTTS(false);
      expect(ttsService.isTTSEnabled, isFalse);

      await ttsService.speak(
        'Texto histórico que no debe reproducirse',
        sceneId: 'escena_01',
      );

      expect(ttsService.isPlaying, isFalse);

      // Restaurar estado
      ttsService.toggleTTS(true);
    });

    test('TC-04: Asignación de duración por defecto cuando durationSeconds <= 0', () async {
      // Camino: Línea 95 -> durationSeconds > 0 ? durationSeconds : 135;
      await ttsService.speak(
        'Texto para evaluar operador ternario de duración',
        sceneId: 'escena_02',
        durationSeconds: 0,
      );

      expect(ttsService.totalDurationSeconds, 135);
    });

    test('TC-05: Pausa de narración activa vs invocación redundante de pausa', () async {
      // Camino: if (!_isPlaying) return;
      // 5a. Estando inactivo: no debe mutar
      await ttsService.pause();
      expect(ttsService.isPaused, isFalse);

      // 5b. Estando en reproducción: pausa y actualiza estado
      await ttsService.speak('Narración en curso', sceneId: 'escena_01');
      expect(ttsService.isPlaying, isTrue);

      await ttsService.pause();
      expect(ttsService.isPlaying, isFalse);
      expect(ttsService.isPaused, isTrue);
    });

    test('TC-06: Reanudación de narración pausada para la misma escena', () async {
      // Camino: if (_isPaused && _currentSceneId == sceneId)
      await ttsService.speak('Texto a pausar y reanudar', sceneId: 'escena_01', durationSeconds: 100);
      await ttsService.pause();
      expect(ttsService.isPaused, isTrue);

      // Reanudar con el mismo sceneId
      await ttsService.speak('Texto a pausar y reanudar', sceneId: 'escena_01', durationSeconds: 100);

      expect(ttsService.isPlaying, isTrue);
      expect(ttsService.isPaused, isFalse);
    });

    test('TC-07: Cambio de escena durante la pausa (desestimar reanudación)', () async {
      // Camino: _isPaused == true pero _currentSceneId != sceneId (rama AND false)
      await ttsService.speak('Escena 1', sceneId: 'escena_01', durationSeconds: 80);
      await ttsService.pause();
      expect(ttsService.isPaused, isTrue);

      // Solicitar reproducción para escena_02
      await ttsService.speak('Escena 2', sceneId: 'escena_02', durationSeconds: 90);

      expect(ttsService.currentSceneId, 'escena_02');
      expect(ttsService.totalDurationSeconds, 90);
      expect(ttsService.elapsedSeconds, 0);
      expect(ttsService.isPlaying, isTrue);
      expect(ttsService.isPaused, isFalse);
    });

    test('TC-08: Avance del tiempo simulado en Timer.periodic y cálculo de progreso', () {
      // Camino: Líneas 128-132 -> _elapsedSeconds < _totalDurationSeconds
      fakeAsync((async) {
        ttsService.speak('Texto para temporizador', sceneId: 'timer_test', durationSeconds: 10);
        expect(ttsService.elapsedSeconds, 0);
        expect(ttsService.progress, 0.0);

        async.elapse(const Duration(seconds: 4));

        expect(ttsService.elapsedSeconds, 4);
        expect(ttsService.progress, 0.4);
      });
    });

    test('TC-09: Finalización automática por expiración de duración total', () {
      // Camino: Líneas 133-135 -> else { stop(); }
      fakeAsync((async) {
        ttsService.speak('Texto corto de 3 segundos', sceneId: 'timer_end', durationSeconds: 3);
        expect(ttsService.isPlaying, isTrue);

        async.elapse(const Duration(seconds: 4));

        expect(ttsService.isPlaying, isFalse);
        expect(ttsService.isPaused, isFalse);
        expect(ttsService.elapsedSeconds, 0);
        expect(ttsService.progress, 0.0);
      });
    });

    test('TC-10: Manejo y captura de excepción al fallar el canal de hardware en speak()', () async {
      // Camino: try { await _flutterTts.speak(text); } catch(e) { debugPrint(...); }
      setupMockTts(failingMethod: 'speak');

      await expectLater(
        ttsService.speak('Texto que generará fallo nativo simulado', sceneId: 'escena_err'),
        completes,
      );

      // El estado interno sobrevive y no rompe la app
      expect(ttsService.isPlaying, isTrue);
      expect(ttsService.currentSceneId, 'escena_err');
    });
  });

  // ===========================================================================
  // GRUPO 2: MÓDULO FUNCIONAL 2 - HISTORIADOR IA (Motor RAG Documental)
  // Casos TC-11 a TC-20
  // ===========================================================================
  group('Módulo Funcional 2: Historiador IA (Motor RAG Documental)', () {
    final engine = RetrievalEngine();

    test('TC-11: Normalización de texto y descarte de acentos y caracteres especiales', () {
      // Camino: RetrievalEngine.normalize()
      final normalized = RetrievalEngine.normalize('¿Quién marchó el 9 de Enero de 1964?');
      expect(normalized, 'quien marcho el 9 de enero de 1964');

      final tokens = RetrievalEngine.tokenize('¿Quién marchó el 9 de Enero de 1964?');
      // 'quien', 'el', 'de' son stopwords; deben quedar tokens sustantivos
      expect(tokens.contains('marcho'), isTrue);
      expect(tokens.contains('enero'), isTrue);
      expect(tokens.contains('1964'), isTrue);
      expect(tokens.contains('quien'), isFalse);
      expect(tokens.contains('el'), isFalse);
    });

    test('TC-12: Consulta compuesta exclusivamente por stopwords (sin tokens sustantivos)', () {
      // Camino: Línea 95 -> if (queryTokens.isEmpty) return RetrievalResult.insufficient
      final result = engine.retrieve('¿Cómo era cuando fue sobre este?');

      expect(result.hasSufficientEvidence, isFalse);
      expect(result.chunks.isEmpty, isTrue);
      expect(result.topScore, 0.0);
    });

    test('TC-13: Recuperación de fragmentos con evidencia suficiente (9 de enero y Balboa)', () {
      // Camino: Puntuación BM25 supera umbral mínimo de 3.2
      final result = engine.retrieve('¿Por qué marcharon los estudiantes a la Escuela de Balboa?');

      expect(result.hasSufficientEvidence, isTrue);
      expect(result.chunks.isNotEmpty, isTrue);
      expect(result.topScore, greaterThanOrEqualTo(3.2));
      expect(result.chunks.first.documentTitle, contains('Wendy Tribaldos'));
    });

    test('TC-14: Bonificación por coincidencia de frase exacta de 2 o más palabras', () {
      // Camino: Líneas 189-191 -> if (cleanChunkText.contains(normalizedQuery)) score += 4.5
      final result = engine.retrieve('acuerdo chiari kennedy');

      expect(result.hasSufficientEvidence, isTrue);
      expect(result.chunks.isNotEmpty, isTrue);
      expect(result.topScore, greaterThan(10.0)); // Gran boost por frase exacta
    });

    test('TC-15: Abstención estricta ante conceptos desconocidos fuera de dominio (Batalla de Waterloo)', () {
      // Camino: Líneas 134-138 -> if (unknownRatio >= 0.3) return RetrievalResult.insufficient
      final result = engine.retrieve('¿Quién ganó la batalla de Waterloo y en qué año?');

      expect(result.hasSufficientEvidence, isFalse);
      expect(result.chunks.isEmpty, isTrue);
    });

    test('TC-16: Abstención estricta ante preguntas de tecnología contemporánea no documentada', () {
      // Camino: Conceptos no contenidos en el corpus documental del 9 de enero
      final result = engine.retrieve('¿Cómo entrenar una red neuronal convolucional en Python?');

      expect(result.hasSufficientEvidence, isFalse);
      expect(result.chunks.isEmpty, isTrue);
    });

    test('TC-17: Descarte de consultas compuestas únicamente por términos genéricos', () {
      // Camino: Línea 179 -> nonGenericMatches == 0 -> no califica
      final result = engine.retrieve('¿Qué ocurrió en el momento y tiempo de aquel día?');

      expect(result.hasSufficientEvidence, isFalse);
      expect(result.chunks.isEmpty, isTrue);
    });

    test('TC-18: Generador pedagógico - Respuesta de abstención cuando no hay evidencia', () {
      // Camino: RAGResponseGenerator.generate() con hasSufficientEvidence == false
      final insufficient = RetrievalResult.insufficient(normalizedQuery: 'consulta_invalida');
      final response = RAGResponseGenerator.generate(
        question: 'Pregunta sin sustento',
        retrievalResult: insufficient,
      );

      expect(response.isAbstention, isTrue);
      expect(response.text, equals(RAGResponseGenerator.abstentionMessage));
      expect(response.references.isEmpty, isTrue);
      expect(response.cardTitle, isNull);
    });

    test('TC-19: Generador pedagógico - Respuesta documentada y extracción de referencias', () {
      // Camino: RAGResponseGenerator.generate() con evidencia suficiente
      final retrieval = engine.retrieve('¿En qué consistía el acuerdo Chiari Kennedy?');
      final response = RAGResponseGenerator.generate(
        question: '¿En qué consistía el acuerdo Chiari Kennedy?',
        retrievalResult: retrieval,
      );

      expect(response.isAbstention, isFalse);
      expect(response.text.isNotEmpty, isTrue);
      expect(response.references.isNotEmpty, isTrue);
      expect(response.references.first.page, isPositive);
      expect(response.references.first.documentTitle, contains('Wendy Tribaldos'));
    });

    test('TC-20: Flujo integral de consulta en AIService y persistencia en historial', () async {
      // Camino: AIService.askHistorian() -> añade mensaje de usuario y respuesta AI
      final aiService = AIService();
      final initialCount = aiService.messages.length;

      final aiMsg = await aiService.askHistorian('¿Por qué marcharon los institutores a Balboa?');

      expect(aiMsg.sender, 'ai');
      expect(aiMsg.message.isNotEmpty, isTrue);
      expect(aiService.messages.length, initialCount + 2);

      final userMsg = aiService.messages[aiService.messages.length - 2];
      expect(userMsg.sender, 'user');
      expect(userMsg.message, '¿Por qué marcharon los institutores a Balboa?');
    });
  });

  // ===========================================================================
  // GRUPO 3: MÓDULO DE AUTENTICACIÓN Y PERSISTENCIA DE PROGRESO
  // Casos TC-21 a TC-25
  // ===========================================================================
  group('Módulo de Autenticación y Persistencia de Progreso', () {
    test('TC-21: Autenticación exitosa en AuthService.signIn() con datos completos', () async {
      // Camino: email.isNotEmpty && password.isNotEmpty
      final auth = AuthService();
      final user = await auth.signIn(email: 'estudiante@academia.pa', password: 'password123');

      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser, isNotNull);
      expect(user.email, 'estudiante@academia.pa');
    });

    test('TC-22: Rechazo de autenticación en AuthService.signIn() por campos vacíos', () async {
      // Camino: if (email.isEmpty || password.isEmpty) throw Exception(...)
      final auth = AuthService();

      expect(
        () async => await auth.signIn(email: '', password: ''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Por favor ingrese correo y contraseña.'),
        )),
      );
    });

    test('TC-23: Rechazo de registro en AuthService.register() por omisión de nombre o correo', () async {
      // Camino: if (email.isEmpty || password.isEmpty || name.isEmpty) throw Exception(...)
      final auth = AuthService();

      expect(
        () async => await auth.register(
          name: '',
          email: 'nuevo@estudiante.pa',
          password: 'secretPassword',
          grade: '11° Grado',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Todos los campos son obligatorios.'),
        )),
      );
    });

    test('TC-24: Cierre de sesión en AuthService.signOut() y anulación de currentUser', () async {
      // Camino: _currentUser = null
      final auth = AuthService();
      await auth.signIn(email: 'user@test.pa', password: '123');
      expect(auth.isAuthenticated, isTrue);

      await auth.signOut();
      expect(auth.currentUser, isNull);
      expect(auth.isAuthenticated, isFalse);
    });

    test('TC-25: Persistencia y recuperación del progreso de lectura en ProgressService', () async {
      // Camino: ProgressService -> getViewedMaterialIds(), markMaterialAsViewed(), resetProgress()
      final progressService = ProgressService();
      await progressService.resetProgress();

      var viewed = await progressService.getViewedMaterialIds();
      expect(viewed.contains('contemporanea_01'), isFalse);

      await progressService.markMaterialAsViewed('contemporanea_01');
      viewed = await progressService.getViewedMaterialIds();
      expect(viewed.contains('contemporanea_01'), isTrue);

      await progressService.setPdfLastPage('contemporanea_01', 12);
      final page = await progressService.getPdfLastPage('contemporanea_01');
      expect(page, 12);
    });
  });
}
