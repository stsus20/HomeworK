import 'package:flutter_test/flutter_test.dart';
import 'package:homework/models/task_model.dart';
import 'package:homework/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.customDatabasePath = inMemoryDatabasePath;
  });

  group('DatabaseService Tests', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService.instance;
      final db = await dbService.database;
      await db.delete(DatabaseService.tableTasks);
    });

    tearDown(() async {
      final db = await dbService.database;
      await db.delete(DatabaseService.tableTasks);
    });

    test('Inserta y recupera tareas activas ordenadas por fecha de entrega', () async {
      final task1 = TaskModel(
        id: 't-1',
        subject: 'Historia',
        description: 'Exposición',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
        colorValue: 0xFFFFD6E0,
      );

      final task2 = TaskModel(
        id: 't-2',
        subject: 'Matemáticas',
        description: 'Álgebra',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        colorValue: 0xFFD0E8F2,
      );

      await dbService.insertTask(task1);
      await dbService.insertTask(task2);

      final active = await dbService.getActiveTasks();
      expect(active.length, 2);
      // t-2 debe ir primero porque vence antes
      expect(active.first.id, 't-2');
      expect(active.last.id, 't-1');
    });

    test('Completar tarea la transfiere al historial y recoverTask la devuelve a activas', () async {
      final task = TaskModel(
        id: 't-complete',
        subject: 'Biología',
        description: 'Genética',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now(),
        colorValue: 0xFFD1F2D9,
      );

      await dbService.insertTask(task);
      expect((await dbService.getActiveTasks()).length, 1);
      expect((await dbService.getCompletedTasks()).isEmpty, isTrue);

      // Completar tarea (Modo Hecho)
      await dbService.completeTask(task.id);
      expect((await dbService.getActiveTasks()).isEmpty, isTrue);
      final completed = await dbService.getCompletedTasks();
      expect(completed.length, 1);
      expect(completed.first.id, 't-complete');
      expect(completed.first.isCompleted, isTrue);
      expect(completed.first.completedAt, isNotNull);

      // Recuperar tarea
      await dbService.recoverTask(task.id);
      final restoredActive = await dbService.getActiveTasks();
      expect(restoredActive.length, 1);
      expect(restoredActive.first.id, 't-complete');
      expect(restoredActive.first.isCompleted, isFalse);
      expect((await dbService.getCompletedTasks()).isEmpty, isTrue);
    });
  });
}
