import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panama_historica/models/historical_scene_model.dart';
import 'package:panama_historica/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configuración por defecto del mock de MethodChannel para flutter_tts
  void setupMockTtsSuccess() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'setLanguage':
          case 'setSpeechRate':
          case 'setVolume':
          case 'setPitch':
          case 'speak':
          case 'pause':
          case 'stop':
            return 1;
          default:
            return null;
        }
      },
    );
  }

  // Configuración del mock de MethodChannel para simular errores en un método específico
  void setupMockTtsErrorForMethod(String failingMethod) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async {
        if (methodCall.method == failingMethod) {
          throw PlatformException(
            code: 'TTS_ERROR',
            message: 'Fallo simulado en el método $failingMethod de FlutterTts',
          );
        }
        return 1;
      },
    );
  }

  setUp(() {
    setupMockTtsSuccess();
  });

  group('Pruebas de Caja Blanca - Módulo de Narración IA (TTSService)', () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
      ttsService.stop(); // Garantizar estado inicial limpio
    });

    test(
        'Camino 1: Reproducción de una nueva narración (speak sin pausa previa)',
        () async {
      // Condición inicial: _isPaused es false
      expect(ttsService.isPaused, false);

      await ttsService.speak(
        'El 9 de enero de 1964 los estudiantes marcharon pacíficamente.',
        sceneId: 'escena_01',
        durationSeconds: 120,
      );

      // Verificación del camino lógico de inicio de narración
      expect(ttsService.isPlaying, true);
      expect(ttsService.isPaused, false);
      expect(ttsService.currentSceneId, 'escena_01');
      expect(ttsService.currentText,
          'El 9 de enero de 1964 los estudiantes marcharon pacíficamente.');
      expect(ttsService.totalDurationSeconds, 120);
      expect(ttsService.elapsedSeconds, 0);
      expect(ttsService.progress, 0.0);
    });

    test(
        'Camino 2: Validación de asignación de duración por defecto (durationSeconds <= 0)',
        () async {
      // Evaluando condición ternaria: durationSeconds > 0 ? durationSeconds : 135
      await ttsService.speak(
        'Texto de prueba con duración cero',
        sceneId: 'escena_02',
        durationSeconds: 0,
      );

      expect(ttsService.totalDurationSeconds, 135);
    });

    test('Camino 3: Pausado de una narración activa (pause)', () async {
      await ttsService.speak(
        'Narración en curso',
        sceneId: 'escena_01',
        durationSeconds: 100,
      );

      expect(ttsService.isPlaying, true);

      await ttsService.pause();

      // Verificación de la rama de pausa
      expect(ttsService.isPlaying, false);
      expect(ttsService.isPaused, true);
    });

    test(
        'Camino 4: Reanudación/Continuación de narración pausada para la misma escena',
        () async {
      // Iniciar y luego pausar
      await ttsService.speak(
        'Narración a pausar y reanudar',
        sceneId: 'escena_01',
        durationSeconds: 100,
      );
      await ttsService.pause();

      expect(ttsService.isPaused, true);
      expect(ttsService.currentSceneId, 'escena_01');

      // Reanudar llamando a speak para la misma escena estando en pausa
      // Evalúa rama: if (_isPaused && _currentSceneId == sceneId)
      await ttsService.speak(
        'Narración a pausar y reanudar',
        sceneId: 'escena_01',
        durationSeconds: 100,
      );

      expect(ttsService.isPlaying, true);
      expect(ttsService.isPaused, false);
    });

    test('Camino 5: Cambio de escena durante la pausa (desestimar reanudación)',
        () async {
      await ttsService.speak(
        'Escena 1',
        sceneId: 'escena_01',
        durationSeconds: 100,
      );
      await ttsService.pause();

      // Llamar a speak para una escena diferente (escena_02)
      // La condición (_isPaused && _currentSceneId == sceneId) debe evaluarse como false
      await ttsService.speak(
        'Escena 2',
        sceneId: 'escena_02',
        durationSeconds: 90,
      );

      expect(ttsService.currentSceneId, 'escena_02');
      expect(ttsService.totalDurationSeconds, 90);
      expect(ttsService.elapsedSeconds, 0);
      expect(ttsService.isPlaying, true);
    });

    test('Camino 6: Detención completa de la narración (stop)', () async {
      await ttsService.speak(
        'Narración activa a detener',
        sceneId: 'escena_01',
        durationSeconds: 60,
      );

      await ttsService.stop();

      // Verificación del estado reiniciado por stop()
      expect(ttsService.isPlaying, false);
      expect(ttsService.isPaused, false);
      expect(ttsService.elapsedSeconds, 0);
      expect(ttsService.progress, 0.0);
      expect(ttsService.currentText, '');
      expect(ttsService.currentSceneId, '');
    });

    test(
        'Camino 7: Deshabilitación de narración por configuración (toggleTTS(false))',
        () async {
      await ttsService.speak(
        'Narración en ejecución',
        sceneId: 'escena_01',
      );
      expect(ttsService.isPlaying, true);

      // Evalúa rama: if (!enabled) -> llama a stop()
      ttsService.toggleTTS(false);

      expect(ttsService.isTTSEnabled, false);
      expect(ttsService.isPlaying, false);
    });

    test(
        'Camino 8: Habilitación de narración por configuración (toggleTTS(true))',
        () async {
      ttsService.toggleTTS(false);
      expect(ttsService.isTTSEnabled, false);

      // Evalúa rama: else -> notifyListeners()
      ttsService.toggleTTS(true);

      expect(ttsService.isTTSEnabled, true);
    });

    test('Camino 9: Formateo de duración en formato MM:SS (formatDuration)',
        () {
      expect(TTSService.formatDuration(135), '02:15');
      expect(TTSService.formatDuration(0), '00:00');
      expect(TTSService.formatDuration(60), '01:00');
      expect(TTSService.formatDuration(3599), '59:59');
    });
  });

  group('Pruebas de Caja Blanca - Avance de Tiempo en Timer.periodic', () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
      ttsService.stop();
    });

    test(
        'Camino 12: Timer.periodic - Avance del tiempo (elapsedSeconds) y cálculo de progreso',
        () {
      fakeAsync((async) {
        ttsService.speak(
          'Texto de prueba para temporizador',
          sceneId: 'escena_timer',
          durationSeconds: 10,
        );

        expect(ttsService.elapsedSeconds, 0);
        expect(ttsService.progress, 0.0);

        // Avanzar 3 segundos en el tiempo simulado
        async.elapse(const Duration(seconds: 3));

        // Evalúa rama: if (_elapsedSeconds < _totalDurationSeconds)
        expect(ttsService.elapsedSeconds, 3);
        expect(ttsService.progress, 0.3);

        // Avanzar 4 segundos más (total 7 segundos)
        async.elapse(const Duration(seconds: 4));

        expect(ttsService.elapsedSeconds, 7);
        expect(ttsService.progress, 0.7);
      });
    });

    test(
        'Camino 13: Timer.periodic - Finalización por alcanzar duración total (_elapsedSeconds >= _totalDurationSeconds)',
        () {
      fakeAsync((async) {
        ttsService.speak(
          'Texto corto de 5 segundos',
          sceneId: 'escena_timer_final',
          durationSeconds: 5,
        );

        expect(ttsService.isPlaying, true);

        // Para durationSeconds = 5, en el segundo 5 _elapsedSeconds llega a 5 (progreso 1.0).
        // En el tick del segundo 6, la condición (_elapsedSeconds < 5) evalúa false y ejecuta la rama else -> stop()
        async.elapse(const Duration(seconds: 6));

        // Evalúa rama: else -> stop() al dejar de cumplirse _elapsedSeconds < _totalDurationSeconds
        expect(ttsService.isPlaying, false);
        expect(ttsService.isPaused, false);
        expect(ttsService.elapsedSeconds, 0);
        expect(ttsService.progress, 0.0);
      });
    });
  });

  group('Pruebas de Caja Blanca - Manejo de Excepciones en Bloques Catch(e)',
      () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
      ttsService.stop();
    });

    test(
        'Camino 14: Provocación de excepción en speak() al fallar FlutterTts.speak',
        () async {
      setupMockTtsErrorForMethod('speak');

      // Ejecutar speak() con mock configurado para lanzar excepción en 'speak'
      // Demuestra que el catch(e) captura el error sin lanzar excepción no controlada hacia afuera
      await expectLater(
        ttsService.speak('Texto que fallará en speak', sceneId: 'escena_err'),
        completes,
      );

      // El estado del servicio configurado antes de la llamada a FlutterTts permanece intacto
      expect(ttsService.isPlaying, true);
      expect(ttsService.currentSceneId, 'escena_err');
    });

    test(
        'Camino 15: Provocación de excepción en speak() durante la reanudación al estar pausado',
        () async {
      setupMockTtsSuccess();
      await ttsService.speak('Texto inicial', sceneId: 'escena_err_resume');
      await ttsService.pause();

      expect(ttsService.isPaused, true);

      // Configurar error simulado para speak
      setupMockTtsErrorForMethod('speak');

      await expectLater(
        ttsService.speak('Texto inicial', sceneId: 'escena_err_resume'),
        completes,
      );

      // El catch en la rama resume captura el error sin romper la app
      expect(ttsService.isPlaying, true);
      expect(ttsService.isPaused, false);
    });

    test(
        'Camino 16: Provocación de excepción en pause() al fallar FlutterTts.pause',
        () async {
      setupMockTtsSuccess();
      await ttsService.speak('Texto para pausar', sceneId: 'escena_pause_err');

      setupMockTtsErrorForMethod('pause');

      await expectLater(ttsService.pause(), completes);

      // El estado interno de pause permanece (isPlaying: false, isPaused: true)
      expect(ttsService.isPlaying, false);
      expect(ttsService.isPaused, true);
    });

    test(
        'Camino 17: Provocación de excepción en stop() al fallar FlutterTts.stop',
        () async {
      setupMockTtsSuccess();
      await ttsService.speak('Texto para detener', sceneId: 'escena_stop_err');

      setupMockTtsErrorForMethod('stop');

      await expectLater(ttsService.stop(), completes);

      // El estado interno de stop() se reinicia adecuadamente pese a la excepción de hardware
      expect(ttsService.isPlaying, false);
      expect(ttsService.isPaused, false);
      expect(ttsService.elapsedSeconds, 0);
      expect(ttsService.progress, 0.0);
    });

    test(
        'Camino 18: Provocación de excepción en _initTts() al fallar FlutterTts.setLanguage',
        () async {
      setupMockTtsErrorForMethod('setLanguage');

      // Instanciar un nuevo servicio provocando fallo en _initTts()
      final serviceInstance = TTSService();

      // Verifica que no se lance la excepción hacia afuera y el objeto sea válido
      expect(serviceInstance, isNotNull);
      expect(serviceInstance.isTTSEnabled, true);
    });
  });

  group('Pruebas de Caja Blanca - Modelo de Escenas e Integración de Contenido',
      () {
    test('Camino 10: Escena histórica con narración e imagen existente', () {
      final scenes = HistoricalScene.getContemporaneaScenes();
      final escena01 = scenes.firstWhere((s) => s.id == 'escena_01');

      expect(escena01.title, '9 de enero de 1964: Reclamación Patriótica');
      expect(escena01.imagePath,
          'assets/modules/contemporanea/images/martires-panama.jpg');
      expect(escena01.source, 'El 9 de enero de 1964: lo que no me contaron');
      expect(escena01.narrationText.isNotEmpty, true);
    });

    test('Camino 11: Escena histórica con narración y sin imagen asignada', () {
      final scenes = HistoricalScene.getContemporaneaScenes();
      final escena04 = scenes.firstWhere((s) => s.id == 'escena_04');

      expect(escena04.title, 'Antecedentes y Consecuencias Históricas');
      expect(escena04.imagePath, isNull);
      expect(escena04.source, 'El 9 de enero de 1964: lo que no me contaron');
      expect(escena04.narrationText.isNotEmpty, true);
    });
  });
}
