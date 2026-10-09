import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

/// Pantalla independiente de Historial que muestra las tareas completadas y permite recuperarlas
class HistoryScreen extends StatefulWidget {
  final VoidCallback onTaskRecovered;

  const HistoryScreen({super.key, required this.onTaskRecovered});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<TaskModel> _completedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final tasks = await _db.getCompletedTasks();
    if (mounted) {
      setState(() {
        _completedTasks = tasks;
        _isLoading = false;
      });
    }
  }

  Future<void> _recoverTask(TaskModel task) async {
    await _db.recoverTask(task.id);
    await NotificationService.instance.scheduleTaskReminder(task);
    widget.onTaskRecovered();

    if (mounted) {
      setState(() {
        _completedTasks.removeWhere((t) => t.id == task.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('«${task.subject}» regresó a la pantalla principal'),
          backgroundColor: const Color(0xFF6B5B95),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Historial de tareas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C6BA6)),
            )
          : _completedTasks.isEmpty
              ? _buildEmptyState()
              : _buildTasksList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE2D4F0).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 46,
                color: Color(0xFF7C6BA6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay tareas en el historial',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cuando completes tareas desde el modo «Hecho», se guardarán aquí y podrás recuperarlas en cualquier momento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _completedTasks.length,
      itemBuilder: (context, index) {
        final task = _completedTasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: color pastel y materia
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: task.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.subject,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_rounded,
                          size: 14, color: Color(0xFF2E7D32)),
                      SizedBox(width: 4),
                      Text(
                        'Completada',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Descripción
            Text(
              task.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF0EDF5), height: 1),
            const SizedBox(height: 12),

            // Metadatos de fecha
            Row(
              children: [
                const Icon(Icons.event_available_rounded,
                    size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Entrega: ${task.formattedDueDate}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (task.completedAt != null)
              Row(
                children: [
                  const Icon(Icons.task_alt_rounded,
                      size: 15, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    'Terminada: ${task.formattedCompletedDate}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Botón Recuperar tarea
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _recoverTask(task),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Recuperar tarea'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C6BA6),
                  side: const BorderSide(color: Color(0xFFC7B8EA)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
