# Detector de Parábolas con Flutter y OpenCV

<p>
Este proyecto combina Flutter y un servidor en Python con OpenCV para detectar curvas parabólicas en tiempo real a partir de imágenes capturadas desde la cámara del dispositivo. Flutter envía los fotogramas al backend, donde se procesan mediante técnicas de visión por computadora y ajuste polinomial. El servidor devuelve los coeficientes de la parábola, permitiendo visualizar y utilizar los resultados directamente en la aplicación móvil.
</p>

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


<h3>RESULTADOS </h3>
<img width="960" height="1280" alt="image" src="https://github.com/user-attachments/assets/e400e7be-f436-4f20-af0f-6dd74279c2e8" />
<h5> DISEÑO </h5>
<img width="1245" height="315" alt="image" src="https://github.com/user-attachments/assets/7a752a76-026d-49ca-8961-1732a2ba7169" />
