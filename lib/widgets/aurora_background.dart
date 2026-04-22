// lib/widgets/aurora_background.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AuroraMode {
  home,       // Standard Violett
  analyzing,  // Intensiv, schnell
  scoreHigh,  // Grün-Gold
  scoreMid,   // Orange-Violett
  scoreLow,   // Rot-Blau
}

class AuroraBackground extends StatefulWidget {
  final AuroraMode mode;
  final Widget child;

  const AuroraBackground({
    super.key,
    required this.mode,
    required this.child,
  });

  // Hilfsmethode: Score -> Mode
  static AuroraMode fromScore(int score) {
    if (score >= 75) return AuroraMode.scoreHigh;
    if (score >= 50) return AuroraMode.scoreMid;
    return AuroraMode.scoreLow;
  }

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with TickerProviderStateMixin {
  late AnimationController _auroraController;
  late AnimationController _colorController;
  late Animation<double> _colorAnimation;

  AuroraMode _currentMode = AuroraMode.home;
  AuroraMode _previousMode = AuroraMode.home;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
    _previousMode = widget.mode;

    _auroraController = AnimationController(
      vsync: this,
      duration: _getDuration(widget.mode),
    )..repeat();

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _colorAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AuroraBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _previousMode = _currentMode;
      _currentMode = widget.mode;

      // Geschwindigkeit anpassen
      _auroraController.duration = _getDuration(widget.mode);
      _auroraController.repeat();

      // Farb-Übergang animieren
      _colorController.forward(from: 0);
    }
  }

  Duration _getDuration(AuroraMode mode) {
    switch (mode) {
      case AuroraMode.analyzing:
        return const Duration(seconds: 3); // Schnell
      case AuroraMode.scoreHigh:
        return const Duration(seconds: 12); // Langsam, ruhig
      case AuroraMode.scoreLow:
        return const Duration(seconds: 6); // Mittel
      default:
        return const Duration(seconds: 10); // Standard
    }
  }

  List<Color> _getColors(AuroraMode mode) {
    switch (mode) {
      case AuroraMode.analyzing:
        return [
          const Color(0xFF7C3AED), // Violett
          const Color(0xFF4F46E5), // Indigo
          const Color(0xFF2563EB), // Blau
        ];
      case AuroraMode.scoreHigh:
        return [
          const Color(0xFF16A34A), // Grün
          const Color(0xFFCA8A04), // Gold
          const Color(0xFF7C3AED), // Violett
        ];
      case AuroraMode.scoreMid:
        return [
          const Color(0xFFD97706), // Orange
          const Color(0xFF7C3AED), // Violett
          const Color(0xFFDB2777), // Pink
        ];
      case AuroraMode.scoreLow:
        return [
          const Color(0xFFDC2626), // Rot
          const Color(0xFF1D4ED8), // Blau
          const Color(0xFF7C3AED), // Violett
        ];
      default: // home
        return [
          const Color(0xFF7C3AED), // Violett
          const Color(0xFF9333EA), // Lila
          const Color(0xFFDB2777), // Pink
        ];
    }
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Aurora Layer
        AnimatedBuilder(
          animation: Listenable.merge([_auroraController, _colorController]),
          builder: (context, child) {
            final currentColors = _getColors(_currentMode);
            final previousColors = _getColors(_previousMode);

            // Interpoliere zwischen alten und neuen Farben
            final t = _colorAnimation.value;
            final blendedColors = List.generate(
              currentColors.length,
              (i) => Color.lerp(previousColors[i], currentColors[i], t)!,
            );

            return CustomPaint(
              painter: _AuroraBackgroundPainter(
                progress: _auroraController.value,
                colors: blendedColors,
                intensity: _currentMode == AuroraMode.analyzing ? 0.25 : 0.15,
              ),
              size: MediaQuery.of(context).size,
            );
          },
        ),

        // Content
        widget.child,
      ],
    );
  }
}

// ==================== PAINTER ====================

class _AuroraBackgroundPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final double intensity;

  _AuroraBackgroundPainter({
    required this.progress,
    required this.colors,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Blob 1 - Oben Rechts
    _drawBlob(
      canvas,
      center: Offset(
        size.width * 0.85 +
            math.cos(progress * 2 * math.pi) * size.width * 0.1,
        size.height * 0.15 +
            math.sin(progress * 2 * math.pi) * size.height * 0.08,
      ),
      radius: size.width * 0.6,
      color: colors[0].withOpacity(intensity),
    );

    // Blob 2 - Unten Links
    _drawBlob(
      canvas,
      center: Offset(
        size.width * 0.1 +
            math.sin(progress * 2 * math.pi + 1) * size.width * 0.08,
        size.height * 0.8 +
            math.cos(progress * 2 * math.pi + 1) * size.height * 0.06,
      ),
      radius: size.width * 0.55,
      color: colors[1].withOpacity(intensity * 0.8),
    );

    // Blob 3 - Mitte (subtil)
    _drawBlob(
      canvas,
      center: Offset(
        size.width * 0.5 +
            math.cos(progress * 2 * math.pi + 2) * size.width * 0.12,
        size.height * 0.5 +
            math.sin(progress * 2 * math.pi + 2) * size.height * 0.08,
      ),
      radius: size.width * 0.4,
      color: colors[2].withOpacity(intensity * 0.5),
    );
  }

  void _drawBlob(
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
  bool shouldRepaint(_AuroraBackgroundPainter old) =>
      old.progress != progress ||
      old.colors != colors ||
      old.intensity != intensity;
}