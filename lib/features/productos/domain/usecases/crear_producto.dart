import '../../../../core/errors/failures.dart';
import '../entities/producto.dart';
import '../repositories/producto_repository.dart';

/// CU-01: Registrar producto.
///
/// Reglas de negocio (implementadas EN el dominio):
/// • Código único obligatorio (sin duplicados, sin importar mayúsculas).
/// • Nombre obligatorio.
/// • Precios y stock mínimo no negativos.
/// • La existencia inicial NO se crea aquí: se registra como movimiento
///   de ENTRADA (CU-05), para conservar la trazabilidad del enunciado.
class CrearProducto {
  final ProductoRepository repository;

  CrearProducto(this.repository);

  Future<Producto> call(Producto producto) async {
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
    if (existente != null) {
      throw CodigoDuplicadoFailure(
          'El código "$codigo" ya está asignado a "${existente.nombre}"');
    }

    final nuevo = producto.copyWith(codigo: codigo);
    await repository.crearProducto(nuevo);
    return nuevo;
  }
}
