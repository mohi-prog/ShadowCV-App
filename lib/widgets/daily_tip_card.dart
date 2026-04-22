import 'package:flutter/material.dart';
import 'package:shadowcv/data/daily_tips.dart';
import 'package:shadowcv/services/daily_tip_service.dart';
import 'package:shadowcv/services/translation_service.dart';

class DailyTipCard extends StatefulWidget {
  const DailyTipCard({super.key});

  @override
  State<DailyTipCard> createState() => _DailyTipCardState();
}

class _DailyTipCardState extends State<DailyTipCard>
    with SingleTickerProviderStateMixin {
  bool _isDismissed = false;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));

    _checkDismissed();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkDismissed() async {
    final dismissed = await DailyTipService.isTipDismissedToday();
    if (mounted) {
      setState(() {
        _isDismissed = dismissed;
        _isLoading = false;
      });
      if (!dismissed) {
        _animController.forward();
      }
    }
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    await DailyTipService.dismissTipForToday();
    if (mounted) {
      setState(() => _isDismissed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isDismissed) return const SizedBox.shrink();

    final index = DailyTipService.getTodayIndex(
      DailyTips.tips['English']!.length,
    );
    final tip = DailyTips.getTip(AppTranslation.currentLang, index);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurpleAccent.withOpacity(0.2),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
                border: Border.all(
                  color: Colors.deepPurpleAccent
                      .withOpacity(0.2 + (_glowAnimation.value * 0.2)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurpleAccent
                        .withOpacity(0.1 * _glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.tips_and_updates_rounded,
                        color: Colors.deepPurpleAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Daily Career Tip',
                      style: TextStyle(
                        color: Colors.deepPurpleAccent.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Boldo',
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    // Tag Nummer
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Day ${index + 1}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          fontFamily: 'Boldo',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tip Text
                Text(
                  tip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.6,
                    fontFamily: 'Boldo',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _dismiss,
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Colors.deepPurpleAccent.withOpacity(0.12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.deepPurpleAccent.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.deepPurpleAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Got it!',
                          style: const TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Boldo',
                          ),
                        ),
                      ],
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
}