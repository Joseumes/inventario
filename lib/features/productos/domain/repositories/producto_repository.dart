import '../entities/producto.dart';
import '../entities/categoria.dart';

/// Contrato del repositorio de productos (capa de dominio).
///
/// La capa de datos implementa este contrato; los casos de uso y la
/// presentación solo lo consumen, nunca acceden al almacenamiento directo.
abstract class ProductoRepository {
  Future<List<Producto>> obtenerProductos();
  Future<Producto?> obtenerPorId(String id);
  Future<Producto?> obtenerPorCodigo(String codigo);
  Future<List<Producto>> buscar(String query);

  Future<void> crearProducto(Producto producto);
  Future<void> actualizarProducto(Producto producto);
  Future<void> desactivarProducto(String id);
  Future<void> reactivarProducto(String id);

  /// Elimina físicamente. Solo válido si el producto no tiene movimientos
  /// (la regla de negocio se aplica en el caso de uso, no aquí).
  Future<void> eliminarProducto(String id);

  Future<List<Categoria>> obtenerCategorias();
  Future<void> crearCategoria(String nombre);
}

/// Contrato del repositorio de categorías.
abstract class CategoriaRepository {
  Future<List<Categoria>> obtenerCategorias();
  Future<void> crearCategoria(String nombre);
}
