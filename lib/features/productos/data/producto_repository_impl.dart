import '../domain/repositories/producto_repository.dart';
import '../domain/entities/producto.dart';
import '../domain/entities/categoria.dart';
import 'inventario_data_store.dart';

/// Implementación del repositorio de productos sobre LocalStorage.
class ProductoRepositoryImpl implements ProductoRepository {
  final InventarioDataStore store;
  final CategoriaRepositoryImpl _categoriaRepo;

  ProductoRepositoryImpl(this.store)
      : _categoriaRepo = CategoriaRepositoryImpl(store);

  @override
  Future<List<Producto>> obtenerProductos() async => store.leerProductos();

  @override
  Future<Producto?> obtenerPorId(String id) async {
    for (final p in store.leerProductos()) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<Producto?> obtenerPorCodigo(String codigo) async {
    final c = codigo.trim();
    if (c.isEmpty) return null;
    for (final p in store.leerProductos()) {
      if (p.codigo == c) return p;
    }
    return null;
  }

  @override
  Future<List<Producto>> buscar(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return store.leerProductos();
    return store.leerProductos().where((p) {
      return p.nombre.toLowerCase().contains(q) ||
          p.codigo.toLowerCase().contains(q) ||
          (p.descripcion ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<void> crearProducto(Producto producto) =>
      _agregarOReemplazar(producto);

  @override
  Future<void> actualizarProducto(Producto producto) =>
      _agregarOReemplazar(producto);

  Future<void> _agregarOReemplazar(Producto producto) async {
    final lista = store.leerProductos();
    final i = lista.indexWhere((e) => e.id == producto.id);
    if (i == -1) {
      lista.add(producto);
    } else {
      lista[i] = producto;
    }
    await store.escribirProductos(lista);
  }

  @override
  Future<void> desactivarProducto(String id) async =>
      _cambiarEstado(id, false);

  @override
  Future<void> reactivarProducto(String id) async => _cambiarEstado(id, true);

  Future<void> _cambiarEstado(String id, bool activo) async {
    final lista = store.leerProductos();
    final i = lista.indexWhere((e) => e.id == id);
    if (i != -1) {
      lista[i] = lista[i].copyWith(activo: activo);
      await store.escribirProductos(lista);
    }
  }

  @override
  Future<void> eliminarProducto(String id) async {
    final lista = store.leerProductos()..removeWhere((p) => p.id == id);
    await store.escribirProductos(lista);
  }

  @override
  Future<List<Categoria>> obtenerCategorias() async =>
      _categoriaRepo.obtenerCategorias();

  @override
  Future<void> crearCategoria(String nombre) async =>
      _categoriaRepo.crearCategoria(nombre);
}

/// Implementación del repositorio de categorías sobre LocalStorage.
/// Evita duplicados por nombre (comparación sin distinción de mayúsculas).
class CategoriaRepositoryImpl implements CategoriaRepository {
  final InventarioDataStore store;

  CategoriaRepositoryImpl(this.store);

  @override
  Future<List<Categoria>> obtenerCategorias() async => store.leerCategorias();

  @override
  Future<void> crearCategoria(String nombre) async {
    final n = nombre.trim();
    if (n.isEmpty) return;
    final lista = store.leerCategorias();
    if (lista.any((c) => c.nombre.toLowerCase() == n.toLowerCase())) {
      return; // Ya existe: no duplica
    }
    final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    lista.add(Categoria(id: id, nombre: n));
    await store.escribirCategorias(lista);
  }
}
