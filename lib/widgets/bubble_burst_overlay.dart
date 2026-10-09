import 'dart:math';
import 'package:flutter/material.dart';

/// Datos de una partícula individual del estallido
class _BurstParticle {
  final double angle;
  final double distance;
  final double size;
  final Color color;

  _BurstParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });
}

/// Widget animado para la explosión/estallido de una burbuja de jabón completada
class BubbleBurstOverlay extends StatefulWidget {
  final Offset center;
  final double initialRadius;
  final Color baseColor;
  final VoidCallback onCompleted;

  const BubbleBurstOverlay({
    super.key,
    required this.center,
    required this.initialRadius,
    required this.baseColor,
    required this.onCompleted,
  });

  @override
  State<BubbleBurstOverlay> createState() => _BubbleBurstOverlayState();
}

class _BubbleBurstOverlayState extends State<BubbleBurstOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_BurstParticle> _particles;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Genera partículas radiales pastel
    final particleCount = 14 + _rng.nextInt(6);
    _particles = List.generate(particleCount, (index) {
      final angle = (index / particleCount) * 2 * pi + (_rng.nextDouble() - 0.5) * 0.4;
      final distance = widget.initialRadius * (0.8 + _rng.nextDouble() * 0.9);
      final size = 4.0 + _rng.nextDouble() * 5.0;

      // Variación sutil de color
      final hsl = HSLColor.fromColor(widget.baseColor);
      final particleColor = hsl
          .withLightness((hsl.lightness + (_rng.nextDouble() - 0.5) * 0.15).clamp(0.2, 0.95))
          .toColor();

      return _BurstParticle(
        angle: angle,
        distance: distance,
        size: size,
        color: particleColor,
      );
    });

    _controller.forward().then((_) {
      if (mounted) {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        // Curva de expansión rápida y desvanecimiento
        final ringScale = 1.0 + sin(progress * pi * 0.5) * 0.45;
        final ringOpacity = (1.0 - progress).clamp(0.0, 1.0);

        return CustomPaint(
          size: Size.infinite,
          painter: _BurstPainter(
            center: widget.center,
            initialRadius: widget.initialRadius,
            particles: _particles,
            progress: progress,
            ringScale: ringScale,
            ringOpacity: ringOpacity,
            baseColor: widget.baseColor,
          ),
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  final Offset center;
  final double initialRadius;
  final List<_BurstParticle> particles;
  final double progress;
  final double ringScale;
  final double ringOpacity;
  final Color baseColor;

  _BurstPainter({
    required this.center,
    required this.initialRadius,
    required this.particles,
    required this.progress,
    required this.ringScale,
    required this.ringOpacity,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Anillo de onda expansiva translúcido
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (3.0 * (1.0 - progress)).clamp(0.5, 3.0)
      ..color = Colors.white.withValues(alpha: ringOpacity * 0.85);

    canvas.drawCircle(center, initialRadius * ringScale, ringPaint);

    // 2. Destello central breve
    if (progress < 0.4) {
      final flashOpacity = ((0.4 - progress) / 0.4).clamp(0.0, 1.0);
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: flashOpacity * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, initialRadius * 0.6, flashPaint);
    }

    // 3. Gotitas / partículas que se dispersan
    for (final p in particles) {
      final currentDist = p.distance * Curves.easeOutCubic.transform(progress);
      final px = center.dx + cos(p.angle) * currentDist;
      final py = center.dy + sin(p.angle) * currentDist;

      final pOpacity = (1.0 - progress).clamp(0.0, 1.0);
      final currentSize = p.size * (1.0 - progress * 0.7);

      final pPaint = Paint()
        ..color = p.color.withValues(alpha: pOpacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(px, py), currentSize, pPaint);

      // Pequeño brillo blanco dentro de la gota
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: pOpacity * 0.7);
      canvas.drawCircle(Offset(px - currentSize * 0.3, py - currentSize * 0.3), currentSize * 0.35, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
