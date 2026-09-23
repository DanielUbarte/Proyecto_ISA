class ChatMessageModel {
  final String id;
  final String sender; // 'user' or 'ai'
  final String message;
  final String timestamp;
  final String? cardTitle;
  final String? imageUrl;
  final List<String>? tags;

  const ChatMessageModel({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    this.cardTitle,
    this.imageUrl,
    this.tags,
  });

  bool get isUser => sender == 'user';

  static List<ChatMessageModel> getMockHistory() {
    return [
      const ChatMessageModel(
        id: 'msg_1',
        sender: 'ai',
        message:
            '¡Hola, Historiador! Soy tu guía virtual para el fascinante recorrido por el pasado de nuestro istmo. ¿Tienes alguna pregunta específica sobre la historia de Panamá?',
        timestamp: '10:45 AM',
      ),
      const ChatMessageModel(
        id: 'msg_2',
        sender: 'user',
        message: '¿Quién fue Victoriano Lorenzo?',
        timestamp: '10:46 AM',
      ),
      const ChatMessageModel(
        id: 'msg_3',
        sender: 'ai',
        cardTitle: 'El Caudillo del Chorrillo',
        message:
            'Victoriano Lorenzo fue un líder indígena y general revolucionario panameño, figura clave en la **Guerra de los Mil Días**. Es recordado como el primer gran líder popular de Panamá y defensor de los derechos de los campesinos e indígenas ante las injusticias de las autoridades centrales.\n\nSu ejecución el 15 de mayo de 1903 es considerada una de las mayores tragedias de nuestra historia pre-republicana, convirtiéndolo en un símbolo eterno de resistencia nacional.',
        timestamp: '10:46 AM',
        imageUrl: 'assets/modules/contemporanea/images/martires-panama.jpg',
        tags: ['Época Departamental', 'Guerra de los Mil Días'],
      ),
    ];
  }
}
