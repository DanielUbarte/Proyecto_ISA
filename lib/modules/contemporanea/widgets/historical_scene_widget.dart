import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/historical_scene_model.dart';
import '../../../services/tts_service.dart';

/// Widget de Escena Histórica del módulo Panamá Contemporánea.
/// Presenta la estructura integrada:
/// IMAGEN EXISTENTE -> TÍTULO -> INFORMACIÓN HISTÓRICA -> FUENTE -> 🔊 NARRACIÓN IA
/// La imagen permanece visible mientras el estudiante consulta el texto y escucha el audio.
class HistoricalSceneWidget extends StatefulWidget {
  final HistoricalScene scene;

  const HistoricalSceneWidget({
    super.key,
    required this.scene,
  });

  @override
  State<HistoricalSceneWidget> createState() => _HistoricalSceneWidgetState();
}

class _HistoricalSceneWidgetState extends State<HistoricalSceneWidget> {
  final TTSService _ttsService = TTSService();

  @override
  void initState() {
    super.initState();
    _ttsService.addListener(_onTTSChanged);
  }

  @override
  void dispose() {
    _ttsService.removeListener(_onTTSChanged);
    super.dispose();
  }

  void _onTTSChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int _parseDurationSeconds(String durationStr) {
    try {
      final parts = durationStr.split(':');
      if (parts.length == 2) {
        final mins = int.parse(parts[0]);
        final secs = int.parse(parts[1]);
        return (mins * 60) + secs;
      }
    } catch (_) {}
    return 135;
  }

  void _playNarration() {
    final totalSecs = _parseDurationSeconds(widget.scene.duration);
    _ttsService.speak(
      widget.scene.narrationText,
      sceneId: widget.scene.id,
      durationSeconds: totalSecs,
    );
  }

  void _pauseNarration() {
    _ttsService.pause();
  }

  void _stopNarration() {
    _ttsService.stop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isThisScenePlaying =
        _ttsService.isPlaying && _ttsService.currentSceneId == widget.scene.id;
    final bool isThisScenePaused =
        _ttsService.isPaused && _ttsService.currentSceneId == widget.scene.id;
    final int currentSecs = (isThisScenePlaying || isThisScenePaused)
        ? _ttsService.elapsedSeconds
        : 0;
    final double currentProgress = (isThisScenePlaying || isThisScenePaused)
        ? _ttsService.progress
        : 0.0;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _ttsService.stop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _ttsService.stop();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            widget.scene.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // 1. IMAGEN EXISTENTE (Permanecerá visible en la parte superior)
            // --------------------------------------------------
            if (widget.scene.imagePath != null &&
                widget.scene.imagePath!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                height: 240,
                decoration: const BoxDecoration(
                  color: Colors.black12,
                ),
                child: Image.asset(
                  widget.scene.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.primaryTealDark,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported,
                                color: Colors.white, size: 48),
                            SizedBox(height: 8),
                            Text(
                              'Imagen local no disponible',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // Si la escena no tiene imagen correspondiente, NO inventar ni descargar ninguna
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryTealDark, AppColors.primaryTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        color: AppColors.sandAccent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.scene.period,
                            style: const TextStyle(
                              color: AppColors.sandAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.scene.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --------------------------------------------------
                  // 2. TÍTULO DE LA ESCENA & CATEGORÍA/ETIQUETA
                  // --------------------------------------------------
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.sandAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.scene.period,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C2D12),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.timer_outlined,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        widget.scene.duration,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    widget.scene.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                      fontFamily: 'Serif',
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --------------------------------------------------
                  // 3. INFORMACIÓN HISTÓRICA
                  // --------------------------------------------------
                  const Text(
                    'Información histórica',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Text(
                      widget.scene.text,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --------------------------------------------------
                  // 4. FUENTE DEL CONTENIDO
                  // --------------------------------------------------
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bookmark_outline,
                            color: AppColors.primaryTeal, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fuente del contenido:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.scene.source,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              if (widget.scene.sourcePage.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.scene.sourcePage,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --------------------------------------------------
                  // 5. 🔊 ESCUCHAR NARRACIÓN (Controles de audio)
                  // --------------------------------------------------
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isThisScenePlaying
                            ? AppColors.primaryTeal
                            : AppColors.borderGrey,
                        width: isThisScenePlaying ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.volume_up_rounded,
                                color: AppColors.primaryTeal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🔊 ESCUCHAR NARRACIÓN',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: AppColors.primaryTeal,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isThisScenePlaying
                                        ? 'Narrando escena...'
                                        : (isThisScenePaused
                                            ? 'Narración pausada'
                                            : 'Voz sintética histórica IA'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Barra de progreso y tiempos: ▶ 00:00 ───────── 02:15
                        Row(
                          children: [
                            Text(
                              TTSService.formatDuration(currentSecs),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryTeal,
                                fontFamily: 'Monospace',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: currentProgress,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              widget.scene.duration,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                                fontFamily: 'Monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Botones de control: ▶ Reproducir / ⏸ Pausar / ⏹ Detener
                        Row(
                          children: [
                            // Botón Reproducir / Reanudar
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isThisScenePlaying ? null : _playNarration,
                                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                label: Text(
                                  isThisScenePaused ? 'Reanudar' : 'Reproducir',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Botón Pausar
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isThisScenePlaying ? _pauseNarration : null,
                                icon: const Icon(Icons.pause_rounded, size: 18),
                                label: const Text('Pausar',
                                    style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textDark,
                                  side: const BorderSide(color: AppColors.borderGrey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Botón Detener
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: (isThisScenePlaying || isThisScenePaused)
                                    ? _stopNarration
                                    : null,
                                icon: const Icon(Icons.stop_rounded, size: 18),
                                label: const Text('Detener',
                                    style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.dangerRed,
                                  side: BorderSide(
                                      color: (isThisScenePlaying || isThisScenePaused)
                                          ? AppColors.dangerRed.withValues(alpha: 0.5)
                                          : AppColors.borderGrey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
