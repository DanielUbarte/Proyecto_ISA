import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/academic_evaluation_model.dart';
import '../../models/module_model.dart';
import '../../models/student_tracking_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/document_storage_service.dart';
import '../../services/evaluation_storage_service.dart';
import '../../services/student_tracking_service.dart';
import '../../widgets/app_logo_leading.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Pantalla para el registro y edición de calificaciones y observaciones académicas.
/// Aplica validaciones estrictas de rango (0-100), formato numérico y campos obligatorios.
class EvaluationRegisterScreen extends StatefulWidget {
  final AcademicEvaluationModel? evaluationToEdit;
  final String? initialStudentId;

  const EvaluationRegisterScreen({
    super.key,
    this.evaluationToEdit,
    this.initialStudentId,
  });

  @override
  State<EvaluationRegisterScreen> createState() => _EvaluationRegisterScreenState();
}

class _EvaluationRegisterScreenState extends State<EvaluationRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final EvaluationStorageService _storageService = EvaluationStorageService();
  final StudentTrackingService _studentService = StudentTrackingService();
  final DatabaseService _dbService = DatabaseService();
  final DocumentStorageService _docStorage = DocumentStorageService();
  final AuthService _authService = AuthService();

  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _activityController = TextEditingController(text: 'Comprobación de Lectura');

  List<StudentTrackingModel> _students = [];
  String? _selectedStudentId;

  List<ModuleModel> _modules = [];
  String _selectedModuleId = 'mod_contemporanea';
  String _selectedModuleTitle = 'Panamá Contemporánea';

  List<String> _sections = [];
  String _selectedSection = '9 de enero de 1964';

  bool _isLoading = false;
  String? _scoreValidationError;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    final students = _studentService.getStudents();
    final modules = await _dbService.getModules();
    final sections = await _docStorage.getSectionsForModule(_selectedModuleId);

    if (mounted) {
      setState(() {
        _students = students;
        _modules = modules;
        _sections = sections;

        if (widget.evaluationToEdit != null) {
          final e = widget.evaluationToEdit!;
          _selectedStudentId = e.studentId;
          _selectedModuleId = e.moduleId;
          _selectedModuleTitle = e.moduleTitle;
          _selectedSection = e.sectionTitle;
          _activityController.text = e.activityTitle;
          _scoreController.text = e.score.toStringAsFixed(1);
          _observationsController.text = e.observations;
        } else {
          _selectedStudentId = widget.initialStudentId ?? (students.isNotEmpty ? students.first.id : null);
          if (sections.isNotEmpty) {
            _selectedSection = sections.first;
          }
        }
      });
    }
  }

  /// Valida estrictamente que el valor sea numérico, no esté vacío y se encuentre entre 0 y 100.
  String? _validateScore(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La calificación es obligatoria.';
    }

    final cleanValue = value.trim().replaceAll(',', '.');

    // Comprobar que solo contenga dígitos y como máximo un punto decimal
    final isNumeric = RegExp(r'^\d+(\.\d+)?$').hasMatch(cleanValue);
    if (!isNumeric) {
      return 'Introduzca únicamente números válidos (0 a 100).';
    }

    final double? parsed = double.tryParse(cleanValue);
    if (parsed == null) {
      return 'Valor numérico no reconocido.';
    }

    if (parsed < 0.0) {
      return 'La calificación no puede ser menor a 0.';
    }

    if (parsed > 100.0) {
      return 'La calificación no puede ser mayor a 100.';
    }

    return null;
  }

  Future<void> _saveEvaluation() async {
    setState(() {
      _scoreValidationError = _validateScore(_scoreController.text);
    });

    if (_scoreValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_scoreValidationError!),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    if (_selectedStudentId == null || _selectedStudentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un estudiante de la lista.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final score = double.parse(_scoreController.text.trim().replaceAll(',', '.'));
    final teacher = _authService.currentUser;
    final teacherId = teacher?.id ?? 'doc_001';
    final teacherName = teacher?.name ?? 'Prof. Docente Autorizado';

    setState(() => _isLoading = true);

    try {
      if (widget.evaluationToEdit != null) {
        final updated = widget.evaluationToEdit!.copyWith(
          studentId: _selectedStudentId,
          moduleId: _selectedModuleId,
          moduleTitle: _selectedModuleTitle,
          sectionTitle: _selectedSection,
          activityTitle: _activityController.text.trim(),
          score: score,
          observations: _observationsController.text.trim(),
        );
        await _storageService.updateEvaluation(updated);
      } else {
        await _storageService.saveEvaluation(
          studentId: _selectedStudentId!,
          teacherId: teacherId,
          teacherName: teacherName,
          moduleId: _selectedModuleId,
          moduleTitle: _selectedModuleTitle,
          sectionTitle: _selectedSection,
          activityTitle: _activityController.text.trim(),
          score: score,
          observations: _observationsController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.evaluationToEdit != null
                  ? 'Calificación actualizada correctamente ($score / 100).'
                  : 'Calificación de $score pts registrada exitosamente.',
            ),
            backgroundColor: AppColors.forestGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error de Registro'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.evaluationToEdit != null;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 84,
        leading: const AppLogoLeading(showBackButton: true),
        title: Text(isEditing ? 'Modificar Calificación' : 'Registrar Calificación'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección 1: Selección de Estudiante
              const Text(
                '1. Estudiante a Evaluar *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.logoNavy,
                ),
              ),
              const SizedBox(height: 8),
              _buildStudentDropdown(),

              const SizedBox(height: 20),

              // Sección 2: Módulo y Sección
              const Text(
                '2. Módulo Histórico y Contenido *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.logoNavy,
                ),
              ),
              const SizedBox(height: 8),
              _buildModuleDropdown(),
              const SizedBox(height: 12),
              _buildSectionDropdown(),

              const SizedBox(height: 20),

              // Sección 3: Actividad y Calificación
              const Text(
                '3. Calificación y Desempeño *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.logoNavy,
                ),
              ),
              const SizedBox(height: 8),

              CustomTextField(
                label: 'Nombre de la Actividad o Comprobación',
                hint: 'Ej. Comprobación de Lectura: El 9 de enero',
                controller: _activityController,
                prefixIcon: Icons.assignment_outlined,
              ),

              const SizedBox(height: 14),

              // Campo de Calificación Numérica
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Calificación Numérica (Escala 0 a 100) *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text('(0 - 100 pts)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _scoreController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      setState(() {
                        _scoreValidationError = _validateScore(val);
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Ej. 95.0',
                      prefixIcon: const Icon(Icons.grade_outlined, color: AppColors.primaryTeal),
                      suffixText: '/ 100 pts',
                      suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.logoNavy),
                      errorText: _scoreValidationError,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              CustomTextField(
                label: 'Observaciones Pedagógicas',
                hint: 'Comentarios del docente sobre fortalezas, comprensión historiográfica o sugerencias de refuerzo...',
                controller: _observationsController,
                prefixIcon: Icons.comment_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 28),

              // Botones de Acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        side: const BorderSide(color: AppColors.borderGrey),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: isEditing ? 'Actualizar' : 'Guardar',
                      isLoading: _isLoading,
                      onPressed: _saveEvaluation,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStudentId,
          isExpanded: true,
          hint: const Text('Seleccione un estudiante'),
          items: _students.map((s) {
            return DropdownMenuItem(
              value: s.id,
              child: Row(
                children: [
                  const Icon(Icons.person, size: 18, color: AppColors.logoNavy),
                  const SizedBox(width: 8),
                  Text(
                    '${s.name} (${s.grade})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedStudentId = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildModuleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedModuleId,
          isExpanded: true,
          items: _modules.map((m) {
            return DropdownMenuItem(
              value: m.id,
              child: Text(
                '${m.code}: ${m.title}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (val) async {
            if (val != null) {
              final mod = _modules.firstWhere((m) => m.id == val);
              final secList = await _docStorage.getSectionsForModule(val);
              setState(() {
                _selectedModuleId = val;
                _selectedModuleTitle = mod.title;
                _sections = secList;
                if (secList.isNotEmpty) {
                  _selectedSection = secList.first;
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sections.contains(_selectedSection)
              ? _selectedSection
              : (_sections.isNotEmpty ? _sections.first : null),
          isExpanded: true,
          items: _sections.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(s, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedSection = val);
            }
          },
        ),
      ),
    );
  }
}

