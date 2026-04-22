import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shadowcv/services/translation_service.dart'; // <-- IMPORT
import 'home_screen.dart';

class Kennlernphase extends StatefulWidget {
  const Kennlernphase({super.key});

  @override
  State<Kennlernphase> createState() => _KennlernphaseState();
}

class _KennlernphaseState extends State<Kennlernphase>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController jobController = TextEditingController();
  String selectedGoal = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Ziele werden direkt übersetzt angezeigt
  final List<String> goalsKeys = [
    'Find a new job',
    'Improve my CV',
    'Career change',
    'Get promotions',
    'Just exploring',
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
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    nameController.dispose();
    jobController.dispose();
    super.dispose();
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _animController.reset();
        _animController.forward();
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }
    if (_currentStep == 1 && jobController.text.trim().isEmpty) {
      _showError('Please enter your job title');
      return;
    }
    if (_currentStep == 2 && selectedGoal.isEmpty) {
      _showError('Please select a goal');
      return;
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
        _animController.reset();
        _animController.forward();
      });
    } else {
      _saveUserData();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.redAccent,
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Boldo',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // WICHTIG: Die Sprache in Firestore initial setzen!
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': nameController.text.trim(),
        'jobTitle': jobController.text.trim(),
        'goal': selectedGoal, // Wird auf Englisch gespeichert (besser für KI)
        'language': AppTranslation
            .currentLang, // <-- App weiß sofort, welche Sprache wir nutzen
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    } catch (e) {
      _showError('Failed to save data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_currentStep > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _previousStep,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 60),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(4, (index) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 4,
                              decoration: BoxDecoration(
                                color: index <= _currentStep
                                    ? Colors.deepPurpleAccent
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 60),
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildStepContent(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildNextButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildJobStep();
      case 2:
        return _buildGoalStep();
      case 3:
        return _buildMotivationStep();
      default:
        return Container();
    }
  }

  Widget _buildNameStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            AppTranslation.t("What's your name?"),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'Boldo',
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppTranslation.t('Let us get to know you better'),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Boldo',
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TextField(
              controller: nameController,
              textAlign: TextAlign.center,
              cursorColor: Colors.deepPurpleAccent,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'Boldo',
                color: Colors.white,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                hintText: AppTranslation.t('Enter your name'),
                hintStyle: const TextStyle(
                  color: Colors.white30,
                  fontSize: 18,
                  fontFamily: 'Boldo',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Colors.deepPurpleAccent,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(
              Icons.work_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            AppTranslation.t("What's your job title?"),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'Boldo',
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppTranslation.t('This helps us personalize your experience'),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Boldo',
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TextField(
              controller: jobController,
              textAlign: TextAlign.center,
              cursorColor: Colors.deepPurpleAccent,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'Boldo',
                color: Colors.white,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                hintText: AppTranslation.t('e.g. Software Developer'),
                hintStyle: const TextStyle(
                  color: Colors.white30,
                  fontSize: 18,
                  fontFamily: 'Boldo',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Colors.deepPurpleAccent,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            AppTranslation.t("What's your goal?"),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'Boldo',
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            AppTranslation.t('Choose what you want to achieve'),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Boldo',
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ...goalsKeys.map((goalKey) {
            final isSelected = selectedGoal == goalKey;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => setState(() => selectedGoal = goalKey),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [
                              Colors.deepPurpleAccent,
                              Colors.purpleAccent,
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.deepPurpleAccent.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        AppTranslation.t(goalKey),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontFamily: 'Boldo',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMotivationStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withOpacity(0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 50),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.deepPurpleAccent.shade100],
            ).createShader(bounds),
            child: Text(
              "${AppTranslation.t("You're all set,")} ${nameController.text}!",
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                fontFamily: 'Boldo',
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppTranslation.t(
                "Together with ShadowCV, you'll uncover hidden opportunities and land your dream job. Let's make it happen! 🚀",
              ),
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Boldo',
                color: Colors.white70,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.deepPurpleAccent.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.person_rounded,
                  AppTranslation.t('Name'),
                  nameController.text,
                ),
                const Divider(color: Colors.white10, height: 32),
                _buildInfoRow(
                  Icons.work_rounded,
                  AppTranslation.t('Job'),
                  jobController.text,
                ),
                const Divider(color: Colors.white10, height: 32),
                _buildInfoRow(
                  Icons.rocket_launch_rounded,
                  AppTranslation.t('Goal'),
                  AppTranslation.t(selectedGoal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurpleAccent.withOpacity(0.2),
                Colors.purpleAccent.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.deepPurpleAccent, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
                fontFamily: 'Boldo',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Boldo',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.5),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentStep == 3
                  ? AppTranslation.t("Let's Go!")
                  : AppTranslation.t('Continue'),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontFamily: 'Boldo',
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              _currentStep == 3
                  ? Icons.rocket_launch_rounded
                  : Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
