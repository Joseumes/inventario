import '../entities/movimiento.dart';
import '../entities/filtro_movimientos.dart';
import '../repositories/movimiento_repository.dart';

/// CU-10: Consultar el historial de movimientos con filtros por
/// producto, tipo y rango de fechas (orden: más reciente primero).
class ObtenerHistorial {
  final MovimientoRepository repository;

  ObtenerHistorial(this.repository);

  Future<List<Movimiento>> call({FiltroMovimientos? filtro}) =>
      repository.obtenerMovimientos(filtro: filtro);
}
