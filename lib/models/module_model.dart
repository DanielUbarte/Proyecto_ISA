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
        id: 'mod_contemporanea',
        code: 'MÓDULO 01',
        title: 'Panamá contemporánea',
        description:
            'Análisis de la democracia moderna, la gesta patriótica de 1964, el crecimiento urbano y los desafíos históricos del siglo XXI.',
        category: 'Época Contemporánea',
        duration: '4h 00m',
        size: '36 MB',
        documentCount: 4,
        downloadProgress: 0.0,
        status: ModuleStatus.available,
        isOfflineAvailable: false,
        unlockRequirement: '',
        bannerImageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f',
        lastUpdated: 'Reciente',
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
