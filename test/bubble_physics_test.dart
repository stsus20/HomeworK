import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework/models/task_model.dart';
import 'package:homework/physics/bubble_simulation.dart';

void main() {
  group('BubbleSimulation Physics Tests', () {
    const screenSize = Size(400, 800);

    test('Sincroniza y crea nodos con posición dentro de pantalla', () {
      final sim = BubbleSimulation();
      final tasks = [
        TaskModel(
          id: '1',
          subject: 'Matemáticas',
          description: 'Ejercicios',
          dueDate: DateTime.now().add(const Duration(days: 2)),
          createdAt: DateTime.now(),
          colorValue: 0xFFFFD6E0,
        ),
        TaskModel(
          id: '2',
          subject: 'Historia',
          description: 'Resumen',
          dueDate: DateTime.now().add(const Duration(days: 5)),
          createdAt: DateTime.now(),
          colorValue: 0xFFD0E8F2,
        ),
      ];

      sim.syncTasks(tasks, screenSize);
      expect(sim.nodes.length, 2);

      for (final node in sim.nodes) {
        expect(node.position.dx, greaterThan(0));
        expect(node.position.dx, lessThan(screenSize.width));
        expect(node.position.dy, greaterThan(0));
        expect(node.position.dy, lessThan(screenSize.height));
      }
    });

    test('Conserva la posición de nodos existentes al sincronizar', () {
      final sim = BubbleSimulation();
      final task1 = TaskModel(
        id: '1',
        subject: 'Matemáticas',
        description: 'Ejercicios',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now(),
        colorValue: 0xFFFFD6E0,
      );

      sim.syncTasks([task1], screenSize);
      final initialPos = sim.nodes.first.position;

      // Sincronizar de nuevo con la misma tarea
      sim.syncTasks([task1], screenSize);
      expect(sim.nodes.first.position, equals(initialPos));
    });

    test('Física de límites: no permite que las burbujas salgan de la pantalla', () {
      final sim = BubbleSimulation();
      final task = TaskModel(
        id: '1',
        subject: 'Química',
        description: 'Laboratorio',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now(),
        colorValue: 0xFFFFD6E0,
      );

      sim.syncTasks([task], screenSize);
      final node = sim.nodes.first;

      // Colocar deliberadamente fuera del borde derecho con velocidad hacia la derecha
      node.position = const Offset(900, 400);
      node.velocity = const Offset(50, 0);

      sim.step(0.016, screenSize, Offset.zero);

      // Debe haber rebotado dentro de los límites
      expect(node.position.dx, lessThanOrEqualTo(screenSize.width));
      expect(node.velocity.dx, lessThan(0)); // Velocidad invertida tras rebote
    });

    test('Detección euclidiana de toque con hitTest', () {
      final sim = BubbleSimulation();
      final task = TaskModel(
        id: '1',
        subject: 'Física',
        description: 'Laboratorio',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        colorValue: 0xFFFFD6E0,
      );

      sim.syncTasks([task], screenSize);
      final node = sim.nodes.first;
      node.position = const Offset(200, 300);
      node.entranceProgress = 1.0;

      // Toque en el centro exacto
      final hitCenter = sim.hitTest(const Offset(200, 300));
      expect(hitCenter, isNotNull);
      expect(hitCenter?.task.id, '1');

      // Toque lejano fuera del radio
      final hitFar = sim.hitTest(const Offset(10, 10));
      expect(hitFar, isNull);
    });
  });
}
