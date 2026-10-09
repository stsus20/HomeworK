import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework/main.dart';
import 'package:homework/services/database_service.dart';
import 'package:homework/services/notification_service.dart';
import 'package:homework/services/sensor_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.customDatabasePath = inMemoryDatabasePath;
    SensorService.enableSensors = false;
    NotificationService.enableNotifications = false;
  });

  setUp(() async {
    final db = await DatabaseService.instance.database;
    await db.delete(DatabaseService.tableTasks);
  });

  testWidgets('HomeworK carga la pantalla principal y abre el menú lateral con las 3 opciones',
      (WidgetTester tester) async {
    // Configura tamaño de pantalla móvil estándar
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const HomeworKApp());
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verifica que el estado vacío amigable se muestra cuando no hay tareas
    expect(find.text('Tu universo está despejado'), findsOneWidget);
    expect(find.text('Agregar primera tarea'), findsOneWidget);

    // Botón de menú en la esquina superior izquierda
    final menuButton = find.byIcon(Icons.menu_rounded);
    expect(menuButton, findsOneWidget);

    // Abrir menú lateral
    await tester.tap(menuButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    // Verifica las 3 opciones obligatorias del menú
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.text('Hecho'), findsOneWidget);
    expect(find.text('Historial'), findsOneWidget);

    // Presionar "Agregar tarea" abre el formulario
    await tester.tap(find.text('Agregar tarea'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nueva tarea'), findsOneWidget);
    expect(find.text('Materia o maestro *'), findsOneWidget);
    expect(find.text('Descripción de la tarea *'), findsOneWidget);
    expect(find.text('Fecha de entrega *'), findsOneWidget);
    expect(find.text('Guardar tarea'), findsOneWidget);
  });
}
