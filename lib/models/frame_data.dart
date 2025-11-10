/// Representa un punto en la trayectoria del objeto detectado.
/// Guarda la posición (x, y) en el frame y el tiempo en milisegundos.
class FrameData {
  /// Posición horizontal del objeto en el frame.
  final double x;

  /// Posición vertical del objeto en el frame.
  final double y;

  /// Tiempo (en milisegundos desde epoch) cuando se capturó este frame.
  final double time;

  FrameData(this.x, this.y, this.time);

  /// Devuelve una representación legible del punto.
  @override
  String toString() => 'FrameData(x: $x, y: $y, time: $time)';

  /// Convierte a un mapa (útil si luego quieres exportar a JSON o CSV).
  Map<String, dynamic> toMap() => {
        'x': x,
        'y': y,
        'time': time,
      };

  /// Crea un objeto `FrameData` a partir de un mapa.
  factory FrameData.fromMap(Map<String, dynamic> map) {
    return FrameData(
      map['x'] as double,
      map['y'] as double,
      map['time'] as double,
    );
  }
}
