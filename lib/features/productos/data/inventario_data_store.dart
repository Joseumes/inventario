import '../../../../core/storage/local_storage.dart';
import '../domain/entities/producto.dart';
import '../domain/entities/categoria.dart';
import '../../inventario/domain/entities/movimiento.dart';

/// Acceso de bajo nivel compartido a productos, categorías y movimientos.
///
/// Centraliza la lectura/escritura de JSON en LocalStorage y sirve de
/// base para las implementaciones de los repositorios (capa de datos).
class InventarioDataStore {
  final LocalStorage storage;
  InventarioDataStore(this.storage);

  // ---------------- PRODUCTOS ----------------
  List<Producto> leerProductos() =>
      storage.getProductos().map((m) => Producto.fromMap(m)).toList();

  Future<void> escribirProductos(List<Producto> lista) =>
      storage.saveProductos(lista.map((p) => p.toMap()).toList());

  // ---------------- CATEGORÍAS ----------------
  List<Categoria> leerCategorias() =>
      storage.getCategorias().map((m) => Categoria.fromMap(m)).toList();

  Future<void> escribirCategorias(List<Categoria> lista) =>
      storage.saveCategorias(lista.map((c) => c.toMap()).toList());

  // ---------------- MOVIMIENTOS ----------------
  List<Movimiento> leerMovimientos() =>
      storage.getMovimientos().map((m) => Movimiento.fromMap(m)).toList();

  Future<void> escribirMovimientos(List<Movimiento> lista) =>
      storage.saveMovimientos(lista.map((m) => m.toMap()).toList());
}
