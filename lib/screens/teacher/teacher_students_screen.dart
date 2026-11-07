import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/academic_evaluation_model.dart';
import '../../models/student_tracking_model.dart';
import '../../services/evaluation_storage_service.dart';
import '../../services/student_tracking_service.dart';
import '../../widgets/app_logo_leading.dart';
import 'evaluation_register_screen.dart';
import 'teacher_evaluations_screen.dart';

/// Pantalla de Gestión y Seguimiento de Estudiantes.
/// Integrada bidireccionalmente con el módulo de Evaluación y Reportes Académicos.
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
      return matchesSearch && matchesGrade;
    }).toList();
  }

  double? _getStudentAverage(String studentId) {
    final list = _evaluations.where((e) => e.studentId == studentId).toList();
    if (list.isEmpty) return null;
    return _evaluationService.calculateAverage(list);
  }

  int _getStudentEvalCount(String studentId) {
    return _evaluations.where((e) => e.studentId == studentId).length;
  }

  void _showStudentDetails(StudentTrackingModel student) {
    final avg = _getStudentAverage(student.id);
    final evalCount = _getStudentEvalCount(student.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.logoNavy,
                  child: Text(
                    student.name.substring(0, 1),
                    style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        '${student.grade} • ${student.email}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (avg != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: avg >= 71 ? AppColors.forestGreen.withValues(alpha: 0.15) : AppColors.dangerRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${avg.toStringAsFixed(1)} pts',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: avg >= 71 ? AppColors.forestGreen : AppColors.dangerRed,
                          ),
                        ),
                        Text(
                          avg >= 90 ? 'Sobresaliente' : avg >= 80 ? 'Bueno' : avg >= 71 ? 'Regular' : 'Refuerzo',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: avg >= 71 ? AppColors.forestGreen : AppColors.dangerRed,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            _buildDetailRow('Módulo en Curso:', student.activeModule),
            _buildDetailRow('Progreso de Lectura:', '${(student.progress * 100).toInt()}%'),
            _buildDetailRow('Documentos Históricos Consultados:', '${student.documentsRead} materiales'),
            _buildDetailRow('Horas Totales de Estudio:', student.studyHours),
            _buildDetailRow('Última Actividad:', student.lastActive),
            _buildDetailRow('Estado del Estudiante:', student.status),

            // Métricas académicas integradas
            const SizedBox(height: 6),
            const Divider(),
            const SizedBox(height: 6),
            _buildDetailRow(
              'Promedio Académico Calculado:',
              avg != null ? '${avg.toStringAsFixed(1)} / 100 pts' : 'Sin evaluaciones aún',
            ),
            _buildDetailRow('Evaluaciones Registradas:', '$evalCount realizadas'),

            const SizedBox(height: 20),

            // Acciones integradas: Ver calificaciones o Evaluar estudiante
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: AppColors.logoNavy),
                    ),
                    icon: const Icon(Icons.history_edu, size: 18, color: AppColors.logoNavy),
                    label: const Text('Ver Historial', style: TextStyle(color: AppColors.logoNavy, fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherEvaluationsScreen(initialStudentId: student.id),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.grade_outlined, size: 18),
                    label: const Text('Evaluar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EvaluationRegisterScreen(initialStudentId: student.id),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // Barra de Búsqueda y Filtro de Grado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppColors.surfaceWhite,
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'Buscar por nombre o correo estudiantil...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Todos', '10° Grado', '11° Grado', '12° Grado'].map((grade) {
                            final isSelected = _selectedGradeFilter == grade;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(grade, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedGradeFilter = grade),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderGrey),

                // Lista de Estudiantes
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.logoNavy,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                                  if (avg != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: avg >= 71 ? AppColors.forestGreen.withValues(alpha: 0.1) : AppColors.dangerRed.withValues(alpha: 0.1),
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
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    '${student.grade} • Progreso: ${(progress * 100).toInt()}% • ${student.lastActive}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
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
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                              onTap: () => _showStudentDetails(student),
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
}
