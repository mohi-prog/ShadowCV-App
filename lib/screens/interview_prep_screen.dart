import 'package:flutter/material.dart';
import 'package:shadowcv/services/translation_service.dart';
import 'package:shadowcv/screens/interview_simulation_screen.dart';

class InterviewPrepScreen extends StatefulWidget {
  final Map<String, dynamic> prepResult;
  final String targetJob;

  const InterviewPrepScreen({
    super.key,
    required this.prepResult,
    required this.targetJob,
  });

  @override
  State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final Set<int> _expandedQuestions = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final questions = widget.prepResult['questions'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.8),
                radius: 1.5,
                colors: [
                  Colors.deepPurpleAccent.withOpacity(0.12),
                  Colors.black,
                ],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(questions.length),
                          const SizedBox(height: 24),
                          ...questions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final question =
                                entry.value as Map<String, dynamic>;
                            return _buildQuestionCard(question, index);
                          }),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppTranslation.t('Interview Prep'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Boldo',
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.deepPurpleAccent.withOpacity(0.3)),
            ),
            child: Text(
              AppTranslation.t('10 Q\'s'),
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

  Widget _buildHeaderCard(int totalQuestions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurpleAccent.withOpacity(0.3),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: Colors.deepPurpleAccent.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: Colors.deepPurpleAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                      AppTranslation.t('AI Personalized'),
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Boldo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.targetJob,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'Boldo',
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$totalQuestions ${AppTranslation.t('personalized questions based on your CV')}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
              fontFamily: 'Boldo',
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Behavioral',
              'Technical',
              'Motivational',
              'Situational'
            ].map((cat) => _buildCategoryChip(cat)).toList(),
          ),
          // In _buildHeaderCard(), nach dem Wrap mit Chips:

const SizedBox(height: 20),
Divider(color: Colors.white.withOpacity(0.08)),
const SizedBox(height: 16),

SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InterviewSimulationScreen(
            prepResult: widget.prepResult,
            targetJob: widget.targetJob,
            // rawCvText optional – falls du es von außen übergibst
          ),
        ),
      );
    },
    icon: const Icon(Icons.play_circle_rounded, size: 20),
    label: Text(
      AppTranslation.t('Start Interview Simulation'),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        fontFamily: 'Boldo',
        letterSpacing: 0.3,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurpleAccent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
    ),
  ),
),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            AppTranslation.t(category),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Boldo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    final id = question['id'] ?? index + 1;
    final category = question['category'] ?? 'General';
    final questionText = question['question'] ?? '';
    final whyAsked = question['whyAsked'] ?? '';
    final exampleAnswer = question['exampleAnswer'] ?? '';
    final proTip = question['proTip'] ?? '';
    final theme = question['theme'] ?? '';
    final hook = question['interviewerHook'] ?? '';
    
    final isExpanded = _expandedQuestions.contains(index);
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isExpanded
            ? color.withOpacity(0.05)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedQuestions.remove(index);
              } else {
                _expandedQuestions.add(index);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '$id',
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Boldo',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: color, size: 7),
                              const SizedBox(width: 4),
                              Text(
                                (theme.isNotEmpty ? '$theme • ' : '').toUpperCase() +
                                AppTranslation.t(category).toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Boldo',
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (hook.isNotEmpty) 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                hook,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                  fontFamily: 'Boldo',
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          Text(
                            questionText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Boldo',
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Divider(color: Colors.white.withOpacity(0.06)),
                      const SizedBox(height: 16),
                      if (whyAsked.isNotEmpty) ...[
                        _buildExpandedSection(
                          icon: Icons.info_outline_rounded,
                          title: AppTranslation.t(
                              'Why interviewers ask this'),
                          content: whyAsked,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (exampleAnswer.isNotEmpty) ...[
                        _buildExpandedSection(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: AppTranslation.t('Example Answer'),
                          content: exampleAnswer,
                          color: Colors.deepPurpleAccent,
                          isHighlighted: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (proTip.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.amber.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.tips_and_updates_rounded,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslation.t('Pro Tip'),
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Boldo',
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      proTip,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.7),
                                        fontSize: 13,
                                        fontFamily: 'Boldo',
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFamily: 'Boldo',
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.deepPurpleAccent.withOpacity(0.08)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHighlighted
                  ? Colors.deepPurpleAccent.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontFamily: 'Boldo',
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}