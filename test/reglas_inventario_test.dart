import 'package:flutter_test/flutter_test.dart';

import 'package:inventario_flutter/core/errors/failures.dart';
import 'package:inventario_flutter/core/utils/id_generator.dart';
import 'package:inventario_flutter/features/productos/domain/entities/producto.dart';
import 'package:inventario_flutter/features/productos/domain/entities/categoria.dart';
import 'package:inventario_flutter/features/productos/domain/repositories/producto_repository.dart';
import 'package:inventario_flutter/features/inventario/domain/entities/movimiento.dart';
import 'package:inventario_flutter/features/inventario/domain/entities/filtro_movimientos.dart';
import 'package:inventario_flutter/features/inventario/domain/repositories/movimiento_repository.dart';
import 'package:inventario_flutter/features/inventario/domain/usecases/registrar_entrada.dart';
import 'package:inventario_flutter/features/inventario/domain/usecases/registrar_salida.dart';
import 'package:inventario_flutter/features/inventario/domain/usecases/registrar_ajuste.dart';
import 'package:inventario_flutter/features/inventario/domain/usecases/registrar_stock_inicial.dart';
import 'package:inventario_flutter/features/productos/domain/usecases/crear_producto.dart';
import 'package:inventario_flutter/features/productos/domain/usecases/desactivar_producto.dart';

/// PRUEBAS DE LAS REGLAS DE INVENTARIO.
/// Se ejecutan con: flutter test
/// Utilizan repositorios fake en memoria.

class FakeProductoRepo implements ProductoRepository {
  final Map<String, Producto> db = {};

  @override
  Future<List<Producto>> obtenerProductos() async => db.values.toList();

  @override
  Future<Producto?> obtenerPorId(String id) async => db[id];

  @override
  Future<Producto?> obtenerPorCodigo(String codigo) async {
    for (final p in db.values) {
      if (p.codigo == codigo) return p;
    }
    return null;
  }

