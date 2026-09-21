/// Service abstraction for Text-To-Speech (Lectura en voz alta) and Accessibility.
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  bool _isTTSEnabled = false;
  String _selectedVoice = 'Español panameño';
  String _textSize = 'Normal'; // 'A', 'Normal', 'A+', 'A++'
  bool _isPlaying = false;
  String _currentText = '';

  bool get isTTSEnabled => _isTTSEnabled;
  String get selectedVoice => _selectedVoice;
  String get textSize => _textSize;
  bool get isPlaying => _isPlaying;
  String get currentText => _currentText;

  void toggleTTS(bool enabled) {
    _isTTSEnabled = enabled;
    if (!enabled) {
      stop();
    }
  }

  void setVoice(String voice) {
    _selectedVoice = voice;
  }

  void setTextSize(String size) {
    _textSize = size;
  }

  Future<void> speak(String text) async {
    if (!_isTTSEnabled) return;
    _isPlaying = true;
    _currentText = text;
    // Simulates speech audio playback
  }

  Future<void> stop() async {
    _isPlaying = false;
    _currentText = '';
  }
}
