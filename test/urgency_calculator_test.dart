import 'package:flutter_test/flutter_test.dart';
import 'package:homework/models/task_model.dart';
import 'package:homework/physics/urgency_calculator.dart';

void main() {
  group('UrgencyCalculator Tests', () {
    final now = DateTime(2026, 10, 10, 12, 0);

    test('Asigna el radio máximo a tareas que vencen hoy', () {
      final taskToday = TaskModel(
        id: 't-today',
        subject: 'Literatura',
        description: 'Lectura',
        dueDate: DateTime(2026, 10, 10),
        createdAt: now.subtract(const Duration(days: 1)),
        colorValue: 0xFFFFD6E0,
      );

      final radius = UrgencyCalculator.calculateRadius(taskToday, now: now);
      expect(radius, equals(UrgencyCalculator.maxRadius));
    });

    test('Asigna radio especial visible a tareas atrasadas', () {
      final taskOverdue = TaskModel(
        id: 't-overdue',
        subject: 'Historia',
        description: 'Línea de tiempo',
        dueDate: DateTime(2026, 10, 8),
        createdAt: now.subtract(const Duration(days: 4)),
        colorValue: 0xFFFFD8BE,
      );

      final radius = UrgencyCalculator.calculateRadius(taskOverdue, now: now);
      expect(radius, equals(UrgencyCalculator.overdueRadius));
    });

    test('Las tareas más cercanas tienen mayor radio que las lejanas', () {
      final taskNear = TaskModel(
        id: 't-near',
        subject: 'Inglés',
        description: 'Vocabulario',
        dueDate: DateTime(2026, 10, 12), // 2 días
        createdAt: now,
        colorValue: 0xFFD0E8F2,
      );

      final taskFar = TaskModel(
        id: 't-far',
        subject: 'Arte',
        description: 'Pintura',
        dueDate: DateTime(2026, 10, 25), // 15 días
        createdAt: now,
        colorValue: 0xFFD1F2D9,
      );

      final radiusNear = UrgencyCalculator.calculateRadius(taskNear, now: now);
      final radiusFar = UrgencyCalculator.calculateRadius(taskFar, now: now);

      expect(radiusNear, greaterThan(radiusFar));
      expect(radiusFar, equals(UrgencyCalculator.minRadius));
      expect(radiusNear, lessThanOrEqualTo(UrgencyCalculator.maxRadius));
    });

    test('Mismo criterio estable para dos tareas con la misma fecha de entrega', () {
      final taskA = TaskModel(
        id: 'a',
        subject: 'Química',
        description: 'Práctica',
        dueDate: DateTime(2026, 10, 14),
        createdAt: now,
        colorValue: 0xFFE2D4F0,
      );

      final taskB = TaskModel(
        id: 'b',
        subject: 'Física',
        description: 'Problemas',
        dueDate: DateTime(2026, 10, 14),
        createdAt: now,
        colorValue: 0xFFFFF1C5,
      );

      final radA = UrgencyCalculator.calculateRadius(taskA, now: now);
      final radB = UrgencyCalculator.calculateRadius(taskB, now: now);

      expect(radA, equals(radB));
    });
  });
}
