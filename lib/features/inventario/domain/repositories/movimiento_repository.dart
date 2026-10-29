import '../entities/movimiento.dart';
import '../../../productos/domain/entities/producto.dart';
import '../entities/filtro_movimientos.dart';

/// Contrato del repositorio de movimientos (capa de dominio).
abstract class MovimientoRepository {
  /// Devuelve los movimientos ordenados del más reciente al más antiguo.
  /// [filtro] permite filtrar por producto, tipo y rango de fechas.
  Future<List<Movimiento>> obtenerMovimientos({FiltroMovimientos? filtro});

  Future<List<Movimiento>> obtenerPorProducto(String productoId);

  /// **Operación única y atómica**: registra el movimiento y actualiza las
  /// existencias del producto en una sola transacción de datos.
  ///
  /// Si falla la escritura, se revierte el estado anterior para que no
  /// quede un movimiento registrado sin stock actualizado (ni al revés).
  Future<void> registrarConActualizacionStock({
    required Movimiento movimiento,
    required Producto productoResultante,
  });
}
