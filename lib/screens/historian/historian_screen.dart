import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/chat_message_model.dart';
import '../../models/rag_reference_model.dart';
import '../../services/ai_service.dart';
import '../../widgets/app_logo_leading.dart';
import '../../widgets/bottom_nav_bar.dart';

class HistorianScreen extends StatefulWidget {
  const HistorianScreen({super.key});

  @override
  State<HistorianScreen> createState() => _HistorianScreenState();
}

class _HistorianScreenState extends State<HistorianScreen> {
  final AIService _aiService = AIService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;

  final List<String> _suggestedTopics = const [
    '¿Por qué marcharon a Balboa?',
    'Acuerdo Chiari-Kennedy',
    'Los Mártires de 1964',
    'El desgarro de la bandera',
  ];

  @override
  void initState() {
    super.initState();
    _messages = List.from(_aiService.messages);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _controller.clear();
    setState(() {
      _isLoading = true;
    });

    await _aiService.askHistorian(text);

    if (mounted) {
      setState(() {
        _messages = List.from(_aiService.messages);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 84,
        leading: const AppLogoLeading(showBackButton: true),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historiador IA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'Basado exclusivamente en documentos oficiales',
              style: TextStyle(fontSize: 11, color: AppColors.logoNavy, fontWeight: FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Fuentes documentales activas',
            onPressed: _showDocumentSourcesDialog,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner informativo sobre la fuente exclusiva de información
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.sandAccent.withValues(alpha: 0.5),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, size: 16, color: Color(0xFF7C2D12)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Asistente documental: responde únicamente con libros y textos del proyecto.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7C2D12), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages View
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Consultando libros y documentos de Panamá Histórica...',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

          // Suggested quick topic chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _suggestedTopics
                  .map((chip) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          backgroundColor: Colors.white,
                          surfaceTintColor: AppColors.primaryTeal,
                          side: const BorderSide(color: AppColors.borderGrey),
                          label: Text(chip, style: const TextStyle(fontSize: 12)),
                          onPressed: () => _sendMessage(chip),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Message Input Field Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border(top: BorderSide(color: AppColors.borderGrey)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessage,
                    decoration: const InputDecoration(
                      hintText: 'Pregunta sobre los documentos históricos...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  void _showDocumentSourcesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.menu_book, color: AppColors.primaryTeal),
            SizedBox(width: 8),
            Text('Documentos Oficiales', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El Historiador IA responde a los estudiantes basándose exclusivamente en:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              '1. «El 9 de enero de 1964: lo que no me contaron»',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
            ),
            Text(
              '   Segunda edición ampliada (2023) por Wendy Tribaldos.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            SizedBox(height: 8),
            Text(
              '2. Materiales y escenas históricas curriculares',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
            ),
            Text(
              '   Documentos del Módulo Panamá Contemporánea.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.patrioticBlue, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Historiador IA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Estudiante',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.patrioticRed,
                    child: Icon(Icons.person, color: Colors.white, size: 14),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryTeal : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(20).copyWith(
                  topLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  topRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: isUser ? null : Border.all(color: AppColors.borderGrey),
                boxShadow: [
                  if (!isUser)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.cardTitle != null) ...[
                    Text(
                      msg.cardTitle!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                        fontFamily: 'Serif',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    msg.message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  if (msg.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: msg.imageUrl!.startsWith('assets/')
                          ? Image.asset(
                              msg.imageUrl!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              msg.imageUrl!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ],
                  if (msg.hasReferences) ...[
                    const SizedBox(height: 14),
                    _buildReferencesSection(msg.references!),
                  ],
                  if (msg.tags != null && msg.tags!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: msg.tags!
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.sandAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7C2D12),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.timestamp,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferencesSection(List<RAGReference> references) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 16, color: AppColors.primaryTeal),
              SizedBox(width: 6),
              Text(
                'Fuentes documentales consultadas:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...references.map((ref) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${ref.documentTitle} (Pág. ${ref.page})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 18, top: 2),
                      child: Text(
                        'Capítulo: ${ref.section}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ),
                    if (ref.excerpt.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 18, top: 2),
                        child: Text(
                          'Cita: «${ref.excerpt}»',
                          style: const TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
