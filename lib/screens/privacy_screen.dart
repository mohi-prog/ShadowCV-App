import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _privacySections = [
    {
      'icon': Icons.shield_rounded,
      'color': Colors.greenAccent,
      'title': 'Data We Collect',
      'content': [
        {
          'subtitle': 'Account Information',
          'text':
              'When you create an account, we collect your name, email address, job title, and career goal. This information personalizes your experience.',
        },
        {
          'subtitle': 'CV Content',
          'text':
              'When you upload a CV, we extract and temporarily process the text content. Your CV text is stored securely in Firebase to enable analysis history and AI chat.',
        },
        {
          'subtitle': 'Usage Data',
          'text':
              'We collect basic usage data such as analysis count, premium status, and last login time. This helps us improve the app.',
        },
      ],
    },
    {
      'icon': Icons.lock_rounded,
      'color': Colors.deepPurpleAccent,
      'title': 'How We Use It',
      'content': [
        {
          'subtitle': 'AI Analysis',
          'text':
              'Your CV text is sent to Groq AI servers to generate analysis, rewrites, interview questions, and other AI-powered features. The AI does not store your data permanently.',
        },
        {
          'subtitle': 'Personalization',
          'text':
              'Your profile information (job title, goal, language) is used to make AI responses more relevant and personalized to your career situation.',
        },
        {
          'subtitle': 'No Third-Party Sharing',
          'text':
              'We never sell or share your personal data or CV content with third parties for marketing or advertising purposes.',
        },
      ],
    },
    {
      'icon': Icons.security_rounded,
      'color': Colors.blueAccent,
      'title': 'Your Rights',
      'content': [
        {
          'subtitle': 'Delete Your Data',
          'text':
              'You can delete your account at any time via Profile → Delete Account. This permanently removes all your data from our servers.',
        },
        {
          'subtitle': 'Data Access',
          'text':
              'You can view all your stored analyses in the My Analyses section. Your profile data is visible in the Profile screen.',
        },
        {
          'subtitle': 'Contact Us',
          'text':
              'For any privacy concerns or data requests, contact us at privacy@shadowcv.app. We respond within 48 hours.',
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> _termsSections = [
    {
      'icon': Icons.check_circle_rounded,
      'color': Colors.greenAccent,
      'title': 'Acceptable Use',
      'points': [
        'Use ShadowCV only for legitimate career development purposes',
        'Upload only your own CV or documents you have permission to analyze',
        'Do not attempt to reverse-engineer or abuse the AI systems',
        'Do not use the app to generate misleading or fraudulent content',
      ],
    },
    {
      'icon': Icons.info_rounded,
      'color': Colors.orangeAccent,
      'title': 'Limitations',
      'points': [
        'AI-generated content is for guidance only – not guaranteed accuracy',
        'Salary estimates are approximations based on market data',
        'We are not responsible for hiring decisions made based on our analysis',
        'Service availability may vary and we reserve the right to update features',
      ],
    },
    {
      'icon': Icons.workspace_premium_rounded,
      'color': Colors.amber,
      'title': 'Premium & Payments',
      'points': [
        'All payments are processed securely via App Store or Google Play',
        'Monthly subscriptions auto-renew unless cancelled 24 hours before renewal',
        'Lifetime purchases are one-time payments with no recurring charges',
        'Refunds are handled according to App Store / Google Play policies',
      ],
    },
  ];

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

  @override
  Widget build(BuildContext context) {
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
                  Colors.blueAccent.withOpacity(0.08),
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
                  _buildTabSelector(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _selectedTab == 0
                        ? _buildPrivacyContent()
                        : _buildTermsContent(),
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
          const Expanded(
            child: Text(
              'Privacy & Terms',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Boldo',
              ),
            ),
          ),
          // Last Updated Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(
              'v1.0',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11,
                fontFamily: 'Boldo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            _buildTab(0, Icons.shield_rounded, 'Privacy Policy'),
            _buildTab(1, Icons.gavel_rounded, 'Terms of Use'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.deepPurpleAccent.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: Colors.deepPurpleAccent.withOpacity(0.3))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.deepPurpleAccent
                    : Colors.white38,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.deepPurpleAccent
                      : Colors.white38,
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w800
                      : FontWeight.w500,
                  fontFamily: 'Boldo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyContent() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _privacySections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildPrivacyHero();
        final section = _privacySections[index - 1];
        return _buildPrivacySection(section);
      },
    );
  }

  Widget _buildPrivacyHero() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.greenAccent.withOpacity(0.12),
            Colors.black.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Colors.greenAccent.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Colors.greenAccent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Boldo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We are committed to protecting your personal data and CV content.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'Boldo',
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

  Widget _buildPrivacySection(Map<String, dynamic> section) {
    final color = section['color'] as Color;
    final content = section['content'] as List<Map<String, String>>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              border: Border(
                  bottom: BorderSide(
                      color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Icon(section['icon'] as IconData,
                    color: color, size: 18),
                const SizedBox(width: 10),
                Text(
                  (section['title'] as String).toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Boldo',
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['subtitle']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Boldo',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Text(
                          item['text']!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            fontFamily: 'Boldo',
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsContent() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _termsSections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildTermsHero();
        final section = _termsSections[index - 1];
        return _buildTermsSection(section);
      },
    );
  }

  Widget _buildTermsHero() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurpleAccent.withOpacity(0.15),
            Colors.black.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Colors.deepPurpleAccent.withOpacity(0.2),
            width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.gavel_rounded,
                color: Colors.deepPurpleAccent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms of Use',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Boldo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By using ShadowCV, you agree to these terms. Last updated: 2025.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'Boldo',
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

  Widget _buildTermsSection(Map<String, dynamic> section) {
    final color = section['color'] as Color;
    final points = section['points'] as List<String>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              border: Border(
                  bottom: BorderSide(
                      color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Icon(section['icon'] as IconData,
                    color: color, size: 18),
                const SizedBox(width: 10),
                Text(
                  (section['title'] as String).toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Boldo',
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: points.map((point) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                          point,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontFamily: 'Boldo',
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}