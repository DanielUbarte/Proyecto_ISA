import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/document_model.dart';
import '../../modules/contemporanea/widgets/image_viewer_widget.dart';
import '../../modules/contemporanea/widgets/pdf_viewer_widget.dart';
import '../../services/document_storage_service.dart';
import '../../widgets/app_logo_leading.dart';

/// Pantalla de Gestión de Documentos y Biblioteca de Contenidos.
/// Permite al docente administrar, publicar, despublicar, archivar y visualizar
/// los libros y materiales educativos organizados por módulos y secciones.
class TeacherDocumentsScreen extends StatefulWidget {
  const TeacherDocumentsScreen({super.key});

  @override
  State<TeacherDocumentsScreen> createState() => _TeacherDocumentsScreenState();
}

class _TeacherDocumentsScreenState extends State<TeacherDocumentsScreen>
    with SingleTickerProviderStateMixin {
  final DocumentStorageService _storageService = DocumentStorageService();

  late TabController _tabController;
  List<EducationalDocumentModel> _allDocs = [];
  String _searchQuery = '';
  String _selectedModuleFilter = 'Todos';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    final docs = await _storageService.getAllDocuments();
    if (mounted) {
      setState(() {
        _allDocs = docs;
        _isLoading = false;
      });
    }
  }

  List<EducationalDocumentModel> _getFilteredDocuments(int tabIndex) {
    var list = _allDocs;

    // Filtro por pestaña de estado
    if (tabIndex == 1) {
      list = list.where((d) => d.isPublished).toList();
    } else if (tabIndex == 2) {
      list = list.where((d) => d.isDraft).toList();
    } else if (tabIndex == 3) {
      list = list.where((d) => d.isArchived).toList();
    }

    // Filtro por módulo
    if (_selectedModuleFilter != 'Todos') {
      list = list.where((d) => d.moduleTitle == _selectedModuleFilter).toList();
    }

    // Filtro de búsqueda
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((d) {
        return d.title.toLowerCase().contains(q) ||
            d.author.toLowerCase().contains(q) ||
            d.sectionTitle.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  void _openDocument(EducationalDocumentModel doc) {
    Widget viewer;
    if (doc.isPdf) {
      viewer = PdfViewerWidget(
        materialId: doc.id,
        title: doc.title,
        assetPath: doc.filePath,
      );
    } else {
      viewer = ImageViewerWidget(
        materialId: doc.id,
        title: doc.title,
        assetPath: doc.filePath,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => viewer),
    );
  }

  Future<void> _changeStatus(
    EducationalDocumentModel doc,
    DocumentPublicationStatus newStatus,
  ) async {
    try {
      await _storageService.setPublicationStatus(doc.id, newStatus);
      await _loadDocuments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documento actualizado a: ${newStatus.displayName}'),
            backgroundColor: newStatus == DocumentPublicationStatus.published
                ? AppColors.forestGreen
                : AppColors.logoNavy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(EducationalDocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.dangerRed),
            SizedBox(width: 8),
            Text('Eliminar Documento'),
          ],
        ),
        content: Text(
          '¿Está seguro de que desea eliminar «${doc.title}»? Esta acción retirará el archivo y sus fragmentos del Historiador IA.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.deleteDocument(doc.id);
      await _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('«${doc.title}» ha sido eliminado de la biblioteca.')),
        );
      }
    }
  }

  Future<void> _confirmArchive(EducationalDocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar Documento'),
        content: Text(
          '¿Desea archivar «${doc.title}»? Los estudiantes dejarán de verlo en su módulo y el Historiador IA no utilizará este documento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _changeStatus(doc, DocumentPublicationStatus.archived);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableModules = ['Todos', ..._allDocs.map((d) => d.moduleTitle).toSet()];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 84,
        leading: const AppLogoLeading(showBackButton: true),
        title: const Text('Biblioteca de Contenidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.logoNavy, size: 26),
            tooltip: 'Añadir nuevo documento',
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.teacherAddDocument);
              _loadDocuments();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.logoNavy,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.logoGold,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Todos (${_allDocs.length})'),
            Tab(text: 'Publicados (${_allDocs.where((d) => d.isPublished).length})'),
            Tab(text: 'Borrador (${_allDocs.where((d) => d.isDraft).length})'),
            Tab(text: 'Archivados (${_allDocs.where((d) => d.isArchived).length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.logoNavy))
          : Column(
              children: [
                // Barra de Búsqueda y Filtro por Módulo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.surfaceWhite,
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Buscar por título, autor o sección...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                        ),
                      ),
                      if (availableModules.length > 2) ...[
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: availableModules.map((m) {
                              final isSelected = _selectedModuleFilter == m;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(m, style: const TextStyle(fontSize: 11)),
                                  selected: isSelected,
                                  onSelected: (_) => setState(() => _selectedModuleFilter = m),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderGrey),

                // Lista de documentos filtrada
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDocumentList(0),
                      _buildDocumentList(1),
                      _buildDocumentList(2),
                      _buildDocumentList(3),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.logoNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file),
        label: const Text(
          'Añadir Documento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.teacherAddDocument);
          _loadDocuments();
        },
      ),
    );
  }

  Widget _buildDocumentList(int tabIndex) {
    final docs = _getFilteredDocuments(tabIndex);

    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No hay documentos en esta sección',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Utilice el botón "Añadir Documento" para cargar libros, PDFs o imágenes desde su dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return _buildDocCard(doc);
      },
    );
  }

  Widget _buildDocCard(EducationalDocumentModel doc) {
    Color statusColor;
    switch (doc.status) {
      case DocumentPublicationStatus.published:
        statusColor = AppColors.forestGreen;
        break;
      case DocumentPublicationStatus.draft:
        statusColor = AppColors.logoGoldDark;
        break;
      case DocumentPublicationStatus.archived:
        statusColor = AppColors.textMuted;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: doc.isPublished ? AppColors.forestGreen.withValues(alpha: 0.35) : AppColors.borderGrey,
          width: doc.isPublished ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDocument(doc),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila Superior: Tipo, Módulo/Sección y Menú
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: doc.isPdf
                            ? AppColors.logoRed.withValues(alpha: 0.1)
                            : AppColors.logoNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        doc.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                        color: doc.isPdf ? AppColors.logoRed : AppColors.logoNavy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${doc.moduleTitle} • ${doc.sectionTitle}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.logoNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Archivo: ${doc.fileName} (${doc.formattedFileSize})',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildDocPopupMenu(doc),
                  ],
                ),

                const SizedBox(height: 10),

                // Título del documento
                Text(
                  doc.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                if (doc.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    doc.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                  ),
                ],

                const SizedBox(height: 10),

                // Fila Inferior: Autor, Estado e Índice IA
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Autor: ${doc.author}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Badge de Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doc.status.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (doc.isPublished && doc.isIndexed) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.logoGoldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.logoGold.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 10, color: AppColors.logoGoldDark),
                            SizedBox(width: 3),
                            Text(
                              'Historiador IA',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.logoGoldDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocPopupMenu(EducationalDocumentModel doc) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
      onSelected: (action) {
        switch (action) {
          case 'view':
            _openDocument(doc);
            break;
          case 'publish':
            _changeStatus(doc, DocumentPublicationStatus.published);
            break;
          case 'draft':
            _changeStatus(doc, DocumentPublicationStatus.draft);
            break;
          case 'archive':
            _confirmArchive(doc);
            break;
          case 'unarchive':
            _changeStatus(doc, DocumentPublicationStatus.draft);
            break;
          case 'delete':
            _confirmDelete(doc);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18),
              SizedBox(width: 8),
              Text('Ver / Abrir documento'),
            ],
          ),
        ),
        if (!doc.isPublished)
          const PopupMenuItem(
            value: 'publish',
            child: Row(
              children: [
                Icon(Icons.publish_outlined, size: 18, color: AppColors.forestGreen),
                SizedBox(width: 8),
                Text('Publicar para estudiantes'),
              ],
            ),
          ),
        if (doc.isPublished)
          const PopupMenuItem(
            value: 'draft',
            child: Row(
              children: [
                Icon(Icons.edit_note_outlined, size: 18, color: AppColors.logoGoldDark),
                SizedBox(width: 8),
                Text('Pasar a Borrador'),
              ],
            ),
          ),
        if (!doc.isArchived)
          const PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                Icon(Icons.archive_outlined, size: 18),
                SizedBox(width: 8),
                Text('Archivar documento'),
              ],
            ),
          ),
        if (doc.isArchived)
          const PopupMenuItem(
            value: 'unarchive',
            child: Row(
              children: [
                Icon(Icons.unarchive_outlined, size: 18),
                SizedBox(width: 8),
                Text('Desarchivar a Borrador'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.dangerRed),
              SizedBox(width: 8),
              Text('Eliminar de biblioteca', style: TextStyle(color: AppColors.dangerRed)),
            ],
          ),
        ),
      ],
    );
  }
}

