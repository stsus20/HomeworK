import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Menú lateral desplegable minimalista y translúcido para HomeworK.
/// Contiene exclusivamente las 3 opciones principales requeridas.
class HiddenMenuDrawer extends StatelessWidget {
  final VoidCallback onAddTask;
  final VoidCallback onDoneMode;
  final VoidCallback onHistory;
  final VoidCallback onClose;
  final bool isDoneModeActive;

  const HiddenMenuDrawer({
    super.key,
    required this.onAddTask,
    required this.onDoneMode,
    required this.onHistory,
    required this.onClose,
    this.isDoneModeActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.78).clamp(280.0, 340.0);

    return Stack(
      children: [
        // Fondo semitransparente para cerrar al tocar fuera
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withValues(alpha: 0.22),
          ),
        ),

        // Panel lateral translúcido con efecto vidrio y colores pastel
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: drawerWidth,
            height: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    border: Border(
                      right: BorderSide(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(8, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado minimalista
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text.rich(
                                      TextSpan(
                                        text: 'HomeworK',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF6B5B95),
                                          letterSpacing: 0.5,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: ' •',
                                            style: TextStyle(
                                              color: Color(0xFFC7B8EA),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tareas flotantes',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
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

                          const SizedBox(height: 28),
                          Divider(
                            color: Colors.black.withValues(alpha: 0.06),
                            thickness: 1,
                          ),
                          const SizedBox(height: 18),

                          // Opción 1: Agregar tarea
                          _buildMenuItem(
                            icon: Icons.add_rounded,
                            title: 'Agregar tarea',
                            subtitle: 'Crea una nueva burbuja',
                            color: const Color(0xFF8E7BB8),
                            onTap: () {
                              onClose();
                              onAddTask();
                            },
                          ),

                          const SizedBox(height: 14),

                          // Opción 2: Hecho
                          _buildMenuItem(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'Hecho',
                            subtitle: isDoneModeActive
                                ? 'Modo activo (toca para salir)'
                                : 'Revienta las tareas terminadas',
                            color: const Color(0xFF48BB78),
                            isActive: isDoneModeActive,
                            onTap: () {
                              onClose();
                              onDoneMode();
                            },
                          ),

                          const SizedBox(height: 14),

                          // Opción 3: Historial
                          _buildMenuItem(
                            icon: Icons.history_rounded,
                            title: 'Historial',
                            subtitle: 'Consulta y recupera tareas',
                            color: const Color(0xFF4299E1),
                            onTap: () {
                              onClose();
                              onHistory();
                            },
                          ),

                          const Spacer(),

                          // Pie de página sutil
                          Center(
                            child: Text(
                              'Organización visual y minimalista',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isActive ? color : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
