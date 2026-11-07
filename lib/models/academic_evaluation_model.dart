/// Modelo que representa una calificación y observación académica registrada por un docente.
class AcademicEvaluationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentGrade;
  final String teacherId;
  final String teacherName;
  final String moduleId;
  final String moduleTitle;
  final String sectionTitle;
  final String activityTitle;
  final double score; // 0.0 a 100.0
  final String observations;
  final DateTime createdAt;

  const AcademicEvaluationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.teacherId,
    required this.teacherName,
    required this.moduleId,
    required this.moduleTitle,
    required this.sectionTitle,
    required this.activityTitle,
    required this.score,
    required this.observations,
    required this.createdAt,
  });

  bool get isApproved => score >= 71.0;

  String get performanceLevel {
    if (score >= 90.0) return 'Sobresaliente';
    if (score >= 80.0) return 'Bueno';
    if (score >= 71.0) return 'Regular';
    return 'Requiere Refuerzo';
  }

  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentGrade': studentGrade,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'moduleId': moduleId,
      'moduleTitle': moduleTitle,
      'sectionTitle': sectionTitle,
      'activityTitle': activityTitle,
      'score': score,
      'observations': observations,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AcademicEvaluationModel.fromJson(Map<String, dynamic> json) {
    return AcademicEvaluationModel(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String? ?? 'Estudiante',
      studentGrade: json['studentGrade'] as String? ?? '11° Grado',
      teacherId: json['teacherId'] as String? ?? 'doc_meduca',
      teacherName: json['teacherName'] as String? ?? 'Docente Autorizado',
      moduleId: json['moduleId'] as String? ?? 'mod_contemporanea',
      moduleTitle: json['moduleTitle'] as String? ?? 'Panamá Contemporánea',
      sectionTitle: json['sectionTitle'] as String? ?? '9 de enero de 1964',
      activityTitle: json['activityTitle'] as String? ?? 'Comprobación de Lectura',
      score: (json['score'] as num).toDouble(),
      observations: json['observations'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AcademicEvaluationModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentGrade,
    String? teacherId,
    String? teacherName,
    String? moduleId,
    String? moduleTitle,
    String? sectionTitle,
    String? activityTitle,
    double? score,
    String? observations,
    DateTime? createdAt,
  }) {
    return AcademicEvaluationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentGrade: studentGrade ?? this.studentGrade,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      moduleId: moduleId ?? this.moduleId,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      activityTitle: activityTitle ?? this.activityTitle,
      score: score ?? this.score,
      observations: observations ?? this.observations,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

