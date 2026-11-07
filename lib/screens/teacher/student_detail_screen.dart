import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/academic_evaluation_model.dart';
import '../../models/student_tracking_model.dart';
import '../../services/evaluation_storage_service.dart';
import '../../widgets/app_logo_leading.dart';
import 'evaluation_register_screen.dart';
import 'teacher_evaluations_screen.dart';

/// Pantalla de Detalle Individual del Estudiante para el rol DOCENTE.
/// Presenta información completa, progreso por módulo histórico, secciones pendientes,
/// documentos consultados, preguntas al Historiador IA y calificaciones registradas.
class StudentDetailScreen extends StatefulWidget {
  final StudentTrackingModel student;

  const StudentDetailScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final EvaluationStorageService _evaluationService = EvaluationStorageService();

  List<AcademicEvaluationModel> _evaluations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
  }

  Future<void> _loadEvaluations() async {
    await _evaluationService.initialize();
    final evals = await _evaluationService.getEvaluationsForStudent(widget.student.id);

    if (mounted) {
      setState(() {
        _evaluations = evals;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final isInactive = student.status == 'Inactivo';
    final double? average = _evaluations.isNotEmpty
        ? _evaluationService.calculateAverage(_evaluations)
        : null;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 84,
        leading: const AppLogoLeading(showBackButton: true),
        title: const Text('Ficha del Estudiante'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.logoNavy))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tarjeta de Perfil del Estudiante
                  _buildStudentHeaderCard(student, isInactive),

                  // Alerta prioritaria si requiere seguimiento
                  if (student.requiresFollowup) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Atención Pedagógica Requerida',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.dangerRed),
                                ),
                                Text(
                                  student.progress < 0.50
                                      ? 'El avance académico (${(student.progress * 100).toInt()}%) está por debajo del promedio grupal recomendado.'
                                      : 'El estudiante registra ${student.lastActive} sin interacción en la plataforma.',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 2. Indicadores Clave de Avance
                  _buildMetricsRow(student, average),

                  const SizedBox(height: 24),

                  // 3. Progreso y Módulos Históricos
                  const Text(
                    'Progreso en Módulos Históricos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  _buildModulesTrackingCard(student),

                  const SizedBox(height: 24),

                  // 4. Secciones y Contenidos Pendientes
                  if (student.pendingSections.isNotEmpty) ...[
                    const Text(
                      'Secciones Pendientes de Estudio',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    _buildPendingSectionsCard(student.pendingSections),
                    const SizedBox(height: 24),
                  ],

                  // 5. Documentos y Materiales del Docente Consultados
                  const Text(
                    'Documentos y Materiales Consultados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Registro de materiales y libros históricos abiertos por el estudiante:',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  _buildConsultedDocumentsCard(student.consultedDocuments),

                  const SizedBox(height: 24),

                  // 6. Consultas al Historiador IA
                  if (student.historianInquiries.isNotEmpty) ...[
                    const Text(
                      'Consultas al Historiador IA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Interacciones autorizadas con el asistente documental de Panamá Histórica:',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    _buildHistorianInquiriesCard(student.historianInquiries),
                    const SizedBox(height: 24),
                  ],

                  // 7. Calificaciones y Observaciones Académicas Registradas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Evaluaciones y Observaciones',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16, color: AppColors.primaryTeal),
                        label: const Text('Nueva Nota', style: TextStyle(color: AppColors.primaryTeal, fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EvaluationRegisterScreen(initialStudentId: student.id),
                            ),
                          );
                          _loadEvaluations();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildEvaluationsListCard(),

                  const SizedBox(height: 28),

                  // 8. Botones de Acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: AppColors.logoNavy),
                          ),
                          icon: const Icon(Icons.history_edu, size: 18, color: AppColors.logoNavy),
                          label: const Text('Ver Historial', style: TextStyle(color: AppColors.logoNavy, fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeacherEvaluationsScreen(initialStudentId: student.id),
                              ),
                            ).then((_) => _loadEvaluations());
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forestGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.grade_outlined, size: 18),
                          label: const Text('Evaluar Estudiante', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EvaluationRegisterScreen(initialStudentId: student.id),
                              ),
                            );
                            if (res == true) {
                              _loadEvaluations();
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentHeaderCard(StudentTrackingModel student, bool isInactive) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isInactive ? Colors.grey.shade400 : AppColors.logoNavy,
            child: Text(
              student.name.substring(0, 1),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
                const SizedBox(height: 2),
                Text(
                  '${student.fullGradeSection} • ${student.email}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isInactive
                            ? Colors.grey.shade200
                            : AppColors.forestGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        student.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isInactive ? Colors.grey.shade700 : AppColors.forestGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Activo: ${student.lastActive}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(StudentTrackingModel student, double? average) {
    return Row(
      children: [
        // Progreso general
        Expanded(
          child: _buildMetricTile(
            title: 'Progreso General',
            value: '${(student.progress * 100).toInt()}%',
            subtitle: student.activeModule,
            color: student.progress >= 0.70 ? AppColors.forestGreen : AppColors.logoGoldDark,
            icon: Icons.donut_large,
          ),
        ),
        const SizedBox(width: 10),
        // Horas de estudio
        Expanded(
          child: _buildMetricTile(
            title: 'Horas de Estudio',
            value: student.studyHours,
            subtitle: '${student.documentsRead} docs leídos',
            color: AppColors.logoNavy,
            icon: Icons.timer_outlined,
          ),
        ),
        const SizedBox(width: 10),
        // Promedio académico
        Expanded(
          child: _buildMetricTile(
            title: 'Promedio Notas',
            value: average != null ? average.toStringAsFixed(1) : 'S/E',
            subtitle: average != null
                ? (average >= 71 ? 'Aprobado' : 'Refuerzo')
                : 'Sin notas',
            color: average != null && average >= 71 ? AppColors.forestGreen : AppColors.dangerRed,
            icon: Icons.grade_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color, fontFamily: 'Serif'),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModulesTrackingCard(StudentTrackingModel student) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Módulos completados
          if (student.completedModules.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: AppColors.forestGreen),
                SizedBox(width: 6),
                Text('Módulos Históricos Completados:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.forestGreen)),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: student.completedModules
                  .map((m) => Chip(
                        label: Text(m, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.forestGreen.withValues(alpha: 0.1),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 10),
          ],

          // Módulo en curso
          const Text('Módulo Actual en Estudio:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.logoNavy)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(student.activeModule, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              Text(
                '${(student.progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.logoNavy),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: student.progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                student.progress >= 0.70 ? AppColors.forestGreen : AppColors.logoGoldDark,
              ),
              minHeight: 6,
            ),
          ),

          // Módulos pendientes
          if (student.pendingModules.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Módulos Pendientes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            ...student.pendingModules.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_unchecked, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(m, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingSectionsCard(List<String> sections) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_outline, size: 14, color: Color(0xFFB45309)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildConsultedDocumentsCard(List<String> documents) {
    if (documents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: const Text('No registra documentos o libros consultados aún.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: documents.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final doc = documents[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.picture_as_pdf, color: AppColors.dangerRed, size: 20),
            title: Text(doc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            subtitle: const Text('Consulta registrada en el módulo', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            trailing: const Icon(Icons.check_circle_outline, color: AppColors.forestGreen, size: 16),
          );
        },
      ),
    );
  }

  Widget _buildHistorianInquiriesCard(List<String> inquiries) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: inquiries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.smart_toy_outlined, color: AppColors.primaryTeal, size: 20),
            title: Text(inquiries[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            subtitle: const Text('Respuesta fundamentada en fuentes del 9 de enero', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          );
        },
      ),
    );
  }

  Widget _buildEvaluationsListCard() {
    if (_evaluations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: const Text('El estudiante no cuenta con evaluaciones registradas aún.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _evaluations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final eval = _evaluations[index];
          final Color badgeColor = eval.score >= 90
              ? AppColors.forestGreen
              : eval.score >= 80
                  ? AppColors.primaryTeal
                  : eval.score >= 71
                      ? AppColors.logoGoldDark
                      : AppColors.dangerRed;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        eval.activityTitle,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${eval.score.toStringAsFixed(1)} pts (${eval.performanceLevel})',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${eval.moduleTitle} • ${eval.sectionTitle} • ${eval.formattedDate}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                if (eval.observations.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Obs: "${eval.observations}"',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
