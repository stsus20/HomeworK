import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';

/// Modal elegante para consultar los detalles completos de una tarea seleccionada
class TaskDetailModal extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onComplete;
  final VoidCallback onClose;

  const TaskDetailModal({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera con pastilla de color y botón cerrar
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: task.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: task.color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.subject,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary),
                        onPressed: onClose,
                        splashRadius: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Pastilla de estado de urgencia
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppColors.overdueBg
                          : (task.isDueToday
                              ? const Color(0xFFFFF3E0)
                              : const Color(0xFFF0F4F8)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOverdue
                            ? AppColors.overdueTag.withValues(alpha: 0.4)
                            : (task.isDueToday
                                ? AppColors.todayTag.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.05)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOverdue
                              ? Icons.warning_amber_rounded
                              : (task.isDueToday
                                  ? Icons.access_time_filled_rounded
                                  : Icons.calendar_today_rounded),
                          size: 16,
                          color: isOverdue
                              ? AppColors.overdueTag
                              : (task.isDueToday
                                  ? AppColors.todayTag
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          task.urgencyLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isOverdue
                                ? AppColors.overdueTag
                                : (task.isDueToday
                                    ? const Color(0xFFC05621)
                                    : AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fecha de entrega
                  Row(
                    children: [
                      const Icon(Icons.event_note_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha de entrega: ${task.formattedDueDate}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEEEAE2), thickness: 1),
                  const SizedBox(height: 12),

                  // Descripción detallada
                  const Text(
                    'Instrucciones y descripción:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        task.description.isEmpty
                            ? 'Sin descripción adicional.'
                            : task.description,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onClose,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                                color: Colors.black.withValues(alpha: 0.12)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            onClose();
                            onComplete();
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Completar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C6BA6),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
