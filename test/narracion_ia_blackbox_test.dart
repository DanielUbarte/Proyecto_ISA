import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panama_historica/models/historical_scene_model.dart';
import 'package:panama_historica/services/tts_service.dart';

/// Pruebas de Caja Negra para el Módulo de Narración IA.
/// Evalúa el comportamiento observable del sistema (Entrada del usuario -> Funcionalidad -> Resultado observable).
/// No evalúa la implementación interna del código ni utiliza cobertura como criterio.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Interceptor de llamadas de canales nativos para simular respuesta exitosa del hardware
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async {
        return 1;
      },
    );
  });

  group('Pruebas de Caja Negra - Escenarios Positivos (Comportamiento Esperado)', () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
      ttsService.stop();
    });

    test('TC-BB-01: Selección de escena histórica con imagen disponible', () {
      // Entrada: Consulta de escena 01 del módulo
      final scenes = HistoricalScene.getContemporaneaScenes();
      final escena = scenes.firstWhere((s) => s.id == 'escena_01');

      // Resultado esperado: Muestra título, fuente y ruta de imagen local existente
      expect(escena.title, contains('9 de enero de 1964'));
      expect(escena.imagePath, 'assets/modules/contemporanea/images/martires-panama.jpg');
      expect(escena.source, isNotEmpty);
      expect(escena.narrationText, isNotEmpty);
    });

    test('TC-BB-02: Selección de escena histórica sin imagen asignada', () {
      // Entrada: Consulta de escena 04 del módulo
      final scenes = HistoricalScene.getContemporaneaScenes();
      final escena = scenes.firstWhere((s) => s.id == 'escena_04');

      // Resultado esperado: La escena se presenta sin imagen (imagePath null), manteniendo texto y fuente
      expect(escena.title, contains('Antecedentes y Consecuencias'));
      expect(escena.imagePath, isNull);
      expect(escena.narrationText, isNotEmpty);
    });

    test('TC-BB-03: Iniciar reproducción de narración en escena válida', () async {
      // Entrada: Presionar "Reproducir" en escena_01 con duración de 120 segundos
      await ttsService.speak(
        'El 9 de enero de 1964 los estudiantes marcharon pacíficamente.',
        sceneId: 'escena_01',
        durationSeconds: 120,
      );

      // Resultado esperado: La narración inicia (isPlaying: true, isPaused: false)
      expect(ttsService.isPlaying, true);
      expect(ttsService.isPaused, false);
      expect(ttsService.currentSceneId, 'escena_01');
      expect(ttsService.totalDurationSeconds, 120);
    });

    test('TC-BB-04: Pausar una narración activa', () async {
      // Entrada: Presionar "Pausar" durante la reproducción
      await ttsService.speak('Texto a pausar', sceneId: 'escena_01');
      await ttsService.pause();

      // Resultado esperado: La narración se pausa (isPlaying: false, isPaused: true)
      expect(ttsService.isPlaying, false);
      expect(ttsService.isPaused, true);
    });

    test('TC-BB-05: Reanudar una narración previamente pausada', () async {
      // Entrada: Presionar "Reanudar" en la misma escena pausada
      await ttsService.speak('Texto a reanudar', sceneId: 'escena_01');
      await ttsService.pause();
      await ttsService.speak('Texto a reanudar', sceneId: 'escena_01');

      // Resultado esperado: La narración reanuda su ejecución (isPlaying: true, isPaused: false)
      expect(ttsService.isPlaying, true);
      expect(ttsService.isPaused, false);
    });

    test('TC-BB-06: Detener por completo una narración activa', () async {
      // Entrada: Presionar "Detener" durante la narración
      await ttsService.speak('Texto a detener', sceneId: 'escena_01');
      await ttsService.stop();

      // Resultado esperado: La narración queda completamente detenida y reseteada
      expect(ttsService.isPlaying, false);
      expect(ttsService.isPaused, false);
      expect(ttsService.elapsedSeconds, 0);
      expect(ttsService.progress, 0.0);
      expect(ttsService.currentSceneId, '');
    });

    test('TC-BB-07: Cambiar de escena mientras una narración está reproduciéndose', () async {
      // Entrada: Seleccionar escena_02 mientras se reproducía escena_01
      await ttsService.speak('Texto escena 1', sceneId: 'escena_01');
      await ttsService.speak('Texto escena 2', sceneId: 'escena_02', durationSeconds: 90);

      // Resultado esperado: La narración cambia a escena_02 y resetea progreso
      expect(ttsService.currentSceneId, 'escena_02');
      expect(ttsService.totalDurationSeconds, 90);
      expect(ttsService.elapsedSeconds, 0);
      expect(ttsService.isPlaying, true);
    });

    test('TC-BB-08: Desactivar la función de narración desde ajustes', () async {
      // Entrada: Desactivar interruptor de narración (toggleTTS(false))
      await ttsService.speak('Texto en voz', sceneId: 'escena_01');
      ttsService.toggleTTS(false);

      // Resultado esperado: La función se desactiva y se detiene la reproducción activa
      expect(ttsService.isTTSEnabled, false);
      expect(ttsService.isPlaying, false);
    });

    test('TC-BB-09: Reactivar la función de narración desde ajustes', () {
      // Entrada: Activar interruptor de narración (toggleTTS(true))
      ttsService.toggleTTS(false);
      ttsService.toggleTTS(true);

      // Resultado esperado: La función de narración queda habilitada (isTTSEnabled: true)
      expect(ttsService.isTTSEnabled, true);
    });

    test('TC-BB-10: Formato visual observable de tiempo de narración', () {
      // Entrada: 135 segundos
      final resultado = TTSService.formatDuration(135);

      // Resultado esperado: Cadena formateada en min:seg '02:15'
      expect(resultado, '02:15');
    });
  });

  group('Pruebas de Caja Negra - Escenarios Negativos / Casos Límite', () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
      ttsService.stop();
    });

    test('TC-BB-11: Entrada de duración negativa o cero en la narración', () async {
      // Entrada: Iniciar narración con duración anómala (-45 segundos)
      await ttsService.speak('Texto con duración inválida', sceneId: 'escena_01', durationSeconds: -45);

      // Resultado esperado: El sistema debe manejar la situación asignando una duración por defecto válida (135s)
      expect(ttsService.totalDurationSeconds, 135);
      expect(ttsService.isPlaying, true);
    });

    test('TC-BB-12: Intentar pausar cuando NO existe una narración activa ni en reproducción', () async {
      // Entrada: El sistema está totalmente detenido (isPlaying: false, isPaused: false, sceneId: '')
      expect(ttsService.isPlaying, false);
      expect(ttsService.isPaused, false);

      // Acción: Usuario presiona "Pausar" sin narración activa
      await ttsService.pause();

      // Resultado esperado: El sistema debe mantener un estado coherente (isPaused debería ser false al no haber nada que pausar)
      // Resultado obtenido en el código actual: isPaused cambia a true en un estado vacío
      expect(ttsService.isPaused, false, reason: 'No se debe marcar isPaused=true cuando no hay narración activa');
    });

    test('TC-BB-13: Intentar reproducir narración cuando la función está desactivada por el usuario', () async {
      // Entrada: Usuario desactivó la narración por voz en ajustes (isTTSEnabled = false)
      ttsService.toggleTTS(false);
      expect(ttsService.isTTSEnabled, false);

      // Acción: Intentar reproducir una narración
      await ttsService.speak('Texto de narración', sceneId: 'escena_01');

      // Resultado esperado: El sistema debe impedir la reproducción si la función está desactivada (isPlaying debería ser false)
      // Resultado obtenido en el código actual: El sistema ignora la deshabilitación e inicia la reproducción (isPlaying = true)
      expect(ttsService.isPlaying, false, reason: 'El sistema no debe iniciar reproducción si TTS está desactivado');
    });

    test('TC-BB-14: Intentar reproducir narración con contenido de texto vacío', () async {
      // Entrada: Contenido de narración vacío ('')
      await ttsService.speak('', sceneId: 'escena_vacia');

      // Resultado esperado: El sistema debe evitar iniciar reproducción para un texto vacío (isPlaying debería ser false)
      // Resultado obtenido en el código actual: El sistema acepta texto vacío e inicia la reproducción
      expect(ttsService.isPlaying, false, reason: 'No se debe reproducir una narración sin contenido de texto');
    });
  });
}
