import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';

/// Servicio de notificaciones locales para HomeworK.
/// Programa recordatorios automáticos 2 días antes de la fecha de entrega de las tareas escolares.
class NotificationService {
  static NotificationService? _instance;
  FlutterLocalNotificationsPlugin? _plugin;

  static bool enableNotifications = true;
  bool _isInitialized = false;

  NotificationService._();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  FlutterLocalNotificationsPlugin get _notificationsPlugin =>
      _plugin ??= FlutterLocalNotificationsPlugin();

  /// Inicializa el servicio de notificaciones y la base de datos de zonas horarias
  Future<void> initialize() async {
    if (!enableNotifications || _isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notificación tocada: ${response.payload}');
        },
      );

      // Solicita permisos en Android 13+ de manera no bloqueante
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('No se pudo inicializar NotificationService: $e');
    }
  }

  /// Genera un entero de 32 bits estable a partir del ID de la tarea
  int _notificationId(String taskId) {
    return taskId.hashCode.abs() % 2147483647;
  }

  /// Programa un recordatorio 2 días antes de la fecha de entrega de la tarea
  Future<void> scheduleTaskReminder(TaskModel task) async {
    if (!enableNotifications || task.isCompleted) return;

    try {
      if (!_isInitialized) await initialize();

      final notifId = _notificationId(task.id);

      // Calcula la fecha del recordatorio: 2 días antes a las 9:00 AM
      final due = task.dueDate;
      final reminderDate = DateTime(
        due.year,
        due.month,
        due.day - 2,
        9, // 9:00 AM
        0,
      );

      final now = DateTime.now();

      // Si la fecha de recordatorio ya pasó o la tarea es para hoy/mañana,
      // no programamos en el pasado lejano
      if (reminderDate.isBefore(now)) {
        // Si falta entre 1 y 2 días, programar en 2 horas si hoy aún no ha vencido
        if (due.isAfter(now)) {
          final nearReminder = now.add(const Duration(hours: 2));
          if (nearReminder.isBefore(due)) {
            await _scheduleAt(
              id: notifId,
              dateTime: nearReminder,
              title: '¡Entrega próxima: ${task.subject}!',
              body: 'Tu tarea «${task.description}» vence pronto (${task.formattedDueDate}). ¡Revísala en HomeworK!',
              payload: task.id,
            );
          }
        }
        return;
      }

      await _scheduleAt(
        id: notifId,
        dateTime: reminderDate,
        title: '¡Recordatorio: ${task.subject} vence en 2 días!',
        body: 'Tienes pendiente: «${task.description}». Entrega programada para el ${task.formattedDueDate}.',
        payload: task.id,
      );
    } catch (e) {
      debugPrint('Error al programar recordatorio de tarea ${task.id}: $e');
    }
  }

  Future<void> _scheduleAt({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
    required String payload,
  }) async {
    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'homework_reminders_channel',
      'Recordatorios de Tareas',
      channelDescription: 'Avisos y recordatorios 2 días antes de la entrega',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Cancela el recordatorio de una tarea (cuando se completa o elimina)
  Future<void> cancelTaskReminder(String taskId) async {
    if (!enableNotifications) return;
    try {
      final notifId = _notificationId(taskId);
      await _notificationsPlugin.cancel(id: notifId);
    } catch (e) {
      debugPrint('Error al cancelar recordatorio: $e');
    }
  }

  /// Cancela todos los recordatorios programados
  Future<void> cancelAll() async {
    if (!enableNotifications) return;
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error al cancelar todas las notificaciones: $e');
    }
  }
}
