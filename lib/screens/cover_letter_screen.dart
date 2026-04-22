import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadowcv/services/translation_service.dart';

class CoverLetterScreen extends StatefulWidget {
  final String coverLetter;
  final String targetJob;
  final String tone;

  const CoverLetterScreen({
    super.key,
    required this.coverLetter,
    required this.targetJob,
    required this.tone,
  });

  @override
  State<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends State<CoverLetterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getToneColor() {
    switch (widget.tone) {
      case 'Professional':
        return Colors.deepPurpleAccent;
      case 'Formal':
        return Colors.blueAccent;
      case 'Creative':
        return Colors.pinkAccent;
      default:
        return Colors.deepPurpleAccent;
    }
  }

  IconData _getToneIcon() {
    switch (widget.tone) {
      case 'Professional':
        return Icons.business_center_rounded;
      case 'Formal':
        return Icons.account_balance_rounded;
      case 'Creative':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.business_center_rounded;
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.coverLetter));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final toneColor = _getToneColor();

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
                  toneColor.withOpacity(0.1),
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
                  _buildAppBar(toneColor),
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(toneColor),
                            const SizedBox(height: 20),
                            _buildCoverLetterCard(toneColor),
                            const SizedBox(height: 20),
                            _buildCopyButton(toneColor),
                            const SizedBox(height: 40),
                          ],
                        ),
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

  Widget _buildAppBar(Color toneColor) {
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
                border:
                    Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppTranslation.t('Cover Letter'),
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
              color: toneColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: toneColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getToneIcon(), color: toneColor, size: 12),
                const SizedBox(width: 6),
                Text(
                  AppTranslation.t(widget.tone),
                  style: TextStyle(
                    color: toneColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

  Widget _buildHeaderCard(Color toneColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            toneColor.withOpacity(0.2),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: toneColor.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: toneColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.description_rounded,
              color: toneColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.targetJob,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Boldo',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
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
                      AppTranslation.t('AI Generated • Ready to use'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: 'Boldo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverLetterCard(Color toneColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: toneColor.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppTranslation.t('YOUR COVER LETTER'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 20),
          SelectableText(
            widget.coverLetter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Boldo',
              height: 1.8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(Color toneColor) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _copyToClipboard,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: _copied
                  ? Colors.greenAccent.withOpacity(0.5)
                  : toneColor.withOpacity(0.4),
              width: 1.5,
            ),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _copied
              ? Row(
                  key: const ValueKey('copied'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      AppTranslation.t('Copied!'),
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Boldo',
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('copy'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy_rounded, color: toneColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      AppTranslation.t('Copy Text'),
                      style: TextStyle(
                        color: toneColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Boldo',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}