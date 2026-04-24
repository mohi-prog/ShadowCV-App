import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shadowcv/services/translation_service.dart';
import 'package:shadowcv/services/gemini_analysis_service.dart';
import 'package:shadowcv/services/app_config.dart';

// Zustände der Simulation
enum _SimPhase { questioning, evaluating, evaluated, completed }

class InterviewSimulationScreen extends StatefulWidget {
  final Map<String, dynamic> prepResult;
  final String targetJob;
  final String? rawCvText; // optional – verbessert Evaluation

  const InterviewSimulationScreen({
    super.key,
    required this.prepResult,
    required this.targetJob,
    this.rawCvText,
  });

  @override
  State<InterviewSimulationScreen> createState() =>
      _InterviewSimulationScreenState();
}

class _InterviewSimulationScreenState extends State<InterviewSimulationScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────
  int _currentIndex = 0;
  _SimPhase _phase = _SimPhase.questioning;
  String _streamedEvaluation = '';
  bool _isStreaming = false;

  // Gespeicherte Ergebnisse: [{question, answer, evaluation, score}]
  final List<Map<String, dynamic>> _evaluations = [];

  // Summary Text (nach allen Fragen)
  String _summary = '';
  bool _isSummaryLoading = false;

  final TextEditingController _answerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Animations
  late AnimationController _entryAnim;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  late AnimationController _dotsAnim;

  // API Config (zentral in AppConfig)
  static const _apiKey = AppConfig.groqApiKey;
  static const _url = AppConfig.groqApiUrl;

  // ── Getter ─────────────────────────────────────────────────
  List<Map<String, dynamic>> get _questions {
    final raw = widget.prepResult['questions'] as List? ?? [];
    return raw.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic>? get _currentQuestion =>
      _currentIndex < _questions.length ? _questions[_currentIndex] : null;

  int get _totalQuestions => _questions.length;
  double get _progress =>
      _totalQuestions > 0 ? (_currentIndex + 1) / _totalQuestions : 0;

  // ── Init / Dispose ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut));
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut));
    _entryAnim.forward();

    _dotsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    _dotsAnim.dispose();
    _answerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'behavioral':
        return Colors.blueAccent;
      case 'technical':
        return Colors.greenAccent;
      case 'motivational':
        return Colors.deepPurpleAccent;
      case 'situational':
        return Colors.orangeAccent;
      default:
        return Colors.white54;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'behavioral':
        return Icons.psychology_rounded;
      case 'technical':
        return Icons.code_rounded;
      case 'motivational':
        return Icons.favorite_rounded;
      case 'situational':
        return Icons.lightbulb_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  // Score aus dem Evaluation-Text extrahieren (sucht "Score: X/10")
  int _extractScore(String evaluation) {
    final match = RegExp(r'(\d+)\s*/\s*10').firstMatch(evaluation);
    if (match != null) {
      return (int.tryParse(match.group(1) ?? '0') ?? 0).clamp(0, 10);
    }
    return 5; // Fallback
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return const Color(0xFF4ADE80);
    if (score >= 5) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  // ── Core Logic ─────────────────────────────────────────────

  /// Schickt die Antwort des Users und streamt die KI-Bewertung
  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty || _isStreaming) return;

    final question = _currentQuestion;
    if (question == null) return;

    setState(() {
      _phase = _SimPhase.evaluating;
      _streamedEvaluation = '';
      _isStreaming = true;
    });
    _scrollToBottom();

    final lang = AppTranslation.currentLang;
    final category = question['category'] ?? 'General';
    final questionText = question['question'] ?? '';
    final exampleAnswer = question['exampleAnswer'] ?? '';
    final cvContext = widget.rawCvText != null
        ? 'CV Context:\n${widget.rawCvText!.substring(0, widget.rawCvText!.length.clamp(0, 3000))}'
        : 'No CV provided.';

    // Evaluation Prompt – strukturiert aber als Fließtext
    final prompt =
        '''
You are an expert interview coach evaluating a candidate's response.

=== INTERVIEW CONTEXT ===
Job: "${widget.targetJob}"
Question Type: $category
Question: "$questionText"

=== CANDIDATE'S ANSWER ===
"$answer"

=== REFERENCE ANSWER (for comparison only) ===
$exampleAnswer

=== $cvContext ===

=== YOUR TASK ===
Evaluate the candidate's answer honestly. Be constructive but direct.

Write your evaluation in $lang using EXACTLY this structure:

**Score: X/10**

**✅ What worked well**
Write 2-3 specific things the candidate did right in their answer.

**⚠️ What was missing**
Write 2-3 concrete things that would have made this answer stronger.

**💡 Ideal answer would include**
Give 2-3 specific points or phrases they should have mentioned, based on the question and job.

**🎯 One-line coaching tip**
One actionable sentence they can apply immediately.

Keep the total evaluation under 250 words. Be specific, never generic.
''';

    try {
      final request = http.Request('POST', Uri.parse(_url));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      });
      request.body = jsonEncode({
        'model': AppConfig.groqModelFast,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.4,
        'max_tokens': 600,
        'stream': true,
      });

      final client = http.Client();
      try {
        final streamed = await client
            .send(request)
            .timeout(const Duration(seconds: 45));

        if (streamed.statusCode != 200) {
          throw Exception('API Error: ${streamed.statusCode}');
        }

        final stream = streamed.stream
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
                setState(() => _streamedEvaluation += delta);
                _scrollToBottom();
              }
            } catch (_) {}
          }
        }
      } finally {
        client.close();
      }

      // Evaluation speichern
      final score = _extractScore(_streamedEvaluation);
      _evaluations.add({
        'question': questionText,
        'category': category,
        'answer': answer,
        'evaluation': _streamedEvaluation,
        'score': score,
      });

      if (mounted) {
        setState(() {
          _phase = _SimPhase.evaluated;
          _isStreaming = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _streamedEvaluation =
              '❌ ${e.toString().replaceAll('Exception: ', '')}';
          _phase = _SimPhase.evaluated;
          _isStreaming = false;
        });
      }
    }
  }

  /// Zur nächsten Frage weitergehen oder Simulation abschließen
  Future<void> _nextQuestion() async {
    _answerController.clear();

    if (_currentIndex + 1 >= _totalQuestions) {
      // Alle Fragen durch → Summary laden
      setState(() {
        _phase = _SimPhase.completed;
        _isSummaryLoading = true;
      });
      await _loadSummary();
    } else {
      setState(() {
        _currentIndex++;
        _phase = _SimPhase.questioning;
        _streamedEvaluation = '';
      });
      // Sanfte Übergangs-Animation
      _entryAnim.reset();
      _entryAnim.forward();
    }
  }

  /// Gesamt-Feedback nach allen Fragen
  Future<void> _loadSummary() async {
    try {
      final summary = await GeminiAnalysisService.generateInterviewSummary(
        evaluations: _evaluations,
        targetJob: widget.targetJob,
        language: AppTranslation.currentLang,
      );
      if (mounted) {
        setState(() {
          _summary = summary;
          _isSummaryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summary = '${AppTranslation.t('Could not load summary')}: $e';
          _isSummaryLoading = false;
        });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Hintergrund-Gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.2,
                colors: [
                  Colors.deepPurpleAccent.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                if (_phase != _SimPhase.completed) _buildProgressBar(),
                Expanded(
                  child: _phase == _SimPhase.completed
                      ? _buildCompletedView()
                      : _buildSimulationView(),
                ),
                if (_phase != _SimPhase.completed) _buildBottomInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showExitDialog(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslation.t('Interview Simulation'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Boldo',
                  ),
                ),
                Text(
                  widget.targetJob,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontFamily: 'Boldo',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Fragen-Zähler
          if (_phase != _SimPhase.completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.deepPurpleAccent.withOpacity(0.3),
                ),
              ),
              child: Text(
                '${_currentIndex + 1} / $_totalQuestions',
                style: const TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Progress Bar ───────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.deepPurpleAccent,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Simulation View (Fragen + Evaluation) ─────────────────
  Widget _buildSimulationView() {
    final question = _currentQuestion;
    if (question == null) return const SizedBox();

    final category = question['category'] ?? 'General';
    final questionText = question['question'] ?? '';
    final whyAsked = question['whyAsked'] ?? '';
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          children: [
            // Fragen-Card
            _buildQuestionCard(category, questionText, whyAsked, color, icon),
            const SizedBox(height: 20),

            // User-Antwort (nach Submit sichtbar)
            if (_phase == _SimPhase.evaluating ||
                _phase == _SimPhase.evaluated) ...[
              _buildAnswerBubble(
                _answerController.text.isNotEmpty
                    ? _answerController.text
                    : _evaluations.isNotEmpty
                    ? _evaluations.last['answer'] ?? ''
                    : '',
              ),
              const SizedBox(height: 16),
            ],

            // Streaming Evaluation oder finales Ergebnis
            if (_phase == _SimPhase.evaluating) ...[
              _buildEvaluationCard(_streamedEvaluation, isStreaming: true),
              const SizedBox(height: 80),
            ],
            if (_phase == _SimPhase.evaluated && _evaluations.isNotEmpty) ...[
              _buildEvaluationCard(
                _evaluations.last['evaluation'] ?? '',
                score: _evaluations.last['score'],
                isStreaming: false,
              ),
              const SizedBox(height: 20),
              _buildNextButton(),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    String category,
    String questionText,
    String whyAsked,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.12), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                AppTranslation.t(category).toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              // Interviewer Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white54,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppTranslation.t('Interviewer'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontFamily: 'Boldo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Frage
          Text(
            questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: 'Boldo',
              height: 1.5,
            ),
          ),

          // Why Asked (als Hint)
          if (whyAsked.isNotEmpty && _phase == _SimPhase.questioning) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white38,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      whyAsked,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontFamily: 'Boldo',
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// User-Antwort als Chat-Bubble rechts
  Widget _buildAnswerBubble(String answer) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Text(
          answer,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Boldo',
            height: 1.5,
          ),
        ),
      ),
    );
  }

  /// Evaluation Card mit optionalem Score-Badge
  Widget _buildEvaluationCard(
    String evaluation, {
    int? score,
    bool isStreaming = false,
  }) {
    final scoreColor = score != null ? _getScoreColor(score) : Colors.white54;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: score != null
              ? scoreColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.deepPurpleAccent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppTranslation.t('AI Feedback').toUpperCase(),
                style: const TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              // Score Badge
              if (score != null && !isStreaming)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scoreColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$score / 10',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Boldo',
                    ),
                  ),
                ),
              // Streaming Indicator
              if (isStreaming)
                AnimatedBuilder(
                  animation: _dotsAnim,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final phase = (_dotsAnim.value + (i * 0.33)) % 1.0;
                        final opacity = 0.3 + (0.7 * _pulseFn(phase));
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent.withOpacity(opacity),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 14),

          // Evaluation Text mit Formatting
          _buildFormattedEvaluation(evaluation.isEmpty ? '▍' : evaluation),
        ],
      ),
    );
  }

  /// Markdown-ähnliches Rendering für **bold** und Bullet-Points
  Widget _buildFormattedEvaluation(String text) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        // Bold Header (beginnt mit **)
        if (line.startsWith('**') && line.endsWith('**')) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              line.replaceAll('**', ''),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'Boldo',
              ),
            ),
          );
        }
        // Inline Bold
        if (line.contains('**')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _buildRichLine(line),
          );
        }
        // Bullet Point
        if (line.startsWith('•') || line.startsWith('-')) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line.replaceFirst(RegExp(r'^[•\-]\s*'), ''),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontFamily: 'Boldo',
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        // Normaler Text
        if (line.trim().isEmpty) return const SizedBox(height: 4);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontFamily: 'Boldo',
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRichLine(String line) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: line.substring(lastEnd, match.start),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontFamily: 'Boldo',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Boldo',
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < line.length) {
      spans.add(
        TextSpan(
          text: line.substring(lastEnd),
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'Boldo',
            fontSize: 13,
            height: 1.5,
          ),
        ),
      );
    }
    return RichText(text: TextSpan(children: spans));
  }

  double _pulseFn(double t) => t < 0.5 ? t * 2 : (1.0 - t) * 2;

  Widget _buildNextButton() {
    final isLast = _currentIndex + 1 >= _totalQuestions;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _nextQuestion,
        icon: Icon(
          isLast ? Icons.bar_chart_rounded : Icons.arrow_forward_rounded,
          size: 20,
        ),
        label: Text(
          isLast
              ? AppTranslation.t('See Results')
              : AppTranslation.t('Next Question'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'Boldo',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ── Bottom Input ───────────────────────────────────────────
  Widget _buildBottomInput() {
    // Input nur in der Frage-Phase zeigen
    if (_phase != _SimPhase.questioning) return const SizedBox();

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hint Text
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.mic_rounded,
                  color: Colors.deepPurpleAccent,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  AppTranslation.t('Type your answer as you would say it'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                    fontFamily: 'Boldo',
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _answerController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Boldo',
                    fontSize: 14,
                  ),
                  maxLines: 5,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: AppTranslation.t('Your answer...'),
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontFamily: 'Boldo',
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.deepPurpleAccent.withOpacity(0.4),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Submit Button
              GestureDetector(
                onTap: _submitAnswer,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Completed View ─────────────────────────────────────────
  Widget _buildCompletedView() {
    // Durchschnittsscore berechnen
    final avgScore = _evaluations.isEmpty
        ? 0.0
        : _evaluations
                  .map((e) => (e['score'] as int?) ?? 0)
                  .reduce((a, b) => a + b) /
              _evaluations.length;

    final scoreColor = _getScoreColor(avgScore.round());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scoreColor.withOpacity(0.15), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: scoreColor.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: 44,
                ),
                const SizedBox(height: 16),
                Text(
                  AppTranslation.t('Simulation Complete!'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Boldo',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.targetJob,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    fontFamily: 'Boldo',
                  ),
                ),
                const SizedBox(height: 20),
                // Avg Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scoreColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        avgScore.toStringAsFixed(1),
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Boldo',
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        ' / 10',
                        style: TextStyle(
                          color: scoreColor.withOpacity(0.5),
                          fontSize: 18,
                          fontFamily: 'Boldo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppTranslation.t('Average Score'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                    fontFamily: 'Boldo',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Per-Question Scores
          _buildSectionLabel(
            AppTranslation.t('Question Scores'),
            Icons.bar_chart_rounded,
            Colors.white54,
          ),
          const SizedBox(height: 12),
          ..._evaluations.asMap().entries.map((e) {
            final i = e.key;
            final eval = e.value;
            final s = (eval['score'] as int?) ?? 0;
            final c = _getScoreColor(s);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Boldo',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      eval['question'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'Boldo',
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$s/10',
                      style: TextStyle(
                        color: c,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Boldo',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // AI Summary
          _buildSectionLabel(
            AppTranslation.t('Overall Feedback'),
            Icons.psychology_rounded,
            Colors.deepPurpleAccent,
          ),
          const SizedBox(height: 12),

          _isSummaryLoading
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurpleAccent,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.deepPurpleAccent.withOpacity(0.15),
                    ),
                  ),
                  child: _buildFormattedEvaluation(_summary),
                ),

          const SizedBox(height: 24),

          // Nochmal Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.replay_rounded, size: 20),
              label: Text(
                AppTranslation.t('Back to Questions'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Boldo',
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontFamily: 'Boldo',
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ── Exit Dialog ────────────────────────────────────────────
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppTranslation.t('Exit Simulation?'),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Boldo',
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          AppTranslation.t('Your progress will be lost if you exit now.'),
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontFamily: 'Boldo',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslation.t('Continue'),
              style: const TextStyle(
                color: Colors.deepPurpleAccent,
                fontFamily: 'Boldo',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog schließen
              Navigator.pop(context); // Screen schließen
            },
            child: Text(
              AppTranslation.t('Exit'),
              style: const TextStyle(
                color: Colors.redAccent,
                fontFamily: 'Boldo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
