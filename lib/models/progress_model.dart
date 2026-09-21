class StudentProgressModel {
  final int completedModules;
  final int totalModules;
  final double studyHours;
  final double averageGrade;
  final List<double> weeklyProgress; // 7 days values normalized 0.0 - 1.0
  final List<RecentActivityModel> recentActivities;

  const StudentProgressModel({
    required this.completedModules,
    required this.totalModules,
    required this.studyHours,
    required this.averageGrade,
    required this.weeklyProgress,
    required this.recentActivities,
  });

  factory StudentProgressModel.mock() {
    return const StudentProgressModel(
      completedModules: 8,
      totalModules: 12,
      studyHours: 42.5,
      averageGrade: 4.8,
      weeklyProgress: [0.3, 0.6, 0.4, 0.9, 0.7, 0.85, 0.5],
      recentActivities: [
        RecentActivityModel(
          title: 'Módulo AR Completado: Casco Viejo',
          timestamp: 'Hoy, 10:45 AM',
          score: '98%',
          duration: '24m',
          type: ActivityType.arModule,
        ),
        RecentActivityModel(
          title: 'Intento de Prueba: Comercio Colonial',
          timestamp: 'Ayer, 4:20 PM',
          score: '82%',
          duration: '15m',
          type: ActivityType.quiz,
        ),
        RecentActivityModel(
          title: 'Lectura: Tratado del Canal Interoceánico',
          timestamp: 'Hace 2 días',
          score: '100%',
          duration: '35m',
          type: ActivityType.reading,
        ),
      ],
    );
  }
}

enum ActivityType { arModule, quiz, reading }

class RecentActivityModel {
  final String title;
  final String timestamp;
  final String score;
  final String duration;
  final ActivityType type;

  const RecentActivityModel({
    required this.title,
    required this.timestamp,
    required this.score,
    required this.duration,
    required this.type,
  });
}
