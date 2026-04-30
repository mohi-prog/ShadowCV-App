// home_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadowcv/widgets/daily_tip_card.dart';
import 'package:shadowcv/screens/analysis_mode_screen.dart';
import 'package:shadowcv/screens/analysis_result_screen.dart';
import 'package:shadowcv/screens/cover_letter_screen.dart';
import 'package:shadowcv/screens/cv_chat_screen.dart';
import 'package:shadowcv/screens/interview_prep_screen.dart';
import 'package:shadowcv/screens/my_analyses_screen.dart';
import 'package:shadowcv/screens/premium_screen.dart';
import 'package:shadowcv/screens/profile_screen.dart';
import 'package:shadowcv/screens/rewrite_result_screen.dart';
import 'package:shadowcv/screens/salary_insights_screen.dart';
import 'package:shadowcv/services/cv_service.dart';
import 'package:shadowcv/services/gemini_analysis_service.dart';
import 'package:shadowcv/services/premium_service.dart';
import 'package:shadowcv/services/translation_service.dart';
import 'package:shadowcv/services/app_config.dart';
import 'package:uuid/uuid.dart';
import 'package:shadowcv/widgets/aurora_background.dart';

enum UploadSource { pdf, gallery, drive }

class UploadResult {
  final String text;
  final String fileName;
  final UploadSource source;

