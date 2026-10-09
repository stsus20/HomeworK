import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de interfaz inmersiva y barra de estado translúcida
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Inicialización del motor SQLite para plataforma actual (Android/Desktop/Tests)
  await DatabaseService.initializePlatform();

  // Inicialización del servicio de notificaciones locales para recordatorios
  await NotificationService.instance.initialize();

  runApp(const HomeworKApp());
}

/// Aplicación principal HomeworK
class HomeworKApp extends StatelessWidget {
  const HomeworKApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeworK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Soporte nativo para idioma español en selectores de fecha y componentes
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('es', 'MX'),
        Locale('es'),
      ],
      locale: const Locale('es', 'MX'),
      home: const HomeScreen(),
    );
  }
}
