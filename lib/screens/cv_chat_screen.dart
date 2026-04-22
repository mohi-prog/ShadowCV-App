import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shadowcv/services/translation_service.dart';
import 'package:shadowcv/services/gemini_analysis_service.dart';

class CVChatScreen extends StatefulWidget {
  final String rawText;
  final Map<String, dynamic> analysisResult;

  const CVChatScreen({
    super.key,
    required this.rawText,
    required this.analysisResult,
  });

  @override
  State<CVChatScreen> createState() => _CVChatScreenState();
}

class _CVChatScreenState extends State<CVChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  late AnimationController _slideAnimController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Typing dots animation
  late AnimationController _dotsAnimController;

  List<String> get _suggestions {
    final mode = widget.analysisResult['mode'] ?? 'generalReview';
    if (mode == 'atsOptimization') {
      return [
        AppTranslation.t('Which keywords am I missing?'),
        AppTranslation.t('How do I fix ATS formatting?'),
        AppTranslation.t('What section titles should I use?'),
      ];
    } else if (mode == 'jobSpecific') {
      return [
        AppTranslation.t('How do I tailor my experience better?'),
        AppTranslation.t('What skills should I highlight?'),
        AppTranslation.t('How do I rewrite my summary for this job?'),
      ];
    } else if (mode == 'customPrompt') {
      return [
        AppTranslation.t('Can you explain this in more detail?'),
        AppTranslation.t('What else should I change?'),
        AppTranslation.t('Give me a rewritten example'),
      ];
    }
    return [
      AppTranslation.t('What is my biggest weakness?'),
      AppTranslation.t('How can I improve my summary?'),
      AppTranslation.t('What should I fix first?'),
    ];
  }

  @override
  void initState() {
    super.initState();

    // Slide-in Animation
    _slideAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideAnimController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideAnimController, curve: Curves.easeIn),
    );
    _slideAnimController.forward();

    // Dots Animation (looping)
    _dotsAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Begrüßung
    _messages.add({
      'role': 'assistant',
      'content': AppTranslation.t(
          'Hi! I have analyzed your CV. Ask me anything about it!'),
    });
  }

  @override
  void dispose() {
    _slideAnimController.dispose();
    _dotsAnimController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _buildSystemPrompt() {
    final lang = AppTranslation.currentLang;
    final mode = widget.analysisResult['mode'] ?? 'generalReview';
    final score = widget.analysisResult['score'] ?? 0;
    final strengths = widget.analysisResult['strengths'] ?? [];
    final weaknesses = widget.analysisResult['weaknesses'] ?? [];
    final priorities = widget.analysisResult['topPriorities'] ?? [];

    return '''
You are an expert CV consultant with deep knowledge of hiring, ATS systems, and career development.

=== CV CONTEXT ===
The user has uploaded their CV. Here is the full text:
---
${widget.rawText}
---

=== ANALYSIS ALREADY DONE ===
- Overall Score: $score/100
- Analysis Mode: $mode
- Key Strengths: ${strengths.join(', ')}
- Key Weaknesses: ${weaknesses.join(', ')}
- Top Priorities: ${priorities.join(', ')}

=== YOUR ROLE ===
- Answer questions specifically about THIS CV and THIS analysis
- Be concrete and reference actual content from the CV
- Give actionable, specific advice – never vague
- If the user asks for rewrites, provide actual example text
- Be encouraging but honest
- Keep responses concise (max 4-5 sentences unless asked for more)
- Use formatting: bold with ** for key points, bullet points with • for lists
- ALWAYS respond in $lang
''';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final trimmed = text.trim();
    _messageController.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': trimmed});
      _isLoading = true;
      _messages.add({'role': 'assistant', 'content': ''});
    });
    _scrollToBottom();

    try {
      // Konversation ohne Begrüßung und ohne leere letzte Nachricht
      final conversationMessages = _messages
          .sublist(1, _messages.length - 1) // Skip welcome + empty last
          .map((m) => {'role': m['role']!, 'content': m['content']!})
          .toList();

      final request = http.Request(
          'POST', Uri.parse('https://api.groq.com/openai/v1/chat/completions'));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer REDACTED_GROQ_KEY',
      });
      request.body = jsonEncode({
        'model': 'llama-3.1-8b-instant',
        'messages': [
          {'role': 'system', 'content': _buildSystemPrompt()},
          ...conversationMessages,
        ],
        'temperature': 0.5,
        'max_tokens': 800,
        'stream': true,
      });

      final client = http.Client();
      try {
        final streamedResponse = await client
            .send(request)
            .timeout(const Duration(seconds: 45), onTimeout: () {
          throw Exception('Connection timed out. Please try again.');
        });

        if (streamedResponse.statusCode != 200) {
          throw Exception('Error: ${streamedResponse.statusCode}');
        }

        final stream = streamedResponse.stream
            .transform(const Utf8Decoder())
            .transform(const LineSplitter());

        await for (final line in stream) {
          if (!mounted) break;
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') break;

            try {
              final json = jsonDecode(data);
              final delta = json['choices']?[0]?['delta']?['content'];
              if (delta != null && delta is String && delta.isNotEmpty) {
                setState(() {
                  _messages[_messages.length - 1] = {
                    'role': 'assistant',
                    'content': (_messages.last['content'] ?? '') + delta,
                  };
                });
                _scrollToBottom();
              }
            } catch (_) {}
          }
        }
      } finally {
        client.close();
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[_messages.length - 1] = {
            'role': 'assistant',
            'content': '❌ ${e.toString().replaceAll('Exception: ', '')}',
          };
          _isLoading = false;
        });
      }
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length +
                      (_messages.length == 1 ? 1 : 0), // +1 for suggestions
                  itemBuilder: (context, index) {
                    // Suggestions nach Welcome
                    if (_messages.length == 1 && index == 1) {
                      return _buildSuggestions();
                    }

                    final msgIndex =
                        index > 1 && _messages.length == 1 ? index - 1 : index;
                    if (msgIndex >= _messages.length) return const SizedBox();

                    final msg = _messages[msgIndex];

                    // Welcome Message
                    if (msg['role'] == 'assistant' && msgIndex == 0) {
                      return _buildWelcomeMessage(msg['content']!);
                    }

                    return _buildMessageBubble(
                      msg['content']!,
                      isUser: msg['role'] == 'user',
                      isStreaming: _isLoading && msgIndex == _messages.length - 1,
                    );
                  },
                ),
              ),
              if (_isLoading && (_messages.last['content'] ?? '').isEmpty)
                _buildTypingIndicator(),
              _buildInputField(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // AI Avatar
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurpleAccent.withOpacity(0.2),
                      Colors.purpleAccent.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.deepPurpleAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslation.t('CV Assistant'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Boldo'),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isLoading
                              ? AppTranslation.t('Typing...')
                              : AppTranslation.t('Online'),
                          style: TextStyle(
                              color: _isLoading
                                  ? Colors.deepPurpleAccent
                                  : Colors.white.withOpacity(0.35),
                              fontSize: 12,
                              fontFamily: 'Boldo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Message Count
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_messages.where((m) => m['role'] == 'user').length} ${AppTranslation.t('msgs')}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                      fontFamily: 'Boldo'),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SUGGESTIONS ====================

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              AppTranslation.t('Quick questions:'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                  fontFamily: 'Boldo'),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              return GestureDetector(
                onTap: () => _sendMessage(s),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.deepPurpleAccent.withOpacity(0.2)),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontSize: 12,
                        fontFamily: 'Boldo',
                        fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== MESSAGES ====================

  Widget _buildWelcomeMessage(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurpleAccent.withOpacity(0.1),
                    Colors.deepPurpleAccent.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                    color: Colors.deepPurpleAccent.withOpacity(0.15)),
              ),
              child: Text(content,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Boldo',
                      height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content,
      {required bool isUser, bool isStreaming = false}) {
    // Streaming cursor
    final displayContent =
        (!isUser && content.isEmpty) ? '▍' : (isStreaming ? '$content▍' : content);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAIAvatar(),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.deepPurpleAccent
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 18 : 4),
                  topRight: Radius.circular(isUser ? 4 : 18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: _buildFormattedText(displayContent, isUser),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }

  /// Einfaches Text-Formatting: **bold** und • Bullets
  Widget _buildFormattedText(String text, bool isUser) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Text vor dem Bold
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      // Bold Text
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ));
      lastEnd = match.end;
    }
    // Rest
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
          fontSize: 14,
          fontFamily: 'Boldo',
          height: 1.5,
        ),
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }

  Widget _buildAIAvatar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.psychology_rounded,
          color: Colors.deepPurpleAccent, size: 16),
    );
  }

  // ==================== TYPING INDICATOR ====================

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          _buildAIAvatar(),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: AnimatedBuilder(
              animation: _dotsAnimController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    // Versetzte Phasen für jeden Dot
                    final phase = (_dotsAnimController.value + (i * 0.33)) % 1.0;
                    final scale = 0.5 + (0.5 * _pulse(phase));
                    final opacity = 0.3 + (0.7 * _pulse(phase));
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color:
                            Colors.deepPurpleAccent.withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                      transform: Matrix4.identity()
                        ..scale(scale, scale),
                      transformAlignment: Alignment.center,
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Smooth pulse curve
  double _pulse(double t) {
    if (t < 0.5) return t * 2;
    return (1.0 - t) * 2;
  }

  // ==================== INPUT ====================

  Widget _buildInputField() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border:
            Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(
                  color: Colors.white, fontFamily: 'Boldo', fontSize: 14),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _isLoading ? null : _sendMessage,
              decoration: InputDecoration(
                hintText: AppTranslation.t('Ask about your CV...'),
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontFamily: 'Boldo',
                    fontSize: 14),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                      color: Colors.deepPurpleAccent.withOpacity(0.4)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading
                ? null
                : () => _sendMessage(_messageController.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : const LinearGradient(colors: [
                        Colors.deepPurpleAccent,
                        Colors.purpleAccent
                      ]),
                color: _isLoading ? Colors.white.withOpacity(0.05) : null,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                color: _isLoading
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}