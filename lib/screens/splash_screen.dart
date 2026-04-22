import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shadowcv/services/translation_service.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  // Aurora Hintergrund
  late AnimationController _auroraController;

  // Text
  late AnimationController _textController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  // Particles
  late AnimationController _particleController;

  // Exit
  late AnimationController _exitController;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // Logo Animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Aurora
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Text
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Exit
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _exitFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    // Sequenz starten
    _startSequence();
  }

  Future<void> _startSequence() async {
    // Logo erscheint
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();

    // Text erscheint
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _textController.forward();

    // Exit
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    await _exitController.forward();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _auroraController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _exitFade,
        child: Stack(
          children: [
            // Aurora Hintergrund
            AnimatedBuilder(
              animation: _auroraController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AuroraPainter(progress: _auroraController.value),
                  size: size,
                );
              },
            ),

            // Particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    progress: _particleController.value,
                  ),
                  size: size,
                );
              },
            ),

            // Center Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: _buildLogo(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Text
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: _buildText(),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Indicator
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textFade,
                child: _buildBottomIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _auroraController,
      builder: (context, child) {
        final glow =
            0.4 + (math.sin(_auroraController.value * 2 * math.pi) * 0.2);

        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA855F7).withOpacity(glow),
                blurRadius: 60,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(glow * 0.5),
                blurRadius: 100,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/NewLogo.png',
            width: 100,
            height: 100,
          ),
        );
      },
    );
  }

  Widget _buildText() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFE0E7FF)],
          ).createShader(bounds),
          child: const Text(
            'ShadowCV',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontFamily: 'Boldo',
              color: Colors.white,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppTranslation.t('Uncover Your Hidden Potential'),
          style: TextStyle(
            fontSize: 15,
            fontFamily: 'Boldo',
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomIndicator() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _auroraController,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final delay = i / 3;
                final animValue = (_auroraController.value + delay) % 1.0;
                final opacity = math.sin(animValue * math.pi).clamp(0.2, 1.0);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          AppTranslation.t('AI-Powered Career Suite'),
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Boldo',
            color: Colors.white.withOpacity(0.2),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ==================== AURORA PAINTER ====================

class _AuroraPainter extends CustomPainter {
  final double progress;

  _AuroraPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Aurora Blob 1 - Oben Rechts
    _drawAuroraBlob(
      canvas,
      center: Offset(
        size.width * 0.8 + math.cos(progress * 2 * math.pi) * size.width * 0.1,
        size.height * 0.2 +
            math.sin(progress * 2 * math.pi) * size.height * 0.05,
      ),
      radius: size.width * 0.55,
      color: const Color(0xFF6366F1).withOpacity(0.12),
    );

    // Aurora Blob 2 - Unten Links
    _drawAuroraBlob(
      canvas,
      center: Offset(
        size.width * 0.1 + math.sin(progress * 2 * math.pi) * size.width * 0.08,
        size.height * 0.75 +
            math.cos(progress * 2 * math.pi) * size.height * 0.05,
      ),
      radius: size.width * 0.5,
      color: const Color(0xFFA855F7).withOpacity(0.10),
    );

    // Aurora Blob 3 - Mitte
    _drawAuroraBlob(
      canvas,
      center: Offset(
        size.width * 0.5 +
            math.cos(progress * 2 * math.pi + 1) * size.width * 0.05,
        size.height * 0.45 +
            math.sin(progress * 2 * math.pi + 1) * size.height * 0.05,
      ),
      radius: size.width * 0.4,
      color: const Color(0xFFEC4899).withOpacity(0.06),
    );
  }

  void _drawAuroraBlob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.progress != progress;
}

// ==================== PARTICLE PAINTER ====================

class _ParticlePainter extends CustomPainter {
  final double progress;

  // Feste Partikel-Positionen (damit sie nicht bei jedem Frame neu berechnet werden)
  static final List<_Particle> _particles = List.generate(20, (i) {
    final random = math.Random(i * 42);
    return _Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 1.0 + random.nextDouble() * 2.5,
      speed: 0.2 + random.nextDouble() * 0.6,
      offset: random.nextDouble(),
    );
  });

  _ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final animProgress = (progress * particle.speed + particle.offset) % 1.0;
      final opacity = math.sin(animProgress * math.pi).clamp(0.0, 0.6);

      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double offset;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.offset,
  });
}
