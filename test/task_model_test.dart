import 'package:flutter_test/flutter_test.dart';
import 'package:homework/models/task_model.dart';

void main() {
  group('TaskModel Tests', () {
    test('Calcula correctamente días restantes y estado de atraso', () {
      final now = DateTime.now();

      final overdueTask = TaskModel(
        id: '1',
        subject: 'Historia',
        description: 'Ensayo de la revolución',
        dueDate: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 5)),
        colorValue: 0xFFFFD6E0,
      );

      expect(overdueTask.isOverdue, isTrue);
      expect(overdueTask.remainingDays, lessThan(0));
      expect(overdueTask.urgencyLabel, contains('Atrasada'));

      final todayTask = TaskModel(
        id: '2',
        subject: 'Matemáticas',
        description: 'Ejercicios de álgebra',
        dueDate: now,
        createdAt: now,
        colorValue: 0xFFD0E8F2,
      );

      expect(todayTask.isOverdue, isFalse);
      expect(todayTask.isDueToday, isTrue);
      expect(todayTask.urgencyLabel, equals('¡Vence hoy!'));

      final futureTask = TaskModel(
        id: '3',
        subject: 'Biología',
        description: 'Maqueta de célula',
        dueDate: now.add(const Duration(days: 5)),
        createdAt: now,
        colorValue: 0xFFD1F2D9,
      );

      expect(futureTask.isOverdue, isFalse);
      expect(futureTask.remainingDays, greaterThanOrEqualTo(4));
    });

    test('Serialización y deserialización a Map para SQLite', () {
      final task = TaskModel(
        id: 'test-uuid-123',
        subject: 'Química',
        description: 'Tabla periódica',
        dueDate: DateTime(2026, 10, 20),
        createdAt: DateTime(2026, 10, 1),
        colorValue: 0xFFFFF1C5,
        isCompleted: true,
        completedAt: DateTime(2026, 10, 5, 14, 30),
      );

      final map = task.toMap();
      expect(map['id'], 'test-uuid-123');
      expect(map['subject'], 'Química');
      expect(map['is_completed'], 1);

      final reconstructed = TaskModel.fromMap(map);
      expect(reconstructed.id, task.id);
      expect(reconstructed.subject, task.subject);
      expect(reconstructed.description, task.description);
      expect(reconstructed.colorValue, task.colorValue);
      expect(reconstructed.isCompleted, isTrue);
      expect(reconstructed.completedAt, isNotNull);
    });

    test('Formato de fecha DD/MM/AAAA', () {
      final task = TaskModel(
        id: '4',
        subject: 'Física',
        description: 'Vectores',
        dueDate: DateTime(2026, 11, 5),
        createdAt: DateTime(2026, 10, 1),
        colorValue: 0xFFE2D4F0,
      );

      expect(task.formattedDueDate, equals('05/11/2026'));
    });
  });
}
