import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shadowcv/services/translation_service.dart';
import 'package:shadowcv/services/gemini_analysis_service.dart';
import 'package:shadowcv/services/app_config.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:vibration/vibration.dart';
import 'package:shadowcv/widgets/aurora_background.dart';

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

  // Voice Interaction
  bool _isListening = false;
  bool _isLiveSession = false; 
  double _soundLevel = 0.0;
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  Timer? _silenceTimer;

  // Silence Nudges
  final List<String> _silenceNudgesDe = [
    "Ich höre noch zu. Lassen Sie sich ruhig Zeit.",
    "Alles in Ordnung? Wir können fortfahren, wenn Sie bereit sind.",
    "Haben Sie meine Frage verstanden oder soll ich sie wiederholen?",
    "Keine Eile, ich bin gespannt auf Ihre Antwort.",
  ];
  final List<String> _silenceNudgesEn = [
    "I'm still listening. Take your time.",
    "Everything okay? We can continue when you're ready.",
    "Did you catch the question, or should I repeat it?",
    "No rush, I'm interested in your answer.",
  ];
  final List<String> _silenceNudgesEs = [
    "Sigo escuchando. Tómate tu tiempo.",
    "¿Todo bien? Podemos continuar cuando estés listo.",
    "¿Entendiste la pregunta o quieres que la repita?",
    "Sin prisas, me interesa tu respuesta.",
  ];

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
  late AnimationController _pulseAnim;

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
    _initVoice();

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

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _initVoice() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        print('STT Error: $error');
        if (_isLiveSession) {
          setState(() => _isListening = false);
        }
      },
      onStatus: (status) => print('STT Status: $status'),
    );
    
    // TTS Config
    String ttsLang = 'en-US';
    if (AppTranslation.currentLang == 'Deutsch') ttsLang = 'de-DE';
    if (AppTranslation.currentLang == 'Español') ttsLang = 'es-ES';

    await _flutterTts.setLanguage(ttsLang);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    // Live-Session Handler: Wenn die KI fertig gesprochen hat, automatisch zuhören
    _flutterTts.setCompletionHandler(() {
      if (_isLiveSession && _phase == _SimPhase.questioning && mounted) {
        _startListening();
      }
    });

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    _dotsAnim.dispose();
    _pulseAnim.dispose();
    _answerController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  // ── Voice Logic ─────────────────────────────────────────────

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    if (!_isListening) return;

    _silenceTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isListening && _lastWords.trim().isEmpty) {
        _handleSilence();
      }
    });
  }

  Future<void> _handleSilence() async {
    if (!_isListening) return;
    
    // Stop listening to speak nudge
    await _speechToText.stop();
    if (mounted) setState(() => _isListening = false);

    // Pick a nudge based on language
    String nudge = '';
    final lang = AppTranslation.currentLang;
    final random = DateTime.now().millisecond % 4;

    if (lang == 'Deutsch') {
      nudge = _silenceNudgesDe[random];
    } else if (lang == 'Español') {
      nudge = _silenceNudgesEs[random];
    } else {
      nudge = _silenceNudgesEn[random];
    }

    await _speak(nudge);

    // Wait for nudge to finish (approximate)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _phase == _SimPhase.questioning && _isLiveSession) {
        _startListening();
      }
    });
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
    }
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> _speakQuestion() async {
    final q = _currentQuestion;
    if (q == null) return;
    
    String textToSpeak = '';
    if (_currentIndex == 0 && widget.prepResult['interviewerIntro'] != null) {
      textToSpeak += '${widget.prepResult['interviewerIntro']}. ';
    }
    
    if (q['interviewerHook'] != null && q['interviewerHook'].toString().isNotEmpty) {
      textToSpeak += '${q['interviewerHook']}. ';
    }
    
    textToSpeak += q['question'] ?? '';
    
    await _speak(textToSpeak);
  }

  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslation.t('Speech recognition not available'))),
      );
      return;
    }
    
    await _flutterTts.stop(); // Stop speaking before listening
    
    if (mounted) {
      setState(() {
        _isListening = true;
        _lastWords = '';
        _soundLevel = 0.0;
      });
    }

    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 40);
      }
    } catch (_) {}

    String sttLocale = 'en_US';
    if (AppTranslation.currentLang == 'Deutsch') sttLocale = 'de_DE';
    if (AppTranslation.currentLang == 'Español') sttLocale = 'es_ES';

    await _speechToText.listen(
      onResult: _onSpeechResult,
      onSoundLevelChange: (level) {
        if (mounted && _isListening) setState(() => _soundLevel = level);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 10), 
      partialResults: true,
      localeId: sttLocale,
    );

    _resetSilenceTimer();
  }

  void _stopListening() async {
    if (!_isListening) return;
    _silenceTimer?.cancel();
    await _speechToText.stop();
    setState(() => _isListening = false);
    
    // Kleiner Delay um sicherzugehen dass onSpeechResult fertig ist
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_lastWords.isNotEmpty && !_isStreaming && _phase == _SimPhase.questioning) {
        _answerController.text = _lastWords;
        _submitAnswer();
      }
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (mounted) {
      setState(() {
        _lastWords = result.recognizedWords;
      });
      _resetSilenceTimer();
    }

    // Automatischer Submit wenn finalResult da ist und wir im Live-Modus sind
    if (result.finalResult && _isLiveSession && !_isStreaming && _phase == _SimPhase.questioning) {
      if (_lastWords.trim().length > 1) {
        _silenceTimer?.cancel();
        if (mounted) setState(() => _isListening = false);
        _answerController.text = _lastWords;
        _submitAnswer();
      }
    }
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
    final persona = question['persona'] ?? 'Professional';
    final theme = question['theme'] ?? 'General';
    
    final cvContext = widget.rawCvText != null
        ? 'CV Context:\n${widget.rawCvText!.substring(0, widget.rawCvText!.length.clamp(0, 3000))}'
        : 'No CV provided.';

    // Evaluation Prompt – Conversational & Persona-based
    final prompt =
        '''
You are acting as an interviewer with a "$persona" persona. 
You just asked a candidate a question about "$theme" for the role of "${widget.targetJob}".

=== THE QUESTION YOU ASKED ===
"$questionText"

=== CANDIDATE'S ANSWER ===
"$answer"

=== REFERENCE ANSWER (for your knowledge) ===
$exampleAnswer

=== $cvContext ===

=== YOUR TASK ===
1. React to the answer naturally as an interviewer would (in $lang).
2. Provide a score and constructive feedback.

CRITICAL: Your reaction MUST be conversational and bridge to the next point. Use your persona ($persona).
Example for Friendly: "I love how you handled that team conflict. It shows real maturity."
Example for Tough: "That's a standard answer. I was looking for more technical depth regarding..."

IMPORTANT: Use the EXACT English headers provided below, but write the CONTENT in $lang.

**Score: X/10**

**Interviewer's Reaction**
Write 2-3 sentences.

**Strengths**
2-3 bullet points.

**Improvements**
2-3 bullet points.

**Pro Coaching Tip**
One powerful, actionable tip.

Keep the total response under 250 words.
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
        
        // Voice Mode: Reaction vorlesen
        String reaction = '';
        final reactionRegex = RegExp(r"\*\*Interviewer's Reaction\*\*\n?(.*?)(?=\n\n\*\*|\n\nStrengths|$)", dotAll: true);
        final reactionMatch = reactionRegex.firstMatch(_streamedEvaluation);
        if (reactionMatch != null) {
          reaction = reactionMatch.group(1)?.trim() ?? '';
        } else {
           reaction = _streamedEvaluation.split('**').firstWhere((l) => l.trim().length > 10 && !l.contains('Score'), orElse: () => '');
        }

        if (_isLiveSession) {
          // Im Live Modus: Reaction sprechen und DIREKT weiter
          if (_currentIndex + 1 < _totalQuestions) {
             final nextQ = _questions[_currentIndex + 1];
             final hook = nextQ['interviewerHook'] ?? '';
             final qText = nextQ['question'] ?? '';
             
             // Wir sprechen Reaction + Hook + Frage in einem Rutsch
             final fullSpeech = "$reaction. $hook. $qText";
             
             await _speak(fullSpeech);
             
             // Wir updaten den Index und den State leise im Hintergrund
             Future.delayed(const Duration(milliseconds: 800), () {
               if (mounted) {
                 setState(() {
                    _currentIndex++;
                    _phase = _SimPhase.questioning;
                    _streamedEvaluation = '';
                    _answerController.clear();
                    _lastWords = '';
                 });
                 // Animation für den Fall dass man gerade doch auf den Chat schaut
                 _entryAnim.reset();
                 _entryAnim.forward();
               }
             });
          } else {
             await _speak("$reaction. ${AppTranslation.t('We have reached the end of the interview. Thank you for your time.')}");
             Future.delayed(const Duration(seconds: 2), () {
               if (mounted) _nextQuestion();
             });
          }
        }
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
    _lastWords = '';

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
      
      if (_isLiveSession) {
        _speakQuestion();
      }
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
    AuroraMode currentMode = AuroraMode.home;
    if (_isStreaming) {
      currentMode = AuroraMode.analyzing;
    } else if (_phase == _SimPhase.completed && _evaluations.isNotEmpty) {
       final avg = _evaluations.map((e) => (e['score'] as int?) ?? 0).reduce((a, b) => a + b) / _evaluations.length;
       currentMode = AuroraBackground.fromScore((avg * 10).round());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: AuroraBackground(
        mode: currentMode,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  if (!_isLiveSession && _phase != _SimPhase.completed) _buildProgressBar(),
                  Expanded(
                    child: _phase == _SimPhase.completed
                        ? _buildCompletedView()
                        : _isLiveSession 
                          ? _buildLiveView()
                          : _buildSimulationView(),
                  ),
                  if (!_isLiveSession && _phase != _SimPhase.completed) _buildBottomInput(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
     return const SizedBox.shrink();
  }

  Color _getPersonaColor(String persona) {
    final p = persona.toLowerCase();
    if (p.contains('friendly') || p.contains('casual')) return Colors.green;
    if (p.contains('tough') || p.contains('stress') || p.contains('challenging')) return Colors.orangeAccent;
    if (p.contains('technical')) return Colors.cyanAccent;
    return Colors.blueAccent; // Default Professional
  }

  // ── Live View (ChatGPT Style) ──────────────────────────────
  Widget _buildLiveView() {
    final persona = _currentQuestion?['persona'] ?? 'Professional';
    final personaColor = _getPersonaColor(persona);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Die zentrale Animation (Aura/Wave)
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Äußere pulsierende Ringe
              ...List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    double val = (_pulseAnim.value + (i * 0.33)) % 1.0;
                    // Reagiert auf Lautstärke:
                    double volumeBoost = _isListening ? (_soundLevel.abs() * 0.05) : 0;
                    double scale = (1.0 + (val * 1.8)) + volumeBoost;
                    double opacity = (1.0 - val) * 0.25;
                    
                    if (_isStreaming) opacity *= 0.4;
                    
                    return Container(
                      width: 130 * scale,
                      height: 130 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: personaColor.withOpacity(opacity),
                          width: 1.5 + volumeBoost * 2,
                        ),
                      ),
                    );
                  },
                );
              }),
              
              // Der Kern
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  double volumeEffect = _isListening ? (_soundLevel.abs() * 0.8) : 0;
                  return Container(
                    width: 120 + volumeEffect,
                    height: 120 + volumeEffect,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _isListening ? personaColor : personaColor.withOpacity(0.5),
                          personaColor.withOpacity(0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: personaColor.withOpacity(_isListening ? 0.6 : 0.2),
                          blurRadius: 40 + volumeEffect,
                          spreadRadius: 10 + volumeEffect / 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isStreaming ? Icons.auto_awesome : (_isListening ? Icons.mic_rounded : Icons.graphic_eq_rounded),
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const Spacer(),
        
        // Status Text (dezent unten)
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              Text(
                _isStreaming 
                  ? AppTranslation.t('Thinking...') 
                  : (_isListening ? AppTranslation.t('Listening...') : AppTranslation.t('Interviewer Speaking')),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              if (_isListening && _lastWords.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _lastWords,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 12,
                      fontFamily: 'Boldo',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
          
          // Live Toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _isLiveSession = !_isLiveSession;
                if (_isLiveSession) {
                  _speakQuestion();
                } else {
                  _flutterTts.stop();
                  _speechToText.stop();
                  _isListening = false;
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isLiveSession 
                  ? Colors.redAccent.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isLiveSession 
                    ? Colors.redAccent.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isLiveSession ? Icons.sensors_rounded : Icons.keyboard_rounded,
                    color: _isLiveSession ? Colors.redAccent : Colors.white60,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isLiveSession ? 'LIVE' : 'CHAT',
                    style: TextStyle(
                      color: _isLiveSession ? Colors.redAccent : Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Boldo',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Fragen-Zähler
          if (_phase != _SimPhase.completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.deepPurpleAccent.withOpacity(0.3),
                ),
              ),
              child: Text(
                '${_currentIndex + 1}/${_totalQuestions}',
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
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
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
    final hook = question['interviewerHook'] ?? '';
    final theme = question['theme'] ?? '';
    final persona = question['persona'] ?? 'Professional';
    
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);

    final intro = widget.prepResult['interviewerIntro'] as String?;

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          children: [
            // Intro message (only on first question)
            if (_currentIndex == 0 && intro != null && intro.isNotEmpty) ...[
              _buildInterviewerSpeechBubble(intro),
              const SizedBox(height: 24),
            ],

            // Theme Label
            if (theme.isNotEmpty)
               Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Row(
                  children: [
                    Icon(Icons.label_important_outline_rounded, color: Colors.white38, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      theme.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Boldo',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            // Fragen-Card
            _buildQuestionCard(category, questionText, whyAsked, hook, color, icon, persona),
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

  Widget _buildInterviewerSpeechBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.record_voice_over_rounded, color: Colors.deepPurpleAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  AppTranslation.t('Interviewer').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Boldo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Boldo',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    String category,
    String questionText,
    String whyAsked,
    String hook,
    Color color,
    IconData icon,
    String persona,
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
              // Persona Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  persona,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontFamily: 'Boldo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Hook
          if (hook.isNotEmpty) ...[
            Text(
              hook,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontFamily: 'Boldo',
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Frage
          Text(
            questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
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
        final trimmedLine = line.trim();
        // Bold Header (z.B. **Header** oder **Header:**)
        if (trimmedLine.startsWith('**') && trimmedLine.contains('**', 2)) {
          // Wenn die Zeile fast nur aus dem Header besteht (z.B. **Strengths**)
          // Wir prüfen ob nach dem schließenden ** noch viel Text kommt
          final lastBoldIndex = trimmedLine.lastIndexOf('**');
          if (lastBoldIndex != -1 && (trimmedLine.length - lastBoldIndex) < 5) {
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                trimmedLine.replaceAll('**', '').replaceAll(':', ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                ),
              ),
            );
          }
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
                  Icons.keyboard_rounded,
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
