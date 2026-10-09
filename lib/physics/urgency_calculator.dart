import 'dart:math';
import '../models/task_model.dart';

/// Calculador de tamaño y urgencia para las burbujas de HomeworK.
/// El tamaño se calcula estrictamente a partir del tiempo restante real (reloj del sistema)
/// y la fecha de entrega fija guardada en la base de datos, garantizando que nunca
/// se reinicie como una cuenta regresiva temporal al abrir la aplicación.
class UrgencyCalculator {
  UrgencyCalculator._();

  static const double minRadius = 50.0; // Radio mínimo para tareas lejanas (> 14 días)
  static const double maxRadius = 98.0; // Radio máximo para tareas que vencen hoy
  static const double overdueRadius = 92.0; // Radio visible para tareas atrasadas

  /// Calcula el radio en píxeles basado en el tiempo restante real hasta la fecha de entrega.
  /// Es 100% determinista y continuo con el tiempo real de calendario.
  static double calculateRadius(TaskModel task, {DateTime? now}) {
    final current = now ?? DateTime.now();

    // La fecha de entrega se considera al final del día escolar asignado (23:59:59)
    final dueEndOfDay = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      23,
      59,
      59,
    );

    final difference = dueEndOfDay.difference(current);
    final hoursRemaining = difference.inHours;

    // Si ya expiró la fecha de entrega: estado atrasado
    if (hoursRemaining < 0) {
      return overdueRadius;
    }

    // Si vence dentro de las próximas 24 horas (hoy): urgencia máxima
    if (hoursRemaining <= 24) {
      return maxRadius;
    }

    // Curva continua entre 24 horas (1 día) y 336 horas (14 días)
    const maxHoursWindow = 14.0 * 24.0; // 336 horas
    final clampedHours = hoursRemaining.toDouble().clamp(24.0, maxHoursWindow);

    // ratio: 1.0 a las 24h, 0.0 a las 336h
    final ratio = 1.0 - ((clampedHours - 24.0) / (maxHoursWindow - 24.0));

    // Curva exponencial suave para dar mayor peso a los días más próximos
    final curved = pow(ratio, 0.85).toDouble();

    final calculated = minRadius + (maxRadius - minRadius) * curved;
    return calculated.clamp(minRadius, maxRadius);
  }

  /// Nivel de urgencia cualitativo (0: atrasada, 1: hoy, 2: mañana, etc.)
  static int getUrgencyTier(TaskModel task, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final due = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
    final days = due.difference(today).inDays;

    if (days < 0) return 0; // Atrasada
    if (days == 0) return 1; // Hoy
    if (days == 1) return 2; // Mañana
    if (days <= 3) return 3; // Próximos 3 días
    if (days <= 7) return 4; // Esta semana
    return 5; // Más de 7 días
  }
}
