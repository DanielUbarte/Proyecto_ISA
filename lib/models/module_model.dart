enum ModuleStatus {
  available,
  downloading,
  downloaded,
  locked,
}

class ModuleModel {
  final String id;
  final String code; // e.g. "MÓDULO 01"
  final String title;
  final String description;
  final String category;
  final String duration;
  final String size;
  final int documentCount;
  final double downloadProgress;
  final ModuleStatus status;
  final bool isOfflineAvailable;
  final String unlockRequirement;
  final String bannerImageUrl;
  final String lastUpdated;

  const ModuleModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.size,
    required this.documentCount,
    required this.downloadProgress,
    required this.status,
    required this.isOfflineAvailable,
    this.unlockRequirement = '',
    required this.bannerImageUrl,
    required this.lastUpdated,
  });

  static List<ModuleModel> getMockModules() {
    return [
      const ModuleModel(
        id: 'mod_01',
        code: 'MÓDULO 01',
        title: 'Época colonial y ruta comercial',
        description:
            'Descubre la historia del istmo durante la dominación española, las rutas transístmicas, las ferias de Portobelo y las fortalezas del Caribe panameño.',
        category: 'Historia Colonial',
        duration: '4h 20m',
        size: '245 MB',
        documentCount: 15,
        downloadProgress: 1.0,
        status: ModuleStatus.downloaded,
        isOfflineAvailable: true,
        bannerImageUrl: 'https://images.unsplash.com/photo-1599571234909-29ed5d1321d6',
        lastUpdated: 'hace 2d',
      ),
      const ModuleModel(
        id: 'mod_02',
        code: 'MÓDULO 02',
        title: 'Independencia de Panamá',
        description:
            'Explora los acontecimientos de 1821, la gesta heroica de Rufina Alfaro, el Primer Grito en La Villa de Los Santos y la unión voluntaria a la Gran Colombia.',
        category: 'Independencia',
        duration: '3h 45m',
        size: '145 MB',
        documentCount: 12,
        downloadProgress: 0.0,
        status: ModuleStatus.available,
        isOfflineAvailable: false,
        bannerImageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957',
        lastUpdated: 'hace 1sem',
      ),
      const ModuleModel(
        id: 'mod_03',
        code: 'MÓDULO 03',
        title: 'Construcción y soberanía del Canal',
        description:
            'Explora el hito de ingeniería que cambió el comercio global. Este módulo interactivo profundiza en las luchas sociales por la soberanía y la transferencia administrativa del canal a manos panameñas mediante modelos AR y líneas de tiempo dinámicas.',
        category: 'Historia Republicana',
        duration: '5h 10m',
        size: '150 MB',
        documentCount: 18,
        downloadProgress: 0.45,
        status: ModuleStatus.downloading,
        isOfflineAvailable: false,
        bannerImageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        lastUpdated: 'hace 3d',
      ),
      const ModuleModel(
        id: 'mod_04',
        code: 'MÓDULO 04',
        title: 'Panamá contemporánea',
        description:
            'Análisis de la democracia moderna, la expansión del canal, el crecimiento urbano y los desafíos ambientales y socioeconómicos del siglo XXI.',
        category: 'Época Contemporánea',
        duration: '4h 00m',
        size: '180 MB',
        documentCount: 10,
        downloadProgress: 0.0,
        status: ModuleStatus.locked,
        isOfflineAvailable: false,
        unlockRequirement: 'Requiere completar M03',
        bannerImageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f',
        lastUpdated: 'hace 2sem',
      ),
    ];
  }

  ModuleModel copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? category,
    String? duration,
    String? size,
    int? documentCount,
    double? downloadProgress,
    ModuleStatus? status,
    bool? isOfflineAvailable,
    String? unlockRequirement,
    String? bannerImageUrl,
    String? lastUpdated,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      documentCount: documentCount ?? this.documentCount,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      status: status ?? this.status,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
