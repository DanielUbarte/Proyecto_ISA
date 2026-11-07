import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/app_logo_leading.dart';

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  String _searchQuery = '';
  String _selectedGradeFilter = 'Todos';

  final List<Map<String, dynamic>> _students = const [
    {
      'id': 'usr_001',
      'name': 'Ricardo Arias',
      'email': 'r.arias@academia.edu.pa',
      'grade': '11° Grado',
      'progress': 0.75,
      'studyHours': '42.5h',
      'lastActive': 'Hoy, 10:30 AM',
      'status': 'Activo',
      'activeModule': 'Panamá Contemporánea',
      'documentsRead': 4,
    },
    {
      'id': 'usr_002',
      'name': 'Valeria Castillo',
      'email': 'v.castillo@academia.edu.pa',
      'grade': '11° Grado',
      'progress': 0.90,
      'studyHours': '51.0h',
      'lastActive': 'Hoy, 09:15 AM',
      'status': 'Activo',
      'activeModule': 'Panamá Contemporánea',
      'documentsRead': 5,
    },
    {
      'id': 'usr_003',
      'name': 'Diego Montero',
      'email': 'd.montero@academia.edu.pa',
      'grade': '10° Grado',
      'progress': 0.40,
      'studyHours': '22.0h',
      'lastActive': 'Ayer, 04:20 PM',
      'status': 'Activo',
      'activeModule': 'Panamá Contemporánea',
      'documentsRead': 2,
    },
    {
      'id': 'usr_004',
      'name': 'Sofía Quintero',
      'email': 's.quintero@academia.edu.pa',
      'grade': '12° Grado',
      'progress': 0.95,
      'studyHours': '64.0h',
      'lastActive': 'Hace 2 horas',
      'status': 'Activo',
      'activeModule': 'Panamá Contemporánea',
      'documentsRead': 6,
    },
    {
      'id': 'usr_005',
      'name': 'Mateo Espino',
      'email': 'm.espino@academia.edu.pa',
      'grade': '11° Grado',
      'progress': 0.25,
      'studyHours': '14.5h',
      'lastActive': 'Hace 3 días',
      'status': 'Inactivo',
      'activeModule': 'Panamá Contemporánea',
      'documentsRead': 1,
    },
  ];

  List<Map<String, dynamic>> get _filteredStudents {
    return _students.where((s) {
      final matchesSearch = s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGrade = _selectedGradeFilter == 'Todos' || s['grade'] == _selectedGradeFilter;
      return matchesSearch && matchesGrade;
    }).toList();
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.logoNavy,
                  child: Text(
                    student['name'].toString().substring(0, 1),
                    style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        '${student['grade']} • ${student['email']}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            _buildDetailRow('Módulo en Curso:', student['activeModule']),
            _buildDetailRow('Progreso de Lectura:', '${((student['progress'] as double) * 100).toInt()}%'),
            _buildDetailRow('Documentos Históricos Consultados:', '${student['documentsRead']} materiales'),
            _buildDetailRow('Horas Totales de Estudio:', student['studyHours']),
            _buildDetailRow('Última Actividad:', student['lastActive']),
            _buildDetailRow('Estado:', student['status']),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 84,
        leading: const AppLogoLeading(showBackButton: true),
        title: const Text('Gestión de Estudiantes'),
      ),
      body: Column(
        children: [
          // Barra de Búsqueda y Filtro de Grado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surfaceWhite,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o correo estudiantil...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Todos', '10° Grado', '11° Grado', '12° Grado'].map((grade) {
                      final isSelected = _selectedGradeFilter == grade;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(grade, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedGradeFilter = grade),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderGrey),

          // Lista de Estudiantes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                final progress = student['progress'] as double;
                final isInactive = student['status'] == 'Inactivo';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: isInactive
                          ? Colors.grey.shade400
                          : AppColors.logoNavy.withValues(alpha: 0.15),
                      child: Text(
                        student['name'].toString().substring(0, 1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isInactive ? Colors.white : AppColors.logoNavy,
                        ),
                      ),
                    ),
                    title: Text(
                      student['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          '${student['grade']} • Progreso: ${(progress * 100).toInt()}% • ${student['lastActive']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 0.7 ? AppColors.forestGreen : AppColors.logoGoldDark,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                    onTap: () => _showStudentDetails(student),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

