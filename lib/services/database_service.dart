import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/task_model.dart';

/// Servicio de almacenamiento persistente local utilizando SQLite.
/// 100% offline, seguro y compatible tanto con Android como con pruebas de escritorio.
class DatabaseService {
  static const String _dbName = 'homework_app.db';
  static const int _dbVersion = 1;
  static const String tableTasks = 'tasks';

  static DatabaseService? _instance;
  Database? _database;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  /// Inicializa el motor de base de datos según la plataforma
  static Future<void> initializePlatform() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  static String? customDatabasePath;

  /// Obtiene o inicializa la base de datos SQLite
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (customDatabasePath != null) {
      return await openDatabase(
        customDatabasePath!,
        version: _dbVersion,
        onCreate: _onCreate,
      );
    }

    String dbPath;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        dbPath = join(appDocDir.path, 'HomeworK', _dbName);
        final dir = Directory(join(appDocDir.path, 'HomeworK'));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } catch (_) {
        // Fallback seguro para entorno de testing o escritorio sin canal registrado
        dbPath = inMemoryDatabasePath;
      }
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = join(databasesPath, _dbName);
    }

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTasks (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        description TEXT NOT NULL,
        due_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT
      )
    ''');
  }

  /// Inserta una nueva tarea
  Future<void> insertTask(TaskModel task) async {
    final db = await database;
    await db.insert(
      tableTasks,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todas las tareas pendientes ordenadas por fecha de entrega
  Future<List<TaskModel>> getActiveTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTasks,
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'due_date ASC',
    );
    return maps.map((m) => TaskModel.fromMap(m)).toList();
  }

  /// Obtiene las tareas completadas ordenadas por fecha de finalización descendente
  Future<List<TaskModel>> getCompletedTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTasks,
      where: 'is_completed = ?',
      whereArgs: [1],
      orderBy: 'completed_at DESC',
    );
    return maps.map((m) => TaskModel.fromMap(m)).toList();
  }

  /// Marca una tarea como completada (Modo Hecho)
  Future<void> completeTask(String id, {DateTime? completedDate}) async {
    final db = await database;
    final timestamp = (completedDate ?? DateTime.now()).toIso8601String();
    await db.update(
      tableTasks,
      {
        'is_completed': 1,
        'completed_at': timestamp,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Recupera una tarea del historial a la pantalla principal
  Future<void> recoverTask(String id) async {
    final db = await database;
    await db.update(
      tableTasks,
      {
        'is_completed': 0,
        'completed_at': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina una tarea permanentemente (para pruebas o mantenimiento)
  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      tableTasks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Cierra la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
