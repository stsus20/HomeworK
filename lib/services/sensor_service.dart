import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Servicio de gestión de sensores de movimiento para HomeworK.
/// Lee los datos del acelerómetro con filtro paso bajo (LERP) para evitar sacudidas,
/// límites de aceleración e independencia ante la ausencia de hardware.
class SensorService {
  static SensorService? _instance;
  StreamSubscription<AccelerometerEvent>? _subscription;

  // Vector de inclinación filtrado: x entre -1.0 y 1.0, y entre -1.0 y 1.0
  Offset _filteredTilt = Offset.zero;
  Offset _rawTilt = Offset.zero;

  static bool enableSensors = true;

  bool _isAvailable = false;
  bool _isPaused = false;

  SensorService._();

  static SensorService get instance {
    _instance ??= SensorService._();
    return _instance!;
  }

  Offset get currentTilt => _filteredTilt;
  bool get isAvailable => _isAvailable;

  /// Inicia la escucha de sensores con control de errores y desacoplamiento
  void start() {
    if (!enableSensors || _subscription != null) return;

    try {
      _subscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          if (_isPaused) return;
          _isAvailable = true;

          // En teléfonos Android estándar en modo vertical (portrait):
          // Inclinación a la derecha: event.x negativo -> fuerza hacia la derecha (+X)
          // Inclinación a la izquierda: event.x positivo -> fuerza hacia la izquierda (-X)
          // Inclinación hacia adelante: event.y positivo -> fuerza hacia arriba (-Y)
          // Inclinación hacia el usuario: event.y negativo -> fuerza hacia abajo (+Y)
          final targetX = (-event.x / 9.8).clamp(-1.0, 1.0);
          final targetY = (event.y / 9.8).clamp(-1.0, 1.0);

          _rawTilt = Offset(targetX, targetY);
        },
        onError: (dynamic error) {
          debugPrint('Sensores de movimiento no disponibles: $error');
          _isAvailable = false;
          _rawTilt = Offset.zero;
          _filteredTilt = Offset.zero;
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('No se pudo inicializar el servicio de sensores: $e');
      _isAvailable = false;
    }
  }

  /// Actualiza la interpolación paso bajo (llamada en cada frame del bucle de física)
  /// [smoothing] entre 0.05 y 0.2 garantiza suavidad orgánica y retorno gradual
  void updateFilter({double smoothing = 0.12}) {
    if (!_isAvailable) {
      _filteredTilt = Offset.lerp(_filteredTilt, Offset.zero, smoothing) ?? Offset.zero;
      return;
    }

    _filteredTilt = Offset(
      _lerp(_filteredTilt.dx, _rawTilt.dx, smoothing),
      _lerp(_filteredTilt.dy, _rawTilt.dy, smoothing),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Pausa la lectura cuando la app entra en segundo plano
  void pause() {
    _isPaused = true;
    _subscription?.pause();
  }

  /// Reanuda la lectura al volver al primer plano
  void resume() {
    _isPaused = false;
    _subscription?.resume();
  }

  /// Cancela la suscripción y libera recursos
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _filteredTilt = Offset.zero;
    _rawTilt = Offset.zero;
  }
}
