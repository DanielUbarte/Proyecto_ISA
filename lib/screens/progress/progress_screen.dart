import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/module_model.dart';
import '../../modules/contemporanea/contemporanea_data.dart';
import '../../services/content_service.dart';
import '../../services/database_service.dart';
import '../../widgets/app_logo_leading.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/historian_floating_button.dart';
import '../../widgets/stat_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final DatabaseService _dbService = DatabaseService();
  final ContentService _contentService = ContentService();

  List<ModuleModel> _modules = [];
  List<ContemporaneaMaterial> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final modules = await _dbService.getModules();
    final materials = await _contentService.getContemporaneaMaterials();

    if (mounted) {
      setState(() {
        _modules = modules;
        _materials = materials;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppLogoLeading(),
        title: const Text('Progreso y Analítica'),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.logoNavy))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Progress Header Card (En cero como se solicitó)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PROGRESO TOTAL',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '0%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.logoNavy,
                                    fontFamily: 'Serif',
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.logoNavy.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Evaluación en otro módulo',
                                style: TextStyle(
                                  color: AppColors.logoNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: const LinearProgressIndicator(
                            value: 0.0, // En cero según requerimiento
                            minHeight: 10,
                            backgroundColor: Color(0xFFE2E8F0),
                            color: AppColors.logoNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'El progreso general y la nota promedio se calcularán al completar el módulo evaluativo.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stat Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Módulos',
                          value: '0 / ${_modules.length}',
                          icon: Icons.menu_book,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: StatCard(
                          label: 'Nota Promedio',
                          value: '0.0 / 5.0',
                          icon: Icons.star,
                          accentColor: AppColors.logoGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Module Breakdown Section (Solo los módulos presentes actualmente)
                  const Text(
                    'Progreso por Módulo Disponible',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_modules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('No hay módulos disponibles en este momento.'),
                    )
                  else
                    ..._modules.map((module) {
                      double progressVal = 0.0;
                      String progressLabel = 'Disponible';

                      if (module.id == 'mod_contemporanea' && _materials.isNotEmpty) {
                        final viewedCount = _materials.where((m) => m.viewed).length;
                        progressVal = viewedCount / _materials.length;
                        if (progressVal == 1.0) {
                          progressLabel = 'Completado';
                        } else if (viewedCount > 0) {
                          progressLabel =
                              '${(progressVal * 100).toInt()}% ($viewedCount/${_materials.length})';
                        } else if (module.isOfflineAvailable) {
                          progressLabel = 'Descargado';
                        }
                      } else if (module.isOfflineAvailable) {
                        progressVal = 1.0;
                        progressLabel = 'Descargado';
                      }

                      return _buildModuleProgressItem(
                        module.title,
                        progressVal,
                        progressLabel,
                      );
                    }),

                  const SizedBox(height: 24),

                  // Recent Activity Timeline (Contextual a los módulos presentes)
                  const Text(
                    'Actividad Reciente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildActivityItem(
                    title: 'Gesta de 1964: Lectura de escenas históricas',
                    subtitle: 'Hoy • Panamá Contemporánea • 15m',
                    icon: Icons.auto_stories,
                  ),
                  _buildActivityItem(
                    title: 'Consulta al Historiador IA: Tratado Chiari-Kennedy',
                    subtitle: 'Hoy • Consulta documental validada • 8m',
                    icon: Icons.psychology,
                  ),
                  _buildActivityItem(
                    title: 'Libro de Wendy Tribaldos: El 9 de enero de 1964',
                    subtitle: 'Ayer • Documento oficial MEDUCA • 25m',
                    icon: Icons.menu_book,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
      floatingActionButton: const HistorianFloatingButton(heroTag: 'fab_progress'),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildModuleProgressItem(String title, double progress, String label) {
    final bool isCompleted = progress == 1.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? AppColors.logoForest
                          : AppColors.textMuted,
                    ),
                  ),
                  if (isCompleted) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle,
                        color: AppColors.logoForest, size: 16),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE2E8F0),
            color: isCompleted ? AppColors.logoForest : AppColors.logoNavy,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.logoNavy.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.logoNavy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }
}
