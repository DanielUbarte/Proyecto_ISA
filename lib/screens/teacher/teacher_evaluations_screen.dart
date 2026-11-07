import 'dart:io';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/academic_evaluation_model.dart';
import '../../models/student_tracking_model.dart';
import '../../services/auth_service.dart';
import '../../services/evaluation_storage_service.dart';
import '../../services/report_export_service.dart';
import '../../services/student_tracking_service.dart';
import '../../widgets/app_logo_leading.dart';
import '../../widgets/custom_button.dart';
import 'evaluation_register_screen.dart';

/// Pantalla principal del módulo de Evaluación y Reportes Académicos para el rol DOCENTE.
/// Integra el registro y modificación de calificaciones, historial filtrable,
/// cálculo de analíticas reales (sin datos estáticos) y exportación oficial a PDF y Excel.
class TeacherEvaluationsScreen extends StatefulWidget {
  final String? initialStudentId;
  final int initialTab;

  const TeacherEvaluationsScreen({
    super.key,
    this.initialStudentId,
    this.initialTab = 0,
  });

  @override
  State<TeacherEvaluationsScreen> createState() => _TeacherEvaluationsScreenState();
}

class _TeacherEvaluationsScreenState extends State<TeacherEvaluationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final EvaluationStorageService _storageService = EvaluationStorageService();
  final StudentTrackingService _studentService = StudentTrackingService();
  final ReportExportService _exportService = ReportExportService();
  final AuthService _authService = AuthService();

  List<AcademicEvaluationModel> _evaluations = [];
  List<StudentTrackingModel> _students = [];
  bool _isLoading = true;

  // Filtros de búsqueda e historial
  String _selectedStudentFilter = 'Todos';
  String _selectedModuleFilter = 'Todos';
  String _selectedPerformanceFilter = 'Todos';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );

    if (widget.initialStudentId != null) {
      _selectedStudentFilter = widget.initialStudentId!;
    }

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _storageService.initialize();

    final evals = await _storageService.getAllEvaluations();
    final students = _studentService.getStudents();

    if (mounted) {
      setState(() {
        _evaluations = evals;
        _students = students;
        _isLoading = false;
      });
    }
  }

  // Evaluaciones filtradas según criterios seleccionados por el docente
  List<AcademicEvaluationModel> get _filteredEvaluations {
    var list = _storageService.applyFilters(
      source: _evaluations,
      studentId: _selectedStudentFilter == 'Todos' ? null : _selectedStudentFilter,
      moduleId: _selectedModuleFilter == 'Todos' ? null : _selectedModuleFilter,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );

    if (_selectedPerformanceFilter != 'Todos') {
      if (_selectedPerformanceFilter == 'Sobresaliente') {
        list = list.where((e) => e.score >= 90.0).toList();
      } else if (_selectedPerformanceFilter == 'Bueno') {
        list = list.where((e) => e.score >= 80.0 && e.score < 90.0).toList();
      } else if (_selectedPerformanceFilter == 'Regular') {
        list = list.where((e) => e.score >= 71.0 && e.score < 80.0).toList();
      } else if (_selectedPerformanceFilter == 'Requiere Refuerzo') {
        list = list.where((e) => e.score < 71.0).toList();
      }
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((e) {
        return e.studentName.toLowerCase().contains(q) ||
            e.activityTitle.toLowerCase().contains(q) ||
            e.sectionTitle.toLowerCase().contains(q) ||
            e.observations.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  // Lista única de módulos presentes en las evaluaciones
  List<String> get _availableModules {
    final set = _evaluations.map((e) => e.moduleTitle).toSet();
    if (set.isEmpty) {
      return ['Panamá Contemporánea'];
    }
    return set.toList();
  }

  Future<void> _openRegisterScreen({AcademicEvaluationModel? evaluationToEdit}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EvaluationRegisterScreen(
          evaluationToEdit: evaluationToEdit,
          initialStudentId: _selectedStudentFilter != 'Todos' ? _selectedStudentFilter : null,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _confirmDeleteEvaluation(AcademicEvaluationModel eval) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed),
            SizedBox(width: 8),
            Text('Eliminar Calificación'),
          ],
        ),
        content: Text(
          '¿Desea eliminar permanentemente la evaluación de ${eval.studentName} en "${eval.activityTitle}" (${eval.score.toStringAsFixed(1)} pts)?',
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.deleteEvaluation(eval.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluación eliminada correctamente.'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final initialDateRange = _selectedDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.logoNavy,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStudentFilter = 'Todos';
      _selectedModuleFilter = 'Todos';
      _selectedPerformanceFilter = 'Todos';
      _selectedDateRange = null;
      _searchQuery = '';
    });
  }

  Future<void> _exportPdfReport() async {
    final teacher = _authService.currentUser;
    final teacherName = teacher?.name ?? 'Prof. Alejandro Méndez';
    final institution = teacher?.institution ?? 'Instituto Nacional de Panamá';

    final evaluationsToExport = _filteredEvaluations;
    final average = _storageService.calculateAverage(evaluationsToExport);
    final count = _storageService.countEvaluatedStudents(evaluationsToExport);

    final filterDesc = _buildFilterSummary();

    try {
      final File file = await _exportService.generatePdfReport(
        reportTitle: 'Informe Oficial de Rendimiento Histórico',
        teacherName: teacherName,
        institution: institution,
        evaluations: evaluationsToExport,
        averageScore: average,
        evaluatedStudentsCount: count,
        filterDescription: filterDesc,
      );

      if (mounted) {
        _showExportSuccessDialog(
          format: 'PDF',
          filePath: file.path,
          totalRecords: evaluationsToExport.length,
          average: average,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _exportExcelReport() async {
    final teacher = _authService.currentUser;
    final teacherName = teacher?.name ?? 'Prof. Alejandro Méndez';
    final institution = teacher?.institution ?? 'Instituto Nacional de Panamá';

    final evaluationsToExport = _filteredEvaluations;
    final average = _storageService.calculateAverage(evaluationsToExport);
    final count = _storageService.countEvaluatedStudents(evaluationsToExport);

    final filterDesc = _buildFilterSummary();

    try {
      final File file = await _exportService.generateExcelReport(
        reportTitle: 'Planilla de Calificaciones y Analítica Curricular',
        teacherName: teacherName,
        institution: institution,
        evaluations: evaluationsToExport,
        averageScore: average,
        evaluatedStudentsCount: count,
        filterDescription: filterDesc,
      );

      if (mounted) {
        _showExportSuccessDialog(
          format: 'Excel (.CSV)',
          filePath: file.path,
          totalRecords: evaluationsToExport.length,
          average: average,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar Excel: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  String _buildFilterSummary() {
    final parts = <String>[];
    if (_selectedStudentFilter != 'Todos') {
      final s = _students.firstWhere(
        (st) => st.id == _selectedStudentFilter,
        orElse: () => StudentTrackingModel(
          id: _selectedStudentFilter,
          name: _selectedStudentFilter,
          email: '',
          grade: '',
          progress: 0,
          studyHours: '',
          lastActive: '',
          status: '',
          activeModule: '',
          documentsRead: 0,
        ),
      );
      parts.add('Estudiante: ${s.name}');
    }
    if (_selectedModuleFilter != 'Todos') {
      parts.add('Módulo: $_selectedModuleFilter');
    }
    if (_selectedPerformanceFilter != 'Todos') {
      parts.add('Nivel: $_selectedPerformanceFilter');
    }
    if (_selectedDateRange != null) {
      final s = _selectedDateRange!.start;
      final e = _selectedDateRange!.end;
      parts.add('Rango: ${s.day}/${s.month}/${s.year} - ${e.day}/${e.month}/${e.year}');
    }
    return parts.isEmpty ? 'Todos los registros disponibles' : parts.join(' | ');
  }

  void _showExportSuccessDialog({
    required String format,
    required String filePath,
    required int totalRecords,
    required double average,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              format == 'PDF' ? Icons.picture_as_pdf : Icons.table_chart,
              color: format == 'PDF' ? AppColors.dangerRed : AppColors.forestGreen,
            ),
            const SizedBox(width: 8),
            Text('Reporte $format Generado', style: const TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'El documento se ha generado exitosamente según los estándares oficiales de MEDUCA.',
              style: TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sandAccent.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Registros incluidos: $totalRecords evaluaciones', style: const TextStyle(fontSize: 12)),
                  Text('• Promedio general calculado: ${average.toStringAsFixed(1)} / 100 pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Ruta de almacenamiento local:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.logoNavy)),
                  SelectableText(filePath, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
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
        title: const Text('Evaluación y Reportes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.logoNavy,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.logoGold,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.history_edu), text: 'Historial y Registros'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Reportes y Analíticas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.logoNavy))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.logoNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Calificación'),
        onPressed: () => _openRegisterScreen(),
      ),
    );
  }

  // ==========================================
  // TAB 1: HISTORIAL Y REGISTROS
  // ==========================================
  Widget _buildHistoryTab() {
    final filtered = _filteredEvaluations;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.logoNavy,
      child: Column(
        children: [
          // Barra de Búsqueda y Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surfaceWhite,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por estudiante, actividad o contenido...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Filtro de Estudiante
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStudentFilter,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                            items: [
                              const DropdownMenuItem(value: 'Todos', child: Text('Estudiantes: Todos')),
                              ..._students.map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedStudentFilter = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filtro de Módulo
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedModuleFilter,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                            items: [
                              const DropdownMenuItem(value: 'Todos', child: Text('Módulos: Todos')),
                              ..._availableModules.map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedModuleFilter = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderGrey),

          // Conteo y botón de limpiar filtros si están activos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} evaluaciones encontradas',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
                if (_selectedStudentFilter != 'Todos' || _selectedModuleFilter != 'Todos' || _searchQuery.isNotEmpty)
                  InkWell(
                    onTap: _clearFilters,
                    child: const Text(
                      'Restablecer filtros',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // Lista de Calificaciones
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No hay evaluaciones que coincidan con el filtro.',
                          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _openRegisterScreen(),
                          child: const Text('Registrar una nueva calificación'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildEvaluationCard(filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(AcademicEvaluationModel eval) {
    final Color badgeColor = eval.score >= 90.0
        ? AppColors.forestGreen
        : eval.score >= 80.0
            ? AppColors.primaryTeal
            : eval.score >= 71.0
                ? AppColors.logoGoldDark
                : AppColors.dangerRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Estudiante, Grado y Fecha
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.logoNavy.withValues(alpha: 0.1),
                child: Text(
                  eval.studentName.substring(0, 1),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.logoNavy),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eval.studentName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    Text(
                      '${eval.studentGrade} • ${eval.formattedDate}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // Calificación Numérica Destacada (0-100)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${eval.score.toStringAsFixed(1)} / 100',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                        fontFamily: 'Serif',
                      ),
                    ),
                    Text(
                      eval.performanceLevel,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Módulo y Sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sandAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  eval.moduleTitle,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C2D12)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  eval.sectionTitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Actividad Evaluada
          Text(
            eval.activityTitle,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),

          // Observaciones si existen
          if (eval.observations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_outlined, size: 14, color: AppColors.primaryTeal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      eval.observations,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 6),

          // Botones de Modificar y Eliminar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Docente: ${eval.teacherName}',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryTeal),
                label: const Text('Modificar', style: TextStyle(fontSize: 12, color: AppColors.primaryTeal)),
                onPressed: () => _openRegisterScreen(evaluationToEdit: eval),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 14, color: AppColors.dangerRed),
                label: const Text('Eliminar', style: TextStyle(fontSize: 12, color: AppColors.dangerRed)),
                onPressed: () => _confirmDeleteEvaluation(eval),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: REPORTES Y ANALÍTICAS (Métricas Reales)
  // ==========================================
  Widget _buildAnalyticsTab() {
    final filtered = _filteredEvaluations;
    final average = _storageService.calculateAverage(filtered);
    final countStudents = _storageService.countEvaluatedStudents(filtered);
    final distribution = _storageService.getDistribution(filtered);
    final moduleAverages = _storageService.getAveragePerModule(filtered);
    final lowPerformance = _storageService.getLowPerformance(filtered);
    final topPerformance = _storageService.getTopPerformance(filtered);

    final passingCount = filtered.where((e) => e.isApproved).length;
    final double passingRate = filtered.isEmpty ? 0.0 : (passingCount / filtered.length) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Barra de Filtros del Reporte
          _buildReportFilterBar(),

          const SizedBox(height: 16),

          // 2. Tarjeta Resumen de Promedio y Métricas Reales
          Container(
            padding: const EdgeInsets.all(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Promedio General Calculado',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.logoGold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Datos Reales Almacenados',
                        style: TextStyle(fontSize: 10, color: AppColors.logoGoldLight, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      average.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Serif',
                      ),
                    ),
                    const Text(' / 100 pts', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    const Spacer(),
                    const Icon(Icons.trending_up, color: AppColors.logoGold, size: 36),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estudiantes Evaluados:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(
                      '$countStudents de ${_students.length} (${_students.isEmpty ? 0 : ((countStudents / _students.length) * 100).toInt()}%)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Evaluaciones Registradas:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('${filtered.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tasa de Aprobación (≥ 71 pts):', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(
                      '${passingRate.toStringAsFixed(1)}%',
                      style: const TextStyle(color: AppColors.logoGoldLight, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Representación Gráfica de Distribución del Rendimiento
          const Text(
            'Distribución de Rendimiento Académico',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Clasificación según los estándares oficiales de escala MEDUCA:',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          _buildDistributionVisual(distribution, filtered.length),

          const SizedBox(height: 24),

          // 4. Rendimiento por Módulo Histórico
          const Text(
            'Rendimiento por Módulo Histórico',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          if (moduleAverages.isEmpty)
            const Text('No hay registros por módulo disponibles.', style: TextStyle(color: AppColors.textMuted))
          else
            ...moduleAverages.entries.map((entry) => _buildModuleScoreBar(entry.key, entry.value)),

          const SizedBox(height: 24),

          // 5. Rendimiento Individual de Estudiantes
          const Text(
            'Rendimiento Individual de los Estudiantes',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          _buildIndividualStudentsPerformance(filtered),

          const SizedBox(height: 24),

          // 6. Alertas Pedagógicas: Bajo Rendimiento y Sobresalientes
          _buildPedagogicalAlerts(lowPerformance, topPerformance),

          const SizedBox(height: 28),

          // 7. Botones Oficiales de Exportación (PDF y Excel)
          const Text(
            'Exportación de Reportes Oficiales',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Descargue las planillas oficiales para supervisión docente y dirección académica.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Exportar PDF',
                  icon: Icons.picture_as_pdf,
                  variant: CustomButtonVariant.green,
                  onPressed: _exportPdfReport,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Exportar Excel',
                  icon: Icons.table_chart,
                  variant: CustomButtonVariant.outline,
                  onPressed: _exportExcelReport,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildReportFilterBar() {
    final hasActiveFilters = _selectedStudentFilter != 'Todos' ||
        _selectedModuleFilter != 'Todos' ||
        _selectedPerformanceFilter != 'Todos' ||
        _selectedDateRange != null;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.logoNavy),
                  SizedBox(width: 6),
                  Text('Filtros del Reporte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              if (hasActiveFilters)
                InkWell(
                  onTap: _clearFilters,
                  child: const Text('Limpiar', style: TextStyle(fontSize: 12, color: AppColors.dangerRed, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Selector de Nivel
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPerformanceFilter,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                      items: const [
                        DropdownMenuItem(value: 'Todos', child: Text('Nivel: Todos')),
                        DropdownMenuItem(value: 'Sobresaliente', child: Text('Sobresaliente (≥90)')),
                        DropdownMenuItem(value: 'Bueno', child: Text('Bueno (80-89)')),
                        DropdownMenuItem(value: 'Regular', child: Text('Regular (71-79)')),
                        DropdownMenuItem(value: 'Requiere Refuerzo', child: Text('Requiere Refuerzo (<71)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPerformanceFilter = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Selector de Fechas
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Rango de Fechas'
                        : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: _selectDateRange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionVisual(Map<String, int> distribution, int total) {
    if (total == 0) {
      return const Text('Sin registros para calcular distribución.', style: TextStyle(color: AppColors.textMuted));
    }

    final sobresaliente = distribution['Sobresaliente (90-100)'] ?? 0;
    final bueno = distribution['Bueno (80-89)'] ?? 0;
    final regular = distribution['Regular (71-79)'] ?? 0;
    final refuerzo = distribution['Requiere Refuerzo (<71)'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          _buildBarRow('Sobresaliente (90 - 100 pts)', sobresaliente, total, AppColors.forestGreen),
          const SizedBox(height: 10),
          _buildBarRow('Bueno (80 - 89 pts)', bueno, total, AppColors.primaryTeal),
          const SizedBox(height: 10),
          _buildBarRow('Regular (71 - 79 pts)', regular, total, AppColors.logoGoldDark),
          const SizedBox(height: 10),
          _buildBarRow('Requiere Refuerzo (< 71 pts)', refuerzo, total, AppColors.dangerRed),
        ],
      ),
    );
  }

  Widget _buildBarRow(String label, int count, int total, Color color) {
    final double pct = total > 0 ? (count / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            Text(
              '$count de $total (${(pct * 100).toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleScoreBar(String moduleTitle, double average) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book, color: AppColors.logoNavy, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(moduleTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (average / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      average >= 80 ? AppColors.forestGreen : AppColors.logoGoldDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '${average.toStringAsFixed(1)} pts',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.logoNavy, fontFamily: 'Serif'),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualStudentsPerformance(List<AcademicEvaluationModel> evaluations) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _students.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderGrey),
        itemBuilder: (context, index) {
          final student = _students[index];
          final studentEvals = evaluations.where((e) => e.studentId == student.id).toList();
          final hasEvals = studentEvals.isNotEmpty;
          final double studentAvg = _storageService.calculateAverage(studentEvals);

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.logoNavy.withValues(alpha: 0.1),
              child: Text(
                student.name.substring(0, 1),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.logoNavy, fontSize: 12),
              ),
            ),
            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(
              '${student.grade} • ${studentEvals.length} evaluaciones',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            trailing: hasEvals
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: studentAvg >= 71.0
                          ? AppColors.forestGreen.withValues(alpha: 0.1)
                          : AppColors.dangerRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${studentAvg.toStringAsFixed(1)} pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: studentAvg >= 71.0 ? AppColors.forestGreen : AppColors.dangerRed,
                      ),
                    ),
                  )
                : const Text('Sin evaluar', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          );
        },
      ),
    );
  }

  Widget _buildPedagogicalAlerts(
    List<AcademicEvaluationModel> lowPerformance,
    List<AcademicEvaluationModel> topPerformance,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alerta de Bajo Rendimiento (< 71)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Atención Pedagógica: Bajo Rendimiento (< 71 pts)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.dangerRed),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (lowPerformance.isEmpty)
                const Text(
                  'No hay estudiantes registrados con bajo rendimiento en los criterios seleccionados.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                )
              else
                ...lowPerformance.map((eval) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• ${eval.studentName}: ${eval.score.toStringAsFixed(1)} pts en "${eval.activityTitle}" (${eval.sectionTitle})',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                      ),
                    )),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Destacados Sobresalientes (>= 90)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.star_rounded, color: AppColors.forestGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Estudiantes con Rendimiento Sobresaliente (≥ 90 pts)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.forestGreen),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (topPerformance.isEmpty)
                const Text(
                  'No se registran evaluaciones sobresalientes con los filtros activos.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                )
              else
                ...topPerformance.map((eval) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• ${eval.studentName}: ${eval.score.toStringAsFixed(1)} pts en "${eval.activityTitle}"',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }
}
