/// Modelo que representa un fragmento de texto indexado a partir de los documentos internos.
class DocumentChunk {
  final String id;
  final String docId;
  final String documentTitle;
  final String section;
  final int page;
  final String text;

  const DocumentChunk({
    required this.id,
    required this.docId,
    required this.documentTitle,
    required this.section,
    required this.page,
    required this.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doc_id': docId,
      'document_title': documentTitle,
      'section': section,
      'page': page,
      'text': text,
    };
  }

  factory DocumentChunk.fromJson(Map<String, dynamic> json) {
    return DocumentChunk(
      id: json['id'] as String? ?? '',
      docId: json['doc_id'] as String? ?? '',
      documentTitle: json['document_title'] as String? ?? 'Documento Interno',
      section: json['section'] as String? ?? 'Sección Principal',
      page: (json['page'] as num?)?.toInt() ?? 1,
      text: json['text'] as String? ?? '',
    );
  }
}
