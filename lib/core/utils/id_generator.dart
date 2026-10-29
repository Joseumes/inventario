import 'package:uuid/uuid.dart';

/// Fábrica de identificadores únicos centralizada para toda la app.
class IdGenerator {
  static const Uuid _uuid = Uuid();

  /// Devuelve un UUID v4 único.
  static String nuevoId() => _uuid.v4();
}
