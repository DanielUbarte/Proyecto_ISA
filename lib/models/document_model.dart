enum DocumentPublicationStatus {
  draft,
  published,
  archived;

  String get displayName {
    switch (this) {
      case DocumentPublicationStatus.draft:
        return 'Borrador';
      case DocumentPublicationStatus.published:
        return 'Publicado';
      case DocumentPublicationStatus.archived:
        return 'Archivado';
    }
  }

  static DocumentPublicationStatus fromString(String? status) {
    if (status == null) return DocumentPublicationStatus.draft;
    switch (status.toLowerCase().trim()) {
      case 'published':
      case 'publicado':
        return DocumentPublicationStatus.published;
      case 'archived':
      case 'archivado':
        return DocumentPublicationStatus.archived;
      case 'draft':
      case 'borrador':
      default:
        return DocumentPublicationStatus.draft;
    }
  }
}

/// Modelo de documento educativo para la biblioteca documental de Panamá Histórica.
/// Permite organizar jerárquicamente: Módulo Histórico -> Sección/Tema -> Documento Educativo.
class EducationalDocumentModel {
  final String id;
  final String fileName;
  final String title;
  final String description;
  final String author;
  final DateTime createdAt;
  final String teacherId;
  final String teacherName;
  final String moduleId;
  final String moduleTitle;
  final String sectionId;
  final String sectionTitle;
  final DocumentPublicationStatus status;
  final String filePath; // Ruta al archivo local copiado o asset
  final String fileType; // 'pdf', 'image'
  final int fileSizeBytes;
  final bool isIndexed; // Si su contenido textual ya fue indexado para el Historiador IA
  final String? extractedText;

  const EducationalDocumentModel({
    required this.id,
    required this.fileName,
    required this.title,
    required this.description,
    required this.author,
    required this.createdAt,
    required this.teacherId,
    required this.teacherName,
    required this.moduleId,
    required this.moduleTitle,
    required this.sectionId,
    required this.sectionTitle,
    this.status = DocumentPublicationStatus.draft,
    required this.filePath,
    required this.fileType,
    required this.fileSizeBytes,
    this.isIndexed = false,
    this.extractedText,
  });

  bool get isDraft => status == DocumentPublicationStatus.draft;
  bool get isPublished => status == DocumentPublicationStatus.published;
  bool get isArchived => status == DocumentPublicationStatus.archived;
  bool get isPdf => fileType.toLowerCase() == 'pdf';
  bool get isImage =>
      fileType.toLowerCase() == 'image' ||
      fileType.toLowerCase() == 'jpg' ||
      fileType.toLowerCase() == 'jpeg' ||
      fileType.toLowerCase() == 'png' ||
      fileType.toLowerCase() == 'jfif';

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'title': title,
      'description': description,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'teacherId': teacherId,
      'teacherName': teacherName,
      'moduleId': moduleId,
      'moduleTitle': moduleTitle,
      'sectionId': sectionId,
      'sectionTitle': sectionTitle,
      'status': status.name,
      'filePath': filePath,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'isIndexed': isIndexed,
      'extractedText': extractedText,
    };
  }

  factory EducationalDocumentModel.fromJson(Map<String, dynamic> json) {
    return EducationalDocumentModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String? ?? '',
      title: json['title'] as String? ?? 'Documento sin título',
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? 'Desconocido',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      teacherId: json['teacherId'] as String? ?? 'doc_meduca',
      teacherName: json['teacherName'] as String? ?? 'Docente Autorizado',
      moduleId: json['moduleId'] as String? ?? 'mod_contemporanea',
      moduleTitle: json['moduleTitle'] as String? ?? 'Panamá Contemporánea',
      sectionId: json['sectionId'] as String? ?? 'sec_01',
      sectionTitle: json['sectionTitle'] as String? ?? '9 de enero de 1964',
      status: DocumentPublicationStatus.fromString(json['status'] as String?),
      filePath: json['filePath'] as String? ?? '',
      fileType: json['fileType'] as String? ?? 'pdf',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      isIndexed: json['isIndexed'] as bool? ?? false,
      extractedText: json['extractedText'] as String?,
    );
  }

  EducationalDocumentModel copyWith({
    String? id,
    String? fileName,
    String? title,
    String? description,
    String? author,
    DateTime? createdAt,
    String? teacherId,
    String? teacherName,
    String? moduleId,
    String? moduleTitle,
    String? sectionId,
    String? sectionTitle,
    DocumentPublicationStatus? status,
    String? filePath,
    String? fileType,
    int? fileSizeBytes,
    bool? isIndexed,
    String? extractedText,
  }) {
    return EducationalDocumentModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      moduleId: moduleId ?? this.moduleId,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      sectionId: sectionId ?? this.sectionId,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      isIndexed: isIndexed ?? this.isIndexed,
      extractedText: extractedText ?? this.extractedText,
    );
  }
}

