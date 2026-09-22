/// Estructura de datos para los materiales educativos del módulo Panamá Contemporánea.
class ContemporaneaMaterial {
  final String id;
  final String title;
  final String type; // 'pdf', 'image', 'text'
  final String assetPath;
  final bool viewed;
  final int order;

  const ContemporaneaMaterial({
    required this.id,
    required this.title,
    required this.type,
    required this.assetPath,
    this.viewed = false,
    required this.order,
  });

  ContemporaneaMaterial copyWith({
    String? id,
    String? title,
    String? type,
    String? assetPath,
    bool? viewed,
    int? order,
  }) {
    return ContemporaneaMaterial(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      assetPath: assetPath ?? this.assetPath,
      viewed: viewed ?? this.viewed,
      order: order ?? this.order,
    );
  }

  /// Lista de materiales reales detectados en el proyecto sin modificar títulos ni contenido.
  static List<ContemporaneaMaterial> getInitialMaterials() {
    return const [
      ContemporaneaMaterial(
        id: 'contemporanea_01',
        title: 'PDF 9 de Enero de 1964 (W. Tribaldos)',
        type: 'pdf',
        assetPath:
            'assets/modules/contemporanea/documents/PDF_9 ENERO 1964_WTRIBALDOS_2023.pdf',
        viewed: false,
        order: 1,
      ),
      ContemporaneaMaterial(
        id: 'contemporanea_02',
        title: 'Mártires de Panamá',
        type: 'image',
        assetPath: 'assets/modules/contemporanea/images/martires-panama.jpg',
        viewed: false,
        order: 2,
      ),
      ContemporaneaMaterial(
        id: 'contemporanea_03',
        title: 'Mártires de Panamá - Fotografías 2',
        type: 'image',
        assetPath: 'assets/modules/contemporanea/images/martires-panama-2.jpg',
        viewed: false,
        order: 3,
      ),
      ContemporaneaMaterial(
        id: 'contemporanea_04',
        title: 'Fotografía Histórica Mártires',
        type: 'image',
        assetPath: 'assets/modules/contemporanea/images/martires.jfif',
        viewed: false,
        order: 4,
      ),
    ];
  }
}
