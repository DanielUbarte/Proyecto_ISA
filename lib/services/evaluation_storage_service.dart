import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/academic_evaluation_model.dart';
import 'student_tracking_service.dart';

/// Servicio de persistencia y analítica para las evaluaciones y reportes académicos.
/// Gestiona calificaciones numéricas (0-100), observaciones pedagógicas y
/// el cálculo de indicadores académicos reales del rol docente.
class EvaluationStorageService {
  static final EvaluationStorageService _instance = EvaluationStorageService._internal();
  factory EvaluationStorageService() => _instance;
  EvaluationStorageService._internal();

  static const String _storageKey = 'ph_academic_evaluations_v1';
  static int _idCounter = 0;

  final StudentTrackingService _studentService = StudentTrackingService();

  List<AcademicEvaluationModel> _evaluations = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  @visibleForTesting
  void resetForTesting() {
    _evaluations = [];
    _isInitialized = false;
  }

  /// Inicializa el servicio cargando datos persistidos o cargando registros base.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(jsonString);
        _evaluations = list
            .map((item) => AcademicEvaluationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _evaluations = _getInitialSeedEvaluations();
        await _persistEvaluations();
      }
    } else {
      _evaluations = _getInitialSeedEvaluations();
      await _persistEvaluations();
    }

    _isInitialized = true;
  }

  /// Obtiene la lista completa de evaluaciones registradas.
  Future<List<AcademicEvaluationModel>> getAllEvaluations() async {
    if (!_isInitialized) await initialize();
    return List.unmodifiable(_evaluations);
  }

  /// Filtra evaluaciones por docente responsable.
  Future<List<AcademicEvaluationModel>> getEvaluationsForTeacher(String teacherId) async {
    if (!_isInitialized) await initialize();
    return _evaluations.where((e) => e.teacherId == teacherId).toList();
  }

  /// Obtiene el historial de calificaciones de un estudiante específico.
  Future<List<AcademicEvaluationModel>> getEvaluationsForStudent(String studentId) async {
    if (!_isInitialized) await initialize();
    return _evaluations.where((e) => e.studentId == studentId).toList();
  }

  /// Registra una nueva calificación con validaciones estrictas (0-100).
  Future<AcademicEvaluationModel> saveEvaluation({
    required String studentId,
    required String teacherId,
    required String teacherName,
    required String moduleId,
    required String moduleTitle,
    required String sectionTitle,
    required String activityTitle,
    required double score,
    required String observations,
    DateTime? date,
  }) async {
    if (!_isInitialized) await initialize();

    // 1. Validaciones
    if (studentId.trim().isEmpty) {
      throw Exception('Debe seleccionar un estudiante para registrar la calificación.');
    }

    if (moduleId.trim().isEmpty) {
      throw Exception('Debe seleccionar el módulo histórico evaluado.');
    }

    if (score < 0.0 || score > 100.0) {
      throw Exception('La calificación debe estar comprendida estrictamente entre 0 y 100.');
    }

    final student = _studentService.getStudentById(studentId);
    final studentName = student?.name ?? 'Estudiante Asignado';
    final studentGrade = student?.grade ?? '11° Grado';

    final cleanSection = sectionTitle.trim().isEmpty ? 'General' : sectionTitle.trim();
    final cleanActivity = activityTitle.trim().isEmpty ? 'Comprobación de Lectura' : activityTitle.trim();

    // 2. Comprobar si ya existe una evaluación exacta para actualizarla o registrarla
    final existingIndex = _evaluations.indexWhere((e) =>
        e.studentId == studentId &&
        e.moduleId == moduleId &&
        e.sectionTitle.toLowerCase().trim() == cleanSection.toLowerCase().trim() &&
        e.activityTitle.toLowerCase().trim() == cleanActivity.toLowerCase().trim());

    final now = date ?? DateTime.now();

    if (existingIndex != -1) {
      // Actualizar registro existente
      final updated = _evaluations[existingIndex].copyWith(
        score: score,
        observations: observations.trim(),
        createdAt: now,
        teacherId: teacherId,
        teacherName: teacherName,
      );
      _evaluations[existingIndex] = updated;
      await _persistEvaluations();
      return updated;
    }

    // 3. Crear nuevo registro
    final newId = 'eval_${now.microsecondsSinceEpoch}_${++_idCounter}';
    final evaluation = AcademicEvaluationModel(
      id: newId,
      studentId: studentId,
      studentName: studentName,
      studentGrade: studentGrade,
      teacherId: teacherId,
      teacherName: teacherName,
      moduleId: moduleId,
      moduleTitle: moduleTitle,
      sectionTitle: cleanSection,
      activityTitle: cleanActivity,
      score: score,
      observations: observations.trim(),
      createdAt: now,
    );

    _evaluations.add(evaluation);
    await _persistEvaluations();
    return evaluation;
  }

  /// Actualiza una evaluación existente.
  Future<AcademicEvaluationModel> updateEvaluation(AcademicEvaluationModel updated) async {
    if (!_isInitialized) await initialize();

    if (updated.score < 0.0 || updated.score > 100.0) {
      throw Exception('La calificación debe estar comprendida entre 0 y 100.');
    }

    final index = _evaluations.indexWhere((e) => e.id == updated.id);
    if (index == -1) {
      throw Exception('Evaluación no encontrada.');
    }

    _evaluations[index] = updated;
    await _persistEvaluations();
    return updated;
  }

  /// Elimina una evaluación del registro.
  Future<void> deleteEvaluation(String evalId) async {
    if (!_isInitialized) await initialize();
    _evaluations.removeWhere((e) => e.id == evalId);
    await _persistEvaluations();
  }

  /// Aplica filtros a la lista de evaluaciones para el módulo de reportes.
  List<AcademicEvaluationModel> applyFilters({
    List<AcademicEvaluationModel>? source,
    String? studentId,
    String? moduleId,
    String? sectionTitle,
    String? grade,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var list = source ?? _evaluations;

    if (studentId != null && studentId.isNotEmpty && studentId != 'Todos') {
      list = list.where((e) => e.studentId == studentId).toList();
    }

    if (moduleId != null && moduleId.isNotEmpty && moduleId != 'Todos') {
      list = list.where((e) => e.moduleId == moduleId || e.moduleTitle == moduleId).toList();
    }

    if (sectionTitle != null && sectionTitle.isNotEmpty && sectionTitle != 'Todas') {
      list = list.where((e) => e.sectionTitle == sectionTitle).toList();
    }

    if (grade != null && grade.isNotEmpty && grade != 'Todos') {
      list = list.where((e) => e.studentGrade == grade).toList();
    }

    if (startDate != null) {
      list = list.where((e) => e.createdAt.isAfter(startDate) || e.createdAt.isAtSameMomentAs(startDate)).toList();
    }

    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      list = list.where((e) => e.createdAt.isBefore(endOfDay) || e.createdAt.isAtSameMomentAs(endOfDay)).toList();
    }

    return list;
  }

  /// Calcula el promedio general numérico (0 - 100) derivado de evaluaciones reales.
  double calculateAverage(List<AcademicEvaluationModel> list) {
    if (list.isEmpty) return 0.0;
    final total = list.fold<double>(0.0, (sum, e) => sum + e.score);
    return double.parse((total / list.length).toStringAsFixed(1));
  }

  /// Cantidad de estudiantes únicos evaluados.
  int countEvaluatedStudents(List<AcademicEvaluationModel> list) {
    return list.map((e) => e.studentId).toSet().length;
  }

  /// Estudiantes con bajo rendimiento (< 71.0 puntos).
  List<AcademicEvaluationModel> getLowPerformance(
    List<AcademicEvaluationModel> list, {
    double threshold = 71.0,
  }) {
    return list.where((e) => e.score < threshold).toList();
  }

  /// Estudiantes con desempeño sobresaliente (>= 90.0 puntos).
  List<AcademicEvaluationModel> getTopPerformance(
    List<AcademicEvaluationModel> list, {
    double threshold = 90.0,
  }) {
    return list.where((e) => e.score >= threshold).toList();
  }

  /// Desglose de promedio por cada módulo histórico.
  Map<String, double> getAveragePerModule(List<AcademicEvaluationModel> list) {
    final Map<String, List<double>> moduleScores = {};

    for (final e in list) {
      if (!moduleScores.containsKey(e.moduleTitle)) {
        moduleScores[e.moduleTitle] = [];
      }
      moduleScores[e.moduleTitle]!.add(e.score);
    }

    final Map<String, double> result = {};
    for (final entry in moduleScores.entries) {
      final avg = entry.value.fold<double>(0.0, (sum, s) => sum + s) / entry.value.length;
      result[entry.key] = double.parse(avg.toStringAsFixed(1));
    }
    return result;
  }

  /// Distribución de calificaciones por niveles de desempeño MEDUCA.
  Map<String, int> getDistribution(List<AcademicEvaluationModel> list) {
    int sobresaliente = 0; // 90-100
    int bueno = 0; // 80-89
    int regular = 0; // 71-79
    int refuerzo = 0; // < 71

    for (final e in list) {
      if (e.score >= 90.0) {
        sobresaliente++;
      } else if (e.score >= 80.0) {
        bueno++;
      } else if (e.score >= 71.0) {
        regular++;
      } else {
        refuerzo++;
      }
    }

    return {
      'Sobresaliente (90-100)': sobresaliente,
      'Bueno (80-89)': bueno,
      'Regular (71-79)': regular,
      'Requiere Refuerzo (<71)': refuerzo,
    };
  }

  Future<void> _persistEvaluations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _evaluations.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// Registros de evaluaciones reales iniciales vinculados a los estudiantes asignados.
  List<AcademicEvaluationModel> _getInitialSeedEvaluations() {
    return [
      AcademicEvaluationModel(
        id: 'seed_eval_01',
        studentId: 'usr_001',
        studentName: 'Ricardo Arias',
        studentGrade: '11° Grado',
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: '9 de enero de 1964',
        activityTitle: 'Comprobación de Lectura: El 9 de enero',
        score: 95.0,
        observations: 'Excelente análisis crítico del acuerdo Chiari-Kennedy y su relación con la bandera.',
        createdAt: DateTime(2024, 11, 4),
      ),
      AcademicEvaluationModel(
        id: 'seed_eval_02',
        studentId: 'usr_002',
        studentName: 'Valeria Castillo',
        studentGrade: '11° Grado',
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: '9 de enero de 1964',
        activityTitle: 'Cuestionario Analítico: Balboa High School',
        score: 98.0,
        observations: 'Dominio perfecto de las fuentes documentales testimoniales de Wendy Tribaldos.',
        createdAt: DateTime(2024, 10, 28),
      ),
      AcademicEvaluationModel(
        id: 'seed_eval_03',
        studentId: 'usr_003',
        studentName: 'Diego Montero',
        studentGrade: '10° Grado',
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: '9 de enero de 1964',
        activityTitle: 'Ensayo Historiográfico: Los Mártires de Enero',
        score: 82.0,
        observations: 'Buen trabajo descriptivo. Se sugiere profundizar en las consecuencias de 1977.',
        createdAt: DateTime(2024, 10, 15),
      ),
      AcademicEvaluationModel(
        id: 'seed_eval_04',
        studentId: 'usr_004',
        studentName: 'Sofía Quintero',
        studentGrade: '12° Grado',
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Tratados Torrijos-Carter',
        activityTitle: 'Análisis de Fuentes Documentales',
        score: 100.0,
        observations: 'Desempeño sobresaliente con citas precisas y excelente argumentación historiográfica.',
        createdAt: DateTime(2024, 11, 2),
      ),
      AcademicEvaluationModel(
        id: 'seed_eval_05',
        studentId: 'usr_005',
        studentName: 'Mateo Espino',
        studentGrade: '11° Grado',
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: '9 de enero de 1964',
        activityTitle: 'Comprobación de Lectura: El 9 de enero',
        score: 64.0,
        observations: 'Falta lectura comprensiva del material documental. Requiere sesión de refuerzo.',
        createdAt: DateTime(2024, 10, 20),
      ),
      AcademicEvaluationModel(
        id: 'seed_eval_06',
        studentId: 'usr_001',
        studentName: 'Ricardo Arias',
        studentGrade: '11° Grado',
        teacherId: 'doc_001',
        teacherName: 'Prof. Alejandro Méndez',
        moduleId: 'mod_contemporanea',
        moduleTitle: 'Panamá Contemporánea',
        sectionTitle: 'Tratados Torrijos-Carter',
        activityTitle: 'Cuestionario Diplomático 1977',
        score: 90.0,
        observations: 'Comprensión cabal del proceso de reversión canalera del 31 de diciembre de 1999.',
        createdAt: DateTime(2024, 11, 6),
      ),
    ];
  }
}

