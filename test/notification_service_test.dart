import 'package:flutter_test/flutter_test.dart';
import 'package:homework/models/task_model.dart';
import 'package:homework/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Tests', () {
    test('Programar y cancelar recordatorios se ejecuta sin errores en cualquier entorno', () async {
      final notif = NotificationService.instance;
      NotificationService.enableNotifications = false;

      final task = TaskModel(
        id: 'task-notif-1',
        subject: 'Historia Universal',
        description: 'Exposición final',
        dueDate: DateTime.now().add(const Duration(days: 4)),
        createdAt: DateTime.now(),
        colorValue: 0xFFFFD6E0,
      );

      // Programar recordatorio (2 días antes)
      await notif.scheduleTaskReminder(task);

      // Cancelar recordatorio (cuando se completa)
      await notif.cancelTaskReminder(task.id);

      // Cancelar todos
      await notif.cancelAll();
    });
  });
}
