import 'package:flutter/material.dart';
import 'package:shadowcv/services/translation_service.dart';

class SalaryInsightsScreen extends StatefulWidget {
  final Map<String, dynamic> insightsResult;
  final String targetJob;
  final String country;

  const SalaryInsightsScreen({
    super.key,
    required this.insightsResult,
    required this.targetJob,
    required this.country,
  });

  @override
  State<SalaryInsightsScreen> createState() => _SalaryInsightsScreenState();
}

class _SalaryInsightsScreenState extends State<SalaryInsightsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getMarketComparisonColor(String comparison) {
    switch (comparison.toLowerCase()) {
      case 'above':
        return Colors.greenAccent;
      case 'below':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  IconData _getMarketComparisonIcon(String comparison) {
    switch (comparison.toLowerCase()) {
      case 'above':
        return Icons.trending_up_rounded;
      case 'below':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  String _getMarketComparisonText(String comparison) {
    switch (comparison.toLowerCase()) {
      case 'above':
        return AppTranslation.t('above market');
      case 'below':
        return AppTranslation.t('below market');
      default:
        return AppTranslation.t('at market');
    }
  }

  String _formatSalary(dynamic value, String currency) {
    if (value == null) return '$currency 0';
    final num =
        value is int ? value : int.tryParse(value.toString()) ?? 0;
    if (num >= 1000) {
      return '$currency ${(num / 1000).toStringAsFixed(0)}k';
    }
    return '$currency $num';
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.insightsResult['currency'] ?? '€';
    final salaryMin = widget.insightsResult['salaryMin'] ?? 0;
    final salaryMid = widget.insightsResult['salaryMid'] ?? 0;
    final salaryMax = widget.insightsResult['salaryMax'] ?? 0;
    final marketAverage = widget.insightsResult['marketAverage'] ?? 0;
    final candidateLevel =
        widget.insightsResult['candidateLevel'] ?? '';
    final experienceYears =
        widget.insightsResult['experienceYears'] ?? 0;
    final salaryBoosts =
        widget.insightsResult['salaryBoosts'] as List? ?? [];
    final salaryLimits =
        widget.insightsResult['salaryLimits'] as List? ?? [];
    final topTips = widget.insightsResult['topTips'] as List? ?? [];
    final marketComparison =
        widget.insightsResult['marketComparison'] ?? 'at market';
    final summary = widget.insightsResult['summary'] ?? '';

    final comparisonColor = _getMarketComparisonColor(marketComparison);
    final comparisonIcon = _getMarketComparisonIcon(marketComparison);
    final comparisonText = _getMarketComparisonText(marketComparison);

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
                  Colors.greenAccent.withOpacity(0.08),
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
                          _buildHeaderCard(
                            candidateLevel,
                            experienceYears,
                            comparisonColor,
                            comparisonIcon,
                            comparisonText,
                          ),
                          const SizedBox(height: 20),
                          _buildSalaryRangeCard(
                            currency,
                            salaryMin,
                            salaryMid,
                            salaryMax,
                            marketAverage,
                          ),
                          const SizedBox(height: 20),
                          if (summary.isNotEmpty) ...[
                            _buildSummaryCard(summary),
                            const SizedBox(height: 20),
                          ],
                          if (salaryBoosts.isNotEmpty) ...[
                            _buildListCard(
                              title: AppTranslation.t('Salary Boosters'),
                              icon: Icons.rocket_launch_rounded,
                              color: Colors.greenAccent,
                              items: salaryBoosts,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (salaryLimits.isNotEmpty) ...[
                            _buildListCard(
                              title: AppTranslation.t('Salary Limiters'),
                              icon: Icons.block_rounded,
                              color: Colors.redAccent,
                              items: salaryLimits,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (topTips.isNotEmpty) ...[
                            _buildListCard(
                              title: AppTranslation.t('How to Earn More'),
                              icon: Icons.tips_and_updates_rounded,
                              color: Colors.amber,
                              items: topTips,
                            ),
                          ],
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
                border: Border.all(
                    color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppTranslation.t('Salary Insights'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Boldo',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Colors.greenAccent, size: 12),
                const SizedBox(width: 4),
                Text(
                  widget.country,
                  style: const TextStyle(
                    color: Colors.greenAccent,
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

  Widget _buildHeaderCard(
    String candidateLevel,
    int experienceYears,
    Color comparisonColor,
    IconData comparisonIcon,
    String comparisonText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.greenAccent.withOpacity(0.15),
            Colors.black.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: Colors.greenAccent.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: Colors.greenAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: comparisonColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: comparisonColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(comparisonIcon,
                        color: comparisonColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      comparisonText,
                      style: TextStyle(
                        color: comparisonColor,
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
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                Icons.work_rounded,
                candidateLevel,
                Colors.deepPurpleAccent,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.calendar_today_rounded,
                '$experienceYears ${AppTranslation.t('yrs exp')}',
                Colors.blueAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
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

  Widget _buildSalaryRangeCard(
    String currency,
    dynamic salaryMin,
    dynamic salaryMid,
    dynamic salaryMax,
    dynamic marketAverage,
  ) {
    final minVal = salaryMin is int
        ? salaryMin
        : int.tryParse(salaryMin.toString()) ?? 0;
    final midVal = salaryMid is int
        ? salaryMid
        : int.tryParse(salaryMid.toString()) ?? 0;
    final maxVal = salaryMax is int
        ? salaryMax
        : int.tryParse(salaryMax.toString()) ?? 0;
    final marketVal = marketAverage is int
        ? marketAverage
        : int.tryParse(marketAverage.toString()) ?? 0;

    final barProgress =
        maxVal > 0 ? (midVal / maxVal).clamp(0.0, 1.0) : 0.0;
    final marketProgress =
        maxVal > 0 ? (marketVal / maxVal).clamp(0.0, 1.0) : 0.0;

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
              const Icon(Icons.bar_chart_rounded,
                  color: Colors.greenAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                AppTranslation.t('SALARY RANGE'),
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSalaryPoint(
                label: AppTranslation.t('Min'),
                value: _formatSalary(minVal, currency),
                color: Colors.white38,
              ),
              _buildSalaryPoint(
                label: AppTranslation.t('You'),
                value: _formatSalary(midVal, currency),
                color: Colors.greenAccent,
                isMain: true,
              ),
              _buildSalaryPoint(
                label: AppTranslation.t('Max'),
                value: _formatSalary(maxVal, currency),
                color: Colors.white38,
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _barAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: barProgress * _barAnimation.value,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.greenAccent,
                            Color(0xFF00E676),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: MediaQuery.of(context).size.width *
                        marketProgress *
                        _barAnimation.value *
                        0.75,
                    top: -4,
                    child: Container(
                      width: 3,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 10,
                height: 3,
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Text(
                '${AppTranslation.t('Market avg')}: ${_formatSalary(marketVal, currency)}',
                style: TextStyle(
                  color: Colors.orangeAccent.withOpacity(0.8),
                  fontSize: 12,
                  fontFamily: 'Boldo',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryPoint({
    required String label,
    required String value,
    required Color color,
    bool isMain = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isMain ? 26 : 16,
            fontWeight: FontWeight.w900,
            fontFamily: 'Boldo',
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 11,
            fontFamily: 'Boldo',
          ),
        ),
      ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_rounded,
                  color: Colors.white54, size: 14),
              const SizedBox(width: 8),
              Text(
                AppTranslation.t('SUMMARY'),
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
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Boldo',
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required IconData icon,
    required Color color,
    required List items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.toString(),
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
            ),
          ),
        ],
      ),
    );
  }
}