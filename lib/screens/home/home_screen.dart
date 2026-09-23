import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/module_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/module_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  UserModel _user = UserModel.mock();
  List<ModuleModel> _modules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _dbService.getUserProfile();
    final modules = await _dbService.getModules();
    setState(() {
      _user = user;
      _modules = modules;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primaryTeal),
          onPressed: () {},
        ),
        title: const Text(
          'Panamá Histórica',
          style: TextStyle(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: AppColors.primaryTeal, size: 28),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Banner Header
                  _buildStudentHeaderCard(),
                  const SizedBox(height: 24),

                  // Módulos Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Módulos de Aprendizaje',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.modules),
                        child: const Text('Ver todo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Modules List
                  ..._modules.map((module) => ModuleCard(
                        module: module,
                        onTap: () {
                          if (module.id == 'mod_04' ||
                              module.title.toLowerCase().contains('contemporánea')) {
                            Navigator.pushNamed(context, AppRoutes.contemporanea);
                          } else if (module.status == ModuleStatus.downloaded) {
                            Navigator.pushNamed(context, AppRoutes.content);
                          } else {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.moduleDetail,
                              arguments: module,
                            );
                          }
                        },
                      )),

                  const SizedBox(height: 16),

                  // Anuncios MEDUCA Section
                  const Text(
                    'Anuncios MEDUCA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnnouncementCard(
                    title: 'Nueva Experiencia AR: La Separación de 1903',
                    subtitle: 'Disponible para descarga este viernes.',
                    icon: Icons.calendar_month,
                  ),
                  const SizedBox(height: 8),
                  _buildAnnouncementCard(
                    title: 'Actualización del Glosario Técnico',
                    subtitle: 'Se agregaron 15 nuevos términos de la época colonial.',
                    icon: Icons.update,
                  ),

                  const SizedBox(height: 24),

                  // Resumen Escolar Card
                  _buildResumenEscolarCard(context),

                  const SizedBox(height: 30),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.amberBadge,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.content),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildStudentHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryTeal,
                backgroundImage: _user.avatarUrl.isNotEmpty
                    ? (_user.avatarUrl.startsWith('assets/')
                        ? AssetImage(_user.avatarUrl) as ImageProvider
                        : NetworkImage(_user.avatarUrl) as ImageProvider)
                    : null,
                child: _user.avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 28)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_user.grade} — ${_user.institution}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sandAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🏆 ${_user.levelTitle}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8C4A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TU PROGRESO SEMANAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textMuted,
                ),
              ),
              Row(
                children: List.generate(
                  7,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: (12 + (index * 4) % 18).toDouble(),
                    decoration: BoxDecoration(
                      color: index == 4
                          ? AppColors.primaryTeal
                          : AppColors.primaryTeal.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryTeal, size: 22),
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

  Widget _buildResumenEscolarCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen Escolar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Serif',
            ),
          ),
          const SizedBox(height: 16),
          _buildResumenRow('Módulos Completos', '08'),
          const Divider(color: Colors.white24, height: 20),
          _buildResumenRow('Horas de Estudio', '42.5h'),
          const Divider(color: Colors.white24, height: 20),
          _buildResumenRow('Promedio Actual', '4.8 / 5.0'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.trending_up, size: 20),
              label: const Text(
                'Ver Analítica',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.progress),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
