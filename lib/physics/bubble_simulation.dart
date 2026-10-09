import 'dart:math';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'urgency_calculator.dart';

/// Nodo individual que representa una burbuja en la simulación física
class BubbleNode {
  final TaskModel task;
  Offset position;
  Offset velocity;
  double targetRadius;
  double currentRadius;
  double floatPhase;
  double floatSpeed;
  double entranceProgress; // 0.0 -> 1.0 para animación elástica de aparición
  bool isBursting; // Marcador si está en proceso de estallido

  BubbleNode({
    required this.task,
    required this.position,
    this.velocity = Offset.zero,
    required this.targetRadius,
    this.currentRadius = 10.0,
    required this.floatPhase,
    required this.floatSpeed,
    this.entranceProgress = 0.0,
    this.isBursting = false,
  });

  /// Radio efectivo actual considerando la animación de entrada
  double get displayRadius {
    if (entranceProgress >= 1.0) return targetRadius;
    // Efecto de rebote elástico suave de entrada
    final t = entranceProgress;
    final scale = sin(t * pi * 0.5) + sin(t * pi) * 0.2;
    return (targetRadius * scale.clamp(0.1, 1.1)).clamp(5.0, targetRadius * 1.15);
  }
}

/// Motor de simulación física 2D para las burbujas flotantes de HomeworK.
/// Controla la flotación orgánica, detección de límites elásticos,
/// repulsión mutua entre burbujas e interacción con la inclinación del teléfono.
class BubbleSimulation {
  final List<BubbleNode> nodes = [];
  final Random _rng = Random();

  // Márgenes seguros de pantalla (evita colisión con la barra de estado y menú superior)
  double paddingTop = 100.0;
  double paddingBottom = 40.0;
  double paddingLeft = 16.0;
  double paddingRight = 16.0;

  // Parámetros de física calibrados para mayor dinamismo y movimiento fluido
  static const double _maxSpeed = 160.0;
  static const double _airDamping = 0.96;
  static const double _tiltMultiplier = 110.0;
  static const double _repulsionStrength = 50.0;
  static const double _bubbleSpacing = 10.0;

  /// Sincroniza la lista de tareas activas con los nodos de la simulación.
  /// Conserva la posición y momentum de las burbujas existentes.
  void syncTasks(List<TaskModel> activeTasks, Size screenSize) {
    final existingIds = {for (var n in nodes) n.task.id: n};
    final newNodes = <BubbleNode>[];

    final effectiveWidth = max(200.0, screenSize.width);
    final effectiveHeight = max(300.0, screenSize.height);

    for (final task in activeTasks) {
      final calculatedRadius = UrgencyCalculator.calculateRadius(task);

      if (existingIds.containsKey(task.id)) {
        final existing = existingIds[task.id]!;
        // Conserva posición física y actualiza datos y radio de urgencia
        newNodes.add(BubbleNode(
          task: task,
          position: existing.position,
          velocity: existing.velocity,
          targetRadius: calculatedRadius,
          currentRadius: calculatedRadius,
          floatPhase: existing.floatPhase,
          floatSpeed: existing.floatSpeed,
          entranceProgress: 1.0,
          isBursting: existing.isBursting,
        ));
      } else {
        // Nueva tarea: posición inicial equilibrada con pequeño impulso orgánico
        final spawnX = paddingLeft + calculatedRadius +
            _rng.nextDouble() *
                (effectiveWidth - paddingLeft - paddingRight - 2 * calculatedRadius)
                    .clamp(10.0, 1000.0);
        final spawnY = paddingTop + calculatedRadius +
            _rng.nextDouble() *
                (effectiveHeight - paddingTop - paddingBottom - 2 * calculatedRadius)
                    .clamp(10.0, 1000.0);

        final initialImpulse = Offset(
          (_rng.nextDouble() - 0.5) * 65.0,
          (_rng.nextDouble() - 0.5) * 65.0,
        );

        newNodes.add(BubbleNode(
          task: task,
          position: Offset(spawnX, spawnY),
          velocity: initialImpulse,
          targetRadius: calculatedRadius,
          currentRadius: 10.0,
          floatPhase: _rng.nextDouble() * 2 * pi,
          floatSpeed: 1.2 + _rng.nextDouble() * 0.8,
          entranceProgress: 0.0,
        ));
      }
    }

    nodes
      ..clear()
      ..addAll(newNodes);
  }

