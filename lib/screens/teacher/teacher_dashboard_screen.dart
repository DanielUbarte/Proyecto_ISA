import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/document_storage_service.dart';
import '../../services/document_sync_service.dart';
import '../../services/student_tracking_service.dart';
import '../../widgets/app_logo_leading.dart';

/// Panel Principal del Rol Docente (Dashboard).
/// Concentra el acceso a Gestión de Estudiantes, Evaluación y Gestión de Documentos.
class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final AuthService _authService = AuthService();
  final DocumentStorageService _storageService = DocumentStorageService();
  final DocumentSyncService _syncService = DocumentSyncService();
  final StudentTrackingService _studentService = StudentTrackingService();

  UserModel? _teacher;
  int _totalDocuments = 0;
  int _publishedDocuments = 0;
  int _draftDocuments = 0;
  int _archivedDocuments = 0;
  int _studentCount = 0;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    _teacher = _authService.currentUser ?? UserModel.mockTeacher();
    await _storageService.initialize();
    await _syncService.initialize();

    final docs = await _storageService.getAllDocuments();

    if (mounted) {
      setState(() {
        _totalDocuments = docs.length;
        _publishedDocuments = docs.where((d) => d.isPublished).length;
        _draftDocuments = docs.where((d) => d.isDraft).length;
        _archivedDocuments = docs.where((d) => d.isArchived).length;
        _studentCount = _studentService.getStudents().length;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    final success = await _syncService.syncWithSharedRepository();
    await _loadDashboardData();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_syncService.lastSyncMessage),
          backgroundColor: success ? AppColors.forestGreen : AppColors.logoGoldDark,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión Docente'),
        content: const Text(
          '¿Está seguro de que desea salir del panel de administración docente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.teacherLogin,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherName = _teacher?.name ?? 'Prof. Docente Autorizado';
    final institution = _teacher?.institution ?? 'Instituto Nacional de Panamá';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppLogoLeading(),
        title: const Text(
          'Panel Docente',
          style: TextStyle(
            color: AppColors.logoNavy,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
          ),
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.logoGold),
                  )
                : const Icon(Icons.sync, color: AppColors.logoNavy),
            tooltip: 'Sincronizar Repositorio Institucional',
            onPressed: _isSyncing ? null : _handleSync,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.dangerRed),
            tooltip: 'Cerrar Sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.logoNavy))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.logoNavy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de perfil docente
                    _buildTeacherProfileCard(teacherName, institution),

                    const SizedBox(height: 20),

                    // Resumen métrico de documentos incorporados
                    const Text(
                      'Resumen Documental de la Institución',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMetricsGrid(),

                    const SizedBox(height: 24),

                    // Accesos principales a los módulos del profesor
                    const Text(
                      'Módulos de Gestión Académica',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. Gestión de Documentos / Biblioteca de Contenidos
                    _buildModuleTile(
                      title: 'Gestión de Documentos',
                      subtitle: 'Incorporar libros, PDFs e imágenes históricas para los estudiantes.',
                      icon: Icons.library_books,
                      badgeText: '$_publishedDocuments Publicados',
                      badgeColor: AppColors.forestGreen,
                      onTap: () async {
                        await Navigator.pushNamed(context, AppRoutes.teacherDocuments);
                        _loadDashboardData();
                      },
                    ),

                    const SizedBox(height: 12),

                    // 2. Gestión y Seguimiento de Estudiantes
                    _buildModuleTile(
                      title: 'Gestión y Seguimiento de Estudiantes',
                      subtitle: 'Supervisar el avance de lectura, sesiones activas y progreso.',
                      icon: Icons.groups_outlined,
                      badgeText: '$_studentCount Alumnos',
                      badgeColor: AppColors.logoNavy,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.teacherStudents);
                      },
                    ),

                    const SizedBox(height: 12),

                    // 3. Evaluación y Reportes Académicos
                    _buildModuleTile(
                      title: 'Evaluación y Reportes Académicos',
                      subtitle: 'Rendimiento escolar, analíticas por módulo y reportes MEDUCA.',
                      icon: Icons.analytics_outlined,
                      badgeText: 'Métricas',
                      badgeColor: AppColors.logoGoldDark,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.teacherEvaluations);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Banner de Sincronización Institucional Compartida
                    _buildSyncStatusBanner(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTeacherProfileCard(String name, String institution) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.logoNavyDark, AppColors.logoNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoNavy.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.logoGold.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.school, color: AppColors.logoGold, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Serif',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      institution,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.logoGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.logoGold.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'Rol: DOCENTE AUTORIZADO • Panamá Histórica MEDUCA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.logoGoldLight,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'Total Archivos',
            value: '$_totalDocuments',
            icon: Icons.folder_copy_outlined,
            color: AppColors.logoNavy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            label: 'Publicados',
            value: '$_publishedDocuments',
            icon: Icons.check_circle_outline,
            color: AppColors.forestGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            label: 'Borradores',
            value: '$_draftDocuments',
            icon: Icons.edit_note_outlined,
            color: AppColors.logoGoldDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            label: 'Archivados',
            value: '$_archivedDocuments',
            icon: Icons.archive_outlined,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: badgeColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sandAccent.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amberBadge),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_done_outlined, color: Color(0xFF7C2D12), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Almacenamiento Compartido Activo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C2D12),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _syncService.lastSyncMessage,
                  style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _handleSync,
            child: const Text(
              'Sincronizar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

