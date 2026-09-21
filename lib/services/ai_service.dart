import '../models/chat_message_model.dart';

/// Service abstraction for AI Historian chatbot API.
/// Prepared for future integration with Gemini / REST API.
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final List<ChatMessageModel> _messages = ChatMessageModel.getMockHistory();

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  /// Sends a query to the AI Historian service.
  Future<ChatMessageModel> askHistorian(String question) async {
    final userMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      message: question,
      timestamp: _formattedTime(),
    );
    _messages.add(userMsg);

    await Future.delayed(const Duration(milliseconds: 1200));

    final aiResponse = ChatMessageModel(
      id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'ai',
      cardTitle: _generateTitle(question),
      message: _generateMockResponse(question),
      timestamp: _formattedTime(),
      tags: const ['Historia de Panamá', 'Educación MEDUCA'],
    );
    _messages.add(aiResponse);

    return aiResponse;
  }

  String _formattedTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _generateTitle(String question) {
    if (question.toLowerCase().contains('balboa') || question.toLowerCase().contains('mar del sur')) {
      return 'El Avistamiento del Mar del Sur';
    }
    if (question.toLowerCase().contains('canal')) {
      return 'Construcción y Soberanía del Canal';
    }
    return 'Respuesta Histórica';
  }

  String _generateMockResponse(String question) {
    if (question.toLowerCase().contains('balboa') || question.toLowerCase().contains('mar del sur')) {
      return 'Vasco Núñez de Balboa divisó el Océano Pacífico (Mar del Sur) el 25 de septiembre de 1513, abriendo la ruta comercial entre dos océanos.';
    }
    return 'Esa es una excelente pregunta sobre la historia panameña. Durante esta época, Panamá desempeñó un papel estratégico como puente comercial y cultural de las Américas.';
  }
}
