/// Modelo de datos para las Escenas Históricas del Módulo Panamá Contemporánea.
class HistoricalScene {
  final String id;
  final String title;
  final String? imagePath; // Ruta local del activo existente (o null si no aplica)
  final String text;
  final String narrationText;
  final String source;
  final String sourcePage;
  final String period;
  final String duration; // e.g. "02:15"

  const HistoricalScene({
    required this.id,
    required this.title,
    this.imagePath,
    required this.text,
    required this.narrationText,
    required this.source,
    required this.sourcePage,
    this.period = 'Contexto histórico',
    this.duration = '02:15',
  });

  /// Lista de escenas históricas preconfiguradas basadas en el material documental
  /// "El 9 de enero de 1964: lo que no me contaron" y asociadas exclusivamente
  /// a las imágenes locales que existen en el proyecto.
  static List<HistoricalScene> getContemporaneaScenes() {
    return const [
      HistoricalScene(
        id: 'escena_01',
        title: '9 de enero de 1964: Reclamación Patriótica',
        imagePath: 'assets/modules/contemporanea/images/martires-panama.jpg',
        period: 'Contexto histórico',
        duration: '02:15',
        source: 'El 9 de enero de 1964: lo que no me contaron',
        sourcePage: 'Páginas 12-18',
        text:
            'El 9 de enero de 1964, un grupo de estudiantes del Instituto Nacional de Panamá marcharon pacíficamente hacia la Escuela Secundaria de Balboa en la Zona del Canal. Su objetivo era hacer cumplir el acuerdo Chiari-Kennedy que establecía que la bandera panameña debía ser izada junto a la estadounidense en los lugares públicos de la Zona del Canal.',
        narrationText:
            'El 9 de enero de 1964 marcó un hito en la historia panameña. Estudiantes del Instituto Nacional acudieron a la Escuela de Balboa para hacer valer la izada de nuestro pabellón patrio. Los ultrajes a la bandera nacional desencadenaron la movilización popular en defensa de la soberanía e integridad territorial de Panamá.',
      ),
      HistoricalScene(
        id: 'escena_02',
        title: 'Los Mártires de la Soberanía Nacional',
        imagePath: 'assets/modules/contemporanea/images/martires-panama-2.jpg',
        period: 'Contexto histórico',
        duration: '03:40',
        source: 'El 9 de enero de 1964: lo que no me contaron',
        sourcePage: 'Páginas 24-30',
        text:
            'Ante el ultraje del pabellón patrio por parte de estudiantes y civiles zonians, la ciudadanía panameña se movilizó en las avenidas limítrofes. El enfrentamiento desigual contra las fuerzas armadas estadounidenses dejó un trágico saldo de más de 20 panameños fallecidos y cientos de heridos, consagrados como los Mártires de Enero.',
        narrationText:
            'La violencia desatada contra el pueblo panameño cobró la vida de jóvenes, estudiantes y trabajadores. Su sacrificio demostró la firme determinación de toda una nación por erradicar el enclave colonial y lograr la plena soberanía sobre todo el territorio istmeño.',
      ),
      HistoricalScene(
        id: 'escena_03',
        title: 'La Izada de la Bandera en la Zona del Canal',
        imagePath: 'assets/modules/contemporanea/images/martires.jfif',
        period: 'Contexto histórico',
        duration: '02:50',
        source: 'El 9 de enero de 1964: lo que no me contaron',
        sourcePage: 'Páginas 35-42',
        text:
            'El compromiso de izar la bandera tricolor panameña fue el resultado de décadas de luchas estudiantiles y diplomáticas. Los sucesos de enero reafirmaron que la presencia de una jurisdicción extranjera en el corazón de Panamá era insostenible para la paz y la dignidad nacional.',
        narrationText:
            'Ver la bandera tricolor flamear en la Zona del Canal fue un anhelo de generaciones. La gesta patriótica de 1964 demostró al mundo que Panamá no descansaría hasta ver unificada su patria bajo una sola bandera y una sola jurisdicción.',
      ),
      HistoricalScene(
        id: 'escena_04',
        title: 'Antecedentes y Consecuencias Históricas',
        imagePath: null, // Escena sin imagen (respetando la regla de no inventar ni descargar imágenes)
        period: 'Contexto histórico',
        duration: '01:55',
        source: 'El 9 de enero de 1964: lo que no me contaron',
        sourcePage: 'Páginas 45-50',
        text:
            'La gesta del 9 de enero obligó a la ruptura de relaciones diplomáticas con EE.UU. y condujo a la firma de los Tratados Torrijos-Carter en 1977, logrando la eliminación del Tratado Hay-Bunau Varilla de 1903 y la transferencia total del Canal a manos panameñas el 31 de diciembre de 1999.',
        narrationText:
            'Los trágicos acontecimientos del 9 de enero transformaron las relaciones entre Panamá y los Estados Unidos. La diplomacia panameña exigió la abrogación del tratado de 1903, culminando años más tarde con la devolución del Canal y la salida de las tropas extranjeras del territorio nacional.',
      ),
    ];
  }
}
