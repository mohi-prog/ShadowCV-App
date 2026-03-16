import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'package:shadowcv/profile_screen.dart';
import 'package:shadowcv/cv_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String userName = '';
  bool showWelcome = false;
  bool isNewUser = false;

  // ─── Loading State ────────────────────────────────────────────────────────
  bool _isAnalyzing = false;
  int _currentStep = 0;
  late AnimationController _loadingFadeController;
  late Animation<double> _loadingFadeAnimation;

  final List<_AnalysisStep> _steps = [
    _AnalysisStep(
      icon: Icons.picture_as_pdf_rounded,
      label: 'Reading CV',
      sublabel: 'Extracting text...',
    ),
    _AnalysisStep(
      icon: Icons.cloud_upload_outlined,
      label: 'Uploading',
      sublabel: 'Secure cloud storage...',
    ),
    _AnalysisStep(
      icon: Icons.psychology_rounded,
      label: 'AI Analysis',
      sublabel: 'Detecting bias...',
    ),
    _AnalysisStep(
      icon: Icons.fact_check_rounded,
      label: 'Saving',
      sublabel: 'Almost done...',
    ),
  ];

  // ─── Animation Controllers ────────────────────────────────────────────────
  late AnimationController _welcomeController;
  late AnimationController _contentController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _welcomeOpacity;
  late Animation<Offset> _welcomeSlide;
  late Animation<double> _contentFade;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkAndShowWelcome();
    _checkPickerRecovery(); // Zuerst Recovery prüfen
    _checkLoadingState();

    _loadingFadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingFadeController, curve: Curves.easeInOut),
    );

    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _welcomeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeOut),
    );
    _welcomeSlide =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _welcomeController, curve: Curves.easeOut),
        );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentController.forward();

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    _contentController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _loadingFadeController.dispose();
    super.dispose();
  }

  void _startLoadingAnimations() {
    _rotateController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _stopLoadingAnimations() {
    _rotateController.stop();
    _pulseController.stop();
  }

  Future<void> _setStep(int step, {int duration = 300}) async {
    if (!mounted) return;
    setState(() => _currentStep = step);
    await Future.delayed(Duration(milliseconds: duration));
  }

  Future<void> _checkPickerRecovery() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingType = prefs.getString('picker_pending');

    if (pendingType != null) {
      debugPrint('DEBUG: Picker Recovery erkannt: $pendingType');
      // Clear flag
      await prefs.remove('picker_pending');

      // Prüfe ob Firestore ein neues File hat
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Zeige Loading sofort
        setState(() {
          _isAnalyzing = true;
          _currentStep = 0;
        });
        _startLoadingAnimations();
        _runSimulation();
      }
    }
  }

  Future<void> _checkLoadingState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isAnalyzing'] == true) {
        if (mounted) {
          setState(() {
            _isAnalyzing = true;
            _currentStep = 0;
          });
          _loadingFadeController.forward();
          _startLoadingAnimations();
          _runSimulation();
        }
      }
    }
  }

  Future<void> _updatePersistentLoading(bool active) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'isAnalyzing': active,
    }, SetOptions(merge: true));
  }

  Future<void> _checkAndShowWelcome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (prefs.exists) {
      final data = prefs.data() as Map<String, dynamic>;
      userName = data['name'] ?? 'User';

      final lastSeen = data['lastSeen'] as Timestamp?;
      final now = DateTime.now();
      bool shouldShowWelcome = false;

      if (lastSeen == null) {
        shouldShowWelcome = true;
        isNewUser = true;
      } else {
        final lastSeenDate = lastSeen.toDate();
        if (now.difference(lastSeenDate).inHours >= 1) {
          shouldShowWelcome = true;
          isNewUser = false;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'lastSeen': FieldValue.serverTimestamp()},
      );

      if (shouldShowWelcome && mounted) {
        setState(() => showWelcome = true);
        _welcomeController.forward();
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            _welcomeController.reverse().then((_) {
              if (mounted) setState(() => showWelcome = false);
            });
          }
        });
      }
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          top: 12,
          left: 24,
          right: 24,
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
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: Colors.deepPurpleAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CV hochladen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Boldo',
                      ),
                    ),
                    Text(
                      'Wähle eine Option',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.4),
                        fontFamily: 'Boldo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildUploadOption(
              icon: Icons.picture_as_pdf_rounded,
              title: 'PDF aus Dateien',
              subtitle: 'Wähle eine PDF-Datei aus',
              color: Colors.redAccent,
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 300));
                await _startAnalysis();
              },
            ),
            const SizedBox(height: 12),
            _buildUploadOption(
              icon: Icons.photo_library_rounded,
              title: 'Aus Galerie',
              subtitle: 'Bis zu 3 Fotos auswählen',
              color: Colors.greenAccent,
              onTap: () async {
                Navigator.pop(context);
                await _startGalleryAnalysis();
              },
            ),
            const SizedBox(height: 12),
            _buildUploadOption(
              icon: Icons.cloud_upload_outlined,
              title: 'Aus Google Drive',
              subtitle: 'Kommt bald',
              color: Colors.blueAccent,
              isDisabled: true,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildUploadOption(
              icon: Icons.description_outlined,
              title: 'Word Dokument',
              subtitle: 'Kommt bald',
              color: Colors.deepPurpleAccent,
              isDisabled: true,
              onTap: () {},
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _startAnalysis() async {
    debugPrint('DEBUG: _startAnalysis gestartet');
    if (!mounted) return;

    // Set picker pending flag BEFORE launching picker (Xiaomi recovery)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('picker_pending', 'pdf');
    debugPrint('DEBUG: picker_pending flag gesetzt');

    try {
      final file = await CVService.pickPDF();
      debugPrint('DEBUG: pickPDF result: $file');

      // Clear flag after picker returns
      await prefs.remove('picker_pending');

      if (file == null) {
        debugPrint('DEBUG: Kein File ausgewählt');
        return;
      }

      if (!mounted) return;

      debugPrint('DEBUG: Zeige Loading UI');

      // 1. Zuerst State setzen
      setState(() {
        _isAnalyzing = true;
        _currentStep = 0;
      });

      // 2. Persistenz setzen (wichtig für Recovery)
      await _updatePersistentLoading(true);

      // 3. Animation starten
      _startLoadingAnimations();
      debugPrint('DEBUG: Animationen gestartet');

      debugPrint('DEBUG: Starte Simulation');
      _runSimulation();
    } catch (e) {
      await prefs.remove('picker_pending');
      debugPrint('DEBUG: FEHLER in _startAnalysis: $e');
      if (mounted) {
        _stopLoadingAnimations();
        _loadingFadeController.reverse().then((_) {
          if (mounted) setState(() => _isAnalyzing = false);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      await _updatePersistentLoading(false);
    }
  }

  Future<void> _startGalleryAnalysis() async {
    debugPrint('DEBUG: _startGalleryAnalysis gestartet');
    if (!mounted) return;

    // Set picker pending flag BEFORE launching picker (Xiaomi recovery)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('picker_pending', 'gallery');
    debugPrint('DEBUG: picker_pending flag gesetzt');

    try {
      final files = await CVService.pickFromGallery();
      debugPrint('DEBUG: pickFromGallery result: ${files.length} files');

      // Clear flag after picker returns
      await prefs.remove('picker_pending');

      if (files.isEmpty) {
        debugPrint('DEBUG: Kein File ausgewählt');
        return;
      }

      if (!mounted) return;

      debugPrint('DEBUG: Zeige Loading UI');

      setState(() {
        _isAnalyzing = true;
        _currentStep = 0;
      });

      await _updatePersistentLoading(true);

      _startLoadingAnimations();
      debugPrint('DEBUG: Animationen gestartet');

      _runSimulation(isGallery: true);
    } catch (e) {
      await prefs.remove('picker_pending');
      debugPrint('DEBUG: FEHLER in _startGalleryAnalysis: $e');
      if (mounted) {
        _stopLoadingAnimations();
        _loadingFadeController.reverse().then((_) {
          if (mounted) setState(() => _isAnalyzing = false);
        });
      }
      await _updatePersistentLoading(false);
    }
  }

  Future<void> _runSimulation({bool isGallery = false}) async {
    final simulationSteps = isGallery
        ? [
            'Bilder werden verarbeitet',
            'Texterkennung (OCR)',
            'KI Analyse',
            'Speichern',
          ]
        : [
            'Step 0: Text extrahieren',
            'Step 1: Uploading',
            'Step 2: KI Analyse',
            'Step 3: Speichern',
          ];

    try {
      for (int i = 0; i < simulationSteps.length; i++) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) break;
        await _setStep(i, duration: 1200);
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _stopLoadingAnimations();
          await _updatePersistentLoading(false);
          _loadingFadeController.reverse().then((_) {
            if (mounted) {
              setState(() => _isAnalyzing = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isGallery
                        ? 'Bild-Erkennung erfolgreich simuliert!'
                        : 'PDF-Analyse erfolgreich simuliert!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _stopLoadingAnimations();
        _loadingFadeController.reverse().then((_) {
          if (mounted) setState(() => _isAnalyzing = false);
        });
        await _updatePersistentLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: build() aufgerufen, _isAnalyzing=$_isAnalyzing');
    return PopScope(
      canPop: !_isAnalyzing,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 1.5,
                  colors: [
                    Colors.deepPurpleAccent.withOpacity(0.08),
                    Colors.black,
                    Colors.black,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _contentFade,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ShadowCV',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'Boldo',
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Professional CV Analysis',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.5),
                                  fontFamily: 'Boldo',
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            ),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildUploadCard(),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Boldo',
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureCard(
                              icon: Icons.history_rounded,
                              title: 'My Analyses',
                              subtitle: 'View past CV scans',
                              onTap: () {},
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureCard(
                              icon: Icons.auto_awesome_rounded,
                              title: 'AI Optimizer',
                              subtitle: 'Get AI-powered CV improvements',
                              isPremium: true,
                              onTap: () {},
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureCard(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'Chat with AI',
                              subtitle: 'Ask questions about your CV',
                              isPremium: true,
                              onTap: () {},
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureCard(
                              icon: Icons.workspace_premium_rounded,
                              title: 'Upgrade to Premium',
                              subtitle: 'Unlock all features - €19.99',
                              isSpecial: true,
                              onTap: () {},
                            ),
                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showWelcome)
              Positioned(
                top: 120,
                left: 24,
                right: 24,
                child: SlideTransition(
                  position: _welcomeSlide,
                  child: FadeTransition(
                    opacity: _welcomeOpacity,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isNewUser
                                  ? Icons.celebration_rounded
                                  : Icons.waving_hand_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isNewUser
                                      ? 'Welcome, $userName!'
                                      : 'Welcome back, $userName!',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'Boldo',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isNewUser
                                      ? "Let's optimize your career together"
                                      : 'Ready to enhance your CV?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.95),
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
              ),
            if (_isAnalyzing) Positioned.fill(child: _buildLoadingOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.2,
          colors: [
            Colors.deepPurpleAccent.withOpacity(0.15),
            Colors.black,
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated progress ring
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.deepPurpleAccent.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: (_currentStep + 1) / _steps.length,
                              strokeWidth: 3,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.deepPurpleAccent,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.deepPurpleAccent.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.deepPurpleAccent.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                _steps[_currentStep].icon,
                                key: ValueKey(_currentStep),
                                color: Colors.deepPurpleAccent,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                // Step title
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _steps[_currentStep].label,
                    key: ValueKey('title_$_currentStep'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Boldo',
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Step subtitle
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _steps[_currentStep].sublabel,
                    key: ValueKey('sublabel_$_currentStep'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: 'Boldo',
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Step indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (index) {
                    final isDone = index < _currentStep;
                    final isCurrent = index == _currentStep;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isCurrent ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.deepPurpleAccent.withOpacity(0.5)
                            : isCurrent
                            ? Colors.deepPurpleAccent
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                // Progress text
                Text(
                  'Step ${_currentStep + 1} of ${_steps.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.3),
                    fontFamily: 'Boldo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurpleAccent, Colors.deepPurpleAccent.shade700],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUploadOptions(),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analyze Your CV',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Boldo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload & discover hidden biases',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontFamily: 'Boldo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Boldo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                            fontFamily: 'Boldo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isDisabled)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.3),
                      size: 14,
                    ),
                  if (isDisabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Bald',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.3),
                          fontFamily: 'Boldo',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isPremium = false,
    bool isSpecial = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSpecial
            ? Colors.deepPurpleAccent.withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSpecial
              ? Colors.deepPurpleAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSpecial
                        ? Colors.deepPurpleAccent.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isSpecial ? Colors.deepPurpleAccent : Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Boldo',
                            ),
                          ),
                          if (isPremium) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.4),
                          fontFamily: 'Boldo',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.2),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisStep {
  final IconData icon;
  final String label;
  final String sublabel;

  _AnalysisStep({
    required this.icon,
    required this.label,
    required this.sublabel,
  });
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double arcLength;

  _ArcPainter({
    required this.color,
    required this.strokeWidth,
    this.arcLength = 0.7,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0,
      arcLength * 2 * pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
