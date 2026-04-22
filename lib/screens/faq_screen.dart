import 'package:flutter/material.dart';
import 'package:shadowcv/services/translation_service.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final Set<int> _expandedItems = {};
  int _selectedCategory = 0;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.assessment_rounded, 'label': 'CV Analysis', 'color': Colors.deepPurpleAccent},
    {'icon': Icons.workspace_premium_rounded, 'label': 'Premium', 'color': Colors.amber},
    {'icon': Icons.psychology_rounded, 'label': 'AI Tools', 'color': Colors.pinkAccent},
    {'icon': Icons.settings_rounded, 'label': 'Account', 'color': Colors.cyanAccent},
  ];

  final List<List<Map<String, String>>> _faqs = [
    // CV Analysis
    [
      {
        'q': 'How does the CV analysis work?',
        'a': 'ShadowCV uses advanced AI (Groq LLaMA) to analyze your CV across multiple dimensions: structure, content quality, language, ATS compatibility, and overall impact. Upload your PDF and get a detailed report in seconds.',
      },
      {
        'q': 'What file formats are supported?',
        'a': 'Currently we support PDF files only. Make sure your CV is saved as a PDF for the best text extraction results. Word documents and image-only PDFs may not work correctly.',
      },
      {
        'q': 'How accurate is the AI score?',
        'a': 'The score is based on industry best practices and ATS standards. It gives you a realistic picture of how your CV performs. However, every recruiter is different – use it as a guide, not a guarantee.',
      },
      {
        'q': 'What are the different analysis modes?',
        'a': 'General Review: Full CV analysis.\nATS Optimization: Check ATS compatibility.\nJob-Specific: Tailored to a target role.\nCustom Prompt: Ask anything about your CV.',
      },
      {
        'q': 'Why was my document rejected as "Not a CV"?',
        'a': 'Our AI strictly checks if the uploaded document is a real CV/resume. If it contains work experience, education, and skills, it will pass. Job descriptions, invoices, or random text will be rejected.',
      },
    ],
    // Premium
    [
      {
        'q': 'What is included in Premium?',
        'a': 'Premium unlocks: Unlimited CV analyses, all 4 analysis modes, AI CV Rewriter, AI Chat, PDF Export, Cover Letter Generator, Interview Prep, and Salary Insights.',
      },
      {
        'q': 'Can I try Premium before buying?',
        'a': 'Yes! You get 3 free analyses with the General Review mode. This lets you experience the core value before upgrading.',
      },
      {
        'q': 'What is the difference between Monthly and Lifetime?',
        'a': 'Monthly (€4.99/month): Pay monthly, cancel anytime.\nLifetime (€19.99): Pay once, use forever. Best value if you use the app regularly.',
      },
      {
        'q': 'How do I restore my purchase?',
        'a': 'Go to the Premium screen and tap "Restore Purchases". Make sure you are logged in with the same account you used for the purchase.',
      },
      {
        'q': 'What happens when my monthly plan expires?',
        'a': 'Your account automatically reverts to the free plan. Your analysis history is preserved. You can re-subscribe anytime to regain Premium access.',
      },
    ],
    // AI Tools
    [
      {
        'q': 'What is the AI CV Rewriter?',
        'a': 'The AI Rewriter professionally rewrites your entire CV using power verbs, quantified achievements, and ATS-friendly formatting. It never invents facts – missing info is marked with [ADD: ...] placeholders.',
      },
      {
        'q': 'What is the AI Chat feature?',
        'a': 'After analysis, you can chat with an AI that has read your CV and analysis. Ask specific questions like "How do I improve my summary?" or "What keywords am I missing?"',
      },
      {
        'q': 'How does Interview Prep work?',
        'a': 'Enter your target job title and upload your CV. The AI generates 10 personalized interview questions based on YOUR actual experience, with example answers and pro tips.',
      },
      {
        'q': 'How does the Cover Letter Generator work?',
        'a': 'Enter your target job, choose a tone (Professional/Formal/Creative), upload your CV, and get a fully personalized cover letter in seconds.',
      },
      {
        'q': 'Are the salary estimates accurate?',
        'a': 'Salary Insights provides AI-estimated ranges based on your CV, target role, and country. These are estimates based on market data – always verify with current job postings.',
      },
    ],
    // Account
    [
      {
        'q': 'How do I change my language?',
        'a': 'Go to Profile → Language. ShadowCV supports English, Deutsch, and Español. The language change takes effect immediately across the entire app.',
      },
      {
        'q': 'How do I edit my profile?',
        'a': 'Go to Profile → Personal Information. You can update your name, job title, and career goal. This information is used to personalize your AI analysis.',
      },
      {
        'q': 'How do I delete my account?',
        'a': 'Go to Profile → Delete Account. This permanently deletes all your data including analyses, chat history, and your account. This action cannot be undone.',
      },
      {
        'q': 'Is my CV data safe?',
        'a': 'Your CV text is stored securely in Firebase (Google Cloud) and is only used to generate your analysis. We never share your data with third parties.',
      },
      {
        'q': 'Can I use ShadowCV on multiple devices?',
        'a': 'Yes! Your account, analyses, and Premium status sync across all devices. Just log in with the same account.',
      },
    ],
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
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.8),
                radius: 1.5,
                colors: [
                  Colors.deepPurpleAccent.withOpacity(0.1),
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
                  _buildHeroHeader(),
                  _buildCategorySelector(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: _faqs[_selectedCategory].length,
                      itemBuilder: (context, index) {
                        return _buildFaqItem(
                            _faqs[_selectedCategory][index], index);
                      },
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
          const Expanded(
            child: Text(
              'FAQ & Help',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Boldo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurpleAccent.withOpacity(0.25),
            Colors.black.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Colors.deepPurpleAccent.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: Colors.deepPurpleAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Boldo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_faqs.fold(0, (sum, list) => sum + list.length)} answers to common questions',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
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

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == index;
          final color = cat['color'] as Color;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = index;
              _expandedItems.clear();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? color.withOpacity(0.4)
                      : Colors.white.withOpacity(0.06),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? color : Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white38,
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
          );
        },
      ),
    );
  }

  Widget _buildFaqItem(Map<String, String> faq, int index) {
    final isExpanded = _expandedItems.contains(index);
    final categoryColor =
        _categories[_selectedCategory]['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isExpanded
            ? categoryColor.withOpacity(0.05)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? categoryColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() {
            if (isExpanded) {
              _expandedItems.remove(index);
            } else {
              _expandedItems.add(index);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: categoryColor,
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
                        faq['q']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Boldo',
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16, left: 40),
                    child: Text(
                      faq['a']!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontFamily: 'Boldo',
                        height: 1.6,
                      ),
                    ),
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
}