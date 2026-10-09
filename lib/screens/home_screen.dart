import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/task_model.dart';
import '../physics/bubble_simulation.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/sensor_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bubble_burst_overlay.dart';
import '../widgets/bubble_widget.dart';
import '../widgets/hidden_menu_drawer.dart';
import '../widgets/task_detail_modal.dart';
import 'add_task_sheet.dart';
import 'history_screen.dart';

/// Datos de una explosión en curso
class _ActiveBurst {
  final String id;
  final Offset center;
  final double radius;
  final Color color;

  _ActiveBurst({
    required this.id,
    required this.center,
    required this.radius,
    required this.color,
  });
}

/// Pantalla principal de HomeworK: Universo de burbujas interactivas
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final DatabaseService _db = DatabaseService.instance;
  final SensorService _sensors = SensorService.instance;
  final BubbleSimulation _simulation = BubbleSimulation();

  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  late AnimationController _entranceController;
  late Animation<double> _entranceFadeAnimation;
  late Animation<double> _entranceScaleAnimation;

  List<TaskModel> _activeTasks = [];
  bool _isLoading = true;
  bool _isMenuOpen = false;
  bool _isDoneMode = false;

  final List<_ActiveBurst> _bursts = [];
  TaskModel? _selectedTask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Animación de entrada elegante con rebote suave al abrir la aplicación
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _entranceFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceScaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    // Inicializa la física y sensores
    _sensors.start();

    _ticker = createTicker(_onTick);

    _loadTasks().then((_) {
      _entranceController.forward();
      _ticker.start();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_ticker.isActive) _ticker.stop();
      _sensors.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (!_ticker.isActive) {
        _lastElapsed = Duration.zero;
        _ticker.start();
      }
      _sensors.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _entranceController.dispose();
    _sensors.dispose();
    super.dispose();
  }

  Size _screenSize = Size.zero;

  Future<void> _loadTasks() async {
    try {
      final tasks = await _db.getActiveTasks();
      if (mounted) {
        setState(() {
          _activeTasks = tasks;
          _isLoading = false;
          if (!_screenSize.isEmpty) {
            _simulation.syncTasks(_activeTasks, _screenSize);
          }
        });

        // Sincroniza recordatorios locales para tareas activas (2 días antes)
        for (final task in tasks) {
          NotificationService.instance.scheduleTaskReminder(task);
        }
      }
    } catch (e) {
      debugPrint('Error al cargar tareas: $e');
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (_screenSize.isEmpty) return;

    // Actualiza filtro del giroscopio / acelerómetro
    _sensors.updateFilter(smoothing: 0.12);

    // Ejecuta el paso de simulación
    _simulation.step(dt, _screenSize, _sensors.currentTilt);

    if (mounted) {
      setState(() {});
    }
  }

  void _handleScreenTap(TapDownDetails details) {
    if (_isMenuOpen) {
      setState(() => _isMenuOpen = false);
      return;
    }

    final hitNode = _simulation.hitTest(details.localPosition);
    if (hitNode == null) return;

    if (_isDoneMode) {
      // Modo Hecho: estallar burbuja seleccionada
      _popBubble(hitNode);
    } else {
      // Modo normal: abrir detalle elegante
      setState(() {
        _selectedTask = hitNode.task;
      });
    }
  }

  void _popBubble(BubbleNode node) {
    final task = node.task;
    node.isBursting = true;

    final burstId = '${task.id}_${DateTime.now().millisecondsSinceEpoch}';
    final burst = _ActiveBurst(
      id: burstId,
      center: node.position,
      radius: node.displayRadius,
      color: task.color,
    );

    setState(() {
      _bursts.add(burst);
      // Al tronar una burbuja completada, se desactiva de inmediato el Modo Hecho
      // para evitar reventar otra por error o al presionar Salir.
      _isDoneMode = false;
    });

    // Guarda de inmediato en la base de datos local y cancela el recordatorio
    _db.completeTask(task.id);
    NotificationService.instance.cancelTaskReminder(task.id);
  }

  void _onBurstFinished(String burstId, String taskId) {
    setState(() {
      _bursts.removeWhere((b) => b.id == burstId);
      _activeTasks.removeWhere((t) => t.id == taskId);
      final size = MediaQuery.sizeOf(context);
      _simulation.syncTasks(_activeTasks, size);
    });
  }

  void _openAddTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskSheet(
        onTaskCreated: (newTask) async {
          await _db.insertTask(newTask);
          await NotificationService.instance.scheduleTaskReminder(newTask);
          await _loadTasks();
        },
      ),
    );
  }

  void _openHistoryScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HistoryScreen(
          onTaskRecovered: () {
            _loadTasks();
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _screenSize = size;

    // Asegura sincronización inicial al primer render
    if (!_isLoading && _simulation.nodes.length != _activeTasks.length) {
      _simulation.syncTasks(_activeTasks, size);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF9F7FB),
              Color(0xFFF3EEF9),
              Color(0xFFFAF7F2),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              // 1. Detección de toques sobre el universo de burbujas
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: _handleScreenTap,
                  child: FadeTransition(
                    opacity: _entranceFadeAnimation,
                    child: ScaleTransition(
                      scale: _entranceScaleAnimation,
                      child: Stack(
                        children: [
                          // Si no hay tareas, mensaje amigable y sutil
                          if (!_isLoading && _activeTasks.isEmpty)
                            _buildEmptyState(),

                          // Renderizado de las burbujas activas optimizado con RepaintBoundary para evitar caídas de FPS
                          ..._simulation.nodes.where((n) => !n.isBursting).map((node) {
                            final rad = node.displayRadius;
                            return Positioned(
                              key: ValueKey(node.task.id),
                              left: node.position.dx - rad,
                              top: node.position.dy - rad,
                              child: RepaintBoundary(
                                child: IgnorePointer(
                                  child: BubbleWidget(
                                    task: node.task,
                                    radius: rad,
                                    isDoneMode: _isDoneMode,
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Renderizado de explosiones / estallidos activos
                          ..._bursts.map((burst) {
                            final taskId = burst.id.split('_').first;
                            return Positioned.fill(
                              key: ValueKey(burst.id),
                              child: IgnorePointer(
                                child: BubbleBurstOverlay(
                                  center: burst.center,
                                  initialRadius: burst.radius,
                                  baseColor: burst.color,
                                  onCompleted: () =>
                                      _onBurstFinished(burst.id, taskId),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Encabezado superior sutil con animación de entrada
              if (!_isDoneMode)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 74,
                  child: FadeTransition(
                    opacity: _entranceFadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HomeworK',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6B5B95),
                            letterSpacing: 0.4,
                          ),
                        ),
                        if (!_isLoading && _activeTasks.isNotEmpty)
                          Text(
                            _activeTasks.length == 1
                                ? '1 tarea flotando'
                                : '${_activeTasks.length} tareas flotando',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // 2. Banner discreto de "Modo Hecho" cuando está activo
              if (_isDoneMode)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 70,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF48BB78).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF48BB78).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Toca una burbuja para reventarla',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _isDoneMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Salir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Botón de menú minimalista en la esquina superior izquierda
              Positioned(
                top: MediaQuery.of(context).padding.top + 14,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isMenuOpen ? Icons.close_rounded : Icons.menu_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _isMenuOpen = !_isMenuOpen;
                      });
                    },
                  ),
                ),
              ),

              // 4. Menú lateral desplegable animado
              if (_isMenuOpen)
                Positioned.fill(
                  child: HiddenMenuDrawer(
                    isDoneModeActive: _isDoneMode,
                    onClose: () => setState(() => _isMenuOpen = false),
                    onAddTask: _openAddTaskModal,
                    onDoneMode: () {
                      setState(() {
                        _isDoneMode = !_isDoneMode;
                      });
                    },
                    onHistory: _openHistoryScreen,
                  ),
                ),

              // 5. Modal de detalle de tarea seleccionada (modo normal)
              if (_selectedTask != null)
                Positioned.fill(
                  child: TaskDetailModal(
                    task: _selectedTask!,
                    onClose: () => setState(() => _selectedTask = null),
                    onComplete: () {
                      final taskToComplete = _selectedTask!;
                      setState(() => _selectedTask = null);
                      // Busca el nodo correspondiente para animar su estallido
                      final matchingNode = _simulation.nodes
                          .where((n) => n.task.id == taskToComplete.id)
                          .firstOrNull;
                      if (matchingNode != null) {
                        _popBubble(matchingNode);
                      } else {
                        _db.completeTask(taskToComplete.id).then((_) => _loadTasks());
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFEFE8FC),
                    Color(0xFFE2D4F0),
                    Colors.white,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC7B8EA).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bubble_chart_rounded,
                size: 56,
                color: Color(0xFF7C6BA6),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Tu universo está despejado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No tienes tareas pendientes por ahora. Agrega una materia o tarea para verla flotar aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openAddTaskModal,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Agregar primera tarea'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6BA6),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
