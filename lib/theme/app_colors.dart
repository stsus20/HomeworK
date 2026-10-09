import 'dart:math';
import 'package:flutter/material.dart';

/// Paleta de colores pastel y diseño visual para HomeworK.
class AppColors {
  AppColors._();

  // Fondos principales (claros, crema y lavanda muy suave)
  static const Color backgroundLight = Color(0xFFFAF8F5);
  static const Color backgroundLavender = Color(0xFFF3EFF9);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundGlass = Color(0xCCFFFFFF);

  // Textos y contrastes legibles
  static const Color textPrimary = Color(0xFF2C2738);
  static const Color textSecondary = Color(0xFF676176);
  static const Color textTertiary = Color(0xFF9892A6);

  // Acentos de estado
  static const Color overdueTag = Color(0xFFFF6B6B);
  static const Color overdueBg = Color(0xFFFFE5E5);
  static const Color todayTag = Color(0xFFFF9F43);
  static const Color soonTag = Color(0xFF54A0FF);
  static const Color normalTag = Color(0xFF10AC84);

  // Paleta seleccionada de colores pastel suaves para las burbujas
  static const List<Color> pastelBubbleColors = [
    Color(0xFFFFD6E0), // Rosa suave
    Color(0xFFE2D4F0), // Lavanda delicada
    Color(0xFFD0E8F2), // Azul cielo pastel
    Color(0xFFD1F2D9), // Menta suave
    Color(0xFFFFD8BE), // Durazno
    Color(0xFFFFF1C5), // Amarillo mantequilla
    Color(0xFFE8D7F1), // Lila claro
    Color(0xFFD5EDF6), // Aguamarina pastel
  ];

  /// Obtiene un color pastel aleatorio para una nueva tarea
  static Color getRandomPastelColor() {
    final random = Random();
    return pastelBubbleColors[random.nextInt(pastelBubbleColors.length)];
  }

  /// Retorna un color con brillo para el reflejo superior de la burbuja
  static Color getHighlightColor(Color baseColor) {
    return Colors.white.withValues(alpha: 0.65);
  }

  /// Retorna un color más profundo para el sombreado interior inferior
  static Color getShadowTone(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  }
}
