import 'package:flutter/foundation.dart';
import '../../../inventario/domain/repositories/movimiento_repository.dart';
import '../../../inventario/domain/usecases/registrar_stock_inicial.dart';
import '../../domain/entities/producto.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/repositories/producto_repository.dart';
import '../../domain/usecases/crear_producto.dart';
import '../../domain/usecases/actualizar_producto.dart';
import '../../domain/usecases/desactivar_producto.dart';

/// ESTADO: Presentación de productos (patrón Provider / ChangeNotifier).
///
/// Flujo de dependencias: Presentación → Casos de uso (Dominio) → Datos.
/// Aquí solo se orquesta estado (cargando / error / datos) y filtros.
class ProductoProvider extends ChangeNotifier {
  final ProductoRepository _repositorio;
  final MovimientoRepository _movRepo;

  ProductoProvider(this._repositorio, this._movRepo);

  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  bool _cargando = false;
  String? _error;
  String _filtro = '';
  bool _verInactivos = false;

  List<Producto> get productos => _productos;
  List<Categoria> get categorias => _categorias;
  bool get cargando => _cargando;
  String? get error => _error;
  String get filtro => _filtro;
  bool get verInactivos => _verInactivos;

  List<Producto> get productosFiltrados {
    Iterable<Producto> base = _productos;
    base = _verInactivos ? base : base.where((p) => p.activo);
    if (_filtro.trim().isNotEmpty) {
      final f = _filtro.trim().toLowerCase();
      base = base.where((p) =>
          p.nombre.toLowerCase().contains(f) ||
          p.codigo.toLowerCase().contains(f) ||
          (p.descripcion ?? '').toLowerCase().contains(f));
    }
    return base.toList();
  }

  List<Producto> get productosActivos =>
      _productos.where((p) => p.activo).toList();

  /// Alerta de stock igual o inferior al mínimo (solo activos).
  List<Producto> get productosStockBajo =>
      _productos.where((p) => p.activo && p.stockBajo).toList();

  /// Valor del inventario = existencias × precio de COMPRA (estimación).
  double get valorInventario =>
      _productos.where((p) => p.activo).fold(0.0, (s, p) => s + p.valorInventario);

  Future<void> cargarProductos() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _productos = await _repositorio.obtenerProductos();
      _categorias = await _repositorio.obtenerCategorias();
    } catch (e) {
      _error = 'No se pudo leer el inventario guardado: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void setFiltro(String valor) {
    _filtro = valor;
    notifyListeners();
  }

  void alternarInactivos() {
    _verInactivos = !_verInactivos;
    notifyListeners();
  }

  Future<Producto?> obtenerPorId(String id) => _repositorio.obtenerPorId(id);

  Future<Producto?> buscarPorCodigo(String codigo) =>
      _repositorio.obtenerPorCodigo(codigo);

  /// CU-01: registrar producto (devuelve el producto con id final).
  Future<Producto> crearProducto(Producto producto) async {
    final creado = await CrearProducto(_repositorio)(producto);
    await cargarProductos();
    return creado;
  }

  /// CU-05: existencias iniciales como ENTRADA (una sola operación).
  Future<void> registrarStockInicial({
    required String productoId,
    required int cantidad,
    required String responsable,
    String motivo = 'Stock inicial',
  }) async {
    await RegistrarStockInicial(_repositorio, _movRepo)(
      productoId: productoId,
      cantidad: cantidad,
      motivo: motivo,
      responsable: responsable,
    );
    await cargarProductos();
  }

  /// CU-03: editar producto.
  Future<void> actualizarProducto(Producto producto) async {
    await ActualizarProducto(_repositorio)(producto);
    await cargarProductos();
  }

  /// CU-04: desactivar/eliminar según exista historial.
  Future<void> desactivarProducto(String id) async {
    await DesactivarProducto(_repositorio, _movRepo)(id);
    await cargarProductos();
  }

  /// CU-06: reactivar producto.
  Future<void> reactivarProducto(String id) async {
    await ReactivarProducto(_repositorio)(id);
    await cargarProductos();
  }

  /// Crea una categoría si no existe y la deja seleccionable en el formulario.
  Future<void> crearCategoria(String nombre) async {
    await _repositorio.crearCategoria(nombre);
    await cargarProductos();
  }
}
