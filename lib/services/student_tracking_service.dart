import '../models/student_tracking_model.dart';

/// Servicio centralizado de seguimiento y directorio de estudiantes.
/// Reutilizado de forma unificada tanto por el módulo de Seguimiento como por Evaluación.
class StudentTrackingService {
  static final StudentTrackingService _instance = StudentTrackingService._internal();
  factory StudentTrackingService() => _instance;
  StudentTrackingService._internal();

  final List<StudentTrackingModel> _students = [
    const StudentTrackingModel(
      id: 'usr_001',
      name: 'Ricardo Arias',
      email: 'r.arias@academia.edu.pa',
      grade: '11° Grado',
      progress: 0.75,
      studyHours: '42.5h',
      lastActive: 'Hoy, 10:30 AM',
      status: 'Activo',
      activeModule: 'Panamá Contemporánea',
      documentsRead: 4,
    ),
    const StudentTrackingModel(
      id: 'usr_002',
      name: 'Valeria Castillo',
      email: 'v.castillo@academia.edu.pa',
      grade: '11° Grado',
      progress: 0.90,
      studyHours: '51.0h',
      lastActive: 'Hoy, 09:15 AM',
      status: 'Activo',
      activeModule: 'Panamá Contemporánea',
      documentsRead: 5,
    ),
    const StudentTrackingModel(
      id: 'usr_003',
      name: 'Diego Montero',
      email: 'd.montero@academia.edu.pa',
      grade: '10° Grado',
      progress: 0.40,
      studyHours: '22.0h',
      lastActive: 'Ayer, 04:20 PM',
      status: 'Activo',
      activeModule: 'Panamá Contemporánea',
      documentsRead: 2,
    ),
    const StudentTrackingModel(
      id: 'usr_004',
      name: 'Sofía Quintero',
      email: 's.quintero@academia.edu.pa',
      grade: '12° Grado',
      progress: 0.95,
      studyHours: '64.0h',
      lastActive: 'Hace 2 horas',
      status: 'Activo',
      activeModule: 'Panamá Contemporánea',
      documentsRead: 6,
    ),
    const StudentTrackingModel(
      id: 'usr_005',
      name: 'Mateo Espino',
      email: 'm.espino@academia.edu.pa',
      grade: '11° Grado',
      progress: 0.25,
      studyHours: '14.5h',
      lastActive: 'Hace 3 días',
      status: 'Inactivo',
      activeModule: 'Panamá Contemporánea',
      documentsRead: 1,
    ),
  ];

  /// Obtiene la lista completa de estudiantes asignados.
  List<StudentTrackingModel> getStudents() {
    return List.unmodifiable(_students);
  }

  /// Busca un estudiante por su ID único.
  StudentTrackingModel? getStudentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Permite registrar un nuevo estudiante en el directorio docente.
  void addStudent(StudentTrackingModel student) {
    if (!_students.any((s) => s.id == student.id)) {
      _students.add(student);
    }
  }
}

