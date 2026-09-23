import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Servicio de síntesis de voz real (Text-To-Speech) y reproducción de narraciones IA históricas.
/// Genera el audio de voz del dispositivo en español y sincroniza el progreso del audio.
class TTSService extends ChangeNotifier {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal() {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();

  bool _isTTSEnabled = true;
  String _selectedVoice = 'Español panameño';
  String _textSize = 'Normal';

  bool _isPlaying = false;
  bool _isPaused = false;
  String _currentText = '';
  String _currentSceneId = '';

  double _progress = 0.0; // 0.0 a 1.0
  int _elapsedSeconds = 0;
  int _totalDurationSeconds = 135;
  Timer? _timer;

  bool get isTTSEnabled => _isTTSEnabled;
  String get selectedVoice => _selectedVoice;
  String get textSize => _textSize;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  String get currentText => _currentText;
  String get currentSceneId => _currentSceneId;
  double get progress => _progress;
  int get elapsedSeconds => _elapsedSeconds;
  int get totalDurationSeconds => _totalDurationSeconds;

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("es-ES");
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        stop();
      });

      _flutterTts.setCancelHandler(() {
        stop();
      });

      _flutterTts.setErrorHandler((msg) {
        stop();
      });
    } catch (e) {
      debugPrint('Error al inicializar FlutterTTS: $e');
    }
  }

  void toggleTTS(bool enabled) {
    _isTTSEnabled = enabled;
    if (!enabled) {
      stop();
    } else {
      notifyListeners();
    }
  }

  void setVoice(String voice) {
    _selectedVoice = voice;
    notifyListeners();
  }

  void setTextSize(String size) {
    _textSize = size;
    notifyListeners();
  }

  /// Inicia la reproducción del audio hablado real de la narración.
  Future<void> speak(
    String text, {
    String sceneId = '',
    int durationSeconds = 135,
  }) async {
    _currentText = text;
    _currentSceneId = sceneId;
    _totalDurationSeconds = durationSeconds > 0 ? durationSeconds : 135;

    if (_isPaused && _currentSceneId == sceneId) {
      _isPlaying = true;
      _isPaused = false;
      notifyListeners();
      _startTimer();
      try {
        await _flutterTts.speak(text);
      } catch (e) {
        debugPrint('Error en speak resume: $e');
      }
      return;
    }

    _timer?.cancel();
    _elapsedSeconds = 0;
    _progress = 0.0;
    _isPlaying = true;
    _isPaused = false;
    notifyListeners();

    _startTimer();
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error en speak: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_elapsedSeconds < _totalDurationSeconds) {
        _elapsedSeconds++;
        _progress = (_elapsedSeconds / _totalDurationSeconds).clamp(0.0, 1.0);
        notifyListeners();
      } else {
        stop();
      }
    });
  }

  /// Pausa la narración de voz.
  Future<void> pause() async {
    _timer?.cancel();
    _isPlaying = false;
    _isPaused = true;
    notifyListeners();
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('Error en pause: $e');
    }
  }

  /// Detiene la voz hablada y reinicia el estado.
  Future<void> stop() async {
    _timer?.cancel();
    _isPlaying = false;
    _isPaused = false;
    _elapsedSeconds = 0;
    _progress = 0.0;
    _currentText = '';
    _currentSceneId = '';
    notifyListeners();
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error en stop: $e');
    }
  }

  /// Formatea segundos como MM:SS
  static String formatDuration(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    final String minsStr = mins.toString().padLeft(2, '0');
    final String secsStr = secs.toString().padLeft(2, '0');
    return '$minsStr:$secsStr';
  }
}
