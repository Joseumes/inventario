import '../../../../core/errors/failures.dart';
import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

/// CU-03: Editar producto.
///
/// La edición NO toca stockActual (eso lo hacen los movimientos) y
/// mantiene el control de código duplicado (excluyendo el propio id).
class ActualizarProducto {
  final ProductoRepository repository;

  ActualizarProducto(this.repository);

  Future<void> call(Producto producto) async {
    final codigo = producto.codigo.trim();
    if (codigo.isEmpty) {
      throw ValidacionFailure('El código es obligatorio');
    }
    if (producto.nombre.trim().isEmpty) {
      throw ValidacionFailure('El nombre es obligatorio');
    }
    if (producto.precioCompra < 0 || producto.precioVenta < 0) {
      throw ValidacionFailure('Los precios no pueden ser negativos');
    }
    if (producto.stockMinimo < 0) {
      throw ValidacionFailure('El stock mínimo no puede ser negativo');
    }

    final existente = await repository.obtenerPorCodigo(codigo);
    if (existente != null && existente.id != producto.id) {
      throw CodigoDuplicadoFailure(
          'El código "$codigo" ya lo usa "${existente.nombre}"');
    }

    await repository.actualizarProducto(
        producto.copyWith(codigo: codigo));
  }
}
