import '../repositories/producto_repository.dart';
import '../../../inventario/domain/repositories/movimiento_repository.dart';

/// CU-04: Desactivar (o eliminar) producto.
///
/// Regla de negocio:
/// "Un producto con movimientos no podrá eliminarse definitivamente;
///  podrá desactivarse."
///
/// Si NO tiene movimientos, se elimina físicamente (dato huérfano).
/// Si SÍ tiene movimientos, se desactiva y el historial se conserva.
class DesactivarProducto {
  final ProductoRepository productos;
  final MovimientoRepository movimientos;

  DesactivarProducto(this.productos, this.movimientos);

  Future<void> call(String id) async {
    final movs = await movimientos.obtenerPorProducto(id);
    if (movs.isEmpty) {
      await productos.eliminarProducto(id);
    } else {
      await productos.desactivarProducto(id);
    }
  }
}

/// CU-06: Reactivar un producto previamente desactivado.
class ReactivarProducto {
  final ProductoRepository productos;

  ReactivarProducto(this.productos);

  Future<void> call(String id) => productos.reactivarProducto(id);
}
