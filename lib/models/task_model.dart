import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modelo inmutable de una tarea en HomeworK.
class TaskModel {
  final String id;
  final String subject; // Materia o maestro
  final String description; // Descripción detallada
  final DateTime dueDate; // Fecha de entrega
  final DateTime createdAt; // Fecha de creación
  final int colorValue; // Valor ARGB del color pastel asignado
  final bool isCompleted; // Estado: pendiente o completada
  final DateTime? completedAt; // Fecha en que se marcó como completada

  const TaskModel({
    required this.id,
    required this.subject,
    required this.description,
    required this.dueDate,
    required this.createdAt,
    required this.colorValue,
    this.isCompleted = false,
    this.completedAt,
  });

  /// Color como objeto Color de Flutter
  Color get color => Color(colorValue);

  /// Días restantes hasta la fecha de entrega (respecto a la medianoche de hoy)
  int get remainingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  /// Indica si la tarea está atrasada
  bool get isOverdue => remainingDays < 0;

  /// Indica si vence hoy
  bool get isDueToday => remainingDays == 0;

  /// Indica si vence mañana
  bool get isDueTomorrow => remainingDays == 1;

  /// Formato legible de fecha: dd/MM/yyyy
  String get formattedDueDate {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(dueDate);
  }

  /// Formato completo de fecha: ej. 14 de octubre de 2026
  String get fullFormattedDueDate {
    final formatter = DateFormat("d 'de' MMMM, yyyy", 'es');
    return formatter.format(dueDate);
  }

  /// Formato legible de fecha de finalización
  String get formattedCompletedDate {
    if (completedAt == null) return '';
    final formatter = DateFormat("dd/MM/yyyy 'a las' HH:mm");
    return formatter.format(completedAt!);
  }

  /// Texto corto de urgencia para mostrar en la burbuja o detalle
  String get urgencyLabel {
    if (isOverdue) {
      final days = remainingDays.abs();
      return days == 1 ? 'Atrasada (1 día)' : 'Atrasada ($days días)';
    }
    if (isDueToday) {
      return '¡Vence hoy!';
    }
    if (isDueTomorrow) {
      return 'Vence mañana';
    }
    return 'En $remainingDays días';
  }

  /// Conversión a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'color_value': colorValue,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Creación desde Map de SQLite
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      subject: map['subject'] as String,
      description: map['description'] as String,
      dueDate: DateTime.parse(map['due_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      colorValue: map['color_value'] as int,
      isCompleted: (map['is_completed'] as int) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  /// Copia inmutable con campos modificables
  TaskModel copyWith({
    String? id,
    String? subject,
    String? description,
    DateTime? dueDate,
    DateTime? createdAt,
    int? colorValue,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      colorValue: colorValue ?? this.colorValue,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          subject == other.subject &&
          description == other.description &&
          dueDate == other.dueDate &&
          colorValue == other.colorValue &&
          isCompleted == other.isCompleted &&
          completedAt == other.completedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      subject.hashCode ^
      description.hashCode ^
      dueDate.hashCode ^
      colorValue.hashCode ^
      isCompleted.hashCode ^
      completedAt.hashCode;
}
