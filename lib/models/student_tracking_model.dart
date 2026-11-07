/// Modelo que representa la información de seguimiento y estado académico de un estudiante.
class StudentTrackingModel {
  final String id;
  final String name;
  final String email;
  final String grade;
  final double progress; // 0.0 a 1.0
  final String studyHours;
  final String lastActive;
  final String status; // 'Activo' o 'Inactivo'
  final String activeModule;
  final int documentsRead;

  const StudentTrackingModel({
    required this.id,
    required this.name,
    required this.email,
    required this.grade,
    required this.progress,
    required this.studyHours,
    required this.lastActive,
    required this.status,
    required this.activeModule,
    required this.documentsRead,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'grade': grade,
      'progress': progress,
      'studyHours': studyHours,
      'lastActive': lastActive,
      'status': status,
      'activeModule': activeModule,
      'documentsRead': documentsRead,
    };
  }

  factory StudentTrackingModel.fromJson(Map<String, dynamic> json) {
    return StudentTrackingModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      grade: json['grade'] as String? ?? '11° Grado',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      studyHours: json['studyHours'] as String? ?? '0.0h',
      lastActive: json['lastActive'] as String? ?? 'Reciente',
      status: json['status'] as String? ?? 'Activo',
      activeModule: json['activeModule'] as String? ?? 'Panamá Contemporánea',
      documentsRead: (json['documentsRead'] as num?)?.toInt() ?? 0,
    );
  }

  StudentTrackingModel copyWith({
    String? id,
    String? name,
    String? email,
    String? grade,
    double? progress,
    String? studyHours,
    String? lastActive,
    String? status,
    String? activeModule,
    int? documentsRead,
  }) {
    return StudentTrackingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      grade: grade ?? this.grade,
      progress: progress ?? this.progress,
      studyHours: studyHours ?? this.studyHours,
      lastActive: lastActive ?? this.lastActive,
      status: status ?? this.status,
      activeModule: activeModule ?? this.activeModule,
      documentsRead: documentsRead ?? this.documentsRead,
    );
  }
}

