import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/academic_evaluation_model.dart';

/// Servicio responsable de generar y exportar reportes académicos oficiales
/// en formato PDF y hojas de cálculo Excel (.csv con codificación UTF-8 BOM).
class ReportExportService {
  static final ReportExportService _instance = ReportExportService._internal();
  factory ReportExportService() => _instance;
  ReportExportService._internal();

  /// Genera un documento PDF estructurado y estilizado con la identidad de Panamá Histórica.
  Future<File> generatePdfReport({
    required String reportTitle,
    required String teacherName,
    required String institution,
    required List<AcademicEvaluationModel> evaluations,
    required double averageScore,
    required int evaluatedStudentsCount,
    String filterDescription = 'Todos los registros',
  }) async {
    final PdfDocument document = PdfDocument();
    document.pageSettings.margins.all = 30;

    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;
    final Size pageSize = page.getClientSize();

    // Colores institucionales
    final PdfColor navyColor = PdfColor(1, 43, 89); // AppColors.logoNavy
    final PdfColor goldColor = PdfColor(200, 144, 24); // AppColors.logoGold

    // Fuentes
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.timesRoman, 18, style: PdfFontStyle.bold);
    final PdfFont subTitleFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfFont boldFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

    // 1. Cabecera institucional
    graphics.drawString(
      'REPÚBLICA DE PANAMÁ • MINISTERIO DE EDUCACIÓN',
      subTitleFont,
      brush: PdfSolidBrush(goldColor),
      bounds: Rect.fromLTWH(0, 0, pageSize.width, 16),
    );

    graphics.drawString(
      'PANAMÁ HISTÓRICA - $reportTitle',
      titleFont,
      brush: PdfSolidBrush(navyColor),
      bounds: Rect.fromLTWH(0, 18, pageSize.width, 24),
    );

    // Línea divisoria decorativa
    graphics.drawLine(
      PdfPen(goldColor, width: 2),
      const Offset(0, 46),
      Offset(pageSize.width, 46),
    );

    // 2. Metadatos del informe
    final String dateStr = _formatCurrentDate();
    final String metaText =
        'Docente: $teacherName   |   Institución: $institution\n'
        'Fecha de Generación: $dateStr   |   Filtro aplicado: $filterDescription';

    graphics.drawString(
      metaText,
      subTitleFont,
      brush: PdfSolidBrush(PdfColor(70, 80, 95)),
      bounds: Rect.fromLTWH(0, 52, pageSize.width, 28),
    );

    // 3. Tarjeta de Indicadores Clave
    final passingCount = evaluations.where((e) => e.isApproved).length;
    final double passingRate = evaluations.isEmpty ? 0.0 : (passingCount / evaluations.length) * 100;

