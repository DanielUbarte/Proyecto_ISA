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
  });

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
    );
  }
}
