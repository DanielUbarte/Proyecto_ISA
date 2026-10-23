/// Modelo que representa una referencia documental verificable adjunta a una respuesta.
class RAGReference {
  final String documentTitle;
  final String section;
  final int page;
  final String excerpt;

  const RAGReference({
    required this.documentTitle,
    required this.section,
    required this.page,
    required this.excerpt,
  });

  Map<String, dynamic> toJson() {
    return {
      'document_title': documentTitle,
      'section': section,
      'page': page,
      'excerpt': excerpt,
    };
  }

  factory RAGReference.fromJson(Map<String, dynamic> json) {
    return RAGReference(
      documentTitle: json['document_title'] as String? ?? 'Documento Interno',
      section: json['section'] as String? ?? 'Sección Principal',
      page: (json['page'] as num?)?.toInt() ?? 1,
      excerpt: json['excerpt'] as String? ?? '',
    );
  }
}
