import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/document_model.dart';
import '../../models/module_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/document_storage_service.dart';
import '../../widgets/app_logo_leading.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Pantalla para que el docente incorpore libros, documentos e imágenes
/// seleccionándolos desde su dispositivo y asignándolos a un módulo y sección histórica.
class TeacherAddDocumentScreen extends StatefulWidget {
  const TeacherAddDocumentScreen({super.key});

  @override
  State<TeacherAddDocumentScreen> createState() => _TeacherAddDocumentScreenState();
}

class _TeacherAddDocumentScreenState extends State<TeacherAddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DocumentStorageService _storageService = DocumentStorageService();
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _newSectionController = TextEditingController();

  List<ModuleModel> _modules = [];
  String _selectedModuleId = 'mod_contemporanea';
  String _selectedModuleTitle = 'Panamá Contemporánea';

  List<String> _sections = [];
  String _selectedSection = '9 de enero de 1964';
  bool _isCreatingNewSection = false;

  PlatformFile? _pickedFile;
  int _pickedFileSize = 0;
  Uint8List? _pickedFileBytes;
  bool _isLoading = false;
  bool _isPublishImmediately = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final modules = await _dbService.getModules();
    final sections = await _storageService.getSectionsForModule(_selectedModuleId);

    if (mounted) {
      setState(() {
        _modules = modules;
        _sections = sections;
        if (sections.isNotEmpty) {
          _selectedSection = sections.first;
        }
      });
    }
  }

  Future<void> _pickFileFromDevice() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'jfif', 'webp'],
      );

      if (file != null) {
        final fileSize = (await file.length()) ?? file.lengthSync() ?? 0;

        // Validar tamaño máximo: 25 MB
        if (fileSize > DocumentStorageService.maxFileSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El archivo supera el tamaño máximo permitido de 25 MB.'),
                backgroundColor: AppColors.dangerRed,
              ),
            );
          }
          return;
        }

        if (fileSize <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El archivo seleccionado está vacío.'),
                backgroundColor: AppColors.dangerRed,
              ),
            );
          }
          return;
        }

        Uint8List? bytes;
        try {
          bytes = await file.readAsBytes();
        } catch (_) {}

        setState(() {
          _pickedFile = file;
          _pickedFileSize = fileSize;
          _pickedFileBytes = bytes;
          // Si el título está vacío, sugerir nombre del archivo sin extensión
          if (_titleController.text.trim().isEmpty) {
            final nameWithoutExt = file.name.split('.').first.replaceAll('_', ' ');
            _titleController.text = nameWithoutExt;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivo: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _saveDocument() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un archivo (PDF o imagen) desde su dispositivo.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título del documento es obligatorio.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final author = _authorController.text.trim();
    if (author.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identifique el autor o la fuente del material educativo.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final section = _isCreatingNewSection
        ? _newSectionController.text.trim()
        : _selectedSection.trim();

    if (section.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar o definir una sección temática.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentTeacher = _authService.currentUser;
      final teacherId = currentTeacher?.id ?? 'doc_meduca';
      final teacherName = currentTeacher?.name ?? 'Prof. Docente Autorizado';

      final doc = await _storageService.addDocument(
        title: title,
        description: _descriptionController.text.trim(),
        author: author,
        moduleId: _selectedModuleId,
        moduleTitle: _selectedModuleTitle,
        sectionTitle: section,
        sourceFilePath: _pickedFile!.path ?? '',
        fileName: _pickedFile!.name,
        fileSizeBytes: _pickedFileSize,
        fileBytes: _pickedFileBytes,
        teacherId: teacherId,
        teacherName: teacherName,
        status: _isPublishImmediately
            ? DocumentPublicationStatus.published
            : DocumentPublicationStatus.draft,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isPublishImmediately
                  ? '«${doc.title}» publicado e indexado para el Historiador IA exitosamente.'
                  : '«${doc.title}» guardado como Borrador.',
            ),
            backgroundColor: AppColors.forestGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Validación de Documento'),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 84,
        leading: const AppLogoLeading(showBackButton: true),
        title: const Text('Incorporar Documento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de carga de archivo
              const Text(
                '1. Archivo desde el Dispositivo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.logoNavy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Formatos admitidos: Libros y documentos PDF, imágenes históricas (JPG, PNG). Máx. 25 MB.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),

              _buildFilePickerSection(),

              const SizedBox(height: 24),

              // Sección de Metadatos
              const Text(
                '2. Información del Material',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.logoNavy,
                ),
              ),
              const SizedBox(height: 12),

              CustomTextField(
                label: 'Título del Documento *',
                hint: 'Ej. Tratados Torrijos-Carter: Instrumentos de Ratificación',
                controller: _titleController,
                prefixIcon: Icons.title,
              ),

              const SizedBox(height: 14),

              CustomTextField(
                label: 'Autor o Fuente Histórica *',
                hint: 'Ej. Archivo Histórico de la Cancillería de Panamá',
                controller: _authorController,
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: 14),

              CustomTextField(
                label: 'Descripción Pedagógica',
                hint: 'Explique brevemente el contenido y relevancia para los estudiantes...',
                controller: _descriptionController,
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Sección de Módulo y Tema
              const Text(
                '3. Ubicación Curricular',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.logoNavy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Seleccione el módulo y la sección exacta donde el documento estará disponible para los estudiantes.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),

              // Selector de Módulo
              _buildModuleSelector(),

              const SizedBox(height: 14),

              // Selector de Sección / Tema
              _buildSectionSelector(),

              const SizedBox(height: 24),

              // Publicación
              const Text(
                '4. Estado de Publicación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.logoNavy,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPublishImmediately ? Icons.public : Icons.drafts_outlined,
                      color: _isPublishImmediately ? AppColors.forestGreen : AppColors.logoGoldDark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPublishImmediately ? 'Publicar inmediatamente' : 'Guardar como borrador',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            _isPublishImmediately
                                ? 'Los estudiantes podrán consultarlo de inmediato en su módulo y el Historiador IA indexará su contenido.'
                                : 'Solo visible para docentes hasta que decida publicarlo.',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPublishImmediately,
                      activeThumbColor: AppColors.forestGreen,
                      onChanged: (val) {
                        setState(() {
                          _isPublishImmediately = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              CustomButton(
                text: _isPublishImmediately ? 'Guardar y Publicar Documento' : 'Guardar en Borradores',
                isLoading: _isLoading,
                onPressed: _saveDocument,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePickerSection() {
    if (_pickedFile != null) {
      final isPdf = _pickedFile!.extension?.toLowerCase() == 'pdf';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.forestGreen, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPdf ? AppColors.logoRed.withValues(alpha: 0.1) : AppColors.logoNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPdf ? Icons.picture_as_pdf : Icons.image,
                color: isPdf ? AppColors.logoRed : AppColors.logoNavy,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pickedFile!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(_pickedFileSize / (1024 * 1024)).toStringAsFixed(2)} MB • Archivo compatible verificado',
                    style: const TextStyle(fontSize: 12, color: AppColors.forestGreen, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.change_circle_outlined, color: AppColors.logoNavy),
              tooltip: 'Cambiar archivo',
              onPressed: _pickFileFromDevice,
            ),
          ],
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pickFileFromDevice,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.logoGold, style: BorderStyle.solid, width: 1.5),
        ),
        child: const Column(
          children: [
            Icon(Icons.cloud_upload_outlined, size: 44, color: AppColors.logoGoldDark),
            SizedBox(height: 10),
            Text(
              'Seleccionar archivo del dispositivo',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.logoNavy,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Toque aquí para abrir el explorador de archivos (PDF o Imagen)',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedModuleId,
          isExpanded: true,
          items: _modules.map((m) {
            return DropdownMenuItem(
              value: m.id,
              child: Text(
                '${m.code}: ${m.title}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (val) async {
            if (val != null) {
              final mod = _modules.firstWhere((m) => m.id == val);
              final secList = await _storageService.getSectionsForModule(val);
              setState(() {
                _selectedModuleId = val;
                _selectedModuleTitle = mod.title;
                _sections = secList;
                if (secList.isNotEmpty) {
                  _selectedSection = secList.first;
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sección / Tema Específico',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isCreatingNewSection = !_isCreatingNewSection;
                });
              },
              child: Text(
                _isCreatingNewSection ? 'Elegir existente' : '+ Nueva sección',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.logoNavy),
              ),
            ),
          ],
        ),
        if (_isCreatingNewSection) ...[
          CustomTextField(
            label: 'Nombre de la Nueva Sección',
            hint: 'Ej. Tratados Torrijos-Carter de 1977',
            controller: _newSectionController,
            prefixIcon: Icons.add_box_outlined,
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sections.contains(_selectedSection) ? _selectedSection : (_sections.isNotEmpty ? _sections.first : null),
                isExpanded: true,
                items: _sections.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedSection = val);
                  }
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
