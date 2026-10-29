import 'package:flutter/foundation.dart';
import '../../domain/entities/movimiento.dart';
import '../../domain/entities/filtro_movimientos.dart';
import '../../domain/repositories/movimiento_repository.dart';
import '../../domain/usecases/obtener_historial.dart';
import '../../domain/usecases/registrar_entrada.dart';
import '../../domain/usecases/registrar_salida.dart';
import '../../domain/usecases/registrar_ajuste.dart';
import '../../domain/usecases/registrar_stock_inicial.dart';
import '../../../productos/domain/repositories/producto_repository.dart';

/// ESTADO: Presentación de movimientos de inventario.
///
/// Flujo de dependencias: Presentación → Casos de uso (Dominio) → Datos.
/// Los errores de reglas de negocio (ValidacionFailure,
/// StockInsuficienteFailure, etc.) se propagan a las páginas para
/// mostrarlos con SnackBar legibles.
class MovimientoProvider extends ChangeNotifier {
  final MovimientoRepository _movRepo;
  final ProductoRepository _prodRepo;

  MovimientoProvider(this._movRepo, this._prodRepo);

  List<Movimiento> _movimientos = [];
  bool _cargando = false;
  String? _error;

  List<Movimiento> get movimientos => _movimientos;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Carga el historial completo (más reciente primero) en memoria.
  /// El filtrado se aplica en memoria con [filtrar] para no perder la
  /// lista completa al cambiar de pestaña o de pantalla.
  Future<void> cargarMovimientos() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _movimientos = await ObtenerHistorial(_movRepo)();
    } catch (e) {
      _error = 'No se pudo leer el historial: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Aplica el caso de uso ObtenerHistorial con filtros sobre la lista
  /// ya cargada (producto, tipo y fechas).
  List<Movimiento> filtrar(FiltroMovimientos filtro) {
    if (filtro.estaVacio) return List.unmodifiable(_movimientos);
    return _movimientos.where((m) {
      if (filtro.productoId != null && m.productoId != filtro.productoId) {
        return false;
      }
      if (filtro.tipo != null && m.tipo != filtro.tipo) return false;
      if (filtro.desde != null && m.fecha.isBefore(filtro.desde!)) return false;
      if (filtro.hasta != null &&
          m.fecha.isAfter(filtro.hasta!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Movimientos de un producto específico (usado en el detalle).
  List<Movimiento> movimientosDe(String productoId) =>
      filtrar(FiltroMovimientos(productoId: productoId));

  Future<void> registrarEntrada({
    required String productoId,
    required int cantidad,
    required String motivo,
    required String responsable,
  }) async {
    await RegistrarEntrada(_prodRepo, _movRepo)(
      productoId: productoId,
      cantidad: cantidad,
      motivo: motivo,
      responsable: responsable,
    );
    await cargarMovimientos();
  }

  Future<void> registrarSalida({
    required String productoId,
    required int cantidad,
    required String motivo,
    required String responsable,
  }) async {
    await RegistrarSalida(_prodRepo, _movRepo)(
      productoId: productoId,
      cantidad: cantidad,
      motivo: motivo,
      responsable: responsable,
    );
    await cargarMovimientos();
  }

  Future<void> registrarAjuste({
    required String productoId,
    required int cantidadContada,
    required String justificacion,
    required String responsable,
  }) async {
    await RegistrarAjuste(_prodRepo, _movRepo)(
      productoId: productoId,
      cantidadContada: cantidadContada,
      justificacion: justificacion,
      responsable: responsable,
    );
    await cargarMovimientos();
  }

  Future<void> registrarStockInicial({
    required String productoId,
    required int cantidad,
    required String responsable,
    String motivo = 'Stock inicial',
  }) async {
    await RegistrarStockInicial(_prodRepo, _movRepo)(
      productoId: productoId,
      cantidad: cantidad,
      motivo: motivo,
      responsable: responsable,
    );
    await cargarMovimientos();
  }
}
