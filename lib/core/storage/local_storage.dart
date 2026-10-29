import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalStorage {
  static const _keyProductos = 'productos';
  static const _keyCategorias = 'categorias';
  static const _keyMovimientos = 'movimientos';
  static const _keyResponsable = 'responsable_nombre';

  late SharedPreferences _prefs;
  bool _initialized = false;
  bool get isReady => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    if (!_prefs.containsKey(_keyCategorias)) {
      await _seedDemo();
    }

    if (!_prefs.containsKey(_keyResponsable)) {
      await _prefs.setString(_keyResponsable, 'Operador local');
    }

    _initialized = true;
  }

  // ---------------- SEED DEMO ----------------
  Future<void> _seedDemo() async {
    final categorias = [
      {'id': 'cat1', 'nombre': 'Electrónica'},
      {'id': 'cat2', 'nombre': 'Alimentos'},
      {'id': 'cat3', 'nombre': 'Limpieza'},
    ];

    // 15 productos demo
    final productosSeed = <Map<String, dynamic>>[
      // Electrónica
      _prod('p1', 'ELE-001', 'Audífonos Bluetooth', 'cat1', 15, 25, 20, 5),
      _prod('p2', 'ELE-002', 'Cable USB-C 2m', 'cat1', 2, 5, 50, 10),
      _prod('p3', 'ELE-003', 'Mouse inalámbrico', 'cat1', 8, 15, 15, 5),
      _prod('p4', 'ELE-004', 'Teclado mecánico', 'cat1', 30, 50, 8, 3),
      _prod('p5', 'ELE-005', 'Cargador 20W', 'cat1', 10, 18, 30, 10),
      // Alimentos
      _prod('p6', 'ALI-001', 'Café molido 500g', 'cat2', 5, 10, 40, 10),
      _prod('p7', 'ALI-002', 'Azúcar 1kg', 'cat2', 1.5, 3, 60, 15),
      _prod('p8', 'ALI-003', 'Arroz 1kg', 'cat2', 1.2, 2.5, 50, 20),
      _prod('p9', 'ALI-004', 'Aceite 1L', 'cat2', 2, 4, 25, 10),
      _prod('p10', 'ALI-005', 'Leche en polvo 400g', 'cat2', 6, 10, 18, 5),
      // Limpieza
      _prod('p11', 'LIM-001', 'Detergente 1L', 'cat3', 3, 6, 35, 10),
      _prod('p12', 'LIM-002', 'Jabón líquido 500ml', 'cat3', 2, 4.5, 40, 12),
      _prod('p13', 'LIM-003', 'Cloro 1L', 'cat3', 1.5, 3.5, 20, 8),
      _prod('p14', 'LIM-004', 'Fregasuelos 2L', 'cat3', 4, 7, 12, 5),
      _prod('p15', 'LIM-005', 'Esponja x3', 'cat3', 1, 2.5, 50, 15),
    ];

    // Movimientos de entrada inicial (trazabilidad)
    final movimientosSeed = <Map<String, dynamic>>[];
    for (final p in productosSeed) {
      movimientosSeed.add({
        'id': const Uuid().v4(),
        'productoId': p['id'],
        'tipo': 'entrada',
        'cantidad': p['stockActual'],
        'stockAnterior': 0,
        'stockResultante': p['stockActual'],
        'motivo': 'Stock inicial demo',
        'responsable': 'Sistema',
        'fecha': DateTime.now().toIso8601String(),
      });
    }

    await _prefs.setString(_keyCategorias, jsonEncode(categorias));
    await _prefs.setString(_keyProductos, jsonEncode(productosSeed));
    await _prefs.setString(_keyMovimientos, jsonEncode(movimientosSeed));
  }

  Map<String, dynamic> _prod(String id, String codigo, String nombre,
      String catId, double pCompra, double pVenta, int stock, int min) {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': 'Producto de demostración',
      'categoriaId': catId,
      'precioCompra': pCompra,
      'precioVenta': pVenta,
      'stockActual': stock,
      'stockMinimo': min,
      'fotoBase64': null,
      'activo': true,
    };
  }

  // ---------------- PRODUCTOS ----------------
  List<Map<String, dynamic>> getProductos() => _leerLista(_keyProductos);
  Future<void> saveProductos(List<Map<String, dynamic>> l) =>
      _guardarLista(_keyProductos, l);

  // ---------------- CATEGORÍAS ----------------
  List<Map<String, dynamic>> getCategorias() => _leerLista(_keyCategorias);
  Future<void> saveCategorias(List<Map<String, dynamic>> l) =>
      _guardarLista(_keyCategorias, l);

  // ---------------- MOVIMIENTOS ----------------
  List<Map<String, dynamic>> getMovimientos() => _leerLista(_keyMovimientos);
  Future<void> saveMovimientos(List<Map<String, dynamic>> l) =>
      _guardarLista(_keyMovimientos, l);

  // ---------------- RESPONSABLE ----------------
  String getResponsable() =>
      _prefs.getString(_keyResponsable) ?? 'Operador local';
  Future<void> setResponsable(String nombre) async {
    await _prefs.setString(_keyResponsable, nombre);
  }

  // ---------------- HELPERS ----------------
  List<Map<String, dynamic>> _leerLista(String key) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('LocalStorage error "$key": $e');
      return [];
    }
  }

  Future<void> _guardarLista(String key, List<Map<String, dynamic>> l) async {
    await _prefs.setString(key, jsonEncode(l));
  }

  Future<void> limpiarTodo() async {
    await _prefs.remove(_keyProductos);
    await _prefs.remove(_keyCategorias);
    await _prefs.remove(_keyMovimientos);
    await _prefs.remove(_keyResponsable);
    _initialized = false;
  }
}
