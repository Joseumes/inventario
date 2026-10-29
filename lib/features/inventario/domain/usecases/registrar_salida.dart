import '../../../../core/errors/failures.dart';
import '../../../productos/domain/repositories/producto_repository.dart';
import '../repositories/movimiento_repository.dart';
import '../services/reglas_inventario.dart';

/// CU-08: Registrar SALIDA de stock.
///
/// Reglas aplicadas (en el dominio):
/// • Cantidad mayor que cero.
/// • NO se permiten salidas superiores al stock disponible.
/// • Motivo obligatorio (venta, daño, etc.).
/// • Producto existente y activo.
/// • Movimiento + actualización de existencias en UNA operación.
class RegistrarSalida {
  final ProductoRepository productos;
  final MovimientoRepository movimientos;

  RegistrarSalida(this.productos, this.movimientos);

  Future<void> call({
    required String productoId,
    required int cantidad,
    required String motivo,
    required String responsable,
  }) async {
    ReglasInventario.validarCantidadPositiva(cantidad);
    final motivoLimpio = ReglasInventario.validarMotivo(motivo);

    final producto = await productos.obtenerPorId(productoId);
    if (producto == null) {
      throw ValidacionFailure('Producto no encontrado');
    }
    ReglasInventario.validarProductoActivo(producto);
    ReglasInventario.validarStockSuficiente(cantidad, producto.stockActual);

    final anterior = producto.stockActual;
    final resultante = anterior - cantidad;

    await movimientos.registrarConActualizacionStock(
      movimiento: ReglasInventario.construirMovimiento(
        productoId: productoId,
        tipo: 'salida',
        cantidad: cantidad,
        stockAnterior: anterior,
        stockResultante: resultante,
        motivo: motivoLimpio,
        responsable: responsable,
      ),
      productoResultante: producto.copyWith(stockActual: resultante),
    );
  }
}
