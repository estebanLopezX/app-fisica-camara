# parabola_detector

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


lib/
 ├── main.dart     # Punto de entrada 
 |── assets/ imagenes
 |            |── logo.png     # Imagenes
 ├── core/
 │    ├── constants.dart       # Constantes globales <--------> Utilizar estas constantes que ya estan predefinidas
 │    ├── theme.dart           # Colores y estilos <----------> 
 ├── data/
 │    ├── models/              # Clases de datos (por ejemplo, resultados del análisis)
 │    └── services/            # Conexión con backend
 ├── presentation/
 │    ├── screens/             # Pantallas principales
 │    │     ├── home_screen.dart
 │    │     ├── results_screen.dart
 │    │     └── video_upload_screen.dart
 │    ├── widgets/             # Componentes reutilizables - aqui encontramos la barra de navegacion
 │    └── charts/              # Gráficas y visualizaciones
