import 'dart:math';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';

/// Widget visual para renderizar una burbuja tridimensional con aspecto de esfera suave o jabón.
class BubbleWidget extends StatelessWidget {
  final TaskModel task;
  final double radius;
  final bool isSelected;
  final bool isDoneMode;

  const BubbleWidget({
    super.key,
    required this.task,
    required this.radius,
    this.isSelected = false,
    this.isDoneMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final isOverdue = task.isOverdue;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pintado de la esfera tridimensional (reflejos, gradiente de volumen y sombra)
          CustomPaint(
            size: Size(diameter, diameter),
            painter: _BubblePainter(
              baseColor: task.color,
              isOverdue: isOverdue,
              isDoneMode: isDoneMode,
              isSelected: isSelected,
            ),
          ),

          // Contenido textual dentro de la burbuja ajustado sin desbordarse
          Padding(
            padding: EdgeInsets.all(radius * 0.22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nombre corto de la materia o maestro
                Flexible(
                  child: Text(
                    task.subject,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: (radius * 0.22).clamp(11.0, 15.0),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // Breve fragmento de la tarea cuando el tamaño lo permite
                if (radius >= 65.0) ...[
                  const SizedBox(height: 3),
                  Flexible(
                    child: Text(
                      task.description,
                      textAlign: TextAlign.center,
                      maxLines: radius >= 82.0 ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: (radius * 0.16).clamp(9.5, 12.0),
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 5),

                // Pastilla indicadora de fecha de entrega / urgencia
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (radius * 0.12).clamp(6.0, 10.0),
                    vertical: (radius * 0.05).clamp(2.5, 4.0),
                  ),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? AppColors.overdueTag.withValues(alpha: 0.2)
                        : (task.isDueToday
                            ? AppColors.todayTag.withValues(alpha: 0.22)
                            : Colors.white.withValues(alpha: 0.65)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOverdue
                          ? AppColors.overdueTag.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.8),
                      width: 0.9,
                    ),
                  ),
                  child: Text(
                    isOverdue
                        ? 'Atrasada'
                        : (task.isDueToday
                            ? 'Hoy'
                            : (task.isDueTomorrow ? 'Mañana' : task.formattedDueDate)),
                    style: TextStyle(
                      fontSize: (radius * 0.15).clamp(8.5, 11.0),
                      fontWeight: FontWeight.w600,
                      color: isOverdue
                          ? AppColors.overdueTag
                          : (task.isDueToday
                              ? const Color(0xFFC05621)
                              : AppColors.textPrimary),
                    ),
                  ),
                ),

                // Indicador especial en Modo Hecho
                if (isDoneMode) ...[
                  const SizedBox(height: 3),
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: (radius * 0.24).clamp(14.0, 20.0),
                    color: const Color(0xFF4A8B71),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter para el renderizado realista de la burbuja (gradiente esférico,
/// reflejo especular en arco/óvalo superior y brillo inferior de rebote)
class _BubblePainter extends CustomPainter {
  final Color baseColor;
  final bool isOverdue;
  final bool isDoneMode;
  final bool isSelected;

  _BubblePainter({
    required this.baseColor,
    required this.isOverdue,
    required this.isDoneMode,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Sombra suave de contacto
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center.translate(0, radius * 0.1), radius * 0.94, shadowPaint);

    // 2. Cuerpo esférico con gradiente radial 3D
    final hsl = HSLColor.fromColor(baseColor);
    final lightColor = hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
    final deepColor = hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor();

    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.38),
        radius: 0.92,
        colors: [
          Colors.white.withValues(alpha: 0.92),
          lightColor.withValues(alpha: 0.88),
          baseColor.withValues(alpha: 0.85),
          deepColor.withValues(alpha: 0.82),
        ],
        stops: const [0.0, 0.25, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, spherePaint);

    // 3. Borde sutil iridiscente/translúcido
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isOverdue ? 2.5 : 1.2
      ..shader = SweepGradient(
        colors: isOverdue
            ? [
                AppColors.overdueTag.withValues(alpha: 0.8),
                AppColors.overdueTag.withValues(alpha: 0.3),
                AppColors.overdueTag.withValues(alpha: 0.8),
              ]
            : [
                Colors.white.withValues(alpha: 0.85),
                baseColor.withValues(alpha: 0.4),
                Colors.white.withValues(alpha: 0.7),
                deepColor.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.85),
              ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius - (isOverdue ? 1.2 : 0.6), borderPaint);

    // 4. Brillo especular superior (reflejo de jabón en media luna/óvalo)
    final specularRect = Rect.fromCenter(
      center: Offset(center.dx - radius * 0.35, center.dy - radius * 0.38),
      width: radius * 0.62,
      height: radius * 0.36,
    );
    final specularPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(specularRect);

    canvas.save();
    canvas.translate(center.dx - radius * 0.35, center.dy - radius * 0.38);
    canvas.rotate(-pi / 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 0.58, height: radius * 0.28),
      specularPaint,
    );
    canvas.restore();

    // 5. Brillo de rebote inferior tenue (bounce light)
    final bounceRect = Rect.fromCenter(
      center: Offset(center.dx + radius * 0.35, center.dy + radius * 0.4),
      width: radius * 0.5,
      height: radius * 0.22,
    );
    final bouncePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(bounceRect);

    canvas.drawOval(bounceRect, bouncePaint);

    // 6. Efecto de pulsación/resaltado en Modo Hecho
    if (isDoneMode) {
      final doneHaloPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFF4A8B71).withValues(alpha: 0.5);
      canvas.drawCircle(center, radius + 2.5, doneHaloPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.isOverdue != isOverdue ||
        oldDelegate.isDoneMode != isDoneMode ||
        oldDelegate.isSelected != isSelected;
  }
}
