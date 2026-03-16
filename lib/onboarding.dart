// onboarding_screen.dart - Aktualisiert mit Purple/Black/White Theme
import 'package:flutter/material.dart';
import 'loginScreen.dart';

class ShadowCVOnboarding extends StatefulWidget {
  const ShadowCVOnboarding({super.key});

  @override
  State<ShadowCVOnboarding> createState() => _ShadowCVOnboardingState();
}

class _ShadowCVOnboardingState extends State<ShadowCVOnboarding> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<_OnboardingModel> _pages = const [
    _OnboardingModel(
      title: "Why Your Application Fails",
      description:
          "75% of applications are automatically rejected – because of name, age, university, gaps. No one tells you why.",
      icon: Icons.report_problem_rounded,
    ),
    _OnboardingModel(
      title: "ShadowCV Analyzes Your CV",
      description:
          "Upload your CV. AI checks it against 50+ ATS algorithms and shows exactly what needs improvement.",
      icon: Icons.analytics_rounded,
    ),
    _OnboardingModel(
      title: "Optimize & Land Jobs",
      description:
          "Get an AI-optimized CV without changing facts, share your score, and boost your career opportunities.",
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
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
                // PageView
                PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _OnboardingPage(model: page);
                  },
                ),

                // Skip Button
                if (_currentIndex != _pages.length - 1)
                  Positioned(
                    top: 16,
                    right: 24,
                    child: TextButton(
                      onPressed: () {
                        _controller.animateToPage(
                          _pages.length - 1,
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        "Skip",
                        style: TextStyle(
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
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 8,
                        width: _currentIndex == index ? 28 : 8,
                        decoration: BoxDecoration(
                          gradient: _currentIndex == index
                              ? LinearGradient(
                                  colors: [
                                    Colors.deepPurpleAccent,
                                    Colors.purpleAccent,
                                  ],
                                )
                              : null,
                          color: _currentIndex == index ? null : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _currentIndex == index
                              ? [
                                  BoxShadow(
                                    color: Colors.deepPurpleAccent.withOpacity(
                                      0.5,
                                    ),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),

                // CTA Button on last page
                if (_currentIndex == _pages.length - 1)
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurpleAccent,
                            Colors.purpleAccent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.5),
                            blurRadius: 25,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const loginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Get Started",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Boldo',
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
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

  const _OnboardingModel({
    required this.title,
    required this.description,
    required this.icon,
  });
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

          // Icon Container
          Container(
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withOpacity(0.4),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Icon(model.icon, size: 70, color: Colors.white),
          ),

          const SizedBox(height: 50),

          // Title
          Text(
            model.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'Boldo',
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            model.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
              fontFamily: 'Boldo',
              fontWeight: FontWeight.w400,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
