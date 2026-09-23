import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/tts_service.dart';

class TTSFloatingBar extends StatefulWidget {
  final String speakerName;
  final String statusText;

  const TTSFloatingBar({
    super.key,
    this.speakerName = 'Vasco Núñez de Balboa',
    this.statusText = 'Narración IA activa',
  });

  @override
  State<TTSFloatingBar> createState() => _TTSFloatingBarState();
}

class _TTSFloatingBarState extends State<TTSFloatingBar> {
  final TTSService _ttsService = TTSService();
  bool _isPlaying = true;
  final double _progress = 0.35;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.record_voice_over,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.speakerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.statusText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 22),
                onPressed: () {},
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                      if (_isPlaying) {
                        _ttsService.speak(widget.speakerName);
                      } else {
                        _ttsService.stop();
                      }
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 22),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: const Color(0xFFE2E8F0),
            color: AppColors.primaryTeal,
          ),
        ],
      ),
    );
  }
}
