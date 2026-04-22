import 'package:flutter/material.dart';
import 'package:shadowcv/services/premium_service.dart';
import 'package:shadowcv/services/translation_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isAlreadyPremium = false;
  int _remainingAnalyses = 3;
  String _selectedPlan = 'lifetime';

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadStatus();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final premiumState = await PremiumService.isPremium();
final isPremium = await PremiumService.isPremium();
    final remaining = await PremiumService.getRemainingAnalyses();
    if (mounted) {
      setState(() {
        _isAlreadyPremium = isPremium;
        _remainingAnalyses = remaining;
      });
    }
  }

  Future<void> _purchase() async {
    if (_isAlreadyPremium) return;
    setState(() => _isLoading = true);

    try {
      if (!PremiumService.isAvailable) {
        await PremiumService.enableDevMode();
        if (mounted) {
          _showSuccess(AppTranslation.t('Premium activated! (Dev Mode)'));
          Navigator.pop(context, true);
        }
        return;
      }

      if (_selectedPlan == 'monthly') {
        await PremiumService.buyMonthly();
      } else {
        await PremiumService.buyLifetime();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(
                      fontFamily: 'Boldo',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Boldo',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurpleAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 1.2,
                  colors: [
                    _isAlreadyPremium
                        ? Colors.greenAccent.withOpacity(0.1)
                        : Colors.deepPurpleAccent.withOpacity(0.2),
                    Colors.black,
                  ],
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Close Button
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Crown Icon
                    _buildCrownIcon(),
                    const SizedBox(height: 24),

                    // Titel – je nach Status
                    Text(
                      _isAlreadyPremium
                          ? 'ShadowCV Premium ✓'
                          : AppTranslation.t('Unlock ShadowCV Premium'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _isAlreadyPremium
                            ? Colors.greenAccent
                            : Colors.white,
                        fontFamily: 'Boldo',
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Untertitel – je nach Status
                    Text(
                      _isAlreadyPremium
                          ? AppTranslation.t('All Premium features unlocked!')
                          : AppTranslation.t(
                              'Get hired faster with AI-powered tools',
                            ),
                      style: TextStyle(
                        fontSize: 15,
                        color: _isAlreadyPremium
                            ? Colors.greenAccent.withOpacity(0.7)
                            : Colors.white.withOpacity(0.5),
                        fontFamily: 'Boldo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Remaining Counter – je nach Status
                    _buildRemainingCounter(),
                    const SizedBox(height: 28),

                    // Comparison Table – immer gleich
                    _buildComparisonTable(),
                    const SizedBox(height: 28),

                    // Plan Cards – immer sichtbar, bei Premium disabled
                    _buildPlanCard(
                      id: 'lifetime',
                      title: AppTranslation.t('Lifetime'),
                      price: '€19.99',
                      period: AppTranslation.t('one time'),
                      description: AppTranslation.t('Pay once, use forever'),
                      isBestValue: true,
                      savingsText: AppTranslation.t('Save 67%'),
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      id: 'monthly',
                      title: AppTranslation.t('Monthly'),
                      price: '€4.99',
                      period: AppTranslation.t('/ month'),
                      description: AppTranslation.t('Cancel anytime'),
                      isBestValue: false,
                    ),
                    const SizedBox(height: 28),

                    // Buy Button – je nach Status
                    _buildBuyButton(),
                    const SizedBox(height: 16),

                    // Restore – nur bei Free
                    if (!_isAlreadyPremium) _buildRestoreButton(),
                    const SizedBox(height: 8),

                    // Legal
                    Text(
                      AppTranslation.t(
                        'Secure payment via App Store / Google Play',
                      ),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 11,
                        fontFamily: 'Boldo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildCrownIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _isAlreadyPremium
              ? [Colors.greenAccent, Colors.green]
              : [const Color(0xFFFFD700), const Color(0xFFFFA500)],
        ),
        boxShadow: [
          BoxShadow(
            color: _isAlreadyPremium
                ? Colors.greenAccent.withOpacity(0.4)
                : const Color(0xFFFFD700).withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        _isAlreadyPremium
            ? Icons.check_circle_rounded
            : Icons.workspace_premium_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Widget _buildRemainingCounter() {
    if (_isAlreadyPremium) {
      // Premium: grüner "Unlimited" Badge
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.all_inclusive_rounded,
              color: Colors.greenAccent,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Unlimited Analyses Active',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Boldo',
              ),
            ),
          ],
        ),
      );
    }

    // Free: normaler Counter
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _remainingAnalyses <= 1
            ? Colors.redAccent.withOpacity(0.1)
            : Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _remainingAnalyses <= 1
              ? Colors.redAccent.withOpacity(0.3)
              : Colors.orangeAccent.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _remainingAnalyses <= 1
                ? Icons.warning_rounded
                : Icons.info_outline_rounded,
            color: _remainingAnalyses <= 1
                ? Colors.redAccent
                : Colors.orangeAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _remainingAnalyses <= 0
                ? AppTranslation.t('No free analyses left – Upgrade now')
                : '${AppTranslation.t('Free analyses remaining')}: $_remainingAnalyses / ${PremiumService.freeAnalysisLimit}',
            style: TextStyle(
              color: _remainingAnalyses <= 1
                  ? Colors.redAccent
                  : Colors.orangeAccent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Boldo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('', style: TextStyle(fontFamily: 'Boldo')),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  AppTranslation.t('Free'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Boldo',
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppTranslation.t('Premium'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Boldo',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildComparisonRow(AppTranslation.t('CV Analyses'), '3', '∞'),
          _buildComparisonRow(
            AppTranslation.t('Analysis Modes'),
            AppTranslation.t('General only'),
            AppTranslation.t('All 4'),
          ),
          _buildComparisonRow(AppTranslation.t('AI Chat'), '—', '✓'),
          _buildComparisonRow(AppTranslation.t('CV Rewrite'), '—', '✓'),
          _buildComparisonRow(AppTranslation.t('PDF Export'), '—', '✓'),
          _buildComparisonRow(
            AppTranslation.t('Priority Processing'),
            '—',
            '✓',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String feature,
    String free,
    String premium, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontFamily: 'Boldo',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 13,
                fontFamily: 'Boldo',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Boldo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String period,
    required String description,
    required bool isBestValue,
    String? savingsText,
  }) {
    final isSelected = _selectedPlan == id;

    return GestureDetector(
      onTap: _isAlreadyPremium
          ? null
          : () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isAlreadyPremium
              ? Colors.white.withOpacity(0.02)
              : isSelected
              ? Colors.deepPurpleAccent.withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isAlreadyPremium
                ? Colors.white.withOpacity(0.04)
                : isSelected
                ? Colors.deepPurpleAccent
                : Colors.white.withOpacity(0.08),
            width: isSelected && !_isAlreadyPremium ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: _isAlreadyPremium ? 0.4 : 1.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected && !_isAlreadyPremium
                        ? Colors.deepPurpleAccent
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected && !_isAlreadyPremium
                          ? Colors.deepPurpleAccent
                          : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: isSelected && !_isAlreadyPremium
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Boldo',
                      ),
                    ),
                    if (isBestValue || savingsText != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (isBestValue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppTranslation.t('Best Value'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Boldo',
                                ),
                              ),
                            ),
                          if (savingsText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                savingsText,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Boldo',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontFamily: 'Boldo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Boldo',
                    ),
                  ),
                  Text(
                    period,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontFamily: 'Boldo',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuyButton() {
    if (_isAlreadyPremium) {
      // Premium: grüner "Already Active" Button
      return SizedBox(
        width: double.infinity,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.greenAccent.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Premium Active ✓',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.greenAccent,
                    fontFamily: 'Boldo',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Free: normaler Kauf-Button
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _purchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _selectedPlan == 'monthly'
                        ? AppTranslation.t('Start for €4.99 / month')
                        : AppTranslation.t('Get Lifetime for €19.99'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Boldo',
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: () async {
        setState(() => _isLoading = true);
        await PremiumService.restorePurchases();
        await _loadStatus();
        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccess(AppTranslation.t('Purchases restored!'));
        }
      },
      child: Text(
        AppTranslation.t('Restore Purchases'),
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontFamily: 'Boldo',
        ),
      ),
    );
  }
}
