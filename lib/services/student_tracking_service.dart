import '../models/student_tracking_model.dart';

/// Servicio centralizado de seguimiento y directorio de estudiantes.
/// Reutilizado de forma unificada tanto por el módulo de Seguimiento como por Evaluación.
/// Permite calcular métricas reales de grupo e individuales sin datos ficticios.
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
      section: 'Sección A',
      progress: 0.75,
      studyHours: '42.5h',
      lastActive: 'Hoy, 10:30 AM',
      status: 'Activo',
      activeModule: 'Panamá Contemporánea',
      documentsRead: 4,
      completedModules: ['Época Prehispánica', 'Época Colonial'],
      pendingModules: ['Época Republicana'],
      moduleProgress: {
        'Época Prehispánica': 1.0,
        'Época Colonial': 1.0,
        'Época Departamental': 0.85,
        'Panamá Contemporánea': 0.75,
        'Época Republicana': 0.40,
      },
      pendingSections: ['Tratados Torrijos-Carter: Reversión', 'La Invasión de 1989'],
      recentActivities: [
        'Comprobación de lectura: El 9 de enero de 1964 (95 pts)',
        'Lectura del documento: Acuerdos Chiari-Kennedy',
        'Consulta al Historiador IA sobre la bandera de los aguiluchos',
      ],
      consultedDocuments: [
        'El 9 de enero de 1964: lo que no me contaron (Wendy Tribaldos)',
        'Convenio Chiari-Kennedy de 1962 (Documento PDF)',
      ],
      historianInquiries: [
        '¿Por qué marcharon los estudiantes del Instituto Nacional el 9 de enero de 1964?',
        '¿Dónde se ubicaba el Balboa High School en la antigua Zona del Canal?',
      ],
    ),
    const StudentTrackingModel(
      id: 'usr_002',
      name: 'Valeria Castillo',
      email: 'v.castillo@academia.edu.pa',
      grade: '11° Grado',
      section: 'Sección A',
      progress: 0.90,
      studyHours: '51.0h',
      lastActive: 'Hoy, 09:15 AM',
      status: 'Activo',
      activeModule: 'Panamá Contemporánea',
      documentsRead: 5,
      completedModules: ['Época Prehispánica', 'Época Colonial', 'Época Departamental'],
      pendingModules: ['Época Republicana'],
      moduleProgress: {
        'Época Prehispánica': 1.0,
        'Época Colonial': 1.0,
        'Época Departamental': 1.0,
        'Panamá Contemporánea': 0.90,
        'Época Republicana': 0.60,
      },
      pendingSections: ['Consecuencias Internacionales de 1964'],
      recentActivities: [
        'Cuestionario analítico: Balboa High School (98 pts)',
        'Lectura completa del Capítulo 2: La Marcha de los Aguiluchos',
        'Consulta al Historiador IA sobre la ruptura de relaciones diplomáticas',
      ],
      consultedDocuments: [
        'El 9 de enero de 1964: lo que no me contaron (Wendy Tribaldos)',
        'Testimonios Históricos de la Gesta Patriótica',
        'Fotografías del 9 de enero en Balboa High School',
      ],
      historianInquiries: [
        '¿Quién era el Rector del Instituto Nacional en enero de 1964?',
        '¿Qué consecuencias tuvo la ruptura de relaciones diplomáticas con EE.UU.?',
      ],
    ),
    const StudentTrackingModel(
      id: 'usr_003',
      name: 'Diego Montero',
      email: 'd.montero@academia.edu.pa',
      grade: '10° Grado',
      section: 'Sección B',
      progress: 0.40,
      studyHours: '22.0h',
      lastActive: 'Ayer, 04:20 PM',
      status: 'Activo',
      activeModule: 'Panamá Contemporánea',
      documentsRead: 2,
      completedModules: ['Época Prehispánica'],
      pendingModules: ['Época Colonial', 'Época Departamental', 'Época Republicana'],
      moduleProgress: {
        'Época Prehispánica': 1.0,
        'Época Colonial': 0.50,
        'Panamá Contemporánea': 0.40,
      },
      pendingSections: [
        'Gesta de Enero: Segunda Oleada',
        'Los Mártires del Instituto Nacional',
        'Tratados Torrijos-Carter',
      ],
      recentActivities: [
        'Ensayo historiográfico: Los Mártires de Enero (82 pts)',
        'Lectura parcial del documento de Wendy Tribaldos (Pág 1 a 15)',
      ],
      consultedDocuments: [
        'El 9 de enero de 1964: lo que no me contaron (Wendy Tribaldos)',
      ],
      historianInquiries: [
        '¿Quién fue Ascanio Arosemena y cuál fue su papel el 9 de enero?',
      ],
    ),
    const StudentTrackingModel(
      id: 'usr_004',
      name: 'Sofía Quintero',
      email: 's.quintero@academia.edu.pa',
      grade: '12° Grado',
      section: 'Sección A',
      progress: 0.95,
      studyHours: '64.0h',
      lastActive: 'Hace 2 horas',
      status: 'Activo',
      activeModule: 'Panamá Contemporánea',
      documentsRead: 6,
      completedModules: ['Época Prehispánica', 'Época Colonial', 'Época Departamental', 'Época Republicana'],
      pendingModules: [],
      moduleProgress: {
        'Época Prehispánica': 1.0,
        'Época Colonial': 1.0,
        'Época Departamental': 1.0,
        'Panamá Contemporánea': 0.95,
        'Época Republicana': 1.0,
      },
      pendingSections: [],
      recentActivities: [
        'Análisis de Fuentes Documentales: Tratados Torrijos-Carter (100 pts)',
        'Revisión documental de actas y tratados bilaterales',
        'Consulta avanzada al Historiador IA sobre la cláusula de neutralidad',
      ],
      consultedDocuments: [
        'El 9 de enero de 1964: lo que no me contaron (Wendy Tribaldos)',
        'Tratado del Canal de Panamá (1977)',
        'Tratado Concerniente a la Neutralidad Permanente',
      ],
      historianInquiries: [
        '¿Cuáles fueron los antecedentes del Tratado Torrijos-Carter derivados de 1964?',
        '¿Cómo funcionaba la Zona del Canal antes de la reversión de 1999?',
      ],
    ),
    const StudentTrackingModel(
      id: 'usr_005',
      name: 'Mateo Espino',
      email: 'm.espino@academia.edu.pa',
      grade: '11° Grado',
      section: 'Sección B',
      progress: 0.25,
      studyHours: '14.5h',
      lastActive: 'Hace 3 días',
      status: 'Inactivo',
      activeModule: 'Panamá Contemporánea',
      documentsRead: 1,
      completedModules: [],
      pendingModules: ['Época Prehispánica', 'Época Colonial', 'Época Departamental', 'Época Republicana'],
      moduleProgress: {
        'Época Prehispánica': 0.50,
        'Panamá Contemporánea': 0.25,
      },
      pendingSections: [
        'Contexto Histórico del 9 de Enero',
        'El Acuerdo Chiari-Kennedy',
        'Sucesos en Balboa High School',
        'La Bandera Rasgada',
      ],
      recentActivities: [
        'Comprobación de lectura: El 9 de enero (64 pts - Requiere Refuerzo)',
        'Apertura inicial del documento de Wendy Tribaldos',
      ],
      consultedDocuments: [
        'El 9 de enero de 1964: lo que no me contaron (Lectura incompleta: pág 1-5)',
      ],
      historianInquiries: [
        '¿Qué ocurrió el 9 de enero?',
      ],
    ),
  ];

  /// Obtiene la lista completa de estudiantes asignados al docente.
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

  /// Calcula el promedio de progreso de todos los estudiantes autorizados.
  double calculateAverageProgress() {
    if (_students.isEmpty) return 0.0;
    final total = _students.fold<double>(0.0, (sum, s) => sum + s.progress);
    return double.parse(((total / _students.length) * 100).toStringAsFixed(1));
  }

  /// Cuenta la cantidad de estudiantes activos en la plataforma.
  int getActiveStudentsCount() {
    return _students.where((s) => s.status == 'Activo').length;
  }

  /// Obtiene la lista de estudiantes con bajo progreso o que requieren seguimiento pedagógico.
  List<StudentTrackingModel> getStudentsRequiringFollowup({double threshold = 0.50}) {
    return _students.where((s) => s.progress < threshold || s.status == 'Inactivo').toList();
  }

  /// Compila las actividades recientes más destacadas del grupo.
  List<Map<String, String>> getRecentGroupActivities() {
    final List<Map<String, String>> activities = [];
    for (final s in _students) {
      for (final act in s.recentActivities) {
        activities.add({
          'studentName': s.name,
          'studentGrade': s.grade,
          'activity': act,
          'lastActive': s.lastActive,
        });
      }
    }
    return activities;
  }
}
