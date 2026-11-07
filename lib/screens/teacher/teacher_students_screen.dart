import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/academic_evaluation_model.dart';
import '../../models/student_tracking_model.dart';
import '../../services/evaluation_storage_service.dart';
import '../../services/student_tracking_service.dart';
import '../../widgets/app_logo_leading.dart';
import 'student_detail_screen.dart';

/// Pantalla principal de Gestión y Seguimiento de Estudiantes para el rol DOCENTE.
/// Muestra métricas reales del grupo (sin datos ficticios), barra de búsqueda,
/// filtros por grado y estado, identificación de estudiantes que requieren seguimiento
/// y navegación hacia la ficha de detalle individual.
class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  final StudentTrackingService _studentService = StudentTrackingService();
  final EvaluationStorageService _evaluationService = EvaluationStorageService();

  String _searchQuery = '';
  String _selectedGradeFilter = 'Todos';
  String _selectedStatusFilter = 'Todos'; // 'Todos', 'Activos', 'Requieren Seguimiento'

  List<StudentTrackingModel> _students = [];
  List<AcademicEvaluationModel> _evaluations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _evaluationService.initialize();
    final students = _studentService.getStudents();
    final evals = await _evaluationService.getAllEvaluations();

    if (mounted) {
      setState(() {
        _students = students;
        _evaluations = evals;
        _isLoading = false;
      });
    }
  }

  List<StudentTrackingModel> get _filteredStudents {
    return _students.where((s) {
      final matchesSearch = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGrade = _selectedGradeFilter == 'Todos' || s.grade == _selectedGradeFilter;

      bool matchesStatus = true;
      if (_selectedStatusFilter == 'Activos') {
        matchesStatus = s.status == 'Activo';
      } else if (_selectedStatusFilter == 'Requieren Seguimiento') {
        matchesStatus = s.requiresFollowup;
      }

      return matchesSearch && matchesGrade && matchesStatus;
    }).toList();
  }

  double? _getStudentAverage(String studentId) {
    final list = _evaluations.where((e) => e.studentId == studentId).toList();
    if (list.isEmpty) return null;
    return _evaluationService.calculateAverage(list);
  }

  void _openStudentDetail(StudentTrackingModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailScreen(student: student),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _students.where((s) => s.status == 'Activo').length;
    final averageGroupProgress = _studentService.calculateAverageProgress();
    final needingFollowup = _students.where((s) => s.requiresFollowup).length;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 84,
        leading: const AppLogoLeading(showBackButton: true),
        title: const Text('Gestión de Estudiantes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.logoNavy))
          : Column(
              children: [
                // 1. Resumen General del Grupo (Indicadores Reales)
                _buildGroupSummaryHeader(
                  total: _students.length,
                  active: activeCount,
                  averageProgress: averageGroupProgress,
                  needingFollowup: needingFollowup,
                ),

                // 2. Barra de Búsqueda y Filtros
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.surfaceWhite,
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'Buscar estudiante por nombre o correo...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Filtro de Grado
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['Todos', '10° Grado', '11° Grado', '12° Grado'].map((grade) {
                                  final isSelected = _selectedGradeFilter == grade;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(grade, style: const TextStyle(fontSize: 11)),
                                      selected: isSelected,
                                      onSelected: (_) => setState(() => _selectedGradeFilter = grade),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          // Filtro de Estado / Seguimiento
                          PopupMenuButton<String>(
                            initialValue: _selectedStatusFilter,
                            icon: const Icon(Icons.tune, size: 20, color: AppColors.logoNavy),
                            tooltip: 'Filtrar por estado',
                            onSelected: (val) => setState(() => _selectedStatusFilter = val),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'Todos', child: Text('Todos los estados')),
                              const PopupMenuItem(value: 'Activos', child: Text('Solo Activos')),
                              const PopupMenuItem(value: 'Requieren Seguimiento', child: Text('Requieren Seguimiento')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderGrey),

                // 3. Conteo y aviso de filtros
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredStudents.length} estudiantes autorizados',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                      if (_selectedGradeFilter != 'Todos' || _selectedStatusFilter != 'Todos' || _searchQuery.isNotEmpty)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedGradeFilter = 'Todos';
                              _selectedStatusFilter = 'Todos';
                              _searchQuery = '';
                            });
                          },
                          child: const Text(
                            'Restablecer',
                            style: TextStyle(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),

                // 4. Lista de Estudiantes
                Expanded(
                  child: _filteredStudents.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text(
                                'No se encontraron estudiantes para los filtros seleccionados.',
                                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: AppColors.logoNavy,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              final progress = student.progress;
                              final isInactive = student.status == 'Inactivo';
                              final avg = _getStudentAverage(student.id);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: student.requiresFollowup
                                        ? const Color(0xFFFDE68A)
                                        : AppColors.borderGrey,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: isInactive
                                          ? Colors.grey.shade400
                                          : AppColors.logoNavy.withValues(alpha: 0.15),
                                      child: Text(
                                        student.name.substring(0, 1),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isInactive ? Colors.white : AppColors.logoNavy,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            student.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        if (student.requiresFollowup)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.flag, size: 10, color: Color(0xFFB45309)),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Seguimiento',
                                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          '${student.fullGradeSection} • ${student.studyHours} de estudio • ${student.lastActive}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  backgroundColor: const Color(0xFFE2E8F0),
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    progress >= 0.7 ? AppColors.forestGreen : AppColors.logoGoldDark,
                                                  ),
                                                  minHeight: 5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              '${(progress * 100).toInt()}%',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: progress >= 0.7 ? AppColors.forestGreen : AppColors.logoGoldDark,
                                              ),
                                            ),
                                            if (avg != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: avg >= 71
                                                      ? AppColors.forestGreen.withValues(alpha: 0.1)
                                                      : AppColors.dangerRed.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${avg.toStringAsFixed(1)} pts',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: avg >= 71 ? AppColors.forestGreen : AppColors.dangerRed,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                                    onTap: () => _openStudentDetail(student),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildGroupSummaryHeader({
    required int total,
    required int active,
    required double averageProgress,
    required int needingFollowup,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.borderGrey)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              label: 'Total Alumnos',
              value: '$total',
              color: AppColors.logoNavy,
              icon: Icons.groups_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              label: 'Estudiantes Activos',
              value: '$active de $total',
              color: AppColors.forestGreen,
              icon: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              label: 'Progreso Promedio',
              value: '${averageProgress.toStringAsFixed(1)}%',
              color: AppColors.primaryTeal,
              icon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              label: 'Seguimiento',
              value: '$needingFollowup',
              color: needingFollowup > 0 ? const Color(0xFFD97706) : AppColors.forestGreen,
              icon: Icons.priority_high,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