  /// Ejecuta un paso de simulación física en delta time [dt] (en segundos).
  void step(double dt, Size screenSize, Offset tilt) {
    if (nodes.isEmpty || screenSize.isEmpty) return;

    // Normaliza dt para evitar saltos bruscos si hay caídas momentáneas de framerate
    final clampedDt = dt.clamp(0.001, 0.05);

    final minX = paddingLeft;
    final maxX = screenSize.width - paddingRight;
    final minY = paddingTop;
    final maxY = screenSize.height - paddingBottom;

    // 1. Repulsión elástica mutua para evitar superposiciones excesivas
    for (int i = 0; i < nodes.length; i++) {
      final a = nodes[i];
      if (a.isBursting) continue;
      final radA = a.displayRadius;

      for (int j = i + 1; j < nodes.length; j++) {
        final b = nodes[j];
        if (b.isBursting) continue;
        final radB = b.displayRadius;

        final delta = b.position - a.position;
        final dist = delta.distance;
        final targetDist = radA + radB + _bubbleSpacing;

        if (dist < targetDist && dist > 0.001) {
          final overlap = targetDist - dist;
          final normal = delta / dist;
          final force = normal * (overlap * _repulsionStrength);

          // Aplica fuerzas opuestas
          a.velocity -= force * clampedDt;
          b.velocity += force * clampedDt;

          // Suave corrección de posición para evitar atascos
          final correction = normal * (overlap * 0.15);
          a.position -= correction;
          b.position += correction;
        }
      }
    }

    // 2. Fuerzas individuales: flotación armónica + inclinación de sensores + amortiguación
    for (final node in nodes) {
      if (node.isBursting) continue;

      // Animación progresiva de entrada
      if (node.entranceProgress < 1.0) {
        node.entranceProgress = (node.entranceProgress + clampedDt * 3.0).clamp(0.0, 1.0);
      }

      // Deriva armónica orgánica
      node.floatPhase += clampedDt * node.floatSpeed;
      final wander = Offset(
        cos(node.floatPhase) * 22.0,
        sin(node.floatPhase * 0.8) * 18.0,
      );

      // Aceleración por inclinación del dispositivo (giroscopio/acelerómetro)
      final tiltForce = tilt * _tiltMultiplier;

      // Actualiza velocidad
      node.velocity += (wander + tiltForce) * clampedDt;

      // Fricción / resistencia suave del aire
      node.velocity = node.velocity * pow(_airDamping, clampedDt * 60.0).toDouble();

      // Limitador de velocidad máxima
      if (node.velocity.distance > _maxSpeed) {
        node.velocity = (node.velocity / node.velocity.distance) * _maxSpeed;
      }

      // Desplazamiento
      node.position += node.velocity * clampedDt;

      // 3. Rebote suave y respeto estricto de bordes de la pantalla
      final radius = node.displayRadius;
      final leftBound = minX + radius;
      final rightBound = maxX - radius;
      final topBound = minY + radius;
      final bottomBound = maxY - radius;

      if (node.position.dx < leftBound) {
        node.position = Offset(leftBound, node.position.dy);
        node.velocity = Offset(-node.velocity.dx * 0.5, node.velocity.dy);
      } else if (node.position.dx > rightBound) {
        node.position = Offset(rightBound, node.position.dy);
        node.velocity = Offset(-node.velocity.dx * 0.5, node.velocity.dy);
      }

      if (node.position.dy < topBound) {
        node.position = Offset(node.position.dx, topBound);
        node.velocity = Offset(node.velocity.dx, -node.velocity.dy * 0.5);
      } else if (node.position.dy > bottomBound) {
        node.position = Offset(node.position.dx, bottomBound);
        node.velocity = Offset(node.velocity.dx, -node.velocity.dy * 0.5);
      }
    }
  }

  /// Encuentra el nodo sobre el que se realizó un toque en pantalla
  BubbleNode? hitTest(Offset touchPoint) {
    for (int i = nodes.length - 1; i >= 0; i--) {
      final node = nodes[i];
      if (node.isBursting) continue;
      final dist = (node.position - touchPoint).distance;
      if (dist <= node.displayRadius) {
        return node;
      }
    }
    return null;
  }
}