    final String statsSummary =
        'Promedio General: ${averageScore.toStringAsFixed(1)} / 100   •   '
        'Estudiantes Evaluados: $evaluatedStudentsCount   •   '
        'Total Evaluaciones: ${evaluations.length}   •   '
        'Aprobación: ${passingRate.toStringAsFixed(1)}%';

    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(248, 250, 252)),
      pen: PdfPen(PdfColor(226, 232, 240), width: 1),
      bounds: Rect.fromLTWH(0, 84, pageSize.width, 24),
    );

    graphics.drawString(
      statsSummary,
      boldFont,
      brush: PdfSolidBrush(navyColor),
      bounds: Rect.fromLTWH(8, 90, pageSize.width - 16, 18),
    );

    // 4. Tabla detallada de calificaciones
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 6);

    grid.headers.add(1);
    final PdfGridRow header = grid.headers[0];
    header.cells[0].value = 'Estudiante';
    header.cells[1].value = 'Grado';
    header.cells[2].value = 'Módulo / Sección';
    header.cells[3].value = 'Actividad';
    header.cells[4].value = 'Nota (0-100)';
    header.cells[5].value = 'Observaciones';

    // Estilo cabecera
    header.style = PdfGridRowStyle(
      backgroundBrush: PdfSolidBrush(navyColor),
      textBrush: PdfBrushes.white,
      font: boldFont,
    );

    // Filas de datos
    for (final eval in evaluations) {
      final row = grid.rows.add();
      row.cells[0].value = eval.studentName;
      row.cells[1].value = eval.studentGrade;
      row.cells[2].value = '${eval.moduleTitle}\n${eval.sectionTitle}';
      row.cells[3].value = eval.activityTitle;
      row.cells[4].value = '${eval.score.toStringAsFixed(1)} pts (${eval.performanceLevel})';
      row.cells[5].value = eval.observations.isNotEmpty ? eval.observations : 'Sin observaciones.';
    }

    grid.style = PdfGridStyle(
      font: subTitleFont,
      cellPadding: PdfPaddings(left: 5, top: 4, right: 5, bottom: 4),
    );

    // Dibujar la tabla debajo del resumen
    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 116, pageSize.width, pageSize.height - 120),
    );

    // Guardar archivo PDF
    final List<int> bytes = await document.save();
    document.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/Reporte_Academico_Panama_Historica_$timestamp.pdf');
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  /// Genera un archivo de hoja de cálculo Excel (CSV estructurado con delimitador institucional y UTF-8 BOM).
  /// Se abre nativamente en Microsoft Excel con columnas automáticas y caracteres en español.
  Future<File> generateExcelReport({
    required String reportTitle,
    required String teacherName,
    required String institution,
    required List<AcademicEvaluationModel> evaluations,
    required double averageScore,
    required int evaluatedStudentsCount,
    String filterDescription = 'Todos los registros',
  }) async {
    final buffer = StringBuffer();

    // Marca UTF-8 BOM para forzar a Excel a abrirlo con acentos sin problemas
    buffer.write('\uFEFF');

    // 1. Cabecera del Reporte
    buffer.writeln('"REPÚBLICA DE PANAMÁ - MINISTERIO DE EDUCACIÓN"');
    buffer.writeln('"PANAMÁ HISTÓRICA - $reportTitle"');
    buffer.writeln('"Docente:";"$teacherName"');
    buffer.writeln('"Institución:";"$institution"');
    buffer.writeln('"Fecha de Generación:";"${_formatCurrentDate()}"');
    buffer.writeln('"Filtro Aplicado:";"$filterDescription"');
    buffer.writeln('');

    // 2. Resumen Estadístico
    final passingCount = evaluations.where((e) => e.isApproved).length;
    final double passingRate = evaluations.isEmpty ? 0.0 : (passingCount / evaluations.length) * 100;

    buffer.writeln('"RESUMEN ACADÉMICO CALCULADO"');
    buffer.writeln('"Promedio General (0-100)";"${averageScore.toStringAsFixed(1)}"');
    buffer.writeln('"Total Estudiantes Evaluados";"$evaluatedStudentsCount"');
    buffer.writeln('"Total Evaluaciones Registradas";"${evaluations.length}"');
    buffer.writeln('"Tasa de Aprobación";"${passingRate.toStringAsFixed(1)}%"');
    buffer.writeln('');

    // 3. Columnas de la Tabla
    buffer.writeln(
      '"ID Estudiante";"Nombre del Estudiante";"Grado";"Módulo Histórico";"Sección / Tema";"Actividad";"Calificación (0-100)";"Nivel de Desempeño";"Observaciones Pedagógicas";"Docente Evaluador";"Fecha de Registro"',
    );

    // 4. Filas de datos
    for (final eval in evaluations) {
      final safeObs = eval.observations.replaceAll('"', '""').replaceAll('\n', ' ');
      buffer.writeln(
        '"${eval.studentId}";"${eval.studentName}";"${eval.studentGrade}";"${eval.moduleTitle}";"${eval.sectionTitle}";"${eval.activityTitle}";"${eval.score.toStringAsFixed(1)}";"${eval.performanceLevel}";"$safeObs";"${eval.teacherName}";"${eval.formattedDate}"',
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/Reporte_Calificaciones_Panama_Historica_$timestamp.csv');
    await file.writeAsString(buffer.toString(), flush: true);

    return file;
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
