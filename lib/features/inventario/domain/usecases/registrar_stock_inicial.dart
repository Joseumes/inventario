import '../../../../core/errors/failures.dart';
import '../../../productos/domain/repositories/producto_repository.dart';
import '../repositories/movimiento_repository.dart';
import '../services/reglas_inventario.dart';

/// CU-05: Registrar las existencias iniciales de un producto como
/// movimiento de ENTRADA (trazabilidad del stock inicial).
///
/// Utiliza la misma operación única que los demás movimientos.
class RegistrarStockInicial {
  final ProductoRepository productos;
  final MovimientoRepository movimientos;

  RegistrarStockInicial(this.productos, this.movimientos);

  Future<void> call({
    required String productoId,
    required int cantidad,
    String motivo = 'Stock inicial',
    required String responsable,
  }) async {
    if (cantidad <= 0) {
      throw ValidacionFailure(
          'La existencia inicial debe ser mayor a cero (o dejar 0)');
    }
    final producto = await productos.obtenerPorId(productoId);
    if (producto == null) {
      throw ValidacionFailure('Producto no encontrado');
    }

    final anterior = producto.stockActual;
    final resultante = anterior + cantidad;

    await movimientos.registrarConActualizacionStock(
      movimiento: ReglasInventario.construirMovimiento(
        productoId: productoId,
        tipo: 'entrada',
        cantidad: cantidad,
        stockAnterior: anterior,
        stockResultante: resultante,
        motivo: motivo,
        responsable: responsable,
      ),
      productoResultante: producto.copyWith(stockActual: resultante),
    );
  }
}
