/// Modelo que representa la información de seguimiento y estado académico de un estudiante.
class StudentTrackingModel {
  final String id;
  final String name;
  final String email;
  final String grade;
  final String section;
  final double progress; // 0.0 a 1.0
  final String studyHours;
  final String lastActive;
  final String status; // 'Activo' o 'Inactivo'
  final String activeModule;
  final int documentsRead;
  final List<String> completedModules;
  final List<String> pendingModules;
  final Map<String, double> moduleProgress;
  final List<String> pendingSections;
  final List<String> recentActivities;
  final List<String> consultedDocuments;
  final List<String> historianInquiries;

  const StudentTrackingModel({
    required this.id,
    required this.name,
    required this.email,
    required this.grade,
    this.section = 'Sección A',
    required this.progress,
    required this.studyHours,
    required this.lastActive,
    required this.status,
    required this.activeModule,
    required this.documentsRead,
    this.completedModules = const [],
    this.pendingModules = const [],
    this.moduleProgress = const {},
    this.pendingSections = const [],
    this.recentActivities = const [],
    this.consultedDocuments = const [],
    this.historianInquiries = const [],
  });

  /// Identifica si el estudiante requiere atención pedagógica prioritaria
  bool get requiresFollowup => progress < 0.50 || status == 'Inactivo';

  /// Nombre completo de grado y sección
  String get fullGradeSection => '$grade - $section';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'grade': grade,
      'section': section,
      'progress': progress,
      'studyHours': studyHours,
      'lastActive': lastActive,
      'status': status,
      'activeModule': activeModule,
      'documentsRead': documentsRead,
      'completedModules': completedModules,
      'pendingModules': pendingModules,
      'moduleProgress': moduleProgress,
      'pendingSections': pendingSections,
      'recentActivities': recentActivities,
      'consultedDocuments': consultedDocuments,
      'historianInquiries': historianInquiries,
    };
  }

  factory StudentTrackingModel.fromJson(Map<String, dynamic> json) {
    return StudentTrackingModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      grade: json['grade'] as String? ?? '11° Grado',
      section: json['section'] as String? ?? 'Sección A',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      studyHours: json['studyHours'] as String? ?? '0.0h',
      lastActive: json['lastActive'] as String? ?? 'Reciente',
      status: json['status'] as String? ?? 'Activo',
      activeModule: json['activeModule'] as String? ?? 'Panamá Contemporánea',
      documentsRead: (json['documentsRead'] as num?)?.toInt() ?? 0,
      completedModules: (json['completedModules'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      pendingModules: (json['pendingModules'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      moduleProgress: (json['moduleProgress'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
      pendingSections: (json['pendingSections'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      recentActivities: (json['recentActivities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      consultedDocuments: (json['consultedDocuments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      historianInquiries: (json['historianInquiries'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  StudentTrackingModel copyWith({
    String? id,
    String? name,
    String? email,
    String? grade,
    String? section,
    double? progress,
    String? studyHours,
    String? lastActive,
    String? status,
    String? activeModule,
    int? documentsRead,
    List<String>? completedModules,
    List<String>? pendingModules,
    Map<String, double>? moduleProgress,
    List<String>? pendingSections,
    List<String>? recentActivities,
    List<String>? consultedDocuments,
    List<String>? historianInquiries,
  }) {
    return StudentTrackingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      progress: progress ?? this.progress,
      studyHours: studyHours ?? this.studyHours,
      lastActive: lastActive ?? this.lastActive,
      status: status ?? this.status,
      activeModule: activeModule ?? this.activeModule,
      documentsRead: documentsRead ?? this.documentsRead,
      completedModules: completedModules ?? this.completedModules,
      pendingModules: pendingModules ?? this.pendingModules,
      moduleProgress: moduleProgress ?? this.moduleProgress,
      pendingSections: pendingSections ?? this.pendingSections,
      recentActivities: recentActivities ?? this.recentActivities,
      consultedDocuments: consultedDocuments ?? this.consultedDocuments,
      historianInquiries: historianInquiries ?? this.historianInquiries,
    );
  }
}
