import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import '../models/rag_reference_model.dart';
import 'document_storage_service.dart';
import 'rag/document_indexer_service.dart';
import 'rag/rag_response_generator.dart';
import 'rag/retrieval_engine.dart';

/// Servicio del Historiador IA basado en recuperación documental (RAG) estricta.
/// Garantiza que el asistente utilice exclusivamente los libros y documentos
/// internos del proyecto, identificando fuentes y absteniéndose cuando no haya evidencia.
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final List<ChatMessageModel> _messages = ChatMessageModel.getMockHistory();
  final DocumentIndexerService _indexer = DocumentIndexerService();
  final RetrievalEngine _retrievalEngine = RetrievalEngine();

  // Opciones de integración con backend seguro o Gemini API
  static const String _backendUrl = String.fromEnvironment(
    'HISTORIAN_BACKEND_URL',
    defaultValue: '',
  );
  static const String _backendApiKey = String.fromEnvironment(
    'HISTORIAN_API_KEY',
    defaultValue: '',
  );
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  /// Consulta al Historiador IA utilizando exclusivamente los documentos internos.
  Future<ChatMessageModel> askHistorian(String question) async {
    final userMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      message: question,
      timestamp: _formattedTime(),
    );
    _messages.add(userMsg);

    // Asegurar que los documentos base e incorporados por docentes estén inicializados e indexados
    if (!_indexer.isInitialized) {
      await _indexer.initialize();
      await DocumentStorageService().initialize();
    }

    // 1. Recuperar los fragmentos más relevantes y verificar umbral de evidencia
    final retrievalResult = _retrievalEngine.retrieve(question);

    ChatMessageModel aiResponse;

    // 2. Si no hay suficiente evidencia documental, abstenerse de inmediato
    if (!retrievalResult.hasSufficientEvidence || retrievalResult.chunks.isEmpty) {
      aiResponse = ChatMessageModel(
        id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'ai',
        cardTitle: null,
        message: RAGResponseGenerator.abstentionMessage,
        timestamp: _formattedTime(),
        tags: const ['Sin evidencia documental'],
        isAbstention: true,
      );
    } else {
      // 3. Si hay evidencia suficiente: intentar Gemini API o backend seguro si están configurados,
      // o utilizar el generador pedagógico directo local estricto.
      RAGResponse? dynamicResponse;
      if (_backendUrl.isNotEmpty) {
        dynamicResponse = await _querySecureBackend(question, retrievalResult);
      } else if (_geminiApiKey.isNotEmpty) {
        dynamicResponse = await _queryGeminiRAG(question, retrievalResult);
      }

      final ragResponse = dynamicResponse ??
          RAGResponseGenerator.generate(
            question: question,
            retrievalResult: retrievalResult,
          );

      aiResponse = ChatMessageModel(
        id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'ai',
        cardTitle: ragResponse.cardTitle,
        message: ragResponse.text,
        timestamp: _formattedTime(),
        tags: ragResponse.tags,
        references: ragResponse.references,
        isAbstention: ragResponse.isAbstention,
      );
    }

    _messages.add(aiResponse);
    return aiResponse;
  }

  /// Consulta directa a la API de Gemini enviando exclusivamente los fragmentos recuperados
  Future<RAGResponse?> _queryGeminiRAG(
    String question,
    RetrievalResult retrievalResult,
  ) async {
    try {
      final contextText = retrievalResult.chunks
          .map((c) => '--- Documento: ${c.documentTitle} (Pág. ${c.page}, Sección: ${c.section}) ---\n${c.text}')
          .join('\n\n');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
      );

      final payload = {
        'system_instruction': {
          'parts': [
            {
              'text':
                  'Eres el Historiador IA de Panamá Histórica, asistente educativo para estudiantes de 11.º grado.\n'
                  'REGLA FUNDAMENTAL: Tu única fuente de información son los fragmentos de documentos oficiales provistos a continuación.\n'
                  'Debes responder DIRECTA, EDUCATIVAMENTE y CON DETALLES a la pregunta planteada, contestando la duda en el primer párrafo.\n'
                  'No inventes fechas ni personajes. No menciones "según el fragmento provisto", responde con seguridad como un historiador experto.\n'
                  'Si los fragmentos no contienen información suficiente para responder, debes responder estrictamente:\n'
                  '"No encuentro información suficiente sobre este tema en los libros y documentos disponibles en Panamá Histórica. Intenta consultar otro documento o formular otra pregunta relacionada con el contenido disponible."'
            }
          ]
        },
        'contents': [
          {
            'parts': [
              {
                'text':
                    'DOCUMENTOS OFICIALES:\n$contextText\n\nPREGUNTA DEL ESTUDIANTE:\n$question'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 800,
        }
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final answer = parts.first['text'] as String?;
            if (answer != null && answer.trim().isNotEmpty) {
              final isAbstention = answer.contains('No encuentro información suficiente');
              return RAGResponse(
                text: answer.trim(),
                cardTitle: 'Respuesta Documental Histórica',
                references: isAbstention
                    ? const []
                    : retrievalResult.chunks
                        .map((c) => RAGReference(
                              documentTitle: c.documentTitle,
                              section: c.section,
                              page: c.page,
                              excerpt: c.text.length > 150 ? '${c.text.substring(0, 147)}...' : c.text,
                            ))
                        .toList(),
                tags: const ['Historiador IA', 'Historia de Panamá'],
                isAbstention: isAbstention,
              );
            }
          }
        }
      }
    } catch (_) {
      // Si falla la llamada a Gemini, se recurre automáticamente al generador local
    }
    return null;
  }

  /// Envía únicamente la pregunta y los fragmentos recuperados a un backend seguro
  Future<RAGResponse?> _querySecureBackend(
    String question,
    RetrievalResult retrievalResult,
  ) async {
    try {
      final payload = {
        'question': question,
        'chunks': retrievalResult.chunks
            .map((c) => {
                  'document_title': c.documentTitle,
                  'section': c.section,
                  'page': c.page,
                  'text': c.text,
                })
            .toList(),
      };

      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {
              'Content-Type': 'application/json',
              if (_backendApiKey.isNotEmpty) 'Authorization': 'Bearer $_backendApiKey',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('answer')) {
          final isAbstention = data['is_abstention'] == true;
          return RAGResponse(
            text: data['answer'] as String? ?? RAGResponseGenerator.abstentionMessage,
            cardTitle: data['card_title'] as String?,
            references: retrievalResult.chunks
                .map((c) => RAGReference(
                      documentTitle: c.documentTitle,
                      section: c.section,
                      page: c.page,
                      excerpt: c.text.length > 150 ? '${c.text.substring(0, 147)}...' : c.text,
                    ))
                .toList(),
            tags: const ['Backend RAG', 'Historia de Panamá'],
            isAbstention: isAbstention,
          );
        }
      }
    } catch (_) {
      // Si el backend seguro falla o excede el tiempo límite, fallback automático
      // al motor RAG documental local estricto.
    }
    return null;
  }

  String _formattedTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
