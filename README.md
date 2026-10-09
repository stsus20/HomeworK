# HomeworK 📚✨

**HomeworK** es una aplicación móvil desarrollada con Flutter para organizar y administrar tareas escolares de una manera sencilla, visual y dinámica. Está diseñada para ayudar a los estudiantes a llevar un mejor control de sus actividades académicas, fechas de entrega y tareas pendientes.

Su interfaz utiliza un estilo moderno, minimalista y cute, con colores pastel, burbujas animadas y una experiencia de usuario intuitiva.

## ✨ Características principales

- **Gestión de tareas:** agrega y administra tus tareas escolares.
- **Registro de actividades:** crea tareas mediante un formulario con el nombre de la materia o maestro, una descripción y la fecha de entrega.
- **Interfaz de burbujas:** visualiza tus tareas mediante burbujas de colores pastel.
- **Tamaño dinámico:** las burbujas aumentan de tamaño conforme se acerca la fecha de entrega, ayudándote a identificar las tareas prioritarias.
- **Colores aleatorios:** utiliza diferentes combinaciones de colores pastel para dar variedad a la pantalla principal.
- **Animaciones dinámicas:** disfruta de movimientos sutiles que hacen más atractiva la experiencia visual.
- **Interacción con el dispositivo:** aprovecha el giroscopio para añadir una sensación de movimiento a las burbujas.
- **Tareas completadas:** marca las actividades como terminadas y retíralas de la pantalla principal.
- **Historial de tareas:** consulta las tareas completadas y recupera aquellas que necesites volver a activar.
- **Navegación sencilla:** accede a las opciones principales desde un menú desplegable.

## 🎨 Diseño

HomeworK busca combinar productividad y estética mediante una interfaz:

- Minimalista y fácil de utilizar.
- Inspirada en tonos pastel.
- Con elementos redondeados y burbujas interactivas.
- Con animaciones suaves y transiciones visuales.
- Pensada para ofrecer una experiencia agradable en dispositivos móviles.

## 🛠️ Tecnologías utilizadas

- **Flutter:** framework para el desarrollo de la aplicación móvil.
- **Dart:** lenguaje de programación.
- **Sensores del dispositivo:** giroscopio para efectos de movimiento, cuando el dispositivo y la implementación lo permitan.

## 📋 Requisitos

Para ejecutar el proyecto necesitas:

- Flutter SDK instalado.
- Dart SDK compatible con la versión de Flutter utilizada.
- Android Studio o Visual Studio Code.
- Un dispositivo Android o un emulador configurado.

## 🚀 Instalación y ejecución

### 1. Clonar el repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
```

### 2. Entrar en la carpeta del proyecto

```bash
cd homework
```

### 3. Instalar las dependencias

```bash
flutter pub get
```

### 4. Ejecutar la aplicación

```bash
flutter run
```

## 📦 Generar APK

Para generar una versión de instalación para Android, ejecuta:

```bash
flutter build apk --release
```

El archivo APK se generará normalmente en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Puedes transferirlo a un dispositivo Android e instalarlo, según la configuración de seguridad del dispositivo.

## 📁 Estructura del proyecto

La estructura exacta depende de la implementación actual, pero un proyecto Flutter normalmente contiene:

```text
homework/
├── android/
├── ios/
├── lib/
│   └── main.dart
├── test/
├── assets/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

- `lib/`: código fuente de la aplicación.
- `android/`: configuración específica para Android.
- `ios/`: configuración específica para iOS.
- `test/`: pruebas automatizadas.
- `assets/`: recursos gráficos y otros archivos, si están configurados.
- `pubspec.yaml`: dependencias y configuración del proyecto.

## 🎯 Objetivo del proyecto

Desarrollar una herramienta práctica para que los estudiantes organicen sus tareas escolares, visualicen sus fechas de entrega y mantengan un historial de sus actividades completadas, todo mediante una interfaz atractiva, intuitiva y fácil de usar.

## 📚 Recursos de Flutter

- [Documentación oficial de Flutter](https://docs.flutter.dev/)
- [Aprender Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Crear tu primera aplicación](https://docs.flutter.dev/get-started/codelab)
- [Recursos de aprendizaje](https://docs.flutter.dev/reference/learning-resources)

---

**HomeworK** — Organiza tus tareas, visualiza tus pendientes y haz que estudiar sea un poco más bonito. 💜📖