  @override
  Future<List<Producto>> buscar(String query) async {
    return db.values
        .where((p) =>
            p.nombre.toLowerCase().contains(query.toLowerCase()) ||
            p.codigo.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<void> crearProducto(Producto producto) async {
    db[producto.id] = producto;
  }

  @override
  Future<void> actualizarProducto(Producto producto) async {
    db[producto.id] = producto;
  }

  @override
  Future<void> desactivarProducto(String id) async {
    final p = db[id];
    if (p != null) db[id] = p.copyWith(activo: false);
  }

  @override
  Future<void> reactivarProducto(String id) async {
    final p = db[id];
    if (p != null) db[id] = p.copyWith(activo: true);
  }

  @override
  Future<void> eliminarProducto(String id) async {
    db.remove(id);
  }

  @override
  Future<List<Categoria>> obtenerCategorias() async => [];

  @override
  Future<void> crearCategoria(String nombre) async {
    // Implementación requerida para cumplir el contrato del repositorio.
  }
}

/// Fake del repositorio de movimientos.
/// Registra el movimiento y actualiza las existencias.
class FakeMovimientoRepo implements MovimientoRepository {
  final FakeProductoRepo productos;
  final List<Movimiento> db = [];

  FakeMovimientoRepo(this.productos);

  @override
  Future<List<Movimiento>> obtenerMovimientos({
    FiltroMovimientos? filtro,
  }) async {
    var lista = [...db]..sort((a, b) => b.fecha.compareTo(a.fecha));

    if (filtro?.productoId != null) {
      lista = lista.where((m) => m.productoId == filtro!.productoId).toList();
    }

    return lista;
  }

  @override
  Future<List<Movimiento>> obtenerPorProducto(String productoId) {
    return obtenerMovimientos(
      filtro: FiltroMovimientos(productoId: productoId),
    );
  }

  @override
  Future<void> registrarConActualizacionStock({
    required Movimiento movimiento,
    required Producto productoResultante,
  }) async {
    db.add(movimiento);
    await productos.actualizarProducto(productoResultante);
  }
}

Producto _productoDemo({int stock = 0, int minimo = 5}) => Producto(
      id: IdGenerator.nuevoId(),
      codigo: 'PRUEBA-001',
      nombre: 'Producto de prueba',
      precioCompra: 10,
      precioVenta: 15,
      stockActual: stock,
      stockMinimo: minimo,
    );

void main() {
  late FakeProductoRepo productos;
  late FakeMovimientoRepo movimientos;

  setUp(() {
    productos = FakeProductoRepo();
    movimientos = FakeMovimientoRepo(productos);
  });

  group('CU-01 Crear producto', () {
    test('rechaza código duplicado', () async {
      final p = _productoDemo();
      await CrearProducto(productos)(p);

      expect(
        () => CrearProducto(productos)(_productoDemo()),
        throwsA(isA<CodigoDuplicadoFailure>()),
      );
    });

    test('rechaza nombre vacío', () async {
      final p = Producto(
        id: 'x1',
        codigo: 'C1',
        nombre: '   ',
        precioCompra: 1,
        precioVenta: 2,
        stockActual: 0,
        stockMinimo: 0,
      );

      expect(
        () => CrearProducto(productos)(p),
        throwsA(isA<ValidacionFailure>()),
      );
    });
  });

  group('CU-05 Stock inicial como entrada', () {
    test('registra un movimiento de entrada trazable', () async {
      final p = _productoDemo();
      await CrearProducto(productos)(p);

      await RegistrarStockInicial(productos, movimientos)(
        productoId: p.id,
        cantidad: 5,
        responsable: 'Tester',
      );

      final movs = await movimientos.obtenerPorProducto(p.id);

      expect(movs, hasLength(1));
      expect(movs.first.tipo, 'entrada');
      expect(movs.first.stockAnterior, 0);
      expect(movs.first.stockResultante, 5);
      expect((await productos.obtenerPorId(p.id))!.stockActual, 5);
    });

    test('rechaza cantidad 0 o negativa', () async {
      final p = _productoDemo();
      await CrearProducto(productos)(p);

      expect(
        () => RegistrarStockInicial(productos, movimientos)(
          productoId: p.id,
          cantidad: 0,
          responsable: 'T',
        ),
        throwsA(isA<ValidacionFailure>()),
      );
    });
  });

  group('CU-07 Entrada', () {
    test('aumenta existencias y guarda anterior/resultante', () async {
      final p = _productoDemo(stock: 5);
      await productos.crearProducto(p);

      await RegistrarEntrada(productos, movimientos)(
        productoId: p.id,
        cantidad: 20,
        motivo: 'Compra',
        responsable: 'Tester',
      );

      final guardado = await productos.obtenerPorId(p.id);
      expect(guardado!.stockActual, 25);

      final movs = await movimientos.obtenerPorProducto(p.id);
      expect(movs.first.stockAnterior, 5);
      expect(movs.first.stockResultante, 25);
      expect(movs.first.responsable, 'Tester');
      expect(movs.first.motivo, 'Compra');
    });

    test('rechaza cantidad 0 o negativa', () async {
      final p = _productoDemo(stock: 5);
      await productos.crearProducto(p);

      expect(
        () => RegistrarEntrada(productos, movimientos)(
          productoId: p.id,
          cantidad: 0,
          motivo: 'Compra',
          responsable: 'T',
        ),
        throwsA(isA<ValidacionFailure>()),
      );
    });

    test('rechaza motivo vacío', () async {
      final p = _productoDemo(stock: 5);
      await productos.crearProducto(p);

      expect(
        () => RegistrarEntrada(productos, movimientos)(
          productoId: p.id,
          cantidad: 1,
          motivo: '  ',
          responsable: 'T',
        ),
        throwsA(isA<ValidacionFailure>()),
      );
    });
  });

  group('CU-08 Salida', () {
    test('permite salida igual al stock disponible', () async {
      final p = _productoDemo(stock: 4);
      await productos.crearProducto(p);

      await RegistrarSalida(productos, movimientos)(
        productoId: p.id,
        cantidad: 4,
        motivo: 'Venta',
        responsable: 'Tester',
      );

      expect((await productos.obtenerPorId(p.id))!.stockActual, 0);
    });

    test('NO permite salida superior al stock', () async {
      final p = _productoDemo(stock: 4);
      await productos.crearProducto(p);

      expect(
        () => RegistrarSalida(productos, movimientos)(
          productoId: p.id,
          cantidad: 5,
          motivo: 'Venta',
          responsable: 'T',
        ),
        throwsA(isA<StockInsuficienteFailure>()),
      );

      // El stock no cambia y no se registra movimiento.
      expect((await productos.obtenerPorId(p.id))!.stockActual, 4);
      expect(await movimientos.obtenerPorProducto(p.id), isEmpty);
    });
  });

  group('CU-09 Ajuste', () {
    test('corrige existencias con justificación obligatoria', () async {
      final p = _productoDemo(stock: 4);
      await productos.crearProducto(p);

      await RegistrarAjuste(productos, movimientos)(
        productoId: p.id,
        cantidadContada: 3,
        justificacion: 'Conteo físico mensual',
        responsable: 'Tester',
      );

      expect((await productos.obtenerPorId(p.id))!.stockActual, 3);

      final movs = await movimientos.obtenerPorProducto(p.id);
      expect(movs.first.tipo, 'ajuste');
      expect(movs.first.stockResultante, 3);
    });

    test('rechaza ajuste sin justificación', () async {
      final p = _productoDemo(stock: 4);
      await productos.crearProducto(p);

      expect(
        () => RegistrarAjuste(productos, movimientos)(
          productoId: p.id,
          cantidadContada: 3,
          justificacion: '',
          responsable: 'T',
        ),
        throwsA(isA<ValidacionFailure>()),
      );
    });

    test('rechaza ajuste sin diferencia', () async {
      final p = _productoDemo(stock: 4);
      await productos.crearProducto(p);

      expect(
        () => RegistrarAjuste(productos, movimientos)(
          productoId: p.id,
          cantidadContada: 4,
          justificacion: 'Conteo',
          responsable: 'T',
        ),
        throwsA(isA<ValidacionFailure>()),
      );
    });
  });

  group('CU-04 Desactivar producto', () {
    test('con movimientos se desactiva, no se elimina', () async {
      final p = _productoDemo(stock: 5);
      await productos.crearProducto(p);

      await RegistrarEntrada(productos, movimientos)(
        productoId: p.id,
        cantidad: 1,
        motivo: 'Compra',
        responsable: 'T',
      );

      await DesactivarProducto(productos, movimientos)(p.id);

      final guardado = await productos.obtenerPorId(p.id);

      expect(guardado, isNotNull);
      expect(guardado!.activo, isFalse);
      expect(await movimientos.obtenerPorProducto(p.id), isNotEmpty);
    });

    test('sin movimientos se elimina', () async {
      final p = _productoDemo();
      await productos.crearProducto(p);

      await DesactivarProducto(productos, movimientos)(p.id);

      expect(await productos.obtenerPorId(p.id), isNull);
    });
  });

  group('Producto desactivado', () {
    test('no admite movimientos', () async {
      final p = _productoDemo(stock: 5);
      await productos.crearProducto(p);
      await productos.desactivarProducto(p.id);

      expect(
        () => RegistrarEntrada(productos, movimientos)(
          productoId: p.id,
          cantidad: 1,
          motivo: 'Compra',
          responsable: 'T',
        ),
        throwsA(isA<ValidacionFailure>()),
      );
    });
  });
}
