import 'rag_reference_model.dart';

/// Modelo para los mensajes del chat del Historiador IA.
class ChatMessageModel {
  final String id;
  final String sender; // 'user' or 'ai'
  final String message;
  final String timestamp;
  final String? cardTitle;
  final String? imageUrl;
  final List<String>? tags;
  final List<RAGReference>? references;
  final bool isAbstention;

  const ChatMessageModel({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    this.cardTitle,
    this.imageUrl,
    this.tags,
    this.references,
    this.isAbstention = false,
  });

  bool get isUser => sender == 'user';
  bool get hasReferences => references != null && references!.isNotEmpty;

  static List<ChatMessageModel> getMockHistory() {
    return [
      const ChatMessageModel(
        id: 'msg_1',
        sender: 'ai',
        message:
            '¡Hola! Soy tu Historiador IA de Panamá Histórica. Mi función es responder tus preguntas utilizando exclusivamente los libros, documentos y testimonios históricos disponibles en la aplicación.\n\nPuedes consultarme sobre la gesta patriótica del 9 de enero de 1964, los antecedentes canaleros, testimonios de los protagonistas y las fuentes documentales disponibles.',
        timestamp: '10:45 AM',
      ),
      const ChatMessageModel(
        id: 'msg_2',
        sender: 'user',
        message: '¿Por qué marcharon los estudiantes del Instituto Nacional el 9 de enero de 1964?',
        timestamp: '10:46 AM',
      ),
      const ChatMessageModel(
        id: 'msg_3',
        sender: 'ai',
        cardTitle: 'Reclamación Patriótica del 9 de Enero',
        message:
            'El 9 de enero de 1964, aproximadamente 200 estudiantes del Instituto Nacional marcharon de forma pacífica hacia la Escuela Secundaria de Balboa (Balboa High School) en la Zona del Canal.\n\nSu propósito fundamental era hacer cumplir los acuerdos vigentes entre Panamá y los Estados Unidos (acuerdo Chiari-Kennedy), que estipulaban que la bandera panameña debía ser izada junto a la estadounidense en los sitios públicos de la Zona del Canal. Los estudiantes solicitaron la histórica bandera de su plantel al Rector del Instituto Nacional para enarbolarla con honor.',
        timestamp: '10:46 AM',
        imageUrl: 'assets/modules/contemporanea/images/martires-panama.jpg',
        tags: ['Gesta de 1964', 'Instituto Nacional', 'Soberanía Canalera'],
        references: [
          RAGReference(
            documentTitle: 'El 9 de enero de 1964: lo que no me contaron (Wendy Tribaldos, 2023)',
            section: 'Introducción: un porqué / Arropados bajo una enseña',
            page: 11,
            excerpt: 'Unos 200 estudiantes del Instituto Nacional marcharon pacíficamente a la escuela secundaria de Balboa en la Zona del Canal, para protestar por el incumplimiento de acuerdos entre Panamá y Estados Unidos relativos a la izada de las banderas de ambos países.',
          ),
        ],
      ),
    ];
  }
}
