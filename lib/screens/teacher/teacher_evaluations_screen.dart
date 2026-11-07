import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/app_logo_leading.dart';
import '../../widgets/custom_button.dart';

class TeacherEvaluationsScreen extends StatefulWidget {
  const TeacherEvaluationsScreen({super.key});

  @override
  State<TeacherEvaluationsScreen> createState() => _TeacherEvaluationsScreenState();
}

class _TeacherEvaluationsScreenState extends State<TeacherEvaluationsScreen> {
  final List<Map<String, dynamic>> _evaluations = const [
    {
      'title': 'Comprobación de Lectura: El 9 de enero de 1964',
      'module': 'Panamá Contemporánea',
      'section': '9 de enero de 1964',
      'completedCount': 28,
      'totalStudents': 32,
      'averageScore': 4.7,
      'date': '04 Nov 2024',
    },
    {
      'title': 'Cuestionario Analítico: Acuerdo Chiari-Kennedy',
      'module': 'Panamá Contemporánea',
      'section': 'Gesta Patriótica',
      'completedCount': 30,
      'totalStudents': 32,
      'averageScore': 4.9,
      'date': '28 Oct 2024',
    },
    {
      'title': 'Ensayo Historiográfico: Causas y Repercusiones de 1964',
      'module': 'Panamá Contemporánea',
      'section': 'Consecuencias Históricas',
      'completedCount': 24,
      'totalStudents': 32,
      'averageScore': 4.5,
      'date': '15 Oct 2024',
    },
  ];

  void _generateOfficialReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.description, color: AppColors.logoNavy),
            SizedBox(width: 8),
            Text('Reporte Académico', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reporte Oficial MEDUCA Generado:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Periodo: II Trimestre 2024'),
            Text('• Módulo Evaluado: Panamá Contemporánea'),
            Text('• Promedio General de Grupo: 4.7 / 5.0'),
            Text('• Tasa de Lectura Documental: 87.5%'),
            Text('• Consultas a Historiador IA: 142 registradas'),
            SizedBox(height: 12),
            Text(
              'El informe ha sido compilado para la supervisión pedagógica institucional.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Descargar Copia'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
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
        title: const Text('Evaluación y Reportes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de Promedio y Métricas
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.logoNavy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promedio Académico Institucional',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '4.7',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Serif',
                        ),
                      ),
                      Text(
                        ' / 5.0',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      Spacer(),
                      Icon(Icons.trending_up, color: AppColors.logoGold, size: 36),
                    ],
                  ),
                  SizedBox(height: 14),
                  Divider(color: Colors.white24),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estudiantes Evaluados:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('32 de 32 (100%)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Aprobación Curricular:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('96.8%', style: TextStyle(color: AppColors.logoGoldLight, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Evaluaciones recientes
            const Text(
              'Evaluaciones y Comprobaciones Registradas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),

            ..._evaluations.map((eval) => _buildEvalCard(eval)),

            const SizedBox(height: 20),

            CustomButton(
              text: 'Generar Reporte Académico Oficial',
              variant: CustomButtonVariant.green,
              onPressed: _generateOfficialReport,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEvalCard(Map<String, dynamic> eval) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sandAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  eval['section'],
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C2D12)),
                ),
              ),
              const Spacer(),
              Text(eval['date'], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            eval['title'],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Entregas: ${eval['completedCount']}/${eval['totalStudents']}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Promedio: ${eval['averageScore']} / 5.0',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
