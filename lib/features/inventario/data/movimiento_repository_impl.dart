import '../../../../core/storage/local_storage.dart';
import '../../../../core/errors/failures.dart';
import '../domain/repositories/movimiento_repository.dart';
import '../domain/entities/movimiento.dart';
import '../domain/entities/filtro_movimientos.dart';
import '../../productos/domain/entities/producto.dart';

/// Implementación del repositorio de movimientos sobre LocalStorage.
///
/// La operación [registrarConActualizacionStock] guarda el movimiento y el
/// producto resultante como UNA SOLA OPERACIÓN de datos. Ante cualquier
/// error de escritura restaura el estado previo (rollback) para garantizar
/// la consistencia entre el historial y las existencias.
class MovimientoRepositoryImpl implements MovimientoRepository {
  final LocalStorage storage;
  MovimientoRepositoryImpl(this.storage);

  @override
  Future<List<Movimiento>> obtenerMovimientos({FiltroMovimientos? filtro}) async {
    final f = filtro ?? const FiltroMovimientos();
    final resultado = storage
        .getMovimientos()
        .map((m) => Movimiento.fromMap(m))
        .where((m) {
          if (f.productoId != null && m.productoId != f.productoId) return false;
          if (f.tipo != null && m.tipo != f.tipo) return false;
          if (f.desde != null && m.fecha.isBefore(f.desde!)) return false;
          if (f.hasta != null &&
              m.fecha.isAfter(f.hasta!.add(const Duration(days: 1)))) {
            return false;
          }
          return true;
        })
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return resultado;
  }

  @override
  Future<List<Movimiento>> obtenerPorProducto(String productoId) =>
      obtenerMovimientos(
          filtro: FiltroMovimientos(productoId: productoId));

  @override
  Future<void> registrarConActualizacionStock({
    required Movimiento movimiento,
    required Producto productoResultante,
  }) async {
    // Copias de seguridad para rollback ante cualquier fallo.
    final movsBackup = storage.getMovimientos();
    final prodsBackup = storage.getProductos();

    try {
      final movs = [...movsBackup];
      movs.add(movimiento.toMap());
      await storage.saveMovimientos(movs);

      final prods = [...prodsBackup];
      final i = prods.indexWhere((e) => e['id'] == productoResultante.id);
      if (i == -1) {
        prods.add(productoResultante.toMap());
      } else {
        prods[i] = productoResultante.toMap();
      }
      await storage.saveProductos(prods);
    } catch (e) {
      // Rollback: se restablece el estado previo a la operación.
      await storage.saveMovimientos(movsBackup);
      await storage.saveProductos(prodsBackup);
      throw AlmacenamientoFailure(
          'No se pudo registrar el movimiento de forma consistente: $e');
    }
  }
}
