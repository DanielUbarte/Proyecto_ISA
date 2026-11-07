enum UserRole {
  student,
  teacher;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Estudiante';
      case UserRole.teacher:
        return 'Docente';
    }
  }

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.student;
    final clean = role.toLowerCase().trim();
    if (clean == 'teacher' || clean == 'docente' || clean == 'profesor') {
      return UserRole.teacher;
    }
    return UserRole.student;
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String grade;
  final String institution;
  final int level;
  final String levelTitle;
  final String deviceInUse;
  final String avatarUrl;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.grade,
    required this.institution,
    required this.level,
    required this.levelTitle,
    required this.deviceInUse,
    required this.avatarUrl,
    this.role = UserRole.student,
  });

  bool get isTeacher => role == UserRole.teacher;
  bool get isStudent => role == UserRole.student;

  factory UserModel.mock() {
    return const UserModel(
      id: 'usr_001',
      name: 'Ricardo Arias',
      email: 'r.arias@academia.edu.pa',
      grade: '11° Grado',
      institution: 'Academia Panamá',
      level: 15,
      levelTitle: 'Historiador Nivel 15',
      deviceInUse: 'iPhone 13 (Apple Inc.)',
      avatarUrl: '',
      role: UserRole.student,
    );
  }

  factory UserModel.mockTeacher({
    String id = 'doc_001',
    String name = 'Prof. Alejandro Méndez',
    String email = 'profesor.historica@meduca.gob.pa',
    String institution = 'Instituto Nacional de Panamá',
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      grade: 'Departamento de Ciencias Sociales e Historia',
      institution: institution,
      level: 30,
      levelTitle: 'Catedrático de Historia Republicana',
      deviceInUse: 'Dispositivo Docente Autorizado',
      avatarUrl: '',
      role: UserRole.teacher,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'grade': grade,
      'institution': institution,
      'level': level,
      'levelTitle': levelTitle,
      'deviceInUse': deviceInUse,
      'avatarUrl': avatarUrl,
      'role': role.name,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? 'usr_unknown',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      institution: json['institution'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      levelTitle: json['levelTitle'] as String? ?? '',
      deviceInUse: json['deviceInUse'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? grade,
    String? institution,
    int? level,
    String? levelTitle,
    String? deviceInUse,
    String? avatarUrl,
    UserRole? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      grade: grade ?? this.grade,
      institution: institution ?? this.institution,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      deviceInUse: deviceInUse ?? this.deviceInUse,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
    );
  }
}
