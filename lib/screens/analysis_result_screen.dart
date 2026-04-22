// analysis_result_screen.dart
// Änderungen:
// 1. initState: Score-Fallback für customPrompt (kein score-Key vorhanden)
// 2. _buildCVResult: branch zu _buildCustomPromptResult() bei customPrompt mode
// 3. NEU: _buildCustomPromptResult() – rendert customResponse, keyPoints, actionItems
// 4. NEU: _buildKeyPointItem() und _buildActionItem() Widgets

import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowcv/providers/premium_provider.dart';
import 'package:shadowcv/screens/cv_chat_screen.dart';
import 'package:shadowcv/screens/premium_screen.dart';
import 'package:shadowcv/screens/rewrite_result_screen.dart';
import 'package:shadowcv/services/gemini_analysis_service.dart';
import 'package:shadowcv/services/translation_service.dart';
import 'package:shadowcv/services/premium_service.dart';
import 'package:shadowcv/widgets/aurora_background.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> result;
  final String? rawText;

  const AnalysisResultScreen({super.key, required this.result, this.rawText});

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen>
    with TickerProviderStateMixin {
  bool _isRewriting = false;
  bool _isPremium = false;

  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnimation;
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();

    // FIX: customPrompt hat keinen 'score' Key → Fallback auf 0
    final mode = widget.result['mode'] ?? 'generalReview';
    final isCustomPrompt = mode == 'customPrompt';
    final targetScore = isCustomPrompt
        ? 0.0
        : ((widget.result['score'] ?? 0) as num).toDouble();

    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: targetScore).animate(
      CurvedAnimation(parent: _scoreAnimController, curve: Curves.easeOutCubic),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    // Score-Animation nur bei Standard-Modi starten
    if (!isCustomPrompt) _scoreAnimController.forward();
    _entryController.forward();
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ==================== HELPERS ====================

  Color _getScoreColor(double score) {
    if (score >= 75) return const Color(0xFF4ADE80);
    if (score >= 50) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  String _getModeBadgeText(String mode) {
    switch (mode) {
      case 'atsOptimization':
        return 'ATS OPTIMIZATION';
      case 'jobSpecific':
        return 'JOB-SPECIFIC';
      case 'customPrompt':
        return 'CUSTOM ANALYSIS';
      default:
        return 'GENERAL REVIEW';
    }
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'atsOptimization':
        return Icons.smart_toy_rounded;
      case 'jobSpecific':
        return Icons.work_rounded;
      case 'customPrompt':
        return Icons.edit_note_rounded;
      default:
        return Icons.assessment_rounded;
    }
  }

  String _getScoreSubtitle(String mode) {
    switch (mode) {
      case 'atsOptimization':
        return 'ATS Compatibility Score';
      case 'jobSpecific':
        return 'Role Fit Score';
      default:
        return 'CV Quality Score';
    }
  }

  String _getStrengthsTitle(String mode) {
    switch (mode) {
      case 'atsOptimization':
        return AppTranslation.t('ATS Passed');
      case 'jobSpecific':
        return AppTranslation.t('Matching Skills');
      default:
        return AppTranslation.t('Strengths');
    }
  }

  String _getWeaknessesTitle(String mode) {
    switch (mode) {
      case 'atsOptimization':
        return AppTranslation.t('ATS Errors & Red Flags');
      case 'jobSpecific':
        return AppTranslation.t('Missing Keywords');
      default:
        return AppTranslation.t('Weaknesses');
    }
  }

  String _getSuggestionsTitle(String mode) {
    switch (mode) {
      case 'atsOptimization':
        return AppTranslation.t('Formatting Fixes');
      case 'jobSpecific':
        return AppTranslation.t('Tailoring Advice');
      default:
        return AppTranslation.t('Detailed Suggestions');
    }
  }

  Future<void> _loadPremiumStatus() async {
    final premium = await PremiumService.isPremium();
    if (!mounted) return;
    setState(() => _isPremium = premium);
  }

  // ==================== REWRITE ====================

  Future<void> _startRewrite() async {
    final isPremium = await PremiumService.isPremium();
    if (!isPremium) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      return;
    }
    if (widget.rawText == null || widget.rawText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No CV text available.',
            style: TextStyle(fontFamily: 'Boldo'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isRewriting = true);

    try {
      String? userJob, userGoal, userLanguage;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          userJob = data['job'] ?? data['jobTitle'];
          userGoal = data['goal'];
          userLanguage = data['language'] ?? AppTranslation.currentLang;
        }
      }

      final rewritten = await GeminiAnalysisService.rewriteCV(
        widget.rawText!,
        analysisResult: widget.result,
        userJob: userJob,
        userGoal: userGoal,
        language: userLanguage,
      );

      if (!mounted) return;
      setState(() => _isRewriting = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RewriteResultScreen(
            originalText: widget.rawText!,
            rewrittenText: rewritten,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isRewriting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e',
                style: const TextStyle(fontFamily: 'Boldo')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final isCV = widget.result['isCV'] == true;
    final isPremium = _isPremium;
    final mode = widget.result['mode'] ?? 'generalReview';

    // Aurora-Farbe: customPrompt bekommt neutrale Home-Farbe (kein Score vorhanden)
    final int score =
        mode == 'customPrompt' ? 60 : (widget.result['score'] ?? 0) as int;
    final auroraMode =
        isCV ? AuroraBackground.fromScore(score) : AuroraMode.home;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppTranslation.t('Analysis Report'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontFamily: 'Boldo',
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: isCV && widget.rawText != null
          ? FloatingActionButton.extended(
              onPressed: () {
                if (!isPremium) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PremiumScreen()),
                  );
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CVChatScreen(
                    rawText: widget.rawText!,
                    analysisResult: widget.result,
                  ),
                );
              },
              backgroundColor: Colors.deepPurpleAccent,
              elevation: 8,
              icon: Icon(
                isPremium ? Icons.psychology_rounded : Icons.lock_rounded,
                color: Colors.white,
              ),
              label: Text(
                AppTranslation.t('Ask AI'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Boldo',
                ),
              ),
            )
          : null,
      body: AuroraBackground(
        mode: auroraMode,
        child: SafeArea(
          child: Stack(
            children: [
              FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
                      bottom: 120,
                    ),
                    child: isCV ? _buildCVResult() : _buildNotCVResult(),
                  ),
                ),
              ),
              if (_isRewriting) _buildRewriteOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== CV RESULT ROUTER ====================

  Widget _buildCVResult() {
    final String mode = widget.result['mode'] ?? 'generalReview';

    // customPrompt → eigenes Layout ohne Score-Ring
    if (mode == 'customPrompt') return _buildCustomPromptResult();

    // Standard-Modi
    return _buildStandardResult();
  }

  // ==================== STANDARD RESULT (generalReview, ats, jobSpecific) ====================

  Widget _buildStandardResult() {
    final int score = (widget.result['score'] ?? 0) as int;
    final String scoreLabel = widget.result['scoreLabel'] ?? 'Unknown';
    final String summary = widget.result['summary'] ?? '';
    final List strengths = widget.result['strengths'] ?? [];
    final List weaknesses = widget.result['weaknesses'] ?? [];
    final List priorities = widget.result['topPriorities'] ?? [];
    final List suggestions = widget.result['suggestions'] ?? [];
    final String mode = widget.result['mode'] ?? 'generalReview';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _buildModeBadge(mode)),
        const SizedBox(height: 24),
        _buildScoreRing(score, scoreLabel, mode),
        const SizedBox(height: 32),
        if (summary.isNotEmpty) ...[
          _buildSectionHeader(
            AppTranslation.t('Summary'),
            Icons.summarize_rounded,
            Colors.white54,
          ),
          _buildSummaryCard(summary),
          const SizedBox(height: 28),
        ],
        if (priorities.isNotEmpty) ...[
          _buildSectionHeader(
            AppTranslation.t('Top Priorities'),
            Icons.priority_high_rounded,
            Colors.redAccent,
          ),
          ...priorities.indexed.map(
              (e) => _buildPriorityItem(e.$2.toString(), e.$1 + 1)),
          const SizedBox(height: 28),
        ],
        if (strengths.isNotEmpty) ...[
          _buildSectionHeader(
            _getStrengthsTitle(mode),
            Icons.check_circle_rounded,
            const Color(0xFF4ADE80),
          ),
          _buildTagCloud(
            strengths.map((e) => e.toString()).toList(),
            const Color(0xFF4ADE80),
          ),
          const SizedBox(height: 28),
        ],
        if (weaknesses.isNotEmpty) ...[
          _buildSectionHeader(
            _getWeaknessesTitle(mode),
            Icons.warning_rounded,
            const Color(0xFFFBBF24),
          ),
          _buildTagCloud(
            weaknesses.map((e) => e.toString()).toList(),
            const Color(0xFFFBBF24),
          ),
          const SizedBox(height: 28),
        ],
        if (suggestions.isNotEmpty) ...[
          _buildSectionHeader(
            _getSuggestionsTitle(mode),
            Icons.lightbulb_outline_rounded,
            Colors.deepPurpleAccent,
          ),
          ...suggestions.indexed.map(
              (e) => _buildSuggestionCard(e.$2, e.$1 + 1)),
          const SizedBox(height: 28),
        ],
        if (widget.rawText != null && widget.rawText!.isNotEmpty) ...[
          _buildRewriteButton(),
          const SizedBox(height: 40),
        ],
      ],
    );
  }

  // ==================== CUSTOM PROMPT RESULT ====================

  Widget _buildCustomPromptResult() {
    final String userPrompt = widget.result['userPrompt'] ?? '';
    final String customResponse = widget.result['customResponse'] ?? '';
    final List<String> keyPoints =
        (widget.result['keyPoints'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final List<String> actionItems =
        (widget.result['actionItems'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Badge
        Center(child: _buildModeBadge('customPrompt')),
        const SizedBox(height: 24),

        // Frage des Users als Kontext-Box
        if (userPrompt.isNotEmpty) ...[
          _buildQuestionBox(userPrompt),
          const SizedBox(height: 24),
        ],

        // Hauptantwort der KI (Fließtext)
        if (customResponse.isNotEmpty) ...[
          _buildSectionHeader(
            AppTranslation.t('Direct Answer'),
            Icons.psychology_rounded,
            Colors.deepPurpleAccent,
          ),
          _buildCustomResponseCard(customResponse),
          const SizedBox(height: 28),
        ],

        // Key Points (optional – nur wenn vorhanden)
        if (keyPoints.isNotEmpty) ...[
          _buildSectionHeader(
            AppTranslation.t('Key Findings'),
            Icons.analytics_rounded,
            const Color(0xFF4ADE80),
          ),
          ...keyPoints.indexed.map(
              (e) => _buildKeyPointItem(e.$2, e.$1 + 1)),
          const SizedBox(height: 28),
        ],

        // Action Items (optional – nur wenn vorhanden)
        if (actionItems.isNotEmpty) ...[
          _buildSectionHeader(
            AppTranslation.t('Action Steps'),
            Icons.checklist_rounded,
            const Color(0xFFFBBF24),
          ),
          ...actionItems.indexed.map(
              (e) => _buildActionItem(e.$2, e.$1 + 1)),
          const SizedBox(height: 28),
        ],

        // Rewrite Button – auch bei customPrompt nutzbar
        if (widget.rawText != null && widget.rawText!.isNotEmpty) ...[
          _buildRewriteButton(),
          const SizedBox(height: 40),
        ],
      ],
    );
  }

  // ==================== CUSTOM PROMPT WIDGETS ====================

  /// Zeigt die ursprüngliche User-Frage als Quote-Box
  Widget _buildQuestionBox(String question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.25)),
        // Linker Akzentbalken wie ein Zitat
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zitat-Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Colors.deepPurpleAccent,
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslation.t('Your Question'),
                  style: TextStyle(
                    color: Colors.deepPurpleAccent.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Boldo',
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Boldo',
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hauptantwort der KI als Fließtext-Card
  Widget _buildCustomResponseCard(String response) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.15)),
      ),
      child: Text(
        response,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.7,
          fontFamily: 'Boldo',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Einzelner Key-Finding Punkt mit nummeriertem Icon
  Widget _buildKeyPointItem(String text, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nummer-Badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color(0xFF4ADE80),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
                fontFamily: 'Boldo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Action Item als Checkbox-Style Card
  Widget _buildActionItem(String text, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox-Icon (ausgefüllt mit Nummer)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
                fontFamily: 'Boldo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildModeBadge(String mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getModeIcon(mode), color: Colors.deepPurpleAccent, size: 14),
          const SizedBox(width: 8),
          Text(
            _getModeBadgeText(mode),
            style: const TextStyle(
              color: Colors.deepPurpleAccent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'Boldo',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRing(int score, String scoreLabel, String mode) {
    final color = _getScoreColor(score.toDouble());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.12), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                final progress = _scoreAnimation.value / 100;
                final displayScore = _scoreAnimation.value.round();
                return CustomPaint(
                  painter: _ScoreRingPainter(
                    progress: progress,
                    color: color,
                    backgroundColor: Colors.white.withOpacity(0.06),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$displayScore',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Boldo',
                            height: 1,
                            letterSpacing: -2,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.35),
                            fontFamily: 'Boldo',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _getScoreSubtitle(mode),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
              fontFamily: 'Boldo',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              scoreLabel.toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                fontFamily: 'Boldo',
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagCloud(List<String> items, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontFamily: 'Boldo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'Boldo',
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        summary,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.6,
          fontFamily: 'Boldo',
        ),
      ),
    );
  }

  Widget _buildPriorityItem(String text, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
                fontFamily: 'Boldo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(dynamic suggestion, int index) {
    final String title = suggestion is Map
        ? (suggestion['title']?.toString() ?? 'Suggestion $index')
        : 'Suggestion $index';
    final String description = suggestion is Map
        ? (suggestion['description']?.toString() ?? '')
        : suggestion.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Boldo',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Boldo',
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'Boldo',
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewriteButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isRewriting ? null : _startRewrite,
        icon: const Icon(Icons.auto_fix_high_rounded, size: 22),
        label: Text(
          AppTranslation.t('Rewrite CV'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            fontFamily: 'Boldo',
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildNotCVResult() {
    final String message = widget.result['message'] ?? '';
    final String documentType = widget.result['documentType'] ?? '';

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orangeAccent.withOpacity(0.1),
              border: Border.all(
                color: Colors.orangeAccent.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.find_in_page_rounded,
              color: Colors.orangeAccent,
              size: 52,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            AppTranslation.t('No CV Detected'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Boldo',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (documentType.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_outlined,
                      color: Colors.orangeAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${AppTranslation.t('Detected')}: $documentType',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Boldo',
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              message.isNotEmpty
                  ? message
                  : AppTranslation.t('Please upload a valid resume PDF.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.6,
                fontFamily: 'Boldo',
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildTipBox(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTipBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: Colors.deepPurpleAccent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslation.t('Tip'),
                  style: const TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Boldo',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppTranslation.t(
                    'Upload a PDF that contains your work experience, education and skills for the best results.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.5,
                    fontFamily: 'Boldo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewriteOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Colors.deepPurpleAccent,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppTranslation.t('Rewriting your CV...'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Boldo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslation.t('This may take a moment'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontFamily: 'Boldo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CUSTOM PAINTER ====================

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * progress),
        colors: [color.withOpacity(0.6), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );

    if (progress > 0.02) {
      final angle = -math.pi / 2 + (2 * math.pi * progress);
      final dotX = center.dx + radius * math.cos(angle);
      final dotY = center.dy + radius * math.sin(angle);

      canvas.drawCircle(
        Offset(dotX, dotY),
        6,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}