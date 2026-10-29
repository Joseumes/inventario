import 'package:flutter/foundation.dart';
import '../../domain/perfil.dart';
import '../../domain/repositories/perfil_repository.dart';

/// ESTADO: Perfil local del responsable de los movimientos.
class PerfilProvider extends ChangeNotifier {
  final PerfilRepository _repositorio;

  PerfilProvider(this._repositorio);

  Perfil _perfil = const Perfil(nombre: 'Operador local');
  Perfil get perfil => _perfil;
  String get nombre => _perfil.nombre;

  Future<void> cargar() async {
    try {
      final n = await _repositorio.obtenerNombre();
      if (n.trim().isNotEmpty) {
        _perfil = Perfil(nombre: n.trim());
        notifyListeners();
      }
    } catch (_) {
      // Sin datos guardados se conserva el valor por defecto.
    }
  }

  Future<void> actualizar(String nuevo) async {
    final n = nuevo.trim();
    if (n.isEmpty) return;
    await _repositorio.guardarNombre(n);
    _perfil = _perfil.copyWith(nombre: n);
    notifyListeners();
  }
}
