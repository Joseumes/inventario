import 'failures.dart';

/// Traduce las excepciones del dominio a mensajes legibles para el usuario.
/// Se usa en las SnackBars de todas las pantallas.
String mensajeAmigable(Object e) {
  if (e is Failure) return e.mensaje;
  final s = e.toString();
  // Evita mostrar "Exception: " crudo al usuario.
  if (s.startsWith('Exception: ')) return s.substring('Exception: '.length);
  return 'Ocurrió un error inesperado. Intenta de nuevo.';
}
