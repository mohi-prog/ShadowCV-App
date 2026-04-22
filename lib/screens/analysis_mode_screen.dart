import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shadowcv/services/gemini_analysis_service.dart';
import 'package:shadowcv/services/translation_service.dart';

class AnalysisModeScreen extends StatefulWidget {
  final String fileName;
  final String rawText;

  const AnalysisModeScreen({
    super.key,
    required this.fileName,
    required this.rawText,
  });

  @override
  State<AnalysisModeScreen> createState() => _AnalysisModeScreenState();
}

class _AnalysisModeScreenState extends State<AnalysisModeScreen>
    with SingleTickerProviderStateMixin {
  AnalysisMode? _selectedMode;
  final _jobController = TextEditingController();
  final _customController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Welche Modi gibt es + Metadaten
  final _modes = const [
    _ModeData(
      mode: AnalysisMode.generalReview,
      icon: Icons.assessment_rounded,
      color: Color(0xFF7C3AED),
      glowColor: Color(0xFF7C3AED),
    ),
    _ModeData(
      mode: AnalysisMode.atsOptimization,
      icon: Icons.smart_toy_rounded,
      color: Color(0xFF0891B2),
      glowColor: Color(0xFF0891B2),
    ),
    _ModeData(
      mode: AnalysisMode.jobSpecific,
      icon: Icons.work_rounded,
      color: Color(0xFFF59E0B),
      glowColor: Color(0xFFF59E0B),
    ),
    _ModeData(
      mode: AnalysisMode.customPrompt,
      icon: Icons.edit_note_rounded,
      color: Color(0xFFDB2777),
      glowColor: Color(0xFFDB2777),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _jobController.dispose();
    _customController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_selectedMode == null) return;

    if (_selectedMode == AnalysisMode.jobSpecific &&
        _jobController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppTranslation.t('Please enter the target job title.'),
                  style: const TextStyle(
                    fontFamily: 'Boldo',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_selectedMode == AnalysisMode.customPrompt &&
        _customController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppTranslation.t('Please enter your question or request.'),
                  style: const TextStyle(
                    fontFamily: 'Boldo',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'mode': _selectedMode,
      'targetJob': _jobController.text.trim(),
      'customPrompt': _customController.text.trim(),
    });
  }

  Color get _selectedColor {
    if (_selectedMode == null) return Colors.deepPurpleAccent;
    return _modes.firstWhere((m) => m.mode == _selectedMode).color;
  }

  String _getModeTitle(AnalysisMode mode) {
    switch (mode) {
      case AnalysisMode.generalReview:
        return AppTranslation.t('General Review');
      case AnalysisMode.atsOptimization:
        return AppTranslation.t('ATS Optimization');
      case AnalysisMode.jobSpecific:
        return AppTranslation.t('Job-Specific Feedback');
      case AnalysisMode.customPrompt:
        return AppTranslation.t('Custom Prompt');
    }
  }

  String _getModeSubtitle(AnalysisMode mode) {
    switch (mode) {
      case AnalysisMode.generalReview:
        return AppTranslation.t(
          'Full CV analysis – structure, content, language & overall impression.',
        );
      case AnalysisMode.atsOptimization:
        return AppTranslation.t(
          'Check if your CV passes Applicant Tracking Systems.',
        );
      case AnalysisMode.jobSpecific:
        return AppTranslation.t(
          "Tailored analysis for a specific job you're targeting.",
        );
      case AnalysisMode.customPrompt:
        return AppTranslation.t('Ask the AI anything specific about your CV.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Animated color glow based on selection
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            top: -80,
            left: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _selectedColor.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildFileChip(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslation.t(
                                'How should we analyze your CV?',
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Boldo',
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Mode Cards
                            ..._modes.map(
                              (modeData) => Column(
                                children: [
                                  _buildModeCard(modeData),
                                  const SizedBox(height: 12),

                                  // Job Input
                                  if (modeData.mode ==
                                          AnalysisMode.jobSpecific &&
                                      _selectedMode == AnalysisMode.jobSpecific)
                                    _buildInputField(
                                      controller: _jobController,
                                      hint: AppTranslation.t(
                                        'e.g. Senior Flutter Developer',
                                      ),
                                      label: AppTranslation.t(
                                        'Target Job Title',
                                      ),
                                      icon: Icons.work_outline_rounded,
                                      accentColor: modeData.color,
                                    ),

                                  // Custom Prompt Input
                                  if (modeData.mode ==
                                          AnalysisMode.customPrompt &&
                                      _selectedMode ==
                                          AnalysisMode.customPrompt)
                                    _buildInputField(
                                      controller: _customController,
                                      hint: AppTranslation.t(
                                        'e.g. Is my CV suitable for a career change?',
                                      ),
                                      label: AppTranslation.t('Your Question'),
                                      icon: Icons.chat_bubble_outline_rounded,
                                      accentColor: modeData.color,
                                      maxLines: 3,
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),

                    // Continue Button
                    _buildContinueButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            onPressed: () => Navigator.pop(context, null),
          ),
          const SizedBox(width: 4),
          Text(
            AppTranslation.t('Analysis Mode'),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Boldo',
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Boldo',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${(widget.rawText.length / 1000).toStringAsFixed(1)}k ${AppTranslation.t('characters')}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontFamily: 'Boldo',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Ready',
                        style: TextStyle(
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
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(_ModeData data) {
    final isSelected = _selectedMode == data.mode;
    final title = _getModeTitle(data.mode);
    final subtitle = _getModeSubtitle(data.mode);

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = data.mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? data.color.withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? data.color.withOpacity(0.5)
                : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: data.color.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: data.color.withOpacity(isSelected ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: data.color.withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: Icon(data.icon, color: data.color, size: 26),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                      fontFamily: 'Boldo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(isSelected ? 0.6 : 0.35),
                      fontFamily: 'Boldo',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Radio Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? data.color : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? data.color
                      : Colors.white.withOpacity(0.15),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: data.color.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    required Color accentColor,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accentColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: accentColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        fontFamily: 'Boldo',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Boldo',
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontFamily: 'Boldo',
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: accentColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isReady = _selectedMode != null;
    final color = _selectedColor;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 16,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isReady
              ? LinearGradient(colors: [color, color.withOpacity(0.7)])
              : null,
          color: isReady ? null : Colors.white.withOpacity(0.05),
          boxShadow: isReady
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isReady ? _continue : null,
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isReady
                        ? AppTranslation.t('Start Analysis')
                        : AppTranslation.t('Select a Mode'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Boldo',
                      color: isReady
                          ? Colors.white
                          : Colors.white.withOpacity(0.25),
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (isReady) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== DATA CLASS ====================

class _ModeData {
  final AnalysisMode mode;
  final IconData icon;
  final Color color;
  final Color glowColor;

  const _ModeData({
    required this.mode,
    required this.icon,
    required this.color,
    required this.glowColor,
  });
}
