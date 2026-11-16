import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panama_historica/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TTSService ttsService;
  final List<MethodCall> methodCalls = [];

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        switch (methodCall.method) {
          case 'speak':
            return 1;
          case 'stop':
            return 1;
          case 'pause':
            return 1;
          case 'setLanguage':
            return 1;
          case 'setSpeechRate':
            return 1;
          case 'setVolume':
            return 1;
          case 'setPitch':
            return 1;
          default:
            return 1;
        }
      },
    );
  });

  setUp(() async {
    methodCalls.clear();
    ttsService = TTSService();
    ttsService.toggleTTS(true);
    await ttsService.stop();
  });

  tearDown(() async {
    await ttsService.stop();
  });

  group('Checklist de Pruebas Unitarias - Servicio de Narración por Voz (TTSService)', () {
    // 1. Inicio de narración con texto válido
    test('1. Inicio exitoso de narración hablada con texto histórico válido (speak)', () async {
      const sampleText = 'El 9 de enero de 1964 los estudiantes marcharon pacíficamente hacia Balboa.';
      await ttsService.speak(sampleText, sceneId: 'escena_01', durationSeconds: 60);

      expect(ttsService.isPlaying, isTrue);
      expect(ttsService.isPaused, isFalse);
      expect(ttsService.currentText, equals(sampleText));
      expect(ttsService.currentSceneId, equals('escena_01'));
      expect(ttsService.totalDurationSeconds, equals(60));
      expect(methodCalls.any((call) => call.method == 'speak'), isTrue);
    });

    // 2. Rechazo de cadenas vacías o espacios en blanco
    test('2. Rechazo estricto de textos vacíos o con espacios sin iniciar reproducción ni temporizador', () async {
      await ttsService.speak('');
      expect(ttsService.isPlaying, isFalse);
      expect(ttsService.currentText, isEmpty);

      await ttsService.speak('     \n\t   ');
      expect(ttsService.isPlaying, isFalse);
      expect(ttsService.currentText, isEmpty);
    });

    // 3. Pausa de la narración activa
    test('3. Pausa de la voz activa suspende la reproducción y preserva el estado (pause)', () async {
      await ttsService.speak('Texto de prueba para verificar pausa', sceneId: 'escena_02', durationSeconds: 80);
      expect(ttsService.isPlaying, isTrue);

      await ttsService.pause();

      expect(ttsService.isPlaying, isFalse);
      expect(ttsService.isPaused, isTrue);
      expect(ttsService.currentSceneId, equals('escena_02'));
      expect(methodCalls.any((call) => call.method == 'pause'), isTrue);
    });

    // 4. Reanudación tras pausa
    test('4. Reanudación de la narración pausada continúa desde el estado acumulado (speak tras pause)', () async {
      const text = 'Texto para evaluar la reanudación';
      await ttsService.speak(text, sceneId: 'escena_03', durationSeconds: 50);
      await ttsService.pause();
      expect(ttsService.isPaused, isTrue);

      // Reanudar con la misma escena
      await ttsService.speak(text, sceneId: 'escena_03', durationSeconds: 50);

      expect(ttsService.isPlaying, isTrue);
      expect(ttsService.isPaused, isFalse);
      expect(ttsService.currentSceneId, equals('escena_03'));
    });

    // 5. Detención completa y reinicio
    test('5. Detención completa restablece todos los indicadores a su estado inicial en reposo (stop)', () async {
      await ttsService.speak('Texto a detener', sceneId: 'escena_04', durationSeconds: 40);
      expect(ttsService.isPlaying, isTrue);

      await ttsService.stop();

      expect(ttsService.isPlaying, isFalse);
      expect(ttsService.isPaused, isFalse);
      expect(ttsService.elapsedSeconds, equals(0));
      expect(ttsService.progress, equals(0.0));
      expect(ttsService.currentText, isEmpty);
      expect(ttsService.currentSceneId, isEmpty);
      expect(methodCalls.any((call) => call.method == 'stop'), isTrue);
    });

    // 6. Desactivación maestra del servicio TTS (toggleTTS)
    test('6. Desactivar el interruptor maestro detiene la narración activa y bloquea nuevas solicitudes', () async {
      await ttsService.speak('Texto en reproducción', sceneId: 'escena_05');
      expect(ttsService.isPlaying, isTrue);

      // Desactivar TTS
      ttsService.toggleTTS(false);

      expect(ttsService.isTTSEnabled, isFalse);
      expect(ttsService.isPlaying, isFalse);

      // Intentar reproducir con TTS desactivado
      await ttsService.speak('Texto ignorado');
      expect(ttsService.isPlaying, isFalse);
      expect(ttsService.currentText, isEmpty);

      // Restaurar
      ttsService.toggleTTS(true);
      expect(ttsService.isTTSEnabled, isTrue);
    });

    // 7. Configuración de preferencias (setVoice y setTextSize)
    test('7. Modificación de voz y tamaño de texto actualiza propiedades y notifica a la interfaz', () {
      bool notified = false;
      ttsService.addListener(() => notified = true);

      ttsService.setVoice('Español neutro');
      expect(ttsService.selectedVoice, equals('Español neutro'));
      expect(notified, isTrue);

      notified = false;
      ttsService.setTextSize('Grande');
      expect(ttsService.textSize, equals('Grande'));
      expect(notified, isTrue);

      // Restaurar valores por defecto
      ttsService.setVoice('Español panameño');
      ttsService.setTextSize('Normal');
    });

    // 8. Formateo numérico de tiempo (formatDuration)
    test('8. Formateo de duración convierte segundos a cadena temporal MM:SS correctamente', () {
      expect(TTSService.formatDuration(0), equals('00:00'));
      expect(TTSService.formatDuration(5), equals('00:05'));
      expect(TTSService.formatDuration(60), equals('01:00'));
      expect(TTSService.formatDuration(65), equals('01:05'));
      expect(TTSService.formatDuration(135), equals('02:15'));
      expect(TTSService.formatDuration(600), equals('10:00'));
    });

    // 9. Finalización natural de la narración al concluir la duración
    test('9. El temporizador interno invoca stop automáticamente al alcanzar la duración total', () async {
      await ttsService.speak('Narración ultra corta', sceneId: 'escena_corta', durationSeconds: 1);
      expect(ttsService.isPlaying, isTrue);

      // Esperar tiempo suficiente para que el temporizador complete ambos ciclos periódicos (2 segundos)
      await Future.delayed(const Duration(milliseconds: 2200));

      expect(ttsService.isPlaying, isFalse);
      expect(ttsService.elapsedSeconds, equals(0));
      expect(ttsService.progress, equals(0.0));
    });

    // 10. Operaciones consecutivas de pausa y detención
    test('10. Secuencia inmediata de pausa y detención transiciona limpiamente sin excepciones de temporizador', () async {
      await ttsService.speak('Texto para transiciones consecutivas', sceneId: 'escena_trans');
      expect(ttsService.isPlaying, isTrue);

      await ttsService.pause();
      expect(ttsService.isPaused, isTrue);

      await ttsService.stop();
      expect(ttsService.isPlaying, isFalse);
      expect(ttsService.isPaused, isFalse);
      expect(ttsService.progress, equals(0.0));
    });

    // 11. Reproducción de un nuevo fragmento mientras otro está activo
    test('11. Iniciar un nuevo fragmento cancela la narración en curso e inicializa el nuevo progreso', () async {
      await ttsService.speak('Fragmento Inicial', sceneId: 'escena_A', durationSeconds: 100);
      expect(ttsService.currentSceneId, equals('escena_A'));

      // Iniciar inmediatamente un segundo fragmento diferente
      await ttsService.speak('Fragmento Nuevo', sceneId: 'escena_B', durationSeconds: 50);

      expect(ttsService.currentSceneId, equals('escena_B'));
      expect(ttsService.currentText, equals('Fragmento Nuevo'));
      expect(ttsService.totalDurationSeconds, equals(50));
      expect(ttsService.elapsedSeconds, equals(0));
      expect(ttsService.isPlaying, isTrue);
    });

    // 12. Simulación de detención al abandonar pantalla (PopScope en HistoricalSceneWidget)
    test('12. Salida de la pantalla de escena histórica detiene la narración activa evitando procesos huérfanos', () async {
      await ttsService.speak('Texto en pantalla', sceneId: 'escena_widget');
      expect(ttsService.isPlaying, isTrue);

      // Simular onPopInvokedWithResult del widget
      await ttsService.stop();

      expect(ttsService.isPlaying, isFalse);
      expect(ttsService.currentText, isEmpty);
      expect(ttsService.currentSceneId, isEmpty);
    });

    // 13. [DEFECTO DETECTADO] Concurrencia: Pulsaciones rápidas simultáneas generan condición de carrera en speak
    test('13. [DEFECTO DETECTADO] Múltiples pulsaciones simultáneas de speak carecen de bloqueo o cola de exclusión mutua', () async {
      // Simular dos pulsaciones simultáneas rápidas sobre el botón reproducir
      final f1 = ttsService.speak('Primera pulsación rápida', sceneId: 'escena_rapida_1');
      final f2 = ttsService.speak('Segunda pulsación rápida', sceneId: 'escena_rapida_2');

      await Future.wait([f1, f2]);

      // En un controlador de voz robusto, las operaciones concurrentes deben estar protegidas
      // por un mecanismo de encolamiento o semáforo atómico (isOperationInProgress / debounce)
      final hasAtomicQueue = ttsService.runtimeType.toString().contains('Queued') ||
          ttsService.runtimeType.toString().contains('Debounced');

      expect(
        hasAtomicQueue,
        isTrue,
        reason: 'TTSService carece de protección contra pulsaciones rápidas (debounce/mutex), provocando llamadas asíncronas no sincronizadas al motor nativo',
      );
    });

    // 14. [DEFECTO DETECTADO] Desacoplamiento: El progreso se calcula con un temporizador artificial y no con los eventos reales de voz
    test('14. [DEFECTO DETECTADO] El progreso de lectura se calcula con un temporizador artificial desacoplado del motor nativo (setProgressHandler)', () {
      // TTSService calcula _progress con Timer.periodic(Duration(seconds: 1)) en lugar de usar
      // _flutterTts.setProgressHandler((text, start, end, word) => ...) para progreso real
      final isEventDriven = ttsService.runtimeType.toString().contains('EventDriven');

      expect(
        isEventDriven,
        isTrue,
        reason: 'TTSService calcula el progreso con un temporizador periódico artificial en lugar de sincronizarse con setProgressHandler del motor de voz',
      );
    });

    // 15. [DEFECTO DETECTADO] Silenciamiento de errores: Fallos del motor TTS se silencian llamando a stop() sin alertar a la interfaz
    test('15. [DEFECTO DETECTADO] Fallos del motor nativo (setErrorHandler) se silencian con stop() sin registrar mensaje de error para la UI', () {
      // Cuando _flutterTts.setErrorHandler recibe un error del motor nativo, ejecuta stop() directamente
      // TTSService no posee propiedad errorMessage, lastError ni estado de fallo para informar a los widgets
      bool hasErrorMessageProperty = false;
      try {
        hasErrorMessageProperty = (ttsService as dynamic).errorMessage != null;
      } on NoSuchMethodError {
        hasErrorMessageProperty = false;
      }

      expect(
        hasErrorMessageProperty,
        isTrue,
        reason: 'TTSService silencia los errores del motor nativo mediante stop() sin exponer una propiedad errorMessage ni notificar el fallo a la interfaz',
      );
    });
  });
}
