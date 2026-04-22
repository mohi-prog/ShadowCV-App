import 'package:flutter/material.dart';
import 'package:shadowcv/services/translation_service.dart'; // <-- IMPORT
import 'loginScreen.dart';

class ShadowCVOnboarding extends StatefulWidget {
  const ShadowCVOnboarding({super.key});

  @override
  State<ShadowCVOnboarding> createState() => _ShadowCVOnboardingState();
}

class _ShadowCVOnboardingState extends State<ShadowCVOnboarding> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<String> availableLanguages = ['English', 'Deutsch', 'Español'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Sprach-Auswahl Bottom Sheet ---
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppTranslation.t('Select Language'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Boldo',
              ),
            ),
            const SizedBox(height: 16),
            ...availableLanguages.map((lang) {
              final isSelected = lang == AppTranslation.currentLang;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      Navigator.pop(context);
                      await AppTranslation.setLanguage(lang); // Speichern
                      setState(() {}); // Screen sofort neu laden!
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.deepPurpleAccent.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lang,
                              style: TextStyle(
                                color: isSelected ? Colors.deepPurpleAccent : Colors.white,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 15,
                                fontFamily: 'Boldo',
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: Colors.deepPurpleAccent, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Die Seiten müssen in der build-Methode stehen, damit sie bei Sprachwechsel übersetzt werden!
    final List<_OnboardingModel> pages = [
      _OnboardingModel(
        title: AppTranslation.t("Why Your Application Fails"),
        description: AppTranslation.t("75% of applications are automatically rejected – because of name, age, university, gaps. No one tells you why."),
        icon: Icons.report_problem_rounded,
      ),
      _OnboardingModel(
        title: AppTranslation.t("ShadowCV Analyzes Your CV"),
        description: AppTranslation.t("Upload your CV. AI checks it against 50+ ATS algorithms and shows exactly what needs improvement."),
        icon: Icons.analytics_rounded,
      ),
      _OnboardingModel(
        title: AppTranslation.t("Optimize & Land Jobs"),
        description: AppTranslation.t("Get an AI-optimized CV without changing facts, share your score, and boost your career opportunities."),
        icon: Icons.workspace_premium_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0xFF1A1A2E), Colors.black],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) => _OnboardingPage(model: pages[index]),
                ),

                // --- NEU: Sprach-Auswahl Button (Oben Links) ---
                Positioned(
                  top: 16,
                  left: 24,
                  child: InkWell(
                    onTap: _showLanguagePicker,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            AppTranslation.currentLang.substring(0, 2).toUpperCase(), // Zeigt "EN", "DE", "ES"
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Boldo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Skip Button (Oben Rechts)
                if (_currentIndex != pages.length - 1)
                  Positioned(
                    top: 16,
                    right: 24,
                    child: TextButton(
                      onPressed: () {
                        _controller.animateToPage(
                          pages.length - 1,
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        AppTranslation.t("Skip"),
                        style: const TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Boldo',
                        ),
                      ),
                    ),
                  ),

                // Dots Indicator
                Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 8,
                        width: _currentIndex == index ? 28 : 8,
                        decoration: BoxDecoration(
                          gradient: _currentIndex == index
                              ? const LinearGradient(colors: [Colors.deepPurpleAccent, Colors.purpleAccent])
                              : null,
                          color: _currentIndex == index ? null : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _currentIndex == index
                              ? [BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),

                // CTA Button (Starten)
                if (_currentIndex == pages.length - 1)
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.deepPurpleAccent, Colors.purpleAccent]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.5), blurRadius: 25, offset: const Offset(0, 12))],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const loginScreen()),
                            (route) => false,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppTranslation.t("Get Started"),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Boldo',
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingModel {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardingModel({required this.title, required this.description, required this.icon});
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingModel model;
  const _OnboardingPage({required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Colors.deepPurpleAccent, Colors.purpleAccent]),
              boxShadow: [BoxShadow(color: Colors.deepPurpleAccent.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 15))],
            ),
            child: Icon(model.icon, size: 70, color: Colors.white),
          ),
          const SizedBox(height: 50),
          Text(
            model.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Boldo', letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          Text(
            model.description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6, fontFamily: 'Boldo', fontWeight: FontWeight.w400),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}