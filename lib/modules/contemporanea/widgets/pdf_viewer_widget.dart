import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../../../app/theme.dart';
import '../../../services/content_service.dart';
import '../../../services/progress_service.dart';

/// Visor interno de documentos PDF dentro de la aplicación Flutter.
/// Permite desplazar páginas, saltar de página y guarda la posición de lectura.
class PdfViewerWidget extends StatefulWidget {
  final String materialId;
  final String title;
  final String assetPath;

  const PdfViewerWidget({
    super.key,
    required this.materialId,
    required this.title,
    required this.assetPath,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  final ProgressService _progressService = ProgressService();
  final ContentService _contentService = ContentService();

  PDFViewController? _pdfViewController;
  String? _localFilePath;
  bool _isLoading = true;
  String? _errorMessage;

  int _totalPages = 0;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  /// Copia los bytes del asset a un archivo temporal para su lectura fluida en el PDFView nativo.
  Future<void> _preparePdf() async {
    try {
      final bytes = await rootBundle.load(widget.assetPath);
      final dir = await getTemporaryDirectory();
      final filename = widget.assetPath.split('/').last;
      final file = File('${dir.path}/$filename');

      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      final initialPage = await _progressService.getPdfLastPage(widget.materialId);

      if (mounted) {
        setState(() {
          _localFilePath = file.path;
          _currentPage = initialPage;
          _isLoading = false;
        });
      }

      // Marcar material como visto automáticamente al abrirlo
      await _contentService.markAsViewed(widget.materialId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudo cargar el archivo PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onPageChanged(int? page, int? total) {
    if (page != null) {
      final pageNumber = page + 1; // 1-based index
      setState(() {
        _currentPage = pageNumber;
        if (total != null) _totalPages = total;
      });
      _progressService.setPdfLastPage(widget.materialId, pageNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pág. $_currentPage / $_totalPages',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryTeal),
                  SizedBox(height: 16),
                  Text('Cargando documento PDF...',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.dangerRed),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                )
              : PDFView(
                  filePath: _localFilePath,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  defaultPage: _currentPage - 1, // 0-based for PDFView
                  onRender: (pages) {
                    setState(() {
                      _totalPages = pages ?? 0;
                    });
                  },
                  onViewCreated: (PDFViewController pdfViewController) {
                    _pdfViewController = pdfViewController;
                  },
                  onPageChanged: _onPageChanged,
                  onError: (error) {
                    setState(() {
                      _errorMessage = error.toString();
                    });
                  },
                ),
      bottomNavigationBar: _totalPages > 1
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceWhite,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.navigate_before, size: 30),
                    color: _currentPage > 1
                        ? AppColors.primaryTeal
                        : Colors.grey.shade400,
                    onPressed: _currentPage > 1
                        ? () {
                            _pdfViewController?.setPage(_currentPage - 2);
                          }
                        : null,
                  ),
                  Text(
                    'Página $_currentPage de $_totalPages',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigate_next, size: 30),
                    color: _currentPage < _totalPages
                        ? AppColors.primaryTeal
                        : Colors.grey.shade400,
                    onPressed: _currentPage < _totalPages
                        ? () {
                            _pdfViewController?.setPage(_currentPage);
                          }
                        : null,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
