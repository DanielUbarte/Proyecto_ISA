import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/tts_floating_bar.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  bool _showCompletedDialog = false;

  void _finishScene() {
    setState(() {
      _showCompletedDialog = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Colors.red, size: 8),
                  SizedBox(width: 6),
                  Text(
                    '02:45',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media / AR Frame
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1579783902614-a3fb3927b675',
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                          child: const Icon(Icons.volume_up,
                              color: AppColors.primaryTeal),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Year & Category Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sandAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Año 1513',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C2D12),
                          ),
                        ),
                        Text(
                          'ÉPOCA COLONIAL',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Title
                const Text(
                  'El Descubrimiento del Mar del Sur',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                    fontFamily: 'Serif',
                  ),
                ),
                const SizedBox(height: 12),

                // Story Content Paragraph
                const Text(
                  'En septiembre de 1513, liderando una expedición de 190 españoles y cientos de indígenas, Balboa cruzó el Istmo de Panamá. Fue el primer europeo en divisar el Océano Pacífico desde su costa oriental, bautizándolo como el "Mar del Sur".',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 20),

                // Key Historical Metadata Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard(
                        title: 'NACIMIENTO',
                        value: '1475, Jerez de los Caballeros',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailCard(
                        title: 'TÍTULO',
                        value: 'Adelantado del Mar del Sur',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action controls
                CustomButton(
                  text: 'Finalizar escena ✓',
                  variant: CustomButtonVariant.green,
                  onPressed: _finishScene,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Cerrar Detalles',
                  variant: CustomButtonVariant.secondary,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 100), // Spacing for floating player
              ],
            ),
          ),

          // Floating Player Bar at bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TTSFloatingBar(),
          ),

          // Scene Completed Dialog Overlay
          if (_showCompletedDialog) _buildCompletedOverlay(context),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.forestGreen,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Escena completada!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                  fontFamily: 'Serif',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Excelente trabajo, Historiador',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Escena:', style: TextStyle(color: AppColors.textMuted)),
                        Text('Avistamiento Mar del Sur',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Duración:', style: TextStyle(color: AppColors.textMuted)),
                        Text('5m 12s', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Módulo:', style: TextStyle(color: AppColors.textMuted)),
                        Text('Época colonial',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.sandAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 6),
                    Text(
                      '+150 XP Obtenidos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C2D12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: '🔄 Repetir escena',
                variant: CustomButtonVariant.primary,
                onPressed: () {
                  setState(() => _showCompletedDialog = false);
                },
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: '🏠 Volver al menú',
                variant: CustomButtonVariant.green,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