  const UploadResult({
    required this.text,
    required this.fileName,
    required this.source,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  String userName = '';
  bool showWelcome = false;
  bool isNewUser = false;
  Map<String, dynamic>? _lastAnalysis;
  bool _isAnalyzing = false;
  int _currentStep = 0;
  bool _isPremium = false;
  int _remainingAnalyses = 3;

  List<_AnalysisStep> get _steps => [
    _AnalysisStep(
      Icons.picture_as_pdf_rounded,
      AppTranslation.t('Reading'),
      AppTranslation.t('Thinking...'),
    ),
    _AnalysisStep(
      Icons.cloud_upload_outlined,
      AppTranslation.t('Sending to AI'),
      AppTranslation.t('Secure cloud storage...'),
    ),
    _AnalysisStep(
      Icons.psychology_rounded,
      AppTranslation.t('AI Analysis'),
      AppTranslation.t('Analyzing...'),
    ),
    _AnalysisStep(
      Icons.fact_check_rounded,
      AppTranslation.t('Saving'),
      AppTranslation.t('Almost done...'),
    ),
  ];

  late AnimationController _loadingFadeController;
  late Animation<double> _loadingFadeAnimation;
  late AnimationController _welcomeController;
  late AnimationController _contentController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _welcomeOpacity;
  late Animation<double> _contentFade;
  late AnimationController _auroraController;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then(
      (prefs) => prefs.remove('awaiting_pdf_pick'),
    );

    _auroraController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

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

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _contentController.forward();

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWelcome();
      _checkLoadingState();
      _loadLastAnalysis();
      _loadPremiumStatus();
    });
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _welcomeController.dispose();
    _contentController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _loadingFadeController.dispose();
    super.dispose();
  }

  // ==================== DATA & STATE ====================

  Future<void> _loadLastAnalysis() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cvs')
          .where('isCV', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty && mounted) {
        setState(() => _lastAnalysis = snap.docs.first.data());
      }
    } catch (_) {}
  }

  Future<Map<String, String?>> _getUserContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return {};
    final data = doc.data() as Map<String, dynamic>;
    return {
      'userJob': data['job'] ?? data['jobTitle'],
      'userGoal': data['goal'],
      'language': data['language'] ?? AppTranslation.currentLang,
    };
  }

  Future<void> _checkLoadingState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists &&
        (doc.data() as Map<String, dynamic>)['isAnalyzing'] == true) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = true;
        _currentStep = 0;
      });
      _loadingFadeController.forward();
      _rotateController.repeat();
    }
  }

  Future<void> _updatePersistentLoading(bool active) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'isAnalyzing': active,
    }, SetOptions(merge: true));
  }

  Future<void> _setStep(int step, {int duration = 300}) async {
    if (!mounted) return;
    setState(() => _currentStep = step);
    await Future.delayed(Duration(milliseconds: duration));
  }

  // ==================== WELCOME ====================

  Future<void> _checkAndShowWelcome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    userName = data['name'] ?? 'User';

    if (data['language'] != null &&
        data['language'] != AppTranslation.currentLang) {
      AppTranslation.currentLang = data['language'];
      await AppTranslation.setLanguage(data['language']);
      if (mounted) setState(() {});
    }

    final lastSeen = data['lastSeen'] as Timestamp?;
    bool shouldShowWelcome = false;

    if (lastSeen == null) {
      shouldShowWelcome = true;
      isNewUser = true;
    } else if (DateTime.now().difference(lastSeen.toDate()).inHours >= 1) {
      shouldShowWelcome = true;
      isNewUser = false;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });

    if (shouldShowWelcome && mounted) {
      setState(() => showWelcome = true);
      _welcomeController.forward();
      Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        _welcomeController.reverse().then((_) {
          if (mounted) setState(() => showWelcome = false);
        });
      });
    }
  }

  // ==================== UPLOAD SOURCE SHEET ====================

  Future<UploadSource?> _showUploadSourceSheet() async {
    UploadSource? selected;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F).withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: Colors.deepPurpleAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslation.t('Upload CV'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Boldo',
                        ),
                      ),
                      Text(
                        AppTranslation.t('Choose an option'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.5),
                          fontFamily: 'Boldo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildUploadOption(
                icon: Icons.picture_as_pdf_rounded,
                title: AppTranslation.t('PDF from files'),
                subtitle: AppTranslation.t('Select a PDF file'),
                color: Colors.redAccent,
                onTap: () {
                  selected = UploadSource.pdf;
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _buildUploadOption(
                icon: Icons.photo_library_rounded,
                title: AppTranslation.t('From Gallery'),
                subtitle: AppTranslation.t('Select a CV photo'),
                color: Colors.deepPurpleAccent,
                badge: 'AI Scan',
                onTap: () {
                  selected = UploadSource.gallery;
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _buildUploadOption(
                icon: Icons.add_to_drive_rounded,
                title: AppTranslation.t('From Google Drive'),
                subtitle: AppTranslation.t('Import from Drive'),
                color: Colors.blueAccent,
                onTap: () {
                  selected = UploadSource.drive;
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppTranslation.t(
                          'Your CV is processed securely and never shared.',
                        ),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12,
                          fontFamily: 'Boldo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );

    return selected;
  }

  Future<UploadResult?> _pickTextForSource(UploadSource source) async {
    if (source == UploadSource.pdf) {
      final file = await CVService.pickPDF();
      if (file == null) return null;
      final text = await CVService.extractTextFromPDF(file);
      return UploadResult(text: text, fileName: file.name, source: source);
    }

    if (source == UploadSource.drive) {
      final file = await CVService.pickFromGoogleDrive();
      if (file == null) return null;

      String text = '';
      if (file.bytes != null) {
        text = await CVService.extractTextFromBytes(file.bytes!);
      } else if (file.path != null) {
        text = await CVService.extractTextFromPDF(file);
      }
      return UploadResult(text: text, fileName: file.name, source: source);
    }

    // gallery
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2000,
      maxHeight: 2800,
    );
    if (image == null) return null;

    final bytes = await File(image.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    final text = await _extractTextFromImageBase64(base64Image) ?? '';
    if (text.trim().isEmpty) return null;

    final fileName = image.name.isNotEmpty
        ? image.name
        : 'cv_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';

    return UploadResult(text: text, fileName: fileName, source: source);
  }

  Future<String?> _extractTextFromImageBase64(String base64Image) async {
    try {
      const apiKey = AppConfig.groqApiKey;
      const url = AppConfig.groqApiUrl;

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConfig.groqModelVision,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      'Extract ALL text from this CV image exactly as it appears. Preserve structure, bullet points and dates. Return ONLY the extracted text, nothing else.',
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                },
              ],
            },
          ],
          'max_tokens': 4096,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('OCR Error: $e');
      return null;
    }
  }

  // ==================== ACTIONS ====================

  Future<void> _handleHeroAnalyzeTap() async {
    final canAnalyze = await PremiumService.canAnalyze();

    if (!canAnalyze) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      await _loadPremiumStatus();
      return;
    }

    final source = await _showUploadSourceSheet();
    if (source == null || !mounted) return;

    await _startAnalysis(source: source);
  }

  Future<void> _startAnalysis({UploadSource source = UploadSource.pdf}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('awaiting_pdf_pick', true);

    try {
      String text = '';
      String fileName = '';
      dynamic platformFileForUpload;

      if (source == UploadSource.pdf) {
        final file = await CVService.pickPDF();
        await prefs.setBool('awaiting_pdf_pick', false);
        if (file == null || !mounted) return;
        fileName = file.name;
        platformFileForUpload = file;
        text = await CVService.extractTextFromPDF(file);
      } else {
        await prefs.setBool('awaiting_pdf_pick', false);
        final picked = await _pickTextForSource(source);
        if (picked == null || !mounted) return;
        fileName = picked.fileName;
        text = picked.text;
      }

      final modeResult = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisModeScreen(fileName: fileName, rawText: text),
        ),
      );

      if (modeResult == null || !mounted) return;
      final mode = modeResult['mode'] as AnalysisMode;

      final canUseMode = await PremiumService.canUseMode(mode.name);

      if (!canUseMode) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
        await _loadPremiumStatus();
        return;
      }

      setState(() {
        _isAnalyzing = true;
        _currentStep = 0;
      });
      _loadingFadeController.forward();
      _rotateController.repeat();
      await _updatePersistentLoading(true);

      await _setStep(0);
      await _setStep(1);

      String? fileUrl;
      if (source == UploadSource.pdf && platformFileForUpload != null) {
        fileUrl = await CVService.uploadPDFToStorage(platformFileForUpload);
      }

      await Future.delayed(const Duration(milliseconds: 1500));
      await _setStep(2);
      await Future.delayed(const Duration(milliseconds: 1500));

      final ctx = await _getUserContext();
      final result = await GeminiAnalysisService.analyzeCVText(
        text,
        mode: mode,
        targetJob: modeResult['targetJob'],
        customPrompt: modeResult['customPrompt'],
        userJob: ctx['userJob'],
        userGoal: ctx['userGoal'],
        language: ctx['language'],
      );

      await _setStep(3);
      await Future.delayed(const Duration(milliseconds: 1200));

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final id = const Uuid().v4();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cvs')
            .doc(id)
            .set({
              'id': id,
              'userId': user.uid,
              'fileName': fileName,
              'fileUrl': fileUrl,
              'rawText': text,
              'isCV': result['isCV'] ?? true,
              'message': result['message'],
              'mode': result['mode'] ?? 'generalReview',
              'score': result['score'] ?? 0,
              'scoreLabel': result['scoreLabel'] ?? 'Unknown',
              'summary': result['summary'] ?? '',
              'strengths': result['strengths'] ?? [],
              'weaknesses': result['weaknesses'] ?? [],
              'suggestions': result['suggestions'] ?? [],
              'topPriorities': result['topPriorities'] ?? [],
              'createdAt': FieldValue.serverTimestamp(),
            });
        await PremiumService.incrementAnalysisCount();
      }

      await _updatePersistentLoading(false);
      _rotateController.stop();

      if (!mounted) return;
      await _loadingFadeController.reverse();
      if (!mounted) return;

      setState(() => _isAnalyzing = false);
      await _loadLastAnalysis();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(result: result, rawText: text),
        ),
      );
    } catch (e) {
      await prefs.setBool('awaiting_pdf_pick', false);
      await _updatePersistentLoading(false);
      _rotateController.stop();
      if (mounted) {
        await _loadingFadeController.reverse();
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslation.t('Error')}: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _loadPremiumStatus() async {
    final premium = await PremiumService.isPremium();
    final remaining = await PremiumService.getRemainingAnalyses();

    if (!mounted) return;

    setState(() {
      _isPremium = premium;
      _remainingAnalyses = remaining;
    });
  }

  Future<void> _startQuickRewrite() async {
    if (!_isPremium) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('awaiting_pdf_pick', true);

    try {
      final file = await CVService.pickPDF();
      await prefs.setBool('awaiting_pdf_pick', false);
      if (file == null || !mounted) return;

      final text = await CVService.extractTextFromPDF(file);
      if (!mounted) return;

      setState(() {
        _isAnalyzing = true;
        _currentStep = 0;
      });
      _loadingFadeController.forward();
      _rotateController.repeat();
      await _updatePersistentLoading(true);

      await _setStep(0, duration: 1000);
      await _setStep(1, duration: 1500);

      final ctx = await _getUserContext();
      final analysis = await GeminiAnalysisService.analyzeCVText(
        text,
        mode: AnalysisMode.generalReview,
        userJob: ctx['userJob'],
        userGoal: ctx['userGoal'],
        language: ctx['language'],
      );

      if (analysis['isCV'] == false) {
        await _updatePersistentLoading(false);
        _rotateController.stop();
        if (mounted) {
          await _loadingFadeController.reverse();
          setState(() => _isAnalyzing = false);

          final id = const Uuid().v4();
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('cvs')
                .doc(id)
                .set({
                  'id': id,
                  'userId': user.uid,
                  'fileName': file.name,
                  'rawText': text,
                  'isCV': false,
                  'message': analysis['message'] ?? '',
                  'documentType': analysis['documentType'] ?? 'Unknown',
                  'mode': 'generalReview',
                  'createdAt': FieldValue.serverTimestamp(),
                });
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AnalysisResultScreen(
                result: {
                  'isCV': false,
                  'message': analysis['message'] ?? '',
                  'documentType': analysis['documentType'] ?? 'Unknown',
                },
                rawText: text,
              ),
            ),
          );
        }
        return;
      }

      await _setStep(2, duration: 1500);

      final rewritten = await GeminiAnalysisService.rewriteCV(
        text,
        analysisResult: analysis,
        userJob: ctx['userJob'],
        userGoal: ctx['userGoal'],
        language: ctx['language'],
      );

      await _setStep(3, duration: 1000);

      final id = const Uuid().v4();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cvs')
            .doc(id)
            .set({
              'id': id,
              'userId': user.uid,
              'fileName': file.name,
              'rawText': text,
              'isCV': true,
              'mode': 'generalReview',
              'score': analysis['score'] ?? 0,
              'scoreLabel': analysis['scoreLabel'] ?? 'Unknown',
              'createdAt': FieldValue.serverTimestamp(),
            });
        await PremiumService.incrementAnalysisCount();
      }

      await _updatePersistentLoading(false);
      _rotateController.stop();

      if (!mounted) return;
      await _loadingFadeController.reverse();
      setState(() => _isAnalyzing = false);
      await _loadLastAnalysis();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RewriteResultScreen(originalText: text, rewrittenText: rewritten),
        ),
      );
    } catch (e) {
      await prefs.setBool('awaiting_pdf_pick', false);
      await _updatePersistentLoading(false);
      _rotateController.stop();
      if (mounted) {
        await _loadingFadeController.reverse();
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslation.t('Error')}: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<String?> _askForCVOption() async {
    String? existingCvText = _lastAnalysis?['rawText'];
    String? existingFileName = _lastAnalysis?['fileName'];

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: SingleChildScrollView(
          child: 
         Column(
          
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslation.t('Enhance with CV?'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'Boldo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslation.t('Adding your CV makes results much more personalized.'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontFamily: 'Boldo',
              ),
            ),
            const SizedBox(height: 24),
            if (existingCvText != null) ...[
              _buildUploadOption(
                icon: Icons.history_rounded,
                title: AppTranslation.t('Use existing CV'),
                subtitle: existingFileName ?? 'Last analyzed CV',
                color: Colors.blueAccent,
                onTap: () => Navigator.pop(context, existingCvText),
              ),
              const SizedBox(height: 12),
            ],
            _buildUploadOption(
              icon: Icons.upload_file_rounded,
              title: AppTranslation.t('Upload new CV'),
              subtitle: AppTranslation.t('Select a PDF or image'),
              color: Colors.deepPurpleAccent,
              onTap: () async {
                final source = await _showUploadSourceSheet();
                if (source != null) {
                  final picked = await _pickTextForSource(source);
                  if (picked != null && mounted) {
                    Navigator.pop(context, picked.text);
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            _buildUploadOption(
              icon: Icons.arrow_forward_rounded,
              title: AppTranslation.t('Continue without CV'),
              subtitle: AppTranslation.t('Use general market data'),
              color: Colors.white38,
              onTap: () => Navigator.pop(context, 'NONE'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ));
  }

  Future<void> _startInterviewPrep() async {
    if (!_isPremium) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      return;
    }

    final input = await _showJobInputDialog();
    if (input == null || !mounted) return;

    final targetJob = input['job'] ?? '';
    if (targetJob.isEmpty) return;

    // Ask for CV (Optional)
    final cvSelection = await _askForCVOption();
    if (cvSelection == null || !mounted) return;
    
    final rawText = cvSelection == 'NONE' ? null : cvSelection;

    setState(() {
      _isAnalyzing = true;
      _currentStep = 0;
    });
    _loadingFadeController.forward();
    _rotateController.repeat();
    await _updatePersistentLoading(true);

    await _setStep(0, duration: 1000);
    await _setStep(1, duration: 1000);
    await _setStep(2, duration: 1500);

    try {
      final ctx = await _getUserContext();
      final result = await GeminiAnalysisService.generateInterviewPrep(
        rawText: rawText,
        targetJob: targetJob,
        experience: input['experience'],
        level: input['level'],
        userJob: ctx['userJob'],
        userGoal: ctx['userGoal'],
        language: ctx['language'],
      );

      await _setStep(3, duration: 1000);
      await _updatePersistentLoading(false);
      _rotateController.stop();

      if (!mounted) return;
      await _loadingFadeController.reverse();
      setState(() => _isAnalyzing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              InterviewPrepScreen(prepResult: result, targetJob: targetJob),
        ),
      );
    } catch (e) {
      await _updatePersistentLoading(false);
      _rotateController.stop();
      if (mounted) {
        await _loadingFadeController.reverse();
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslation.t('Error')}: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _startCoverLetter() async {
    if (!_isPremium) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      return;
    }

    final input = await _showCoverLetterInputDialog();
    if (input == null || !mounted) return;

    final targetJob = input['job'] ?? '';
    final tone = input['tone'] ?? 'Professional';
    if (targetJob.isEmpty) return;

    final source = await _showUploadSourceSheet();
    if (source == null || !mounted) return;

    final picked = await _pickTextForSource(source);
    if (picked == null || !mounted) return;

    final text = picked.text;

    setState(() {
      _isAnalyzing = true;
      _currentStep = 0;
    });
    _loadingFadeController.forward();
    _rotateController.repeat();
    await _updatePersistentLoading(true);

    await _setStep(0, duration: 1000);
    await _setStep(1, duration: 1000);
    await _setStep(2, duration: 1500);

    try {
      final ctx = await _getUserContext();
      final coverLetter = await GeminiAnalysisService.generateCoverLetter(
        rawText: text,
        targetJob: targetJob,
        tone: tone,
        userJob: ctx['userJob'],
        userGoal: ctx['userGoal'],
        language: ctx['language'],
      );

      await _setStep(3, duration: 1000);
      await _updatePersistentLoading(false);
      _rotateController.stop();

      if (!mounted) return;
      await _loadingFadeController.reverse();
      setState(() => _isAnalyzing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CoverLetterScreen(
            coverLetter: coverLetter,
            targetJob: targetJob,
            tone: tone,
          ),
        ),
      );
    } catch (e) {
      await _updatePersistentLoading(false);
      _rotateController.stop();
      if (mounted) {
        await _loadingFadeController.reverse();
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslation.t('Error')}: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _startSalaryInsights() async {
    if (!_isPremium) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      return;
    }

    final input = await _showSalaryInputDialog();
    if (input == null || !mounted) return;

    final targetJob = input['job'] ?? '';
    final country = input['country'] ?? '';
    if (targetJob.isEmpty || country.isEmpty) return;

    // Ask for CV (Optional)
    final cvSelection = await _askForCVOption();
    if (cvSelection == null || !mounted) return;
    
    final rawText = cvSelection == 'NONE' ? null : cvSelection;

    setState(() {
      _isAnalyzing = true;
      _currentStep = 0;
    });
    _loadingFadeController.forward();
    _rotateController.repeat();
    await _updatePersistentLoading(true);

    await _setStep(0, duration: 800);
    await _setStep(1, duration: 1000);
    await _setStep(2, duration: 1200);

    try {
      final ctx = await _getUserContext();
      final result = await GeminiAnalysisService.generateSalaryInsights(
        rawText: rawText,
        targetJob: targetJob,
        country: country,
        experience: input['experience'],
        level: input['level'],
        userJob: ctx['userJob'],
        language: ctx['language'],
      );

      await _setStep(3, duration: 800);
      await _updatePersistentLoading(false);
      _rotateController.stop();

      if (!mounted) return;
      await _loadingFadeController.reverse();
      setState(() => _isAnalyzing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SalaryInsightsScreen(
            insightsResult: result,
            targetJob: targetJob,
            country: country,
          ),
        ),
      );
    } catch (e) {
      await _updatePersistentLoading(false);
      _rotateController.stop();
      if (mounted) {
        await _loadingFadeController.reverse();
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslation.t('Error')}: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _openChat() async {
    if (!_isPremium) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      return;
    }

    final rawText = _lastAnalysis?['rawText'] ?? '';
    final result =
        _lastAnalysis ??
        {
          'mode': 'generalReview',
          'score': 0,
          'isCV': true,
          'strengths': [],
          'weaknesses': [],
          'topPriorities': [],
        };

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CVChatScreen(rawText: rawText, analysisResult: result),
    );
  }

  // ==================== DIALOGS ====================

  Future<Map<String, String>?> _showJobInputDialog() async {
    final controller = TextEditingController();
    final expController = TextEditingController();
    String selectedLevel = 'Mid-Level';
    final levels = ['Junior', 'Mid-Level', 'Senior', 'Lead'];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            AppTranslation.t('Interview Prep'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontFamily: 'Boldo',
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogLabel(AppTranslation.t('Which role are you interviewing for?')),
                const SizedBox(height: 8),
                _buildDialogField(controller, AppTranslation.t('e.g. Senior Flutter Developer'), Colors.deepPurpleAccent),
                const SizedBox(height: 16),
                _buildDialogLabel(AppTranslation.t('Years of Experience')),
                const SizedBox(height: 8),
                _buildDialogField(expController, AppTranslation.t('e.g. 5'), Colors.deepPurpleAccent, isNumber: true),
                const SizedBox(height: 16),
                _buildDialogLabel(AppTranslation.t('Experience Level')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: levels.map((level) {
                    final isSelected = selectedLevel == level;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedLevel = level),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.08)),
                        ),
                        child: Text(
                          AppTranslation.t(level),
                          style: TextStyle(
                            color: isSelected ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                            fontFamily: 'Boldo',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppTranslation.t('Cancel'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'Boldo',
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'job': controller.text.trim(),
                'experience': expController.text.trim(),
                'level': selectedLevel,
              }),
              child: Text(
                AppTranslation.t('Generate'),
                style: const TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>?> _showCoverLetterInputDialog() async {
    final controller = TextEditingController();
    String selectedTone = 'Professional';
    final tones = ['Professional', 'Formal', 'Creative'];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            AppTranslation.t('Cover Letter'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontFamily: 'Boldo',
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslation.t('Target Job Title'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: 'Boldo',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Boldo',
                ),
                decoration: InputDecoration(
                  hintText: AppTranslation.t('e.g. Product Manager at Apple'),
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontFamily: 'Boldo',
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.deepPurpleAccent,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppTranslation.t('Tone'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: 'Boldo',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: tones.map((tone) {
                  final isSelected = selectedTone == tone;
                  Color toneColor;
                  switch (tone) {
                    case 'Professional':
                      toneColor = Colors.deepPurpleAccent;
                      break;
                    case 'Formal':
                      toneColor = Colors.blueAccent;
                      break;
                    case 'Creative':
                      toneColor = Colors.pinkAccent;
                      break;
                    default:
                      toneColor = Colors.deepPurpleAccent;
                  }
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedTone = tone),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? toneColor.withOpacity(0.15)
                              : Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? toneColor
                                : Colors.white.withOpacity(0.08),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          AppTranslation.t(tone),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? toneColor
                                : Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w500,
                            fontFamily: 'Boldo',
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppTranslation.t('Cancel'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'Boldo',
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'job': controller.text.trim(),
                'tone': selectedTone,
              }),
              child: Text(
                AppTranslation.t('Generate'),
                style: const TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>?> _showSalaryInputDialog() async {
    final jobController = TextEditingController();
    final countryController = TextEditingController();
    final expController = TextEditingController();
    String selectedLevel = 'Mid-Level';
    final levels = ['Junior', 'Mid-Level', 'Senior', 'Lead'];

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            AppTranslation.t('Salary Insights'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontFamily: 'Boldo',
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogLabel(AppTranslation.t('Target Job Title')),
                const SizedBox(height: 8),
                _buildDialogField(jobController, AppTranslation.t('e.g. Senior Developer'), Colors.greenAccent),
                const SizedBox(height: 16),
                _buildDialogLabel(AppTranslation.t('Country')),
                const SizedBox(height: 8),
                _buildDialogField(countryController, AppTranslation.t('e.g. Germany'), Colors.greenAccent),
                const SizedBox(height: 16),
                _buildDialogLabel(AppTranslation.t('Years of Experience')),
                const SizedBox(height: 8),
                _buildDialogField(expController, AppTranslation.t('e.g. 5'), Colors.greenAccent, isNumber: true),
                const SizedBox(height: 16),
                _buildDialogLabel(AppTranslation.t('Experience Level')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: levels.map((level) {
                    final isSelected = selectedLevel == level;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedLevel = level),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.greenAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? Colors.greenAccent : Colors.white.withOpacity(0.08)),
                        ),
                        child: Text(
                          AppTranslation.t(level),
                          style: TextStyle(
                            color: isSelected ? Colors.greenAccent : Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                            fontFamily: 'Boldo',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppTranslation.t('Cancel'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'Boldo',
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'job': jobController.text.trim(),
                'country': countryController.text.trim(),
                'experience': expController.text.trim(),
                'level': selectedLevel,
              }),
              child: Text(
                AppTranslation.t('Analyze'),
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Boldo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontFamily: 'Boldo',
        fontSize: 12,
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String hint, Color color, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontFamily: 'Boldo', fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontFamily: 'Boldo',
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: color,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isAnalyzing,
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        floatingActionButton: !_isAnalyzing
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        111,
                        73,
                        215,
                      ).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: _openChat,
                  backgroundColor: Colors.deepPurpleAccent,
                  elevation: 0,
                  icon: Icon(
                    !_isPremium ? Icons.lock_rounded : Icons.psychology_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    !_isPremium
                        ? '${AppTranslation.t('Ask AI')} (PRO)'
                        : AppTranslation.t('Ask AI'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Boldo',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              )
            : null,
        body: AuroraBackground(
          mode: _isAnalyzing ? AuroraMode.analyzing : AuroraMode.home,
          child: Stack(
            children: [
              SafeArea(
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              _buildModernHeroCard(),
                              const SizedBox(height: 24),
                              const DailyTipCard(),
                              const SizedBox(height: 24),
                              if (!_isPremium)
                                _buildSleekRemainingBanner(_remainingAnalyses),
                              if (!_isPremium) const SizedBox(height: 24),
                              Text(
                                AppTranslation.t('Quick Actions'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'Boldo',
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildGlassActionCard(
                                Icons.history_rounded,
                                AppTranslation.t('My Analyses'),
                                AppTranslation.t('View past CV scans'),
                                Colors.blueAccent,
                                () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MyAnalysesScreen(),
                                    ),
                                  );
                                  await _loadLastAnalysis();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildGlassActionCard(
                                Icons.auto_awesome_rounded,
                                AppTranslation.t('AI Optimizer'),
                                AppTranslation.t(
                                  'Get AI-powered CV improvements',
                                ),
                                Colors.pinkAccent,
                                _startQuickRewrite,
                                isPro: !_isPremium,
                              ),
                              const SizedBox(height: 12),
                              _buildGlassActionCard(
                                Icons.record_voice_over_rounded,
                                AppTranslation.t('Interview Prep'),
                                AppTranslation.t(
                                  'AI-powered interview questions',
                                ),
                                Colors.purpleAccent,
                                _startInterviewPrep,
                                isPro: !_isPremium,
                              ),
                              const SizedBox(height: 12),
                              _buildGlassActionCard(
                                Icons.description_rounded,
                                AppTranslation.t('Cover Letter'),
                                AppTranslation.t('AI-generated cover letter'),
                                Colors.orangeAccent,
                                _startCoverLetter,
                                isPro: !_isPremium,
                              ),
                              const SizedBox(height: 12),
                              _buildGlassActionCard(
                                Icons.attach_money_rounded,
                                AppTranslation.t('Salary Insights'),
                                AppTranslation.t(
                                  'AI salary estimation for your profile',
                                ),
                                Colors.greenAccent,
                                _startSalaryInsights,
                                isPro: !_isPremium,
                              ),
                              const SizedBox(height: 12),
                              if (!_isPremium)
                                _buildGlassActionCard(
                                  Icons.workspace_premium_rounded,
                                  AppTranslation.t('Upgrade to Premium'),
                                  AppTranslation.t(
                                    'Unlock all features - €19.99',
                                  ),
                                  const Color(0xFFFFD700),
                                  () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PremiumScreen(),
                                      ),
                                    );
                                  },
                                  isSpecial: true,
                                ),
                              const SizedBox(height: 120),
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
                  top: 100,
                  left: 24,
                  right: 24,
                  child: FadeTransition(
                    opacity: _welcomeOpacity,
                    child: _buildWelcomeBanner(),
                  ),
                ),
              if (_isAnalyzing)
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _loadingFadeAnimation,
                    child: _buildLoadingOverlay(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFE0E7FF)],
                      ).createShader(bounds),
                      child: const Text(
                        'ShadowCV',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Boldo',
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    if (_isPremium) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Boldo',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  AppTranslation.t('Professional CV Analysis'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: 'Boldo',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              await _loadLastAnalysis();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurpleAccent.withOpacity(0.3),
                    Colors.deepPurpleAccent.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.deepPurpleAccent.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Boldo',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeroCard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.015),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFFA855F7),
                  Color(0xFFEC4899),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA855F7).withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleHeroAnalyzeTap,
                borderRadius: BorderRadius.circular(32),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = constraints.maxWidth;
                          final logoSize = maxW < 340 ? 90.0 : 120.0;
                          return Row(
                            children: [
                              Flexible(
                                fit: FlexFit.tight,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Image.asset(
                                      'assets/images/NewLogo.png',
                                      width: logoSize,
                                      height: logoSize,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            AppTranslation.t('AI Ready'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Boldo',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 36),
                      Text(
                        AppTranslation.t('Analyze Your CV'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Boldo',
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppTranslation.t('Upload & get AI-powered feedback'),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: 'Boldo',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSleekRemainingBanner(int remaining) {
    final isLow = remaining <= 1;
    final isEmpty = remaining <= 0;
    final color = isEmpty
        ? const Color(0xFFEF4444)
        : isLow
        ? const Color(0xFFF59E0B)
        : Colors.white.withOpacity(0.6);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  isEmpty
                      ? Icons.lock_rounded
                      : isLow
                      ? Icons.warning_rounded
                      : Icons.bolt_rounded,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEmpty
                        ? AppTranslation.t(
                            'No free analyses left – Upgrade now',
                          )
                        : '${AppTranslation.t('Free analyses remaining')}: $remaining / ${PremiumService.freeAnalysisLimit}',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Boldo',
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withOpacity(0.6),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassActionCard(
    IconData icon,
    String title,
    String subtitle,
    Color glowColor,
    VoidCallback onTap, {
    bool isPro = false,
    bool isSpecial = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isSpecial
                ? glowColor.withOpacity(0.1)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSpecial
                  ? glowColor.withOpacity(0.3)
                  : Colors.white.withOpacity(0.06),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: glowColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withOpacity(0.2),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: glowColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontFamily: 'Boldo',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPro) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.amber,
                                      fontFamily: 'Boldo',
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
                              color: Colors.white.withOpacity(0.5),
                              fontFamily: 'Boldo',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.2),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurpleAccent, Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Boldo',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isNewUser
                          ? '${AppTranslation.t('Welcome, ')}$userName 👋'
                          : '${AppTranslation.t('Welcome back, ')}$userName 👋',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Boldo',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isNewUser
                          ? AppTranslation.t(
                              "Let's optimize your career together",
                            )
                          : AppTranslation.t('Ready to enhance your CV?'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: 'Boldo',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
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
    String? badge,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.3 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Boldo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.deepPurpleAccent,
                                      Color(0xFF9333EA),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'Boldo',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.5),
                            fontFamily: 'Boldo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isDisabled)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.3),
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
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
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: (_currentStep + 1) / _steps.length,
                          strokeWidth: 4,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.deepPurpleAccent,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepPurpleAccent.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.deepPurpleAccent.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _steps[_currentStep].icon,
                            key: ValueKey(_currentStep),
                            color: Colors.deepPurpleAccent,
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _steps[_currentStep].label,
                    key: ValueKey('t_$_currentStep'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Boldo',
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _steps[_currentStep].sublabel,
                    key: ValueKey('s_$_currentStep'),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: 'Boldo',
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (index) {
                    final isDone = index < _currentStep;
                    final isCurrent = index == _currentStep;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isCurrent ? 36 : 8,
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
  _AnalysisStep(this.icon, this.label, this.sublabel);
}
